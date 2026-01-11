import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/downloaded_book.dart';
import '../models/librivox_book.dart';
import 'logging_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service de gestion des téléchargements de livres LibriVox
class DownloadService {
  static const String _booksDirectory = 'downloaded_books';
  static const String _coversDirectory = 'book_covers';

  // Stream pour notifier les progrès de téléchargement
  final StreamController<DownloadProgress> _downloadProgressController =
      StreamController<DownloadProgress>.broadcast();

  Stream<DownloadProgress> get downloadProgress =>
      _downloadProgressController.stream;

  // Gestionnaire de notifications
  static FlutterLocalNotificationsPlugin? _notificationsPlugin;
  static const String _downloadChannelId = 'booktune_downloads';
  static const String _downloadChannelName = 'Téléchargements BookTune';
  static const String _downloadChannelDescription =
      'Notifications de progression des téléchargements';

  // IDs de notifications pour éviter les conflits
  static const int _baseNotificationId = 1000;

  /// Initialise le service
  Future<void> initialize() async {
    await _initializeNotifications();
    LoggingService.i('DownloadService initialisé');
  }

  /// Initialise le système de notifications
  Future<void> _initializeNotifications() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin!.initialize(initializationSettings);

    // Créer le canal de notifications pour les téléchargements
    const androidChannel = AndroidNotificationChannel(
      _downloadChannelId,
      _downloadChannelName,
      description: _downloadChannelDescription,
      importance: Importance.low,
      showBadge: false,
      enableVibration: false,
      playSound: false,
    );

