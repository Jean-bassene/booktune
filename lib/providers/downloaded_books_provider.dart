import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/downloaded_book.dart';
import '../models/librivox_book.dart';
import '../services/downloaded_books_database.dart';
import '../services/logging_service.dart';
import '../services/librivox_service.dart';

/// Provider pour gérer les livres téléchargés
class DownloadedBooksProvider with ChangeNotifier {
  List<DownloadedBook> _downloadedBooks = [];
  bool _isLoading = false;

  List<DownloadedBook> get downloadedBooks => _downloadedBooks;
  bool get isLoading => _isLoading;

  /// Initialise le provider
  Future<void> initialize() async {
    await loadDownloadedBooks();

    // Rafraîchir systématiquement les informations depuis l'API (comme l'explorateur)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllBooksFromApi();
    });
  }

  /// Charge tous les livres téléchargés depuis la base de données
  Future<void> loadDownloadedBooks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _downloadedBooks = await DownloadedBooksDatabase.getAllDownloadedBooks();
      LoggingService.i('${_downloadedBooks.length} livres téléchargés chargés');
    } catch (e) {
      LoggingService.e('Erreur chargement livres téléchargés', e);
      _downloadedBooks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ajoute un livre téléchargé (appelé après téléchargement réussi)
  Future<void> addDownloadedBook(DownloadedBook book) async {
    // Vérifier si le livre n'est pas déjà présent
    final existingIndex = _downloadedBooks.indexWhere((b) => b.id == book.id);
    if (existingIndex >= 0) {
      // Mettre à jour le livre existant
      _downloadedBooks[existingIndex] = book;
    } else {
      // Ajouter le nouveau livre
      _downloadedBooks.insert(0, book); // Au début de la liste
    }

    notifyListeners();
    LoggingService.i('Livre ajouté à la bibliothèque: ${book.title}');
  }

  /// Supprime un livre téléchargé
  Future<void> removeDownloadedBook(String bookId) async {
    try {
      await DownloadedBooksDatabase.deleteDownloadedBook(bookId);
      _downloadedBooks.removeWhere((book) => book.id == bookId);
      notifyListeners();
      LoggingService.i('Livre supprimé de la bibliothèque: $bookId');
    } catch (e) {
      LoggingService.e('Erreur suppression livre $bookId', e);
      throw Exception('Échec de la suppression: $e');
    }
  }

  /// Met à jour la progression d'écoute d'un chapitre
  Future<void> updateChapterProgress(
      String chapterId, int listenedSeconds) async {
    try {
      await DownloadedBooksDatabase.updateChapterProgress(
          chapterId, listenedSeconds);

      // Mettre à jour la liste locale
      for (final book in _downloadedBooks) {
        final chapterIndex = book.chapters.indexWhere((c) => c.id == chapterId);
        if (chapterIndex >= 0) {
          book.chapters[chapterIndex] =
              book.chapters[chapterIndex].updateProgress(listenedSeconds);
          notifyListeners();
          break;
        }
      }

      LoggingService.d('Progression chapitre mise à jour: $chapterId');
    } catch (e) {
      LoggingService.e('Erreur mise à jour progression chapitre $chapterId', e);
    }
  }

  /// Recherche dans les livres téléchargés
  Future<List<DownloadedBook>> searchBooks(String query) async {
    if (query.isEmpty) return _downloadedBooks;

    try {
      return await DownloadedBooksDatabase.searchDownloadedBooks(query);
    } catch (e) {
      LoggingService.e('Erreur recherche livres téléchargés', e);
      return [];
    }
  }

  /// Vérifie si un livre est téléchargé
  bool isBookDownloaded(String bookId) {
    return _downloadedBooks.any((book) => book.id == bookId);
  }

  /// Obtient un livre téléchargé par son ID
  DownloadedBook? getDownloadedBook(String bookId) {
    try {
      return _downloadedBooks.firstWhere((book) => book.id == bookId);
    } catch (e) {
      return null;
    }
  }

  /// Obtient des statistiques sur les livres téléchargés
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final stats = await DownloadedBooksDatabase.getStatistics();
      stats['localBooksCount'] = _downloadedBooks.length;
      return stats;
    } catch (e) {
      LoggingService.e('Erreur récupération statistiques', e);
      return {
        'bookCount': 0,
        'totalSize': 0,
        'totalListeningTime': 0,
        'localBooksCount': 0,
      };
    }
  }

  /// Trie les livres par différents critères
  void sortBooks(String sortBy) {
    switch (sortBy) {
      case 'title':
        _downloadedBooks.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'author':
        _downloadedBooks.sort((a, b) => a.author.compareTo(b.author));
        break;
      case 'date':
        _downloadedBooks
            .sort((a, b) => b.downloadDate.compareTo(a.downloadDate));
        break;
      case 'progress':
        _downloadedBooks
            .sort((a, b) => b.listeningProgress.compareTo(a.listeningProgress));
        break;
      default:
        // Trier par date de téléchargement (plus récent en premier)
        _downloadedBooks
            .sort((a, b) => b.downloadDate.compareTo(a.downloadDate));
    }

    notifyListeners();
  }

  /// Récupère les vraies informations d'un livre depuis l'API LibriVox de recherche
  Future<LibrivoxBook?> getBookInfoFromSearchApi(String bookId) async {
    try {
      final librivoxService = LibrivoxService(httpClient: http.Client());

      // Utiliser l'API de recherche avec l'ID du livre
      final searchResults = await librivoxService.searchBooks(bookId, limit: 5);

      // NE CHERCHER QUE LE LIVRE EXACT PAR ID - pas de fallback
      try {
        final exactBook = searchResults.firstWhere(
          (book) => book.id == bookId,
        );
        LoggingService.d(
            'Livre exact trouvé par ID $bookId dans les résultats de recherche');
        return exactBook;
      } catch (e) {
        // SI PAS DE CORRESPONDANCE EXACTE, NE PAS METTRE À JOUR
        // pour éviter de remplacer par un livre complètement différent
        LoggingService.w(
            'Aucun livre exact trouvé pour ID $bookId - pas de mise à jour');
        return null; // ← RETOURNER NULL AU LIEU DU PREMIER RÉSULTAT
      }
    } catch (e) {
      LoggingService.e(
          'Erreur récupération API recherche pour livre $bookId', e);
      return null;
    }
  }

  /// Met à jour les informations d'un livre téléchargé depuis l'API LibriVox
  Future<void> updateBookInfoFromApi(String bookId) async {
    try {
      final existingBook = getDownloadedBook(bookId);
      if (existingBook == null) return;

      // Récupérer les vraies informations depuis l'API de recherche
      final updatedBookInfo = await getBookInfoFromSearchApi(bookId);

      if (updatedBookInfo != null) {
        // Créer un nouveau livre avec les informations mises à jour
        final updatedBook = existingBook.copyWith(
          author: updatedBookInfo.author,
          description: updatedBookInfo.description,
          language: updatedBookInfo.language,
        );

        // Mettre à jour dans la base de données
        await DownloadedBooksDatabase.saveDownloadedBook(updatedBook);

        // Mettre à jour la liste locale
        final index = _downloadedBooks.indexWhere((b) => b.id == bookId);
        if (index >= 0) {
          _downloadedBooks[index] = updatedBook;
          notifyListeners();
        }

        LoggingService.i(
            'Informations du livre mises à jour depuis API: ${updatedBook.title}');
      }
    } catch (e) {
      LoggingService.e('Erreur mise à jour informations livre $bookId', e);
    }
  }

  /// Rafraîchissement systématique de tous les livres depuis l'API (comme l'explorateur)
  Future<void> _refreshAllBooksFromApi() async {
    // Attendre un peu pour que l'interface se charge
    await Future.delayed(const Duration(seconds: 2));

    if (_downloadedBooks.isEmpty) {
      LoggingService.d('Aucun livre téléchargé à rafraîchir');
      return;
    }

    LoggingService.i(
        'Rafraîchissement systématique des ${downloadedBooks.length} livres depuis API recherche...');

    // Rafraîchir tous les livres depuis l'API de recherche (comme l'explorateur)
    int refreshedCount = 0;
    for (final book in _downloadedBooks) {
      try {
        await updateBookInfoFromApi(book.id);
        refreshedCount++;
        // Petite pause entre chaque rafraîchissement pour éviter surcharge API
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        LoggingService.e('Erreur rafraîchissement livre ${book.id}', e);
      }
    }

    LoggingService.i(
        'Rafraîchissement terminé: $refreshedCount/${_downloadedBooks.length} livres mis à jour depuis API');
  }
}
