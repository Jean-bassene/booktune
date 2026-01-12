import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/downloaded_book.dart';
import 'logging_service.dart';

/// Service de base de données pour les livres LibriVox téléchargés
class DownloadedBooksDatabase {
  static Database? _database;
  static const String _dbName = 'downloaded_books.db';
  static const int _dbVersion = 1;

  // Tables
  static const String _booksTable = 'downloaded_books';
  static const String _chaptersTable = 'downloaded_chapters';

  /// Initialise la base de données
  static Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  /// Crée et initialise la base de données
  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  /// Crée les tables de la base de données
  static Future<void> _createTables(Database db, int version) async {
    // Table des livres téléchargés
    await db.execute('''
      CREATE TABLE $_booksTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        description TEXT NOT NULL,
        language TEXT NOT NULL,
        totalTimeSeconds INTEGER NOT NULL,
        coverUrl TEXT,
        downloadDate TEXT NOT NULL,
        localCoverPath TEXT NOT NULL,
        totalSizeBytes INTEGER NOT NULL,
        genre TEXT NOT NULL,
        chaptersCount INTEGER NOT NULL
      )
    ''');

    // Table des chapitres téléchargés
    await db.execute('''
      CREATE TABLE $_chaptersTable (
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        title TEXT NOT NULL,
        durationSeconds INTEGER NOT NULL,
        localFilePath TEXT NOT NULL,
        fileSizeBytes INTEGER NOT NULL,
        listenedSeconds INTEGER NOT NULL DEFAULT 0,
        downloadDate TEXT NOT NULL,
        FOREIGN KEY (bookId) REFERENCES $_booksTable (id) ON DELETE CASCADE
      )
    ''');

    LoggingService.i('Tables de base de données créées');
  }

  /// Met à jour la base de données
  static Future<void> _upgradeDatabase(
      Database db, int oldVersion, int newVersion) async {
    // Logique de migration future
    LoggingService.i('Migration BD: $oldVersion -> $newVersion');
  }

  /// Sauvegarde un livre téléchargé
  static Future<void> saveDownloadedBook(DownloadedBook book) async {
    final db = await database;

    await db.transaction((txn) async {
      // Insérer le livre
      await txn.insert(
        _booksTable,
        book.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Supprimer les anciens chapitres
      await txn.delete(
        _chaptersTable,
        where: 'bookId = ?',
        whereArgs: [book.id],
      );

      // Insérer les nouveaux chapitres
      for (final chapter in book.chapters) {
        await txn.insert(
          _chaptersTable,
          chapter.toMap(book.id),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    LoggingService.i('Livre sauvegardé: ${book.title}');
  }

  /// Récupère tous les livres téléchargés
  static Future<List<DownloadedBook>> getAllDownloadedBooks() async {
    final db = await database;

    final bookMaps = await db.query(_booksTable, orderBy: 'downloadDate DESC');

    final books = <DownloadedBook>[];
    for (final bookMap in bookMaps) {
      final chapters = await _getChaptersForBook(db, bookMap['id'] as String);
      final book = DownloadedBook.fromMap(bookMap, chapters);
      books.add(book);
    }

    return books;
  }

  /// Récupère un livre téléchargé par son ID
  static Future<DownloadedBook?> getDownloadedBook(String bookId) async {
    final db = await database;

    final bookMaps = await db.query(
      _booksTable,
      where: 'id = ?',
      whereArgs: [bookId],
    );

    if (bookMaps.isEmpty) return null;

    final chapters = await _getChaptersForBook(db, bookId);
    return DownloadedBook.fromMap(bookMaps.first, chapters);
  }

  /// Récupère les chapitres d'un livre
  static Future<List<DownloadedChapter>> _getChaptersForBook(
      Database db, String bookId) async {
    final chapterMaps = await db.query(
      _chaptersTable,
      where: 'bookId = ?',
      whereArgs: [bookId],
      orderBy: 'id ASC',
    );

    return chapterMaps.map((map) => DownloadedChapter.fromMap(map)).toList();
  }

  /// Met à jour la progression d'écoute d'un chapitre
  static Future<void> updateChapterProgress(
      String chapterId, int listenedSeconds) async {
    final db = await database;

    await db.update(
      _chaptersTable,
      {'listenedSeconds': listenedSeconds},
      where: 'id = ?',
      whereArgs: [chapterId],
    );

    LoggingService.d('Progression chapitre mise à jour: $chapterId');
  }

  /// Supprime un livre téléchargé
  static Future<void> deleteDownloadedBook(String bookId) async {
    final db = await database;

    await db.delete(
      _booksTable,
      where: 'id = ?',
      whereArgs: [bookId],
    );

    LoggingService.i('Livre supprimé de la BD: $bookId');
  }

  /// Vérifie si un livre est déjà téléchargé
  static Future<bool> isBookDownloaded(String bookId) async {
    final db = await database;

    final result = await db.query(
      _booksTable,
      where: 'id = ?',
      whereArgs: [bookId],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  /// Recherche des livres téléchargés
  static Future<List<DownloadedBook>> searchDownloadedBooks(
      String query) async {
    final db = await database;

    final bookMaps = await db.query(
      _booksTable,
      where: 'title LIKE ? OR author LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'downloadDate DESC',
    );

    final books = <DownloadedBook>[];
    for (final bookMap in bookMaps) {
      final chapters = await _getChaptersForBook(db, bookMap['id'] as String);
      final book = DownloadedBook.fromMap(bookMap, chapters);
      books.add(book);
    }

    return books;
  }

  /// Obtient des statistiques
  static Future<Map<String, dynamic>> getStatistics() async {
    final db = await database;

    final bookCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $_booksTable'),
        ) ??
        0;

    final totalSize = Sqflite.firstIntValue(
          await db.rawQuery('SELECT SUM(totalSizeBytes) FROM $_booksTable'),
        ) ??
        0;

    final totalListeningTime = Sqflite.firstIntValue(
          await db.rawQuery('SELECT SUM(listenedSeconds) FROM $_chaptersTable'),
        ) ??
        0;

    return {
      'bookCount': bookCount,
      'totalSize': totalSize,
      'totalListeningTime': totalListeningTime,
    };
  }

  /// Ferme la base de données
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
