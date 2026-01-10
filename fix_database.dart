import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

void main() async {
  print('🔧 Réparation de la base de données Booktune...');

  try {
    // Obtenir le répertoire des documents
    final directory = await getApplicationDocumentsDirectory();
    final dbPath = path.join(directory.path, 'booktune.db');

    print('📁 Chemin de la base de données: $dbPath');

    // Vérifier si la base de données existe
    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      print(
          '🗃️ Base de données trouvée, taille: ${await dbFile.length()} bytes');

      // Fermer toutes les connexions potentielles
      await databaseFactory.deleteDatabase(dbPath);
      print('🗑️ Ancienne base de données supprimée');
    } else {
      print('📭 Aucune base de données trouvée');
    }

    // Créer une nouvelle base de données
    final database = await openDatabase(
      dbPath,
      version: 3,
      onCreate: (db, version) async {
        print('🏗️ Création de la nouvelle base de données...');

        // Table audiobooks
        await db.execute('''
          CREATE TABLE audiobooks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            author TEXT NOT NULL,
            filePath TEXT NOT NULL,
            duration INTEGER,
            coverArtPath TEXT,
            lastPosition INTEGER DEFAULT 0,
            dateImported INTEGER NOT NULL,
            fileSize INTEGER,
            isFavorite INTEGER DEFAULT 0,
            isNetwork INTEGER DEFAULT 0
          )
        ''');

        // Table ambient_music
        await db.execute('''
          CREATE TABLE ambient_music (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            filePath TEXT NOT NULL,
            dateImported INTEGER NOT NULL,
            fileSize INTEGER,
            isFavorite INTEGER DEFAULT 0
          )
        ''');

        print('✅ Tables créées avec succès');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        print('⬆️ Migration de version $oldVersion vers $newVersion');

        if (oldVersion < 2) {
          // Ajouter la colonne isNetwork si elle n'existe pas
          try {
            await db.execute(
                'ALTER TABLE audiobooks ADD COLUMN isNetwork INTEGER DEFAULT 0');
          } catch (e) {
            print('Colonne isNetwork déjà existante: $e');
          }
        }

        if (oldVersion < 3) {
          // Migration vers version 3 si nécessaire
          print('Migration vers version 3 terminée');
        }
      },
    );

    // Tester la base de données
    final audiobookCount = Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM audiobooks'));
    final ambientCount = Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM ambient_music'));

    print('📊 Test de la base de données:');
    print('   - Livres audio: $audiobookCount');
    print('   - Musiques d\'ambiance: $ambientCount');

    await database.close();
    print('✅ Base de données réparée avec succès !');
  } catch (e, stackTrace) {
    print('❌ Erreur lors de la réparation: $e');
    print('StackTrace: $stackTrace');
  }
}
