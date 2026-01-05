import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/text_audiobook.dart';

class TextImportService {
  /// Importer un fichier texte, EPUB ou PDF
  Future<TextAudiobook?> importTextFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'epub', 'pdf'],
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      final filePath = file.path!;

      if (filePath.endsWith('.txt')) {
        return _importTxtFile(filePath);
      } else if (filePath.endsWith('.epub')) {
        // TODO: Implémenter EPUB parsing
        print('EPUB support à venir');
        return null;
      } else if (filePath.endsWith('.pdf')) {
        // TODO: Implémenter PDF text extraction
        print('PDF support à venir');
        return null;
      }

      return null;
    } catch (e) {
      print('Erreur import fichier: $e');
      return null;
    }
  }

  /// Importer un fichier TXT
  Future<TextAudiobook> _importTxtFile(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      final fileName = file.path.split('/').last.split('.').first;

      return TextAudiobook(
        title: fileName,
        author: 'Importé',
        sourceType: 'txt',
        content: content,
        totalCharacters: content.length,
        dateImported: DateTime.now(),
      );
    } catch (e) {
      print('Erreur lecture TXT: $e');
      rethrow;
    }
  }

  /// Extraire chunks de texte (paragraphes) pour TTS
  List<String> chunkTextByParagraphs(String text, {int maxChars = 500}) {
    final paragraphs =
        text.split('\n').where((p) => p.trim().isNotEmpty).toList();
    final chunks = <String>[];
    String currentChunk = '';

    for (final paragraph in paragraphs) {
      if ((currentChunk + paragraph).length > maxChars) {
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk.trim());
        }
        currentChunk = paragraph;
      } else {
        currentChunk += '\n$paragraph';
      }
    }

    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk.trim());
    }

    return chunks;
  }

  /// Obtenir chunk suivant à partir de position (en caractères)
  String getChunkFromPosition(String text, int position) {
    if (position >= text.length) {
      return '';
    }
    return text.substring(position);
  }

  /// Créer audiobook depuis texte local
  TextAudiobook createLocalTextAudiobook(
    String title,
    String author,
    String sourceType,
    String content,
  ) {
    return TextAudiobook(
      title: title,
      author: author,
      sourceType: sourceType,
      content: content,
      totalCharacters: content.length,
      dateImported: DateTime.now(),
    );
  }
}
