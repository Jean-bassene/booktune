import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/librivox_book.dart';
import 'logging_service.dart';

class LibrivoxService {
  final http.Client _httpClient;
  final String _librivoxApiBaseUrl = 'https://librivox.org/api/feed/audiobooks';
  final String _rssBaseUrl = 'https://librivox.org/rss';

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

  /// Fetches book details and chapters from the RSS feed (au lieu de archive.org)
  Future<LibrivoxBook?> getBookDetails(String bookId) async {
    LoggingService.d('[getBookDetails] Début pour bookId: $bookId');

    try {
      // Utiliser le RSS pour obtenir les chapitres
      final rssUrl = Uri.parse('$_rssBaseUrl/$bookId');
      LoggingService.d('[getBookDetails] RSS URL: $rssUrl');

      final response = await _httpClient.get(rssUrl);

      if (response.statusCode != 200) {
        LoggingService.e(
            '[getBookDetails] Erreur HTTP ${response.statusCode} pour $bookId');
        return null;
      }

      final xmlContent = response.body;

      // Parser le titre
      final titleMatch = RegExp(r'<title><!\[CDATA\[(.*?)\]\]></title>')
          .firstMatch(xmlContent);
      final title = titleMatch?.group(1) ?? 'Untitled';

      // Parser l'auteur (itunes:author)
      final authorMatch =
          RegExp(r'<itunes:author><!\[CDATA\[(.*?)\]\]></itunes:author>')
              .firstMatch(xmlContent);
      final author = authorMatch?.group(1) ?? 'Unknown Author';

      // Parser la description
      final descMatch =
          RegExp(r'<description><!\[CDATA\[(.*?)\]\]></description>')
              .firstMatch(xmlContent);
      final description = _stripHtmlTags(descMatch?.group(1) ?? '');

      // Parser les chapitres depuis les items
      final chapters = <LibrivoxChapter>[];
      int chapterNum = 0;

      // Extraire tous les items
      final itemPattern = RegExp(
        r'<item>.*?<title><!\[CDATA\[(.*?)\]\]></title>.*?<enclosure url="(.*?)".*?<itunes:duration>(.*?)</itunes:duration>',
        dotAll: true,
      );

      for (final match in itemPattern.allMatches(xmlContent)) {
        chapterNum++;
        final itemTitle = match.group(1) ?? 'Unknown';
        final url = match.group(2) ?? '';
        final duration = match.group(3);

        if (url.isNotEmpty && url.endsWith('.mp3')) {
          chapters.add(LibrivoxChapter(
            title: 'Chapter $chapterNum: $itemTitle',
            url: url,
            trackNumber: chapterNum,
            duration: _parseDuration(duration),
          ));
        }
      }

      if (chapters.isEmpty) {
        LoggingService.w('[getBookDetails] Aucun chapitre trouvé pour $bookId');
        return null;
      }

      LoggingService.i(
          '[getBookDetails] Succès: "$title" avec ${chapters.length} chapitres');

      // Calculer la durée totale
      final totalDuration = chapters.fold<Duration>(
        Duration.zero,
        (sum, c) => sum + c.duration,
      );

      return LibrivoxBook(
        id: bookId,
        title: title,
        author: author,
        description: description,
        language: 'English',
        coverUrl: null,
        totalDuration: totalDuration,
        chapters: chapters,
      );
    } catch (e, stackTrace) {
      LoggingService.e(
          '[getBookDetails) Exception pour $bookId', e, stackTrace);
      return null;
    }
  }

  /// Supprime les balises HTML d'une chaîne
  String _stripHtmlTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  /// Parse une chaîne de durée en Duration
  Duration _parseDuration(String? durationString) {
    if (durationString == null || durationString.isEmpty) {
      return Duration.zero;
    }

    try {
      // Format HH:MM:SS ou MM:SS
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

      // Format secondes simples
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
