import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/audiobook.dart';
import '../models/ambient_music.dart';
import '../models/librivox_book.dart';
import '../models/downloaded_book.dart';
import '../services/audio_player_service.dart';
import '../services/logging_service.dart';
import '../services/media_notification_service.dart';
import '../services/librivox_service.dart';
import 'audiobook_provider.dart';
import 'downloaded_books_provider.dart';
import 'dart:async';

class PlayerProvider with ChangeNotifier {
  final AudioPlayerService _audioService = AudioPlayerService();
  AudiobookProvider? _audiobookProvider;

  Audiobook? _currentAudiobook;
  LibrivoxBook?
      _currentLibrivoxBook; // To store the currently playing LibriVox book
  int _currentLibrivoxChapterIndex = -1; // To track the current chapter index
  AmbientMusic? _currentAmbientMusic;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  double _audiobookVolume = 0.8;
  double _ambientVolume = 0.3;
  double _playbackSpeed = 1.0;

  // Sleep timer
  Timer? _sleepTimer;
  int _sleepTimerMinutes = 0;

  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _stateSubscription;
  StreamSubscription? _playerCompletedSubscription;

  // Getters
  Audiobook? get currentAudiobook => _currentAudiobook;
  LibrivoxBook? get currentLibrivoxBook => _currentLibrivoxBook;
  int get currentLibrivoxChapterIndex => _currentLibrivoxChapterIndex;

  /// Vérifie s'il y a un chapitre suivant
  bool get hasNextChapter {
    if (_currentLibrivoxBook == null || _currentLibrivoxChapterIndex == -1) {
      return false;
    }
    return _currentLibrivoxChapterIndex + 1 <
        _currentLibrivoxBook!.chapters.length;
  }

  /// Vérifie s'il y a un chapitre précédent
  bool get hasPreviousChapter {
    if (_currentLibrivoxBook == null || _currentLibrivoxChapterIndex <= 0) {
      return false;
    }
    return true;
  }

  /// Retourne "1/7" pour le chapitre actuel
  String get chapterInfo {
    if (_currentLibrivoxBook == null || _currentLibrivoxChapterIndex == -1) {
      return '';
    }
    return '${_currentLibrivoxChapterIndex + 1}/${_currentLibrivoxBook!.chapters.length}';
  }

  /// Retourne le titre du chapitre actuel
  String? get currentChapterTitle {
    if (_currentLibrivoxBook == null || _currentLibrivoxChapterIndex == -1) {
      return null;
    }
    return _currentLibrivoxBook!.chapters[_currentLibrivoxChapterIndex].title;
  }

  AmbientMusic? get currentAmbientMusic => _currentAmbientMusic;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _isPlaying;
  double get audiobookVolume => _audiobookVolume;
  double get ambientVolume => _ambientVolume;
  double get playbackSpeed => _playbackSpeed;
  int get sleepTimerMinutes => _sleepTimerMinutes;
  bool get hasSleepTimer => _sleepTimer != null && _sleepTimerMinutes > 0;
  double get progress =>
      _duration.inSeconds > 0 ? _position.inSeconds / _duration.inSeconds : 0.0;

  PlayerProvider() {
    _initListeners();
  }

  /// Affiche la notification de lecture en cours
  void _showPlaybackNotification() {
    if (_currentAudiobook != null) {
      NotificationService.showPlaybackNotification(
        _currentAudiobook!,
        isPlaying: _isPlaying,
      );
    } else if (_currentLibrivoxBook != null &&
        _currentLibrivoxChapterIndex >= 0) {
      final chapterTitle =
          _currentLibrivoxBook!.chapters[_currentLibrivoxChapterIndex].title;
      NotificationService.showPlaybackNotificationFromLibrivox(
        _currentLibrivoxBook!,
        chapterTitle,
        isPlaying: _isPlaying,
      );
    }
  }

