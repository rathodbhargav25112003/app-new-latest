import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:path_provider/path_provider.dart';

/// Offline-video encryption for at-rest protection.
///
/// File format:
///   v2 (chunked, streaming-safe — new default):
///     [magic "SUSH"][version=2][chunk_count (u32 big-endian)]
///     per chunk: [nonce(12)][len(u32 BE)][ciphertext(len bytes)][tag(16)]
///
///   v1 (legacy — full-file GCM, kept for backward-compatibility with
///       already-downloaded files on user devices):
///     [magic "SUSH"][version=1][nonce(12)][ciphertext][tag(16)]
///
/// v2 allows encrypt/decrypt of multi-hundred-MB videos without loading the
/// entire file into RAM (iOS would OOM on ~500MB). Chunk size is 4 MiB.
///
/// Back-compat: [decryptFileToTemp] auto-detects the version and handles both.
/// New encryptions always write v2.
class OfflineEncryptor {
  static const List<int> _magic = [0x53, 0x55, 0x53, 0x48]; // "SUSH"
  static const int _versionV1 = 1;
  static const int _versionV2 = 2;
  static const int _chunkSize = 4 * 1024 * 1024; // 4 MiB

  /// Encrypt [inFile] → [outFile] using AES-256-GCM (chunked v2 format).
  /// Streams in 4MB chunks so memory footprint stays tiny even for huge files.
  static Future<void> encryptFile(File inFile, File outFile, List<int> key) async {
    if (key.length != 32) {
      throw ArgumentError('AES-256 requires a 32-byte key, got ${key.length}');
    }

    final totalBytes = await inFile.length();
    final chunkCount = (totalBytes / _chunkSize).ceil();

    final cipher = AesGcm.with256bits();
    final secretKey = SecretKey(key);

    // Ensure any stale output is removed first.
    if (await outFile.exists()) {
      try {
        await outFile.delete();
      } catch (_) {}
    }
    await outFile.parent.create(recursive: true);

    final input = inFile.openRead();
    final sink = outFile.openWrite();

    try {
      // Header: magic + version + chunk_count(u32 BE)
      sink.add(_magic);
      sink.add([_versionV2]);
      sink.add(_u32BE(chunkCount));

      // We collect 4MiB into a single buffer, encrypt, emit, repeat.
      // openRead() yields arbitrary-sized chunks; we must re-chunk.
      final pending = BytesBuilder(copy: false);

      Future<void> flushChunk() async {
        if (pending.length == 0) return;
        final plain = pending.takeBytes();
        final nonce = _secureRandomBytes(12);
        final box = await cipher.encrypt(plain, secretKey: secretKey, nonce: nonce);
        sink.add(nonce);
        sink.add(_u32BE(box.cipherText.length));
        sink.add(box.cipherText);
        sink.add(box.mac.bytes);
      }

      await for (final part in input) {
        int off = 0;
        while (off < part.length) {
          final remain = _chunkSize - pending.length;
          final take = math.min(remain, part.length - off);
          pending.add(part.sublist(off, off + take));
          off += take;
          if (pending.length >= _chunkSize) {
            await flushChunk();
          }
        }
      }
      // Flush the tail chunk (may be < 4MiB)
      await flushChunk();
    } finally {
      await sink.flush();
      await sink.close();
    }
  }

  /// Decrypt [encFile] → temp clear file and return it.
  ///
  /// Auto-detects v1 (legacy whole-file) and v2 (chunked) formats.
  /// Streams v2 files so RAM usage stays bounded even for very large videos.
  static Future<File> decryptFileToTemp(File encFile, List<int> key) async {
    if (key.length != 32) {
      throw ArgumentError('AES-256 requires a 32-byte key');
    }

    final raf = await encFile.open();
    try {
      // Read header: magic(4) + version(1)
      final headerProbe = await raf.read(_magic.length + 1);
      if (headerProbe.length < _magic.length + 1) {
        throw const FormatException('Invalid encrypted file: header too short');
      }
      for (int i = 0; i < _magic.length; i++) {
        if (headerProbe[i] != _magic[i]) {
          throw const FormatException('Bad magic header');
        }
      }
      final version = headerProbe[_magic.length];

      final tmpDir = await getTemporaryDirectory();
      final tmp = File(
        '${tmpDir.path}/${encFile.uri.pathSegments.last}.${DateTime.now().millisecondsSinceEpoch}.tmp',
      );
      await tmp.parent.create(recursive: true);

      if (version == _versionV1) {
        // Legacy: whole-file GCM. Small files okay; use streaming read to
        // avoid pulling everything at once when possible. GCM still needs the
        // auth tag at the end — so for v1 we fall back to full-buffer.
        final total = await encFile.length();
        final remaining = total - (_magic.length + 1);
        final rest = await raf.read(remaining);
        if (rest.length < 12 + 16) {
          throw const FormatException('v1 file truncated');
        }
        final nonce = rest.sublist(0, 12);
        final tag = rest.sublist(rest.length - 16);
        final ciphertext = rest.sublist(12, rest.length - 16);
        final cipher = AesGcm.with256bits();
        final secretKey = SecretKey(key);
        final clear = await cipher.decrypt(
          SecretBox(ciphertext, nonce: nonce, mac: Mac(tag)),
          secretKey: secretKey,
        );
        await tmp.writeAsBytes(clear, flush: true);
        return tmp;
      }

      if (version != _versionV2) {
        throw FormatException('Unsupported version: $version');
      }

      // v2: chunked — stream-decrypt
      final chunkCountBytes = await raf.read(4);
      if (chunkCountBytes.length < 4) {
        throw const FormatException('v2 file truncated at header');
      }
      final chunkCount = _readU32BE(chunkCountBytes);

      final cipher = AesGcm.with256bits();
      final secretKey = SecretKey(key);

      final out = tmp.openWrite();
      try {
        for (int i = 0; i < chunkCount; i++) {
          final nonce = await raf.read(12);
          if (nonce.length < 12) {
            throw FormatException('v2 file truncated at chunk $i nonce');
          }
          final lenBytes = await raf.read(4);
          if (lenBytes.length < 4) {
            throw FormatException('v2 file truncated at chunk $i len');
          }
          final len = _readU32BE(lenBytes);
          final ct = await raf.read(len);
          if (ct.length < len) {
            throw FormatException('v2 file truncated at chunk $i ciphertext');
          }
          final tag = await raf.read(16);
          if (tag.length < 16) {
            throw FormatException('v2 file truncated at chunk $i tag');
          }
          final clear = await cipher.decrypt(
            SecretBox(ct, nonce: nonce, mac: Mac(tag)),
            secretKey: secretKey,
          );
          out.add(clear);
        }
      } finally {
        await out.flush();
        await out.close();
      }
      return tmp;
    } finally {
      await raf.close();
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  static final math.Random _rng = math.Random.secure();

  static List<int> _secureRandomBytes(int n) {
    final out = Uint8List(n);
    for (int i = 0; i < n; i++) {
      out[i] = _rng.nextInt(256);
    }
    return out;
  }

  static List<int> _u32BE(int v) {
    return [
      (v >> 24) & 0xFF,
      (v >> 16) & 0xFF,
      (v >> 8) & 0xFF,
      v & 0xFF,
    ];
  }

  static int _readU32BE(List<int> b) {
    return ((b[0] & 0xFF) << 24) |
        ((b[1] & 0xFF) << 16) |
        ((b[2] & 0xFF) << 8) |
        (b[3] & 0xFF);
  }
}
