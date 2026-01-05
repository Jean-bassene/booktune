import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:epubx/epubx.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
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
        return await _importEpubFile(filePath);
      } else if (filePath.endsWith('.pdf')) {
        return await _importPdfFile(filePath);
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

  /// Importer un fichier EPUB
  Future<TextAudiobook> _importEpubFile(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final book = await EpubReader.readBook(bytes);
      
      // Extraire métadonnées
      final title = book.Title ?? 'EPUB Importé';
      final author = book.Author ?? 'Auteur inconnu';
      
      // Extraire le contenu texte
      final content = StringBuffer();
      
      // Parcourir tous les chapitres
      for (final chapter in book.Chapters ?? <EpubChapter>[]) {
        final chapterContent = await _extractChapterText(chapter);
        if (chapterContent.isNotEmpty) {
          content.writeln(chapterContent);
          content.writeln(); // Saut de ligne entre chapitres
        }
      }
      
      final fullText = content.toString();
      
      return TextAudiobook(
        title: title,
        author: author,
        sourceType: 'epub',
        content: fullText,
        totalCharacters: fullText.length,
        dateImported: DateTime.now(),
      );
    } catch (e) {
      print('Erreur lecture EPUB: $e');
      rethrow;
    }
  }

  /// Extraire le texte d'un chapitre EPUB
  Future<String> _extractChapterText(EpubChapter chapter) async {
    try {
      final htmlContent = chapter.HtmlContent ?? '';
      // Supprimer les balises HTML basiques
      String text = htmlContent
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      
      // Traiter les sous-chapitres récursivement
      for (final subChapter in chapter.SubChapters ?? <EpubChapter>[]) {
        final subText = await _extractChapterText(subChapter);
        if (subText.isNotEmpty) {
          text += '\n\n$subText';
        }
      }
      
      return text;
    } catch (e) {
      print('Erreur extraction chapitre: $e');
      return '';
    }
  }

  /// Importer un fichier PDF
  Future<TextAudiobook> _importPdfFile(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      
      final content = StringBuffer();
      
      // Extraire le texte de chaque page
      for (int i = 0; i < document.pages.count; i++) {
        final textExtractor = PdfTextExtractor(document);
        final pageText = textExtractor.extractText(startPageIndex: i, endPageIndex: i);
        
        if (pageText.isNotEmpty) {
          content.writeln(pageText);
          content.writeln(); // Saut de ligne entre pages
        }
      }
      
      document.dispose();
      
      final fileName = file.path.split('/').last.split('.').first;
      final fullText = content.toString();
      
      return TextAudiobook(
        title: fileName,
        author: 'PDF Importé',
        sourceType: 'pdf',
        content: fullText,
        totalCharacters: fullText.length,
        dateImported: DateTime.now(),
      );
    } catch (e) {
      print('Erreur lecture PDF: $e');
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