  void _initListeners() {
    _positionSubscription = _audioService.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });

    _durationSubscription = _audioService.durationStream.listen((duration) {
      if (duration != null) {
        _duration = duration;
        notifyListeners();
      }
    });

    _stateSubscription = _audioService.playerStateStream.listen((state) {
      _isPlaying = state.playing;

      // Afficher/cacher la notification de lecture
      if (_isPlaying &&
          (_currentAudiobook != null || _currentLibrivoxBook != null)) {
        _showPlaybackNotification();
      } else {
        NotificationService.hidePlaybackNotification();
      }

      notifyListeners();
    });

    // Écouter la fin de la lecture pour passer au chapitre suivant
    _playerCompletedSubscription =
        _audioService.playbackCompletedStream.listen((completed) {
      if (completed && _currentLibrivoxBook != null) {
        debugPrint('Chapitre terminé, passage au suivant...');
        _saveChapterProgress(); // Sauvegarder progression avant de changer
        playNextChapter();
      }
    });
  }

  /// Charge et joue un livre audio
  Future<void> loadAndPlayAudiobook(Audiobook audiobook) async {
    try {
      _currentAudiobook = audiobook;
      notifyListeners();

      await _audioService.loadAudiobook(
        audiobook.filePath,
        isNetwork: audiobook.isNetwork,
      );

      // Reprendre à la dernière position pour les livres locaux
      if (!audiobook.isNetwork && audiobook.lastPosition > 0) {
        await _audioService.seek(Duration(seconds: audiobook.lastPosition));
      }

      await _audioService.setAudiobookVolume(_audiobookVolume);

      // TODO: Notifications désactivées temporairement
      // await MediaNotificationService.updateMediaItem(audiobook);

      await _audioService.play();
    } catch (e) {
      debugPrint('Erreur chargement audiobook: $e');
    }
  }

  /// Charge et joue un chapitre d'un livre LibriVox
  Future<void> loadAndPlayLibrivoxChapter(
      LibrivoxBook book, LibrivoxChapter chapter) async {
    _currentLibrivoxBook = book;
    _currentLibrivoxChapterIndex = book.chapters.indexOf(chapter);
    if (_currentLibrivoxChapterIndex == -1) {
      _currentLibrivoxChapterIndex =
          0; // Fallback to first chapter if not found
    }
    await _loadAndPlayLibrivoxChapterAtIndex();
  }

  /// Retourne le titre du livre LibriVox en cours
  String? get currentBookTitle {
    return _currentLibrivoxBook?.title;
  }

  /// Retourne l'auteur du livre LibriVox en cours
  String? get currentBookAuthor {
    return _currentLibrivoxBook?.author;
  }

  /// Helper to load and play the chapter at _currentLibrivoxChapterIndex
  Future<void> _loadAndPlayLibrivoxChapterAtIndex(
      {Duration? resumePosition}) async {
    if (_currentLibrivoxBook == null ||
        _currentLibrivoxChapterIndex == -1 ||
        _currentLibrivoxChapterIndex >= _currentLibrivoxBook!.chapters.length) {
      debugPrint('No LibriVox book or invalid chapter index to play.');
      return;
    }

    final chapter =
        _currentLibrivoxBook!.chapters[_currentLibrivoxChapterIndex];
    // Create a temporary Audiobook object for playback
    final tempAudiobook = Audiobook(
      // No ID as it's not in the local DB
      title: '${_currentLibrivoxBook!.title} - ${chapter.title}',
      author: _currentLibrivoxBook!.author,
      filePath: chapter.url,
      isNetwork: true,
      duration: chapter.duration.inSeconds,
    );
    await loadAndPlayAudiobook(tempAudiobook);

    // Reprendre à la position sauvegardée si fournie
    if (resumePosition != null && resumePosition.inSeconds > 0) {
      await _audioService.seek(resumePosition);
      LoggingService.i(
          'Reprise à ${resumePosition.inSeconds}s dans le chapitre');
    }

    // TODO: Notifications désactivées temporairement
    // final chapterTitle =
    //     _currentLibrivoxBook!.chapters[_currentLibrivoxChapterIndex].title;
    // await MediaNotificationService.updateMediaItemFromLibrivox(
    //     _currentLibrivoxBook!, chapterTitle);

    notifyListeners(); // Notify listeners that the chapter has changed
  }

  /// Joue le chapitre suivant du livre LibriVox en cours
  Future<void> playNextChapter() async {
    if (_currentLibrivoxBook == null || _currentLibrivoxChapterIndex == -1) {
      return;
    }
    if (_currentLibrivoxChapterIndex + 1 <
        _currentLibrivoxBook!.chapters.length) {
      _currentLibrivoxChapterIndex++;
      await _loadAndPlayLibrivoxChapterAtIndex();
    } else {
      debugPrint('Reached the end of the book.');
    }
  }

  /// Joue le chapitre précédent du livre LibriVox en cours
  Future<void> playPreviousChapter() async {
    if (_currentLibrivoxBook == null || _currentLibrivoxChapterIndex == -1) {
      return;
    }
    if (_currentLibrivoxChapterIndex - 1 >= 0) {
      _currentLibrivoxChapterIndex--;
      await _loadAndPlayLibrivoxChapterAtIndex();
    } else {
      debugPrint('Reached the beginning of the book.');
      await seek(Duration.zero);
    }
  }

  /// Setter pour AudiobookProvider
  void setAudiobookProvider(AudiobookProvider provider) {
    _audiobookProvider = provider;
  }

  /// Charge et joue une musique d'ambiance
  Future<void> loadAndPlayAmbient(AmbientMusic music) async {
    print('🎵 loadAndPlayAmbient appelée pour: ${music.name}');
    try {
      print('🎵 Chargement de ${music.filePath}');
      await _audioService.loadAmbientMusic(music.filePath);
      print('🎵 Réglage volume ambiance: $_ambientVolume');
      await _audioService.setAmbientVolume(_ambientVolume);

      _currentAmbientMusic = music;
      print('🎵 Ambiance définie: ${music.name}');
      notifyListeners();

      if (_isPlaying) {
        print('🎵 Lecture en cours, démarrage ambiance');
        await _audioService.play();
        print('✅ Ambiance démarrée avec succès: ${music.name}');
      } else {
        print('🎵 Lecture pas en cours, ambiance chargée mais pas démarrée');
      }
    } catch (e) {
      print('❌ Erreur chargement musique pour ${music.name}: $e');
      // Ne pas définir _currentAmbientMusic si le chargement échoue
      _currentAmbientMusic = null;
      notifyListeners();
      // Remonter l'erreur pour affichage dans l'UI
      rethrow;
    }
  }

  /// Arrête la musique d'ambiance
  Future<void> stopAmbient() async {
    await _audioService.stopAmbient();
    _currentAmbientMusic = null;
    notifyListeners();
  }

  /// Lecture / Pause
  Future<void> togglePlayPause() async {
    if (_currentAudiobook == null) return;

    if (_isPlaying) {
      await _audioService.pause(); // Met en pause livre ET ambiance
      await _saveCurrentPosition();
      await _saveChapterProgress(); // Sauvegarder progression chapitre
    } else {
      await _audioService.play(); // Démarre livre ET ambiance si chargée
    }
  }

  /// Sauvegarde la position actuelle du livre en cours
  Future<void> _saveCurrentPosition() async {
    if (_currentAudiobook != null &&
        _currentAudiobook!.id != null &&
        _position.inSeconds > 0) {
      await _audiobookProvider?.updatePosition(
        _currentAudiobook!.id!,
        _position.inSeconds,
      );
    }
  }

  /// Avancer de 15 secondes
  Future<void> skipForward() async {
    await _audioService.skipForward(15);
  }

  /// Reculer de 15 secondes
  Future<void> skipBackward() async {
    await _audioService.skipBackward(15);
  }

  /// Chercher à une position
  Future<void> seek(Duration position) async {
    await _audioService.seek(position);
  }

  /// Définir le volume du livre audio
  Future<void> setAudiobookVolume(double volume) async {
    _audiobookVolume = volume;
    await _audioService.setAudiobookVolume(volume);
    notifyListeners();
  }

  /// Définir le volume de la musique d'ambiance
  Future<void> setAmbientVolume(double volume) async {
    _ambientVolume = volume;
    await _audioService.setAmbientVolume(volume);
    notifyListeners();
  }

  /// Définir la vitesse de lecture
  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _audioService.setSpeed(speed);
    notifyListeners();
  }

  /// Définir un minuteur de sommeil
  void setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    _sleepTimerMinutes = minutes;

    if (minutes > 0) {
      _sleepTimer = Timer(Duration(minutes: minutes), () async {
        await togglePlayPause();
        _sleepTimerMinutes = 0;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  /// Annuler le minuteur de sommeil
  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimerMinutes = 0;
    notifyListeners();
  }

  /// Extrait le numéro du chapitre depuis le titre
  int _extractChapterNumberFromTitle(String chapterTitle, int fallbackNumber) {
    try {
      // Chercher des patterns comme "Chapter 01", "Chapitre 20", "01 - Title", etc.
      final patterns = [
        RegExp(r'Chapter\s+(\d+)', caseSensitive: false),
        RegExp(r'Chapitre\s+(\d+)', caseSensitive: false),
        RegExp(r'^(\d+)\s*[-:]',
            caseSensitive: false), // "01 - Title" ou "1: Title"
        RegExp(r'^\s*(\d+)\s*$'), // Juste un numéro
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(chapterTitle);
        if (match != null && match.groupCount >= 1) {
          final number = int.tryParse(match.group(1)!);
          if (number != null && number > 0) {
            return number;
          }
        }
      }

      // Si aucun pattern ne match, utiliser le fallback
      return fallbackNumber;
    } catch (e) {
      LoggingService.w('Erreur extraction numéro chapitre: "$chapterTitle"');
      return fallbackNumber;
    }
  }

  /// Sauvegarde la progression d'écoute du chapitre en cours
  Future<void> _saveChapterProgress() async {
    try {
      if (_currentLibrivoxBook == null ||
          _currentLibrivoxChapterIndex == -1 ||
          _position.inSeconds <= 0) {
        return; // Rien à sauvegarder
      }

      // Trouver le livre téléchargé correspondant
      final downloadedBooksProvider = DownloadedBooksProvider();
      await downloadedBooksProvider.loadDownloadedBooks();
      final downloadedBooks = downloadedBooksProvider.downloadedBooks;

      final currentBook = downloadedBooks.firstWhere(
        (book) => book.id == _currentLibrivoxBook!.id,
        orElse: () => null as DownloadedBook,
      );

      if (currentBook == null) {
        LoggingService.d(
            'Livre non trouvé dans téléchargements - pas de sauvegarde');
        return;
      }

      // Trouver le chapitre correspondant dans le livre téléchargé
      final currentChapter =
          _currentLibrivoxBook!.chapters[_currentLibrivoxChapterIndex];
      final downloadedChapter = currentBook.chapters.firstWhere(
        (chapter) => chapter.title == currentChapter.title,
        orElse: () => null as DownloadedChapter,
      );

      if (downloadedChapter == null) {
        LoggingService.w('Chapitre non trouvé dans téléchargements');
        return;
      }

      // Mettre à jour la progression
      final newListenedSeconds = _position.inSeconds;
      if (newListenedSeconds > downloadedChapter.listenedSeconds) {
        final updatedChapter =
            downloadedChapter.updateProgress(newListenedSeconds);

        // Mettre à jour dans la liste du livre
        final chapterIndex = currentBook.chapters.indexOf(downloadedChapter);
        if (chapterIndex != -1) {
          currentBook.chapters[chapterIndex] = updatedChapter;

          // Sauvegarder dans la base de données
          await downloadedBooksProvider.updateChapterProgress(
            updatedChapter.id,
            newListenedSeconds,
          );

          LoggingService.d(
              'Progression sauvegardée: ${currentChapter.title} - ${newListenedSeconds}s');
        }
      }
    } catch (e) {
      LoggingService.w('Erreur sauvegarde progression chapitre: $e');
    }
  }

  /// Charge et joue un livre téléchargé depuis LibriVox
  /// Utilise getBookDetails() avec extraction RSS améliorée
  Future<void> loadAndPlayDownloadedBook(DownloadedBook book) async {
    LoggingService.d('Extraction RSS améliorée pour lecteur: ${book.title}');

    LibrivoxBook bookToPlay;
    try {
      // Utiliser getBookDetails() avec extraction RSS en priorité
      final librivoxService = LibrivoxService(httpClient: http.Client());
      final fullBookDetails =
          await librivoxService.getBookDetails(book.id, existingBook: null);

      if (fullBookDetails == null) {
        throw Exception('Impossible de récupérer les détails du livre');
      }

      // Construire le livre avec données RSS + chapitres locaux TRIÉS
      final sortedChapters = book.chapters.map((chapter) {
        // Extraire le numéro réel du chapitre depuis le titre
        final trackNumber = _extractChapterNumberFromTitle(
            chapter.title, book.chapters.indexOf(chapter) + 1);
        return LibrivoxChapter(
          title: chapter.title,
          url: chapter.localFilePath,
          trackNumber: trackNumber,
          duration: chapter.duration,
        );
      }).toList();

      // Trier par numéro de chapitre pour ordre 1, 2, 3...
      sortedChapters.sort((a, b) => a.trackNumber.compareTo(b.trackNumber));

      LoggingService.d(
          '[loadAndPlayDownloadedBook] Chapitres triés: ${sortedChapters.map((c) => c.trackNumber).toList()}');

      bookToPlay = LibrivoxBook(
        id: book.id,
        title: fullBookDetails.title, // ← Extraction RSS améliorée
        author: fullBookDetails.author, // ← RSS itunes:author en priorité
        description: fullBookDetails.description,
        language: fullBookDetails.language, // ← Traduction langue RSS
        totalDuration: fullBookDetails.totalDuration,
        chapters: sortedChapters,
      );
      LoggingService.i(
          'Extraction RSS réussie pour lecteur: ${bookToPlay.author}');
    } catch (e) {
      LoggingService.e(
          'Erreur extraction RSS pour lecteur ${book.title}, fallback local',
          e);
      // Fallback: données locales
      bookToPlay = LibrivoxBook(
        id: book.id,
        title: book.title,
        author: book.author,
        description: book.description,
        language: book.language,
        totalDuration: Duration(seconds: book.totalTimeSeconds),
        chapters: book.chapters
            .map((chapter) => LibrivoxChapter(
                  title: chapter.title,
                  url: chapter.localFilePath,
                  trackNumber: book.chapters.indexOf(chapter) + 1,
                  duration: chapter.duration,
                ))
            .toList(),
      );
    }

    _currentLibrivoxBook = bookToPlay;

    // Commencer toujours par le premier chapitre (reprise de lecture désactivée temporairement)
    _currentLibrivoxChapterIndex = 0;
    await _loadAndPlayLibrivoxChapterAtIndex();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _saveCurrentPosition();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _stateSubscription?.cancel();
    _playerCompletedSubscription?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}
