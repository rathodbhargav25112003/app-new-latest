// Cortex AI v2/v3 — API service
//
// Wraps every /api/cortex/* endpoint. Mirrors the existing http-package
// idiom used everywhere else in the app (api_service.dart). SSE streaming
// is implemented WITHOUT an extra package — uses a raw HttpClient + line
// reader, which works on iOS, Android, and web Flutter without adding any
// new dependency. (flutter_client_sse would also work but is unnecessary
// here.)
//
// Auth header attached the same way as every other ApiService call:
// SharedPreferences.getInstance().getString("token") on every request.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/constants.dart';
import '../../models/cortex_models.dart';

class CortexService {
  // ── Helpers ─────────────────────────────────────────────────────────────

  Future<Map<String, String>> _headers({bool json = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      if (json) 'Content-Type': 'application/json',
      'Authorization': token,
    };
  }

  /// Unwraps the standard server envelope `{ success, data }` and returns
  /// `data` as a `Map<String, dynamic>`. Falls back to the raw body if the
  /// envelope is missing.
  Map<String, dynamic> _unwrap(http.Response res) {
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      if (decoded['data'] is Map<String, dynamic>) {
        return decoded['data'] as Map<String, dynamic>;
      }
      return decoded;
    }
    return {};
  }

  // ── Usage ───────────────────────────────────────────────────────────────

  Future<CortexUsage> getUsage() async {
    final res = await http.get(Uri.parse(cortexUsage), headers: await _headers());
    if (res.statusCode == 200) return CortexUsage.fromJson(_unwrap(res));
    return CortexUsage.empty();
  }

  // ── Chat CRUD ───────────────────────────────────────────────────────────

  Future<List<CortexChat>> listChats({
    int page = 1,
    int limit = 30,
    String? contextKind,
    bool? archived,
  }) async {
    final qp = <String, String>{'page': '$page', 'limit': '$limit'};
    if (contextKind != null) qp['context_kind'] = contextKind;
    if (archived != null) qp['archived'] = archived ? 'true' : 'false';
    final uri = Uri.parse(cortexChats).replace(queryParameters: qp);
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode == 200) {
      final data = _unwrap(res);
      final chats = (data['chats'] as List?) ?? [];
      return chats.map((c) => CortexChat.fromJson(c as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Creates a chat. If [firstMessage] is supplied, the server runs the
  /// first turn and includes it in the response under `first_reply`.
  Future<Map<String, dynamic>> createChat({
    String contextKind = 'general',
    String? questionId,
    String? examId,
    String? userExamId,
    String? topicName,
    String? subtopicName,
    String? title,
    String? firstMessage,
    List<String>? images,
  }) async {
    final body = <String, dynamic>{
      'context_kind': contextKind,
      if (questionId != null) 'question_id': questionId,
      if (examId != null) 'exam_id': examId,
      if (userExamId != null) 'user_exam_id': userExamId,
      if (topicName != null) 'topic_name': topicName,
      if (subtopicName != null) 'subtopic_name': subtopicName,
      if (title != null) 'title': title,
      if (firstMessage != null) 'first_message': firstMessage,
      if (images != null && images.isNotEmpty) 'images': images,
    };
    final res = await http.post(
      Uri.parse(cortexChat),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 201 || res.statusCode == 200) return _unwrap(res);
    throw Exception('Create chat failed: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> getChat(String chatId, {bool full = false, int? tail}) async {
    final qp = <String, String>{};
    if (full) qp['full'] = 'true';
    if (tail != null) qp['tail'] = '$tail';
    final uri = Uri.parse('$cortexChat/$chatId').replace(queryParameters: qp.isEmpty ? null : qp);
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode == 200) return _unwrap(res);
    throw Exception('Get chat failed: ${res.statusCode}');
  }

  Future<void> patchChat(
    String chatId, {
    String? title,
    bool? pinned,
    bool? archived,
  }) async {
    final body = <String, dynamic>{
      if (title != null) 'title': title,
      if (pinned != null) 'pinned': pinned,
      if (archived != null) 'archived': archived,
    };
    await http.patch(
      Uri.parse('$cortexChat/$chatId'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
  }

  Future<void> deleteChat(String chatId) async {
    await http.delete(Uri.parse('$cortexChat/$chatId'), headers: await _headers());
  }

  // ── Append message — non-streaming ──────────────────────────────────────

  Future<Map<String, dynamic>> sendMessage(
    String chatId,
    String content, {
    List<String>? images,
    int? maxTokens,
  }) async {
    final body = <String, dynamic>{
      'content': content,
      if (images != null && images.isNotEmpty) 'images': images,
      if (maxTokens != null) 'max_tokens': maxTokens,
    };
    final res = await http.post(
      Uri.parse('$cortexChatMessage/$chatId/message'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) return _unwrap(res);
    final err = _safeError(res);
    throw CortexApiException(err.message, err.code, res.statusCode);
  }

  // ── Append message — STREAMING via raw HttpClient ───────────────────────
  //
  // Returns a stream of CortexStreamEvent. Calling code:
  //   final stream = service.streamMessage(chatId, content);
  //   await for (final ev in stream) {
  //     if (ev is CortexDelta) appendToBubble(ev.text);
  //     if (ev is CortexDone) markDone(ev);
  //     if (ev is CortexMeta) saveIds(ev);
  //     if (ev is CortexError) showError(ev.message);
  //   }

  Stream<CortexStreamEvent> streamMessage(
    String chatId,
    String content, {
    List<String>? images,
  }) async* {
    final uri = Uri.parse('$cortexChatMessage/$chatId/message?stream=true');
    final body = <String, dynamic>{
      'content': content,
      if (images != null && images.isNotEmpty) 'images': images,
    };
    yield* _streamPost(uri, body);
  }

  // Streaming variants for special endpoints
  Stream<CortexStreamEvent> streamMistakeDebrief({
    required String questionId,
    required String selectedOption,
    String? correctOption,
    String? examId,
    String? userExamId,
    String examType = 'regular',
  }) async* {
    final uri = Uri.parse('$cortexMistakeDebrief?stream=true');
    final body = <String, dynamic>{
      'question_id': questionId,
      'selected_option': selectedOption,
      if (correctOption != null) 'correct_option': correctOption,
      if (examId != null) 'exam_id': examId,
      if (userExamId != null) 'user_exam_id': userExamId,
      'exam_type': examType,
    };
    yield* _streamPost(uri, body);
  }

  Stream<CortexStreamEvent> streamRoleplay({
    required String role,
    required String scenario,
    String difficulty = 'standard',
  }) async* {
    final uri = Uri.parse('$cortexRoleplay?stream=true');
    yield* _streamPost(uri, {'role': role, 'scenario': scenario, 'difficulty': difficulty});
  }

  Stream<CortexStreamEvent> streamOsceViva(String topic) async* {
    final uri = Uri.parse('$cortexOsceViva?stream=true');
    yield* _streamPost(uri, {'topic': topic});
  }

  Stream<CortexStreamEvent> streamTopicDeepDive(String topic) async* {
    final uri = Uri.parse('$cortexTopicDeepDive?stream=true');
    yield* _streamPost(uri, {'topic': topic});
  }

  // Core SSE pump — used by all stream* methods above
  Stream<CortexStreamEvent> _streamPost(Uri uri, Map<String, dynamic> body) async* {
    final headers = await _headers();
    final client = HttpClient();
    HttpClientRequest? request;
    HttpClientResponse? response;
    try {
      request = await client.postUrl(uri);
      headers.forEach((k, v) => request!.headers.set(k, v));
      request.write(jsonEncode(body));
      response = await request.close();

      if (response.statusCode != 200) {
        // Read the error body and yield CortexError, then bail.
        final errBody = await response.transform(utf8.decoder).join();
        Map<String, dynamic>? errJson;
        try { errJson = jsonDecode(errBody) as Map<String, dynamic>; } catch (_) {}
        final msg = errJson?['err']?['message']?.toString() ??
            errJson?['error']?.toString() ??
            'Stream failed (${response.statusCode})';
        final code = errJson?['err']?['code']?.toString();
        yield CortexError(msg, code, response.statusCode);
        return;
      }

      // SSE format: each event is `data: <json>\n\n`. We split on \n, skip
      // anything not prefixed with `data:`, and yield events one by one.
      final lines = response.transform(utf8.decoder).transform(const LineSplitter());
      await for (final line in lines) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('data:')) continue;
        final data = trimmed.substring(5).trim();
        if (data.isEmpty) continue;
        try {
          final ev = jsonDecode(data) as Map<String, dynamic>;
          switch (ev['type']) {
            case 'delta':
              yield CortexDelta((ev['text'] ?? '').toString());
              break;
            case 'done':
              yield CortexDone(
                inputTokens: (ev['input_tokens'] ?? 0) is int ? ev['input_tokens'] as int : 0,
                outputTokens: (ev['output_tokens'] ?? 0) is int ? ev['output_tokens'] as int : 0,
                finishReason: (ev['finish_reason'] ?? '').toString(),
              );
              break;
            case 'meta':
              yield CortexMeta(
                chatId: ev['chat_id']?.toString(),
                userMessageId: ev['user_message_id']?.toString(),
                assistantMessageId: ev['assistant_message_id']?.toString(),
                model: ev['model']?.toString(),
                error: ev['error']?.toString(),
              );
              break;
            case 'error':
              yield CortexError(ev['error']?.toString() ?? 'unknown', ev['code']?.toString(), 0);
              break;
          }
        } catch (e) {
          log('[Cortex SSE] parse error: $e on line "$data"');
        }
      }
    } catch (e) {
      yield CortexError('Network error: $e', null, 0);
    } finally {
      try { client.close(force: true); } catch (_) {}
    }
  }

  // ── Mistake debrief (non-streaming) ────────────────────────────────────

  Future<Map<String, dynamic>> mistakeDebrief({
    required String questionId,
    required String selectedOption,
    String? correctOption,
    String? examId,
    String? userExamId,
    String examType = 'regular',
  }) async {
    final body = <String, dynamic>{
      'question_id': questionId,
      'selected_option': selectedOption,
      if (correctOption != null) 'correct_option': correctOption,
      if (examId != null) 'exam_id': examId,
      if (userExamId != null) 'user_exam_id': userExamId,
      'exam_type': examType,
    };
    final res = await http.post(
      Uri.parse(cortexMistakeDebrief),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) return _unwrap(res);
    final err = _safeError(res);
    throw CortexApiException(err.message, err.code, res.statusCode);
  }

  // ── Related MCQs ────────────────────────────────────────────────────────

  Future<List<CortexRelatedMcq>> relatedMcqs(String questionId,
      {String examType = 'regular', int limit = 5}) async {
    final uri = Uri.parse('$cortexRelatedMcqs/$questionId').replace(
      queryParameters: {'exam_type': examType, 'limit': '$limit'},
    );
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode == 200) {
      final data = _unwrap(res);
      final results = (data['results'] as List?) ?? [];
      return results.map((r) => CortexRelatedMcq.fromJson(r as Map<String, dynamic>)).toList();
    }
    return [];
  }

  // ── Modes (non-streaming) ──────────────────────────────────────────────

  Future<Map<String, dynamic>> startRoleplay({
    required String role,
    required String scenario,
    String difficulty = 'standard',
  }) async {
    return _post(cortexRoleplay, {'role': role, 'scenario': scenario, 'difficulty': difficulty}, 201);
  }

  Future<Map<String, dynamic>> startOsceViva(String topic) =>
      _post(cortexOsceViva, {'topic': topic}, 201);

  Future<Map<String, dynamic>> startTopicDeepDive(String topic) =>
      _post(cortexTopicDeepDive, {'topic': topic}, 201);

  Future<Map<String, dynamic>> mnemonic(String concept) =>
      _post(cortexMnemonic, {'concept': concept}, 200);

  Future<Map<String, dynamic>> diagram(String concept) =>
      _post(cortexDiagram, {'concept': concept}, 200);

  // ── Suggestions / summary ──────────────────────────────────────────────

  Future<List<String>> generateFollowups(String messageId) async {
    final res = await http.get(
      Uri.parse('$cortexFollowups/$messageId/follow-ups'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = _unwrap(res);
      final list = (data['followups'] as List?) ?? [];
      return list.map((e) => e.toString()).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> summarizeChat(String chatId) async {
    final res = await http.post(
      Uri.parse('$cortexSummarize/$chatId/summarize'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return _unwrap(res);
    return {};
  }

  // ── Flashcards ─────────────────────────────────────────────────────────

  Future<List<CortexFlashcard>> generateFlashcards(String messageId, {int count = 5}) async {
    final res = await http.post(
      Uri.parse('$cortexFlashcards/$messageId/flashcards'),
      headers: await _headers(),
      body: jsonEncode({'count': count}),
    );
    if (res.statusCode == 200) {
      final data = _unwrap(res);
      final list = (data['flashcards'] as List?) ?? [];
      return list.map((e) => CortexFlashcard.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  // ── Snippets ────────────────────────────────────────────────────────────

  Future<bool> toggleSnippet(String messageId, {bool? save, String? note}) async {
    final res = await http.post(
      Uri.parse('$cortexSnippet/$messageId/snippet'),
      headers: await _headers(),
      body: jsonEncode({
        if (save != null) 'save': save,
        if (note != null) 'note': note,
      }),
    );
    if (res.statusCode == 200) {
      final data = _unwrap(res);
      return data['saved'] == true;
    }
    return false;
  }

  Future<List<CortexMessage>> listSnippets({int page = 1, int limit = 30}) async {
    final res = await http.get(
      Uri.parse(cortexSnippets).replace(queryParameters: {'page': '$page', 'limit': '$limit'}),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = _unwrap(res);
      final list = (data['snippets'] as List?) ?? [];
      return list.map((m) => CortexMessage.fromJson(m as Map<String, dynamic>)).toList();
    }
    return [];
  }

  // ── Search ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> searchChats(String query, {int limit = 50}) async {
    final res = await http.get(
      Uri.parse(cortexSearch).replace(queryParameters: {'q': query, 'limit': '$limit'}),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = _unwrap(res);
      final hits = (data['hits'] as List?) ?? [];
      return hits.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ── Export ─────────────────────────────────────────────────────────────

  Future<String> exportChat(String chatId) async {
    final res = await http.get(
      Uri.parse('$cortexExport/$chatId/export'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = _unwrap(res);
      return (data['markdown'] ?? '').toString();
    }
    return '';
  }

  // ── Memory ─────────────────────────────────────────────────────────────

  Future<CortexMemory> getMemory() async {
    final res = await http.get(Uri.parse(cortexMemory), headers: await _headers());
    if (res.statusCode == 200) return CortexMemory.fromJson(_unwrap(res));
    return CortexMemory.empty();
  }

  Future<CortexMemory> updateMemory({String? notes, CortexPreferences? preferences}) async {
    final body = <String, dynamic>{
      if (notes != null) 'notes': notes,
      if (preferences != null) 'preferences': preferences.toJson(),
    };
    final res = await http.patch(
      Uri.parse(cortexMemory),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) return CortexMemory.fromJson(_unwrap(res));
    return CortexMemory.empty();
  }

  // ── Quick prompts ──────────────────────────────────────────────────────

  Future<CortexQuickPrompts> getQuickPrompts({String contextKind = 'general'}) async {
    final res = await http.get(
      Uri.parse(cortexQuickPrompts).replace(queryParameters: {'context_kind': contextKind}),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return CortexQuickPrompts.fromJson(_unwrap(res));
    return CortexQuickPrompts();
  }

  // ── Internal POST helper ───────────────────────────────────────────────

  Future<Map<String, dynamic>> _post(String url, Map<String, dynamic> body, int expectedStatus) async {
    final res = await http.post(
      Uri.parse(url),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == expectedStatus || res.statusCode == 200) return _unwrap(res);
    final err = _safeError(res);
    throw CortexApiException(err.message, err.code, res.statusCode);
  }

  _ApiError _safeError(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map<String, dynamic>) {
        final errMsg = body['err']?['message']?.toString() ??
            body['error']?.toString() ??
            body['message']?.toString();
        final code = body['err']?['code']?.toString();
        return _ApiError(errMsg ?? 'Cortex error', code);
      }
    } catch (_) {}
    return _ApiError('Cortex error', null);
  }
}

class _ApiError {
  final String message;
  final String? code;
  _ApiError(this.message, this.code);
}

class CortexApiException implements Exception {
  final String message;
  final String? code;
  final int statusCode;
  CortexApiException(this.message, this.code, this.statusCode);

  bool get isRateLimit => code == 'CORTEX_RATE_LIMIT' || statusCode == 429;
  @override
  String toString() => 'CortexApiException($statusCode${code == null ? '' : '/$code'}): $message';
}

// ── SSE event types ─────────────────────────────────────────────────────

abstract class CortexStreamEvent {}

class CortexDelta extends CortexStreamEvent {
  final String text;
  CortexDelta(this.text);
}

class CortexDone extends CortexStreamEvent {
  final int inputTokens;
  final int outputTokens;
  final String finishReason;
  CortexDone({this.inputTokens = 0, this.outputTokens = 0, this.finishReason = ''});
}

class CortexMeta extends CortexStreamEvent {
  final String? chatId;
  final String? userMessageId;
  final String? assistantMessageId;
  final String? model;
  final String? error;
  CortexMeta({this.chatId, this.userMessageId, this.assistantMessageId, this.model, this.error});
}

class CortexError extends CortexStreamEvent {
  final String message;
  final String? code;
  final int statusCode;
  CortexError(this.message, this.code, this.statusCode);
  bool get isRateLimit => code == 'CORTEX_RATE_LIMIT' || statusCode == 429;
}
