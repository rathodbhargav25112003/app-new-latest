import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../models/video_offline_data_model.dart';
import 'package:shusruta_lms/models/notes_offline_data_model.dart';


class DbHelper {
  static Database? _database;
  final String tableName = 'notes_table';
  final String videoTableName = 'video_table';

  /// One-time-per-process flag that confirms we've ensured the runtime
  /// indexes are present. See [_ensureIndexes] for why we do this outside
  /// of the onCreate / onUpgrade migrations.
  static bool _indexesEnsured = false;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await initDatabase();
    // Runtime index creation — catches existing installs that were created
    // at schema v1 before the index existed. `CREATE INDEX IF NOT EXISTS` is
    // idempotent so repeated calls are a no-op on installs that already
    // have it.
    await _ensureIndexes(_database!);
    return _database!;
  }

  Future<Database> initDatabase() async {
    final dbPath = await getDatabasesPath();
    final pathToDatabase = path.join(dbPath, 'notes.db');
    return await openDatabase(pathToDatabase,
        version: 1, onCreate: _createDatabase);
  }

  /// Create indexes on hot-path lookup columns.
  ///
  /// Why not use `onUpgrade` + `version: 2`? Bumping the schema version
  /// triggers sqflite's migration hook — if a user has a corrupt or
  /// partially-migrated DB (seen in the wild on abrupt kills during a
  /// migration) the whole app gets stuck in a failed-open loop. Runtime
  /// `CREATE INDEX IF NOT EXISTS` is safe on every install: new ones hit
  /// the index right away, old ones get it on next app launch.
  ///
  /// Perf note: `getVideoByTitleId` + `deleteVideoByTitleId` run on every
  /// offline-video tap, list render, and load-downloaded scan. Without the
  /// index they full-table-scan `video_table`; with it they're O(log n)
  /// lookups. For a user with 200 downloaded lectures this is the
  /// difference between 50 ms and <1 ms per query.
  Future<void> _ensureIndexes(Database db) async {
    if (_indexesEnsured) return;
    try {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_video_titleId ON $videoTableName(titleId)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notes_titleId ON $tableName(titleId)',
      );
      _indexesEnsured = true;
    } catch (e) {
      // Non-fatal — queries will just be slower. Don't block app startup on
      // index creation failures (e.g. locked DB, disk full).
      // ignore: avoid_print
      print('[DB] _ensureIndexes failed: $e');
    }
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
    CREATE TABLE $tableName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      topicName TEXT,
        title TEXT,
      categoryName TEXT,
      subCategoryName TEXT,
        titleId TEXT,
      categoryId TEXT,
      subCategoryId TEXT,
      topicId TEXT,
      notePath TEXT,
      annotation_json TEXT
    )
  ''');

    await db.execute('''
      CREATE TABLE $videoTableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topicName TEXT,
        title TEXT,
        videoPath TEXT,
        categoryName TEXT,
        subCategoryName TEXT,
        categoryId TEXT,
        subCategoryId TEXT,
        topicId TEXT,
        titleId TEXT
      )
    ''');

    // Create indexes as part of fresh install — no upgrade needed.
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_video_titleId ON $videoTableName(titleId)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_notes_titleId ON $tableName(titleId)',
    );
  }

  Future<int> insert(NotesOfflineDataModel dataModel) async {
    final db = await database;
    return await db.insert(tableName, dataModel.toMap());
  }

  Future<int> insertVideo(VideoOfflineDataModel dataModel) async {
    final db = await database;
    return await db.insert(videoTableName, dataModel.toMap());
  }

  Future<List<NotesOfflineDataModel>> getAllNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return List.generate(maps.length, (i) {
      return NotesOfflineDataModel.fromMap(maps[i]);
    });
  }

  Future<List<NotesOfflineDataModel>> getAllNotesGroupedByCategoryId() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM $tableName
      GROUP BY categoryId
    ''');

    return List.generate(maps.length, (i) {
      return NotesOfflineDataModel.fromMap(maps[i]);
    });
  }

  Future<List<VideoOfflineDataModel>> getAllVideoGroupedByCategoryId() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM $videoTableName
      GROUP BY categoryId
    ''');

    return List.generate(maps.length, (i) {
      return VideoOfflineDataModel.fromMap(maps[i]);
    });
  }
  Future<Map<String, int>> getOfflineNotesCountsByCategoryIds(List<String> categoryIds) async {
    final db = await database;

    final Map<String, int> counts = {};

    for (String categoryId in categoryIds) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableName WHERE categoryId = ?',
        [categoryId],
      );
      counts[categoryId] = result.isNotEmpty ? (result.first['count'] as int) : 0;
    }

    return counts;
  }

  Future<Map<String, int>> getOfflineCountsByCategoryIds(List<String> categoryIds) async {
    final db = await database;

    final Map<String, int> counts = {};

    for (String categoryId in categoryIds) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $videoTableName WHERE categoryId = ?',
        [categoryId],
      );
      counts[categoryId] = result.isNotEmpty ? (result.first['count'] as int) : 0;
    }

    return counts;
  }

  Future<Map<String, int>> getOfflineNotesCountsBySubCategoryIds(List<String> subCategoryIds) async {
    final db = await database;

    final Map<String, int> counts = {};

    for (String subCategoryId in subCategoryIds) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableName WHERE subCategoryId = ?',
        [subCategoryId],
      );
      counts[subCategoryId] = result.isNotEmpty ? (result.first['count'] as int) : 0;
    }

    return counts;
  }

  Future<Map<String, int>> getOfflineCountsBySubCategoryIds(List<String> subCategoryIds) async {
    final db = await database;

    final Map<String, int> counts = {};

    for (String subCategoryId in subCategoryIds) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $videoTableName WHERE subCategoryId = ?',
        [subCategoryId],
      );
      counts[subCategoryId] = result.isNotEmpty ? (result.first['count'] as int) : 0;
    }

    return counts;
  }

  Future<Map<String, int>> getOfflineNotesCountsByTopicIds(List<String> topicIds) async {
    final db = await database;

    final Map<String, int> counts = {};

    for (String topicId in topicIds) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableName WHERE topicId = ?',
        [topicId],
      );
      counts[topicId] = result.isNotEmpty ? (result.first['count'] as int) : 0;
    }

    return counts;
  }

  Future<Map<String, int>> getOfflineCountsByTopicIds(List<String> topicIds) async {
    final db = await database;

    final Map<String, int> counts = {};

    for (String topicId in topicIds) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $videoTableName WHERE topicId = ?',
        [topicId],
      );
      counts[topicId] = result.isNotEmpty ? (result.first['count'] as int) : 0;
    }

    return counts;
  }

  Future<int> getAllNotesGroupByCategoryIdDelete() async {
    final db = await database;
    return await db.rawDelete('DELETE FROM $tableName');
  }

  Future<List<NotesOfflineDataModel>> getAllNotesGroupedBySubCategoryId(
      String categoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM $tableName WHERE categoryId = "$categoryId"
      GROUP BY subCategoryId
    ''');

    return List.generate(maps.length, (i) {
      return NotesOfflineDataModel.fromMap(maps[i]);
    });
  }

  Future<List<NotesOfflineDataModel>> getAllNotesGroupedByTopicId(
      String subCategoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM $tableName WHERE subCategoryId = "$subCategoryId"
      GROUP BY topicId
    ''');

    return List.generate(maps.length, (i) {
      return NotesOfflineDataModel.fromMap(maps[i]);
    });
  }

  Future<List<NotesOfflineDataModel>> getAllNotesGroupedByTitleId(String topicId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM $tableName WHERE topicId = "$topicId"
      GROUP BY titleId
    ''');

    return List.generate(maps.length, (i) {
      return NotesOfflineDataModel.fromMap(maps[i]);
    });
  }

  Future<int> deleteAllNotesByTopicIdWithSubcription(Set topicId) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: 'topicId =! ?',
      whereArgs: [topicId],
    );
  }

  Future<int> deleteAllNotesByTopicId(String topicId) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: 'topicId = ?',
      whereArgs: [topicId],
    );
  }

  Future<int> deleteAllNotesByTitleId(String titleId) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: 'titleId = ?',
      whereArgs: [titleId],
    );
  }

  Future<int> deleteAllNotes() async {
    final db = await database;
    return await db.delete(tableName);
  }

  Future<NotesOfflineDataModel?> getNoteByTitleId(String titleId) async {
    final db = await database;
    final result = await db.query(
      tableName,
      where: 'titleId = ?',
      whereArgs: [titleId],
    );

    if (result.isNotEmpty) {
      return NotesOfflineDataModel.fromMap(result.first);
    }
    return null;
  }

  Future<VideoOfflineDataModel?> getVideoByTitleId(String titleId) async {
    final db = await database;
    final result = await db.query(
      videoTableName,
      where: 'titleId = ?',
      whereArgs: [titleId],
    );

    if (result.isNotEmpty) {
      return VideoOfflineDataModel.fromMap(result.first);
    }
    return null;
  }

  Future<int> deleteNoteByTitleId(String titleId) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: 'titleId = ?',
      whereArgs: [titleId],
    );
  }

  Future<int> deleteVideoByTitleId(String titleId) async {
    final db = await database;
    // Also delete the encrypted file from disk
    final result = await db.query(
      videoTableName,
      where: 'titleId = ?',
      whereArgs: [titleId],
    );
    if (result.isNotEmpty) {
      final videoPath = result.first['videoPath'] as String?;
      if (videoPath != null && videoPath.isNotEmpty) {
        try {
          final file = File(videoPath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
    }
    return await db.delete(
      videoTableName,
      where: 'titleId = ?',
      whereArgs: [titleId],
    );
  }

  Future<void> saveAnnotationJson(String titleId, String json) async {
    final db = await database;
    try {
      await db.update(
        tableName,
        {'annotation_json': json},
        where: 'titleId = ?',
        whereArgs: [titleId],
      );
    } on DatabaseException catch (e) {
      if (e.toString().contains('no such column: annotation_json')) {
        await db.execute('ALTER TABLE $tableName ADD COLUMN annotation_json TEXT;');
        // Retry the update
        await db.update(
          tableName,
          {'annotation_json': json},
          where: 'titleId = ?',
          whereArgs: [titleId],
        );
      } else {
        rethrow;
      }
    }
  }

  Future<String?> getAnnotationJson(String titleId) async {
    final db = await database;
    try {
      final result = await db.query(
        tableName,
        columns: ['annotation_json'],
        where: 'titleId = ?',
        whereArgs: [titleId],
        limit: 1,
      );
      if (result.isNotEmpty) {
        return result.first['annotation_json'] as String?;
      }
      return null;
    } on DatabaseException catch (e) {
      if (e.toString().contains('no such column: annotation_json')) {
        await db.execute('ALTER TABLE $tableName ADD COLUMN annotation_json TEXT;');
        // Retry the query
        final result = await db.query(
          tableName,
          columns: ['annotation_json'],
          where: 'titleId = ?',
          whereArgs: [titleId],
          limit: 1,
        );
        if (result.isNotEmpty) {
          return result.first['annotation_json'] as String?;
        }
        return null;
      } else {
        rethrow;
      }
    }
  }

}
