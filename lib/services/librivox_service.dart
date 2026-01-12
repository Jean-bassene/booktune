import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/librivox_book.dart';
import 'logging_service.dart';

class LibrivoxService {
  final http.Client _httpClient;
  final String _librivoxApiBaseUrl =
      'https://librivox.org/api/feed/audiobooks/';
  final String _librivoxSearchUrl =
      'https://librivox.org/api/feed/audiobooks/search/';
  final String _rssBaseUrl = 'https://librivox.org/rss';

  // Cache en mémoire
  final Map<String, CachedData<List<LibrivoxBook>>> _searchCache = {};
  final Map<String, CachedData<LibrivoxBook>> _bookDetailsCache = {};
  final Duration _cacheDuration = Duration(hours: 1);

  // Debouncer pour recherches
  Timer? _searchDebouncer;

  // Timeout pour les requêtes
  final Duration _requestTimeout = Duration(seconds: 15);

  LibrivoxService({required http.Client httpClient}) : _httpClient = httpClient;

  /// Fetches recent books avec cache
  Future<List<LibrivoxBook>> getRecentBooks() async {
    const cacheKey = 'recent_books';

    // Vérifier le cache
    if (_searchCache.containsKey(cacheKey) &&
        !_searchCache[cacheKey]!.isExpired) {
      LoggingService.d('Utilisation du cache pour livres récents');
      return _searchCache[cacheKey]!.data;
    }

    try {
      final url = Uri.parse('$_librivoxApiBaseUrl?format=json&limit=50');
      final response = await _httpClient.get(url).timeout(_requestTimeout);

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

        // Mettre en cache
        _searchCache[cacheKey] = CachedData(books, DateTime.now());

        LoggingService.i('Récupérés ${books.length} livres récents');
        return books;
      } else {
        LoggingService.e('Erreur API LibriVox: status ${response.statusCode}');
        throw Exception('Failed to load recent books from LibriVox API');
      }
    } on TimeoutException {
      LoggingService.e('Timeout lors de la récupération des livres récents');
      return _searchCache[cacheKey]?.data ?? [];
    } catch (e) {
      LoggingService.e('Erreur getRecentBooks', e);
      return _searchCache[cacheKey]?.data ?? [];
    }
  }

  /// Recherche avec debouncing et cache - Recherche améliorée par auteur et titre
  Future<List<LibrivoxBook>> searchBooks(
    String query, {
    bool useDebounce = true,
    int limit = 50,
    int offset = 0,
  }) async {
    if (query.isEmpty) {
      return getRecentBooks();
    }

    // Créer une clé de cache unique
    final cacheKey = 'search_${query.toLowerCase()}_${limit}_$offset';

    // Vérifier le cache
    if (_searchCache.containsKey(cacheKey) &&
        !_searchCache[cacheKey]!.isExpired) {
      LoggingService.d('Utilisation du cache pour "$query"');
      return _searchCache[cacheKey]!.data;
    }

    try {
      final List<LibrivoxBook> allResults = [];

      // 1. Recherche par auteur
      final authorResults =
          await _searchByField(query, 'author', limit, offset);
      allResults.addAll(authorResults);

      // 2. Si peu de résultats par auteur, recherche par titre
      if (authorResults.length < 5) {
        final titleResults =
            await _searchByField(query, 'title', limit, offset);
        // Éviter les doublons
        for (final book in titleResults) {
          if (!allResults.any((existing) => existing.id == book.id)) {
            allResults.add(book);
          }
        }
      }

      // 3. Si toujours peu de résultats, recherche générale
      if (allResults.length < 5) {
        final generalResults = await _searchGeneral(query, limit, offset);
        // Éviter les doublons
        for (final book in generalResults) {
          if (!allResults.any((existing) => existing.id == book.id)) {
            allResults.add(book);
          }
        }
      }

      // Limiter les résultats
      final limitedResults = allResults.take(limit).toList();

      // Mettre en cache
      _searchCache[cacheKey] = CachedData(limitedResults, DateTime.now());

      LoggingService.i(
          'Recherche améliorée "$query": ${limitedResults.length} résultats');
      return limitedResults;
    } on TimeoutException {
      LoggingService.e('Timeout recherche "$query"');
      return _searchCache[cacheKey]?.data ?? [];
    } catch (e) {
      LoggingService.e('Erreur searchBooks', e);
      return _searchCache[cacheKey]?.data ?? [];
    }
  }

  /// Recherche par un champ spécifique (author, title, ou general)
  Future<List<LibrivoxBook>> _searchByField(
    String query,
    String field,
    int limit,
    int offset,
  ) async {
    try {
      final queryParams = {
        'format': 'json',
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      // Ajouter le champ de recherche approprié
      if (field == 'author') {
        queryParams['author'] = query;
      } else if (field == 'title') {
        queryParams['title'] = query;
      }

      final url =
          Uri.parse(_librivoxSearchUrl).replace(queryParameters: queryParams);
      LoggingService.d('[searchBooks] URL $field: $url');

      final response = await _httpClient.get(url).timeout(_requestTimeout);

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

        LoggingService.d(
            'Recherche $field "$query": ${books.length} résultats');
        return books;
      } else if (response.statusCode == 402 || response.statusCode == 429) {
        // API limitée - utiliser recherche locale
        LoggingService.w(
            'API LibriVox limitée (${response.statusCode}), recherche locale');
        return _localSearchFallback(query);
      } else {
        LoggingService.w(
            'Erreur API $field "${query}": ${response.statusCode}');
        return [];
      }
    } catch (e) {
      LoggingService.e('Erreur _searchByField $field', e);
      return [];
    }
  }

  /// Recherche générale (sans champ spécifique)
  Future<List<LibrivoxBook>> _searchGeneral(
    String query,
    int limit,
    int offset,
  ) async {
    try {
      final queryParams = {
        'format': 'json',
        'q': query, // Recherche générale
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      final url =
          Uri.parse(_librivoxSearchUrl).replace(queryParameters: queryParams);
      LoggingService.d('[searchBooks] URL général: $url');

      final response = await _httpClient.get(url).timeout(_requestTimeout);

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

        LoggingService.d(
            'Recherche générale "$query": ${books.length} résultats');
        return books;
      } else {
        LoggingService.w(
            'Erreur API générale "${query}": ${response.statusCode}');
        return [];
      }
    } catch (e) {
      LoggingService.e('Erreur _searchGeneral', e);
      return [];
    }
  }

  /// Recherche avec debouncing (pour utilisation dans UI)
  Future<List<LibrivoxBook>> searchBooksDebounced(
    String query,
    Duration debounceDuration,
  ) async {
    final completer = Completer<List<LibrivoxBook>>();

    _searchDebouncer?.cancel();
    _searchDebouncer = Timer(debounceDuration, () async {
      final results = await searchBooks(query);
      if (!completer.isCompleted) {
        completer.complete(results);
      }
    });

    return completer.future;
  }

  /// Search books by author avec cache
  Future<List<LibrivoxBook>> searchByAuthor(String author) async {
    if (author.isEmpty) {
      return getRecentBooks();
    }

    final cacheKey = 'author_${author.toLowerCase()}';

    if (_searchCache.containsKey(cacheKey) &&
        !_searchCache[cacheKey]!.isExpired) {
      return _searchCache[cacheKey]!.data;
    }

    try {
      final encodedAuthor = Uri.encodeComponent(author);
      final url = Uri.parse(
          '$_librivoxApiBaseUrl?author=$encodedAuthor&format=json&limit=50');
      LoggingService.d('[searchByAuthor] URL: $url');

      final response = await _httpClient.get(url).timeout(_requestTimeout);

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

        _searchCache[cacheKey] = CachedData(books, DateTime.now());

        LoggingService.i(
            'Recherche auteur "$author": ${books.length} résultats');
        return books;
      } else {
        LoggingService.e('Erreur API LibriVox: status ${response.statusCode}');
        return _searchCache[cacheKey]?.data ?? [];
      }
    } on TimeoutException {
      LoggingService.e('Timeout recherche auteur "$author"');
      return _searchCache[cacheKey]?.data ?? [];
    } catch (e) {
      LoggingService.e('Erreur searchByAuthor', e);
      return _searchCache[cacheKey]?.data ?? [];
    }
  }

  /// Récupère seulement le nombre de chapitres (léger pour explorateur)
  Future<int?> getChapterCount(String bookId) async {
    try {
      final rssUrl = Uri.parse('$_rssBaseUrl/$bookId');
      final response =
          await _httpClient.get(rssUrl).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return null;

      final xmlContent = response.body;
      final urlPattern = RegExp(r'<enclosure url="(.*?\.mp3)"');
      final urls =
          urlPattern.allMatches(xmlContent).map((m) => m.group(1)!).toList();

      return urls.length;
    } catch (e) {
      return null;
    }
  }

  /// Fetches book details avec cache
  /// Si existingBook est fourni, on garde son auteur
  Future<LibrivoxBook?> getBookDetails(String bookId,
      {LibrivoxBook? existingBook}) async {
    LoggingService.d('[getBookDetails] Début pour bookId: $bookId');
    LoggingService.d(
        '[getBookDetails] existingBook fourni: ${existingBook != null}');
    if (existingBook != null) {
      LoggingService.d(
          '[getBookDetails] existingBook auteur: "${existingBook.author}"');
      LoggingService.d(
          '[getBookDetails] existingBook titre: "${existingBook.title}"');
    }

    // Vérifier le cache
    if (_bookDetailsCache.containsKey(bookId) &&
        !_bookDetailsCache[bookId]!.isExpired) {
      LoggingService.d('Utilisation du cache pour book $bookId');
      final cachedBook = _bookDetailsCache[bookId]!.data;
      LoggingService.d('[getBookDetails] Cache auteur: "${cachedBook.author}"');
      return cachedBook;
    }

    try {
      final rssUrl = Uri.parse('$_rssBaseUrl/$bookId');
      LoggingService.d('[getBookDetails] RSS URL: $rssUrl');

      final response = await _httpClient.get(rssUrl).timeout(_requestTimeout);

      if (response.statusCode != 200) {
        LoggingService.e(
            '[getBookDetails] Erreur HTTP ${response.statusCode} pour $bookId');
        return _bookDetailsCache[bookId]?.data;
      }

      final xmlContent = response.body;

      final titleMatch = RegExp(r'<title><!\[CDATA\[(.*?)\]\]></title>')
          .firstMatch(xmlContent);
      final title = titleMatch?.group(1) ?? 'Untitled';

      // DEBUG: Chercher l'auteur dans le titre d'abord (format "Titre by Auteur")
      final titleAuthorMatch =
          RegExp(r'by\s+(.+?)(?:\s*\(|$)').firstMatch(title);
      final titleAuthor = titleAuthorMatch?.group(1)?.trim();
      LoggingService.d('[getBookDetails] Auteur dans titre: "$titleAuthor"');

      // PRIORISER LE RSS (comme dans booktun4) - plus fiable que l'API JSON
      final authorMatch =
          RegExp(r'<itunes:author><!\[CDATA\[(.*?)\]\]></itunes:author>')
              .firstMatch(xmlContent);
      final rssAuthor = authorMatch?.group(1);
      LoggingService.d('[getBookDetails] Auteur RSS brut: "$rssAuthor"');

      // Essayer plusieurs sources d'auteur par ordre de priorité
      final author = rssAuthor ?? // 1. RSS itunes:author
          titleAuthor ?? // 2. Auteur dans le titre
          (existingBook != null &&
                  existingBook.author != 'Unknown Author' &&
                  existingBook.author != 'Auteur inconnu'
              ? existingBook.author
              : 'Auteur inconnu'); // 3. existingBook ou inconnu

      LoggingService.d('[getBookDetails] Auteur final choisi: "$author"');

      // PRIORISER LA LANGUE RSS (comme pour l'auteur)
      final languageMatch =
          RegExp(r'<language><!\[CDATA\[(.*?)\]\]></language>')
              .firstMatch(xmlContent);
      final rssLanguage = languageMatch?.group(1);
      LoggingService.d('[getBookDetails] Langue RSS: "$rssLanguage"');

      final language = rssLanguage ?? // ← RSS en priorité
          (existingBook != null &&
                  existingBook.language != null &&
                  existingBook.language!.isNotEmpty &&
                  existingBook.language != 'Unknown'
              ? existingBook.language
              : 'Langue inconnue');

      LoggingService.d('[getBookDetails] Langue finale: "$language"');

      final descMatch =
          RegExp(r'<description><!\[CDATA\[(.*?)\]\]></description>')
              .firstMatch(xmlContent);
      final description = _stripHtmlTags(descMatch?.group(1) ?? '');

      final chapters = <LibrivoxChapter>[];

      final urlPattern = RegExp(r'<enclosure url="(.*?\.mp3)"');
      final titlePattern =
          RegExp(r'<item>.*?<title><!\[CDATA\[(.*?)\]\]></title>');
      final durationPattern =
          RegExp(r'<itunes:duration><!\[CDATA\[(.*?)\]\]></itunes:duration>');

      final urls =
          urlPattern.allMatches(xmlContent).map((m) => m.group(1)!).toList();
      final titles =
          titlePattern.allMatches(xmlContent).map((m) => m.group(1)!).toList();
      final durations = durationPattern
          .allMatches(xmlContent)
          .map((m) => m.group(1)!)
          .toList();

      LoggingService.d(
          '[getBookDetails] URLs: ${urls.length}, Titres: ${titles.length}, Durées: ${durations.length}');

      final count = urls.length;
      for (int i = 0; i < count; i++) {
        final url = urls[i];
        final chapterTitle = i < titles.length ? titles[i] : 'Chapter ${i + 1}';
        final duration = i < durations.length ? durations[i] : '';

        if (url.isNotEmpty) {
          chapters.add(LibrivoxChapter(
            title: 'Chapter ${i + 1}: $chapterTitle',
            url: url,
            trackNumber: i + 1,
            duration: _parseDuration(duration),
          ));
        }
      }

      if (chapters.isEmpty) {
        LoggingService.w('[getBookDetails] Aucun chapitre trouvé pour $bookId');
        return null;
      }

      // TRIER LES CHAPITRES PAR ORDRE NUMÉRIQUE (trackNumber)
      chapters.sort((a, b) => a.trackNumber.compareTo(b.trackNumber));
      LoggingService.d(
          '[getBookDetails] Chapitres triés: ${chapters.map((c) => c.trackNumber).toList()}');

      LoggingService.i(
          '[getBookDetails] Succès: "$title" avec ${chapters.length} chapitres (triés)');

      final totalDuration = chapters.fold<Duration>(
        Duration.zero,
        (sum, c) => sum + c.duration,
      );

      LoggingService.d(
          '[getBookDetails] Durée totale calculée: ${totalDuration.inMinutes}min ${totalDuration.inSeconds.remainder(60)}s');

      final book = LibrivoxBook(
        id: bookId,
        title: title,
        author: author,
        description: description,
        language: language,
        coverUrl: null,
        totalDuration: totalDuration,
        chapters: chapters,
      );

      // Mettre en cache
      _bookDetailsCache[bookId] = CachedData(book, DateTime.now());

      return book;
    } on TimeoutException {
      LoggingService.e('[getBookDetails] Timeout pour $bookId');
      return _bookDetailsCache[bookId]?.data;
    } catch (e, stackTrace) {
      LoggingService.e(
          '[getBookDetails] Exception pour $bookId', e, stackTrace);
      return _bookDetailsCache[bookId]?.data;
    }
  }

  /// Nettoie le cache expiré
  void cleanExpiredCache() {
    _searchCache.removeWhere((key, value) => value.isExpired);
    _bookDetailsCache.removeWhere((key, value) => value.isExpired);
    LoggingService.d('Cache nettoyé');
  }

  /// Vide tout le cache
  void clearCache() {
    _searchCache.clear();
    _bookDetailsCache.clear();
    LoggingService.d('Cache vidé');
  }

  String _stripHtmlTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

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
            seconds: double.parse(parts[2]).round(),
          );
        } else if (parts.length == 2) {
          return Duration(
            minutes: int.parse(parts[0]),
            seconds: double.parse(parts[1]).round(),
          );
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

  void dispose() {
    _searchDebouncer?.cancel();
    _cacheCleanupTimer?.cancel();
  }

  /// Recherche locale dans les livres récents (fallback quand API limitée)
  /// Recherche améliorée : mots partiels, prénoms, noms séparés, etc.
  Future<List<LibrivoxBook>> _localSearchFallback(String query) async {
    if (query.isEmpty) return getRecentBooks();

    try {
      // Récupérer les livres récents
      final recentBooks = await getRecentBooks();
      final queryLower = query.toLowerCase().trim();
      final queryWords = queryLower.split(RegExp(r'\s+')); // Diviser en mots

      // Fonction pour vérifier si un livre correspond à la recherche
      bool matchesBook(LibrivoxBook book) {
        final titleLower = book.title.toLowerCase();
        final authorLower = book.author.toLowerCase();

        // Recherche complète (titre ou auteur contient la requête entière)
        if (titleLower.contains(queryLower) ||
            authorLower.contains(queryLower)) {
          return true;
        }

        // Recherche par mots individuels
        for (final word in queryWords) {
          if (word.length < 2) continue; // Ignorer les mots trop courts

          // Recherche dans titre et auteur
          if (titleLower.contains(word) || authorLower.contains(word)) {
            return true;
          }
        }

        // Recherche floue pour les auteurs (prénoms, noms séparés)
        // Ex: "Alexandre" devrait trouver "Alexandre Dumas"
        // Ex: "Victor" devrait trouver "Victor Hugo"
        if (authorLower != 'unknown author') {
          for (final word in queryWords) {
            if (word.length >= 3) {
              // Au moins 3 caractères
              final authorWords = authorLower.split(RegExp(r'[,\s]+'));
              for (final authorWord in authorWords) {
                if (authorWord.contains(word) || word.contains(authorWord)) {
                  return true;
                }
              }
            }
          }
        }

        return false;
      }

      // Appliquer le filtre
      final results = recentBooks.where(matchesBook).toList();

      LoggingService.i(
          'Recherche locale "$query": ${results.length} résultats trouvés');
      return results;
    } catch (e) {
      LoggingService.e('Erreur _localSearchFallback', e);
      return [];
    }
  }

  // === Méthodes pour l'UI ===

  /// Charge plus de résultats pour la pagination
  Future<List<LibrivoxBook>> loadMoreResults({
    required String query,
    required int currentCount,
    int pageSize = 50,
  }) async {
    if (query.isEmpty) return [];
    return searchBooks(query, limit: pageSize, offset: currentCount);
  }

  /// Retourne les statistiques du cache
  Map<String, Map<String, dynamic>> getCacheStats() {
    return {
      'searchCache': {
        'total': _searchCache.length,
        'active': _searchCache.values.where((v) => !v.isExpired).length,
        'expired': _searchCache.values.where((v) => v.isExpired).length,
      },
      'detailsCache': {
        'total': _bookDetailsCache.length,
        'active': _bookDetailsCache.values.where((v) => !v.isExpired).length,
        'expired': _bookDetailsCache.values.where((v) => v.isExpired).length,
      },
    };
  }

  // Nettoyage automatique du cache
  Timer? _cacheCleanupTimer;

  /// Démarre le nettoyage automatique du cache (toutes les 10 minutes)
  void startAutomaticCacheCleanup() {
    _cacheCleanupTimer?.cancel();
    _cacheCleanupTimer = Timer.periodic(Duration(minutes: 10), (_) {
      cleanExpiredCache();
    });
  }

  /// Arrête le nettoyage automatique du cache
  void stopAutomaticCacheCleanup() {
    _cacheCleanupTimer?.cancel();
    _cacheCleanupTimer = null;
  }
}

/// Classe helper pour le cache
class CachedData<T> {
  final T data;
  final DateTime timestamp;

  CachedData(this.data, this.timestamp);

  bool get isExpired {
    return DateTime.now().difference(timestamp) > Duration(hours: 1);
  }
}
