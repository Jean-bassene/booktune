import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/audiobook.dart';
import '../models/ambient_music.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('audiobook_mixer.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Supprimer la base existante pour forcer la recréation avec la nouvelle structure
    // TODO: À supprimer après la migration initiale
    final dbFile = File(path);
    if (await dbFile.exists()) {
      await dbFile.delete();
      print('Base de données supprimée pour migration');
    }

    return await openDatabase(
      path,
      version: 3, // Nouvelle version pour forcer la recréation
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Ajouter la colonne isFavorite si elle n'existe pas
      await db.execute(
          'ALTER TABLE audiobooks ADD COLUMN isFavorite INTEGER DEFAULT 0');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE audiobooks (
        id $idType,
        title $textType,
        author $textType,
        filePath $textType,
        duration $intType,
        coverArtPath TEXT,
        lastPosition $intType,
        dateImported $intType,
        fileSize $intType,
        isFavorite $intType DEFAULT 0,
        isNetwork $intType DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ambient_music (
        id $idType,
        name $textType,
        filePath $textType,
        duration $intType,
        isLoop $intType,
        category $textType,
        dateImported $intType
      )
    ''');

    await db.execute('''
      CREATE TABLE user_preferences (
        key $textType PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  // ========== Audiobooks ==========

  Future<int> insertAudiobook(Audiobook audiobook) async {
    final db = await database;
    return await db.insert('audiobooks', audiobook.toMap());
  }

  Future<List<Audiobook>> getAllAudiobooks() async {
    final db = await database;
    final maps = await db.query(
      'audiobooks',
      orderBy: 'dateImported DESC',
    );
    return maps.map((map) => Audiobook.fromMap(map)).toList();
  }

  Future<Audiobook?> getAudiobook(int id) async {
    final db = await database;
    final maps = await db.query(
      'audiobooks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Audiobook.fromMap(maps.first);
  }

  Future<int> updateAudiobook(Audiobook audiobook) async {
    final db = await database;
    return await db.update(
      'audiobooks',
      audiobook.toMap(),
      where: 'id = ?',
      whereArgs: [audiobook.id],
    );
  }

  Future<int> updateAudiobookPosition(int id, int position) async {
    final db = await database;
    return await db.update(
      'audiobooks',
      {'lastPosition': position},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateAudiobookFavorite(int id, bool isFavorite) async {
    final db = await database;
    return await db.update(
      'audiobooks',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAudiobook(int id) async {
    final db = await database;
    return await db.delete(
      'audiobooks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== Ambient Music ==========

  Future<int> insertAmbientMusic(AmbientMusic music) async {
    final db = await database;
    return await db.insert('ambient_music', music.toMap());
  }

  Future<List<AmbientMusic>> getAllAmbientMusic() async {
    final db = await database;
    final maps = await db.query(
      'ambient_music',
      orderBy: 'name ASC',
    );
    return maps.map((map) => AmbientMusic.fromMap(map)).toList();
  }

  Future<int> deleteAmbientMusic(int id) async {
    final db = await database;
    return await db.delete(
      'ambient_music',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== User Preferences (Freemium) ==========

  Future<void> setUserPreference(String key, String value) async {
    final db = await database;
    await db.insert(
      'user_preferences',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getUserPreference(String key) async {
    final db = await database;
    final maps = await db.query(
      'user_preferences',
      where: 'key = ?',
      whereArgs: [key],
    );
    return maps.isNotEmpty ? maps.first['value'] as String : null;
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
