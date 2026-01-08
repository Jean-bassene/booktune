import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/librivox_book.dart';
import 'logging_service.dart';

class LibrivoxService {
  final http.Client _httpClient;
  final String _librivoxApiBaseUrl = 'https://librivox.org/api/feed/audiobooks';
  final String _archiveBaseUrl = 'https://archive.org';

  LibrivoxService({required http.Client httpClient}) : _httpClient = httpClient;

  /// Fetches recent books from the LibriVox API.
  Future<List<LibrivoxBook>> getRecentBooks() async {
    try {
      final url = Uri.parse('$_librivoxApiBaseUrl?format=json');
      final response = await _httpClient.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<LibrivoxBook> books = [];
        if (data != null && data['books'] is List) {
          for (final bookData in data['books']) {
            if (bookData['id'] != null) {
              books.add(LibrivoxBook.fromLibrivoxApiJson(bookData));
            }
          }
        }
        LoggingService.i('Récupérés ${books.length} livres récents');
        return books;
      } else {
        LoggingService.e('Erreur API LibriVox: status ${response.statusCode}');
        throw Exception('Failed to load recent books from LibriVox API');
      }
    } catch (e) {
      LoggingService.e('Erreur getRecentBooks', e);
      rethrow;
    }
  }

  /// Searches for audiobooks on LibriVox using the LibriVox API.
  Future<List<LibrivoxBook>> searchBooks(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
          '$_librivoxApiBaseUrl/search?title=$encodedQuery&format=json');

      final response = await _httpClient.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<LibrivoxBook> books = [];
        if (data != null && data['books'] is List) {
          for (final bookData in data['books']) {
            if (bookData['id'] != null) {
              books.add(LibrivoxBook.fromLibrivoxApiJson(bookData));
            }
          }
        }
        LoggingService.i('Recherche "$query": ${books.length} résultats');
        return books;
      } else {
        LoggingService.e('Erreur recherche API: status ${response.statusCode}');
        throw Exception('Failed to search books from LibriVox API');
      }
    } catch (e) {
      LoggingService.e('Erreur searchBooks', e);
      rethrow;
    }
  }

  /// Fetches the details for a single audiobook from the archive.org API.
  Future<LibrivoxBook?> getBookDetails(String bookId) async {
    LoggingService.d('[getBookDetails] Début pour bookId: $bookId');

    try {
      final url = Uri.parse('$_archiveBaseUrl/metadata/$bookId');
      LoggingService.d('[getBookDetails] URL: $url');

      final response = await _httpClient.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Vérifier les données de base
        if (data == null || data is! Map<String, dynamic>) {
          LoggingService.w(
              '[getBookDetails] Données nulles ou invalides pour $bookId');
          return null;
        }

        final server = data['server'];
        final dir = data['dir'];
        final metadata = data['metadata'];

        if (server == null || dir == null || metadata == null) {
          LoggingService.w(
              '[getBookDetails] Métadonnées incomplètes pour $bookId');
          LoggingService.d(
              '[getBookDetails] server=$server, dir=$dir, metadata=${metadata?.runtimeType}');
          return null;
        }

        LoggingService.d('[getBookDetails] Métadonnées valides pour $bookId');

        // Extraire les fichiers
        final dynamic filesData = data['files'];
        List<Map<String, dynamic>> fileList = [];

        if (filesData is Map<String, dynamic>) {
          fileList =
              filesData.values.whereType<Map<String, dynamic>>().toList();
        } else if (filesData is List<dynamic>) {
          fileList = filesData.whereType<Map<String, dynamic>>().toList();
        }

        LoggingService.d(
            '[getBookDetails] ${fileList.length} fichiers trouvés');

        // Chercher les fichiers MP3 avec différents formats
        var mp3Files =
            fileList.where((file) => file['format'] == '128Kbps MP3').toList();
        if (mp3Files.isEmpty) {
          mp3Files =
              fileList.where((file) => file['format'] == '64Kbps MP3').toList();
        }
        if (mp3Files.isEmpty) {
          mp3Files = fileList
              .where(
                  (file) => (file['format'] ?? '').toString().contains('MP3'))
              .toList();
        }

        LoggingService.d(
            '[getBookDetails] ${mp3Files.length} fichiers MP3 trouvés');

        if (mp3Files.isEmpty) {
          LoggingService.w('[getBookDetails] Aucun fichier MP3 pour $bookId');
          return null;
        }

        // Trier par track
        mp3Files.sort(
            (a, b) => (a['track'] ?? '999').compareTo(b['track'] ?? '999'));

        // Créer les chapitres
        final chapters = <LibrivoxChapter>[];
        for (var file in mp3Files) {
          final trackNum = file['track']?.split('/').first ?? '0';
          chapters.add(LibrivoxChapter(
            title: file['title'] ?? 'Unknown Chapter',
            url: 'https://$server$dir/${file['name']}',
            trackNumber: int.tryParse(trackNum) ?? 0,
            duration: _parseDuration(file['length']),
          ));
        }

        final identifier = metadata['identifier'] ?? bookId;
        LoggingService.i(
            '[getBookDetails) Succès: "${metadata['title']}" avec ${chapters.length} chapitres');

        return LibrivoxBook(
          id: identifier,
          title: metadata['title'] ?? 'Untitled',
          author: _parseAuthor(metadata['creator']),
          description: metadata['description']?.toString() ??
              'No description available.',
          language: metadata['language'] ?? 'Unknown',
          coverUrl:
              'https://archive.org/services/get-item-image.php?identifier=$identifier',
          totalDuration: _parseDuration(metadata['runtime']),
          chapters: chapters,
        );
      } else {
        LoggingService.e(
            '[getBookDetails) Erreur HTTP ${response.statusCode} pour $bookId');
        return null;
      }
    } catch (e, stackTrace) {
      LoggingService.e(
          '[getBookDetails) Exception pour $bookId', e, stackTrace);
      return null;
    }
  }

  /// Parse l'auteur (peut être une liste ou une chaîne)
  String _parseAuthor(dynamic creator) {
    if (creator == null) return 'Unknown Author';
    if (creator is List) {
      return creator.join(', ');
    }
    return creator.toString();
  }

  /// Parse une chaîne de durée en Duration
  Duration _parseDuration(String? durationString) {
    if (durationString == null || durationString.isEmpty) {
      return Duration.zero;
    }

    try {
      if (durationString.contains(':')) {
        final parts = durationString.split(':');
        if (parts.length == 3) {
          return Duration(
              hours: int.parse(parts[0]),
              minutes: int.parse(parts[1]),
              seconds: double.parse(parts[2]).round());
        } else if (parts.length == 2) {
          return Duration(
              minutes: int.parse(parts[0]),
              seconds: double.parse(parts[1]).round());
        }
      }

      final seconds = double.tryParse(durationString);
      if (seconds != null) {
        return Duration(milliseconds: (seconds * 1000).round());
      }
    } catch (e) {
      LoggingService.w('Erreur parsing durée: "$durationString"');
    }

    return Duration.zero;
  }
}
