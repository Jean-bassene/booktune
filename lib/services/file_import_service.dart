import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/audiobook.dart';
import '../models/ambient_music.dart';

class FileImportService {
  final _uuid = const Uuid();

  /// Ouvre le sélecteur de fichiers pour importer un livre audio
  Future<List<File>?> pickAudiobookFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowedExtensions: ['mp3', 'm4a', 'm4b', 'ogg', 'flac', 'wav'],
      );

      if (result != null) {
        return result.paths.map((p) => File(p!)).toList();
      }
    } catch (e) {
      print('Erreur lors de la sélection: $e');
    }
    return null;
  }

  /// Ouvre le sélecteur de fichiers pour importer une musique d'ambiance
  Future<List<File>?> pickAmbientMusicFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowedExtensions: ['mp3', 'ogg', 'wav', 'm4a'],
      );

      if (result != null) {
        return result.paths.map((p) => File(p!)).toList();
      }
    } catch (e) {
      print('Erreur lors de la sélection: $e');
    }
    return null;
  }

  /// Copie un fichier dans le stockage interne de l'app
  Future<String> copyToInternalStorage(
      File sourceFile, String directory) async {
    final appDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory('${appDir.path}/$directory');

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final extension = path.extension(sourceFile.path);
    final fileName = '${_uuid.v4()}$extension';
    final targetPath = '${targetDir.path}/$fileName';

    await sourceFile.copy(targetPath);
    return targetPath;
  }

  /// Extrait les métadonnées basiques d'un fichier audio
  Future<Map<String, dynamic>> extractBasicMetadata(File file) async {
    final fileName = path.basenameWithoutExtension(file.path);
    final fileSize = await file.length();

    return {
      'title': fileName,
      'author': 'Auteur inconnu',
      'duration': 0, // Sera obtenu par le lecteur audio
      'fileSize': fileSize,
    };
  }

  /// Crée un objet Audiobook à partir d'un fichier
  Future<Audiobook> createAudiobookFromFile(File file) async {
    final internalPath = await copyToInternalStorage(file, 'audiobooks');
    final metadata = await extractBasicMetadata(file);

    return Audiobook(
      title: metadata['title'],
      author: metadata['author'],
      filePath: internalPath,
      duration: metadata['duration'],
      fileSize: metadata['fileSize'],
    );
  }

  /// Crée un objet AmbientMusic à partir d'un fichier
  Future<AmbientMusic> createAmbientMusicFromFile(File file) async {
    final internalPath = await copyToInternalStorage(file, 'ambient');
    final metadata = await extractBasicMetadata(file);

    return AmbientMusic(
      name: metadata['title'],
      filePath: internalPath,
      duration: metadata['duration'],
      category: 'custom',
    );
  }

  /// Supprime un fichier du stockage
  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Erreur lors de la suppression: $e');
    }
  }

  /// Valide qu'un fichier est un audio valide
  Future<bool> isValidAudioFile(File file) async {
    final allowedExtensions = ['.mp3', '.m4a', '.m4b', '.ogg', '.flac', '.wav'];
    final extension = path.extension(file.path).toLowerCase();
    return allowedExtensions.contains(extension) && await file.exists();
  }
}