    await _notificationsPlugin!
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    LoggingService.i('Notifications de téléchargement initialisées');
  }

  /// Télécharge un livre LibriVox complet avec tous ses chapitres
  Future<DownloadedBook> downloadBook(LibrivoxBook book) async {
    LoggingService.i('Début téléchargement livre: ${book.title}');

    try {
      // Créer les répertoires nécessaires
      final directories = await _createDirectories(book.id);

      // Télécharger la couverture
      final coverPath = await _downloadCover(book, directories['covers']!);

      // Télécharger tous les chapitres
      final downloadedChapters = <DownloadedChapter>[];
      for (final chapter in book.chapters) {
        final downloadedChapter = await _downloadChapter(
          chapter,
          book.id,
          directories['chapters']!,
        );
        downloadedChapters.add(downloadedChapter);
      }

      // Créer l'objet DownloadedBook
      final downloadedBook = DownloadedBook.fromLibrivoxBook(
        book,
        coverPath,
        downloadedChapters,
      );

      LoggingService.i('Téléchargement terminé: ${book.title}');
      return downloadedBook;
    } catch (e) {
      LoggingService.e('Erreur téléchargement livre ${book.id}', e);
      throw Exception('Échec du téléchargement: $e');
    }
  }

  /// Télécharge un chapitre spécifique
  Future<DownloadedChapter> downloadChapter(
    LibrivoxChapter chapter,
    String bookId,
  ) async {
    LoggingService.i('Téléchargement chapitre: ${chapter.title}');

    try {
      final directories = await _createDirectories(bookId);
      return await _downloadChapter(chapter, bookId, directories['chapters']!);
    } catch (e) {
      LoggingService.e('Erreur téléchargement chapitre ${chapter.title}', e);
      throw Exception('Échec du téléchargement du chapitre: $e');
    }
  }

  /// Télécharge la couverture d'un livre
  Future<String> _downloadCover(LibrivoxBook book, String coversDir) async {
    if (book.coverUrl == null || book.coverUrl!.isEmpty) {
      // Couverture par défaut si aucune URL
      return path.join(coversDir, '${book.id}_default.jpg');
    }

    final coverFileName = '${book.id}_cover.jpg';
    final coverPath = path.join(coversDir, coverFileName);

    try {
      LoggingService.d('Téléchargement couverture: ${book.coverUrl}');

      final response = await http.get(Uri.parse(book.coverUrl!));
      if (response.statusCode == 200) {
        final file = File(coverPath);
        await file.writeAsBytes(response.bodyBytes);
        LoggingService.d('Couverture téléchargée: $coverPath');
        return coverPath;
      } else {
        LoggingService.w(
            'Échec téléchargement couverture: ${response.statusCode}');
        return path.join(coversDir, '${book.id}_default.jpg');
      }
    } catch (e) {
      LoggingService.e('Erreur téléchargement couverture', e);
      return path.join(coversDir, '${book.id}_default.jpg');
    }
  }

  /// Télécharge un chapitre audio
  Future<DownloadedChapter> _downloadChapter(
    LibrivoxChapter chapter,
    String bookId,
    String chaptersDir,
  ) async {
    final chapterFileName =
        '${bookId}_${chapter.trackNumber}_${chapter.title.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_')}.mp3';
    final chapterPath = path.join(chaptersDir, chapterFileName);

    // Notifier le début du téléchargement
    _notifyProgress(DownloadProgress(
      bookId: bookId,
      chapterId: chapterFileName,
      status: DownloadStatus.downloading,
      progress: 0.0,
      downloadedBytes: 0,
      totalBytes: 0,
    ));

    try {
      LoggingService.d('Téléchargement chapitre: ${chapter.url}');

      final request = http.Request('GET', Uri.parse(chapter.url));
      final response = await request.send();

      if (response.statusCode != 200) {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }

      final totalBytes = response.contentLength ?? 0;
      var downloadedBytes = 0;

      final file = File(chapterPath);
      final sink = file.openWrite();

      await response.stream.forEach((chunk) {
        sink.add(chunk);
        downloadedBytes += chunk.length;

        // Notifier la progression
        final progress = totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;
        _notifyProgress(DownloadProgress(
          bookId: bookId,
          chapterId: chapterFileName,
          status: DownloadStatus.downloading,
          progress: progress.clamp(0.0, 1.0),
          downloadedBytes: downloadedBytes,
          totalBytes: totalBytes,
        ));
      });

      await sink.close();

      // Vérifier la taille du fichier
      final fileSize = await file.length();
      LoggingService.d(
          'Chapitre téléchargé: $chapterPath (${_formatBytes(fileSize)})');

      // Notifier la fin du téléchargement
      _notifyProgress(DownloadProgress(
        bookId: bookId,
        chapterId: chapterFileName,
        status: DownloadStatus.completed,
        progress: 1.0,
        downloadedBytes: fileSize,
        totalBytes: fileSize,
      ));

      return DownloadedChapter.fromLibrivoxChapter(
        chapter,
        chapterPath,
        fileSize,
      );
    } catch (e) {
      // Notifier l'échec
      _notifyProgress(DownloadProgress(
        bookId: bookId,
        chapterId: chapterFileName,
        status: DownloadStatus.failed,
        progress: 0.0,
        downloadedBytes: 0,
        totalBytes: 0,
        errorMessage: e.toString(),
      ));

      // Supprimer le fichier partiellement téléchargé
      final file = File(chapterPath);
      if (await file.exists()) {
        await file.delete();
      }

      throw e;
    }
  }

  /// Crée les répertoires nécessaires pour un livre
  Future<Map<String, String>> _createDirectories(String bookId) async {
    final appDir = await getApplicationDocumentsDirectory();

    final booksDir = Directory(path.join(appDir.path, _booksDirectory));
    final bookDir = Directory(path.join(booksDir.path, bookId));
    final chaptersDir = Directory(path.join(bookDir.path, 'chapters'));
    final coversDir = Directory(path.join(bookDir.path, 'covers'));

    await booksDir.create(recursive: true);
    await bookDir.create(recursive: true);
    await chaptersDir.create(recursive: true);
    await coversDir.create(recursive: true);

    return {
      'book': bookDir.path,
      'chapters': chaptersDir.path,
      'covers': coversDir.path,
    };
  }

  /// Notifie la progression d'un téléchargement
  void _notifyProgress(DownloadProgress progress) {
    if (!_downloadProgressController.isClosed) {
      _downloadProgressController.add(progress);
    }

    // Afficher la notification de progression
    _showDownloadNotification(progress);
  }

  /// Affiche une notification de progression de téléchargement
  Future<void> _showDownloadNotification(DownloadProgress progress) async {
    if (_notificationsPlugin == null) return;

    final notificationId = _baseNotificationId + progress.bookId.hashCode;

    // Calculer la progression en pourcentage
    final progressPercent = (progress.progress * 100).round();

    // Déterminer le titre et le message selon l'état
    String title;
    String body;
    bool showProgress = false;
    int? maxProgress;
    int? currentProgress;

    switch (progress.status) {
      case DownloadStatus.downloading:
        title = 'Téléchargement en cours';
        body = '${progressPercent}% - ${progress.chapterId.split('_').last}';
        showProgress = true;
        maxProgress = 100;
        currentProgress = progressPercent;
        break;

      case DownloadStatus.completed:
        title = 'Téléchargement terminé';
        body = 'Chapitre téléchargé avec succès';
        showProgress = false;
        // Masquer la notification après 3 secondes
        Future.delayed(const Duration(seconds: 3), () {
          _notificationsPlugin?.cancel(notificationId);
        });
        break;

      case DownloadStatus.failed:
        title = 'Échec du téléchargement';
        body = progress.errorMessage ?? 'Erreur inconnue';
        showProgress = false;
        // Masquer la notification après 5 secondes
        Future.delayed(const Duration(seconds: 5), () {
          _notificationsPlugin?.cancel(notificationId);
        });
        break;

      default:
        return; // Ne pas afficher pour les autres états
    }

    final androidDetails = AndroidNotificationDetails(
      _downloadChannelId,
      _downloadChannelName,
      channelDescription: _downloadChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
      showProgress: showProgress,
      maxProgress: maxProgress ?? 100,
      progress: currentProgress ?? 0,
      ongoing: progress.status == DownloadStatus.downloading,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin!.show(
      notificationId,
      title,
      body,
      notificationDetails,
    );
  }

  /// Masque une notification de téléchargement
  Future<void> hideDownloadNotification(String bookId) async {
    if (_notificationsPlugin == null) return;

    final notificationId = _baseNotificationId + bookId.hashCode;
    await _notificationsPlugin!.cancel(notificationId);
  }

  /// Masque toutes les notifications de téléchargement
  Future<void> hideAllDownloadNotifications() async {
    if (_notificationsPlugin == null) return;

    // Annuler toutes les notifications dans la plage des téléchargements
    for (int i = 0; i < 100; i++) {
      await _notificationsPlugin!.cancel(_baseNotificationId + i);
    }
  }

  /// Supprime un livre téléchargé
  Future<void> deleteDownloadedBook(String bookId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final bookDir =
          Directory(path.join(appDir.path, _booksDirectory, bookId));

      if (await bookDir.exists()) {
        await bookDir.delete(recursive: true);
        LoggingService.i('Livre supprimé: $bookId');
      }
    } catch (e) {
      LoggingService.e('Erreur suppression livre $bookId', e);
      throw Exception('Échec de la suppression: $e');
    }
  }

  /// Vérifie si un livre est déjà téléchargé
  Future<bool> isBookDownloaded(String bookId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final bookDir = Directory(path.join(appDir.path, _booksDirectory, bookId));
    return await bookDir.exists();
  }

  /// Obtient l'espace disque utilisé par les téléchargements
  Future<int> getTotalDownloadedSize() async {
    final appDir = await getApplicationDocumentsDirectory();
    final booksDir = Directory(path.join(appDir.path, _booksDirectory));

    if (!await booksDir.exists()) return 0;

    return await _calculateDirectorySize(booksDir);
  }

  /// Calcule la taille d'un répertoire récursivement
  Future<int> _calculateDirectorySize(Directory dir) async {
    int totalSize = 0;

    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    } catch (e) {
      LoggingService.e('Erreur calcul taille répertoire', e);
    }

    return totalSize;
  }

  /// Nettoie les fichiers temporaires et incomplets
  Future<void> cleanTemporaryFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory(path.join(appDir.path, _booksDirectory));

      if (!await booksDir.exists()) return;

      await for (final entity in booksDir.list(recursive: true)) {
        if (entity is File) {
          final fileName = path.basename(entity.path);

          // Supprimer les fichiers .tmp et autres fichiers temporaires
          if (fileName.endsWith('.tmp') ||
              fileName.endsWith('.download') ||
              fileName.contains('incomplete')) {
            await entity.delete();
            LoggingService.d('Fichier temporaire supprimé: $fileName');
          }
        }
      }
    } catch (e) {
      LoggingService.e('Erreur nettoyage fichiers temporaires', e);
    }
  }

  /// Formate les bytes en texte lisible
  String _formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  /// Nettoie les ressources
  void dispose() {
    _downloadProgressController.close();
    LoggingService.i('DownloadService disposed');
  }
}
