import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/audiobook.dart';
import '../models/librivox_book.dart';
import 'logging_service.dart';

/// Gestionnaire audio pour AudioService - maintient la lecture en arrière-plan
class BookTuneAudioHandler extends BaseAudioHandler
    with SeekHandler, QueueHandler {
  final AudioPlayer _player = AudioPlayer();
  final List<MediaItem> _queue = [];
  int _currentIndex = -1;

  // États pour gérer les deux sources audio
  Audiobook? _currentAudiobook;
  LibrivoxBook? _currentLibrivoxBook;
  String? _currentAmbientUrl;
  double _audiobookVolume = 1.0;
  double _ambientVolume = 0.3;

  // Gestion du WakeLock pour appareils Honor/Huawei
  bool _isWakeLockEnabled = false;

  BookTuneAudioHandler() {
    _init();
  }

  void _init() {
    // Synchronise l'état du lecteur avec AudioService
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Synchronise la position
    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });

    // Gère la fin de la piste
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _handleTrackCompleted();
      }
    });

    LoggingService.i('BookTuneAudioHandler initialisé');
  }

  /// Transforme les événements du lecteur en état de lecture AudioService
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2], // Boutons visibles
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _currentIndex >= 0 ? _currentIndex : null,
    );
  }

  /// Gère la fin d'une piste
  void _handleTrackCompleted() {
    LoggingService.d('Piste terminée, gestion automatique');
    // Pour l'instant, on arrête simplement
    // TODO: Implémenter la logique de file d'attente
  }

  // === COMMANDES AUDIO ===

  @override
  Future<void> play() async {
    LoggingService.d('Commande: Play');
    await _player.play();

    // Activer WakeLock pour appareils Honor/Huawei
    await _enableWakeLockForHonorDevices();
  }

  @override
  Future<void> pause() async {
    LoggingService.d('Commande: Pause');
    await _player.pause();

    // Désactiver WakeLock quand en pause
    await _disableWakeLock();
  }

  @override
  Future<void> stop() async {
    LoggingService.d('Commande: Stop');
    await _player.stop();

    // Désactiver WakeLock à l'arrêt
    await _disableWakeLock();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    LoggingService.d('Commande: Seek to $position');
    await _player.seek(position);
  }

  // === GESTION DES LIVRES AUDIO ===

  /// Charge et joue un livre audio local
  Future<void> loadAndPlayAudiobook(
    Audiobook audiobook, {
    String? chapterTitle,
    Duration? startPosition,
  }) async {
    LoggingService.i('Chargement livre audio: ${audiobook.title}');

    _currentAudiobook = audiobook;
    _currentLibrivoxBook = null;

    // Pour l'instant, on simule avec un fichier audio
    // TODO: Implémenter la logique complète des chapitres
    final mediaItem = MediaItem(
      id: 'audiobook_${audiobook.id}',
      title: chapterTitle ?? audiobook.title,
      artist: audiobook.author,
      album: audiobook.title,
      duration: audiobook.duration != null
          ? Duration(seconds: audiobook.duration!)
          : null,
      artUri: null, // TODO: Ajouter couverture
    );

    super.mediaItem.add(mediaItem); // Définit le mediaItem actuel

    // Simuler le chargement d'un fichier audio
    // await _player.setUrl('path/to/chapter/file.mp3');

    LoggingService.i('Livre audio chargé: ${mediaItem.title}');
  }

  /// Charge et joue un livre LibriVox
  Future<void> loadAndPlayLibrivoxChapter(
    LibrivoxBook book,
    LibrivoxChapter chapter,
  ) async {
    LoggingService.i('Chargement chapitre LibriVox: ${chapter.title}');

    _currentLibrivoxBook = book;
    _currentAudiobook = null;

    final mediaItem = MediaItem(
      id: chapter.url,
      title: chapter.title,
      artist: book.author,
      album: book.title,
      duration: chapter.duration,
      artUri: book.coverUrl != null ? Uri.parse(book.coverUrl!) : null,
    );

    super.mediaItem.add(mediaItem);
    await _player.setUrl(chapter.url);

    LoggingService.i('Chapitre LibriVox chargé: ${mediaItem.title}');
  }

  /// Charge et joue une musique d'ambiance
  Future<void> loadAndPlayAmbient(String url, String name) async {
    LoggingService.i('Chargement ambiance: $name');

    _currentAmbientUrl = url;

    final mediaItem = MediaItem(
      id: url,
      title: name,
      artist: 'Ambiance',
      album: 'Musique d\'ambiance',
      artUri: null,
    );

    // Pour l'ambiance, on utilise un lecteur séparé ou on mixe
    // TODO: Implémenter le mixage audio

    LoggingService.i('Ambiance chargée: $name');
  }

  /// Arrête la musique d'ambiance
  Future<void> stopAmbient() async {
    LoggingService.d('Arrêt ambiance');
    _currentAmbientUrl = null;
    // TODO: Implémenter l'arrêt de l'ambiance
  }

  // === CONTRÔLE DU VOLUME ===

  /// Définit le volume du livre audio
  Future<void> setAudiobookVolume(double volume) async {
    _audiobookVolume = volume;
    LoggingService.d('Volume livre audio: ${volume.toStringAsFixed(2)}');
    // TODO: Appliquer le volume au lecteur principal
  }

  /// Définit le volume de l'ambiance
  Future<void> setAmbientVolume(double volume) async {
    _ambientVolume = volume;
    LoggingService.d('Volume ambiance: ${volume.toStringAsFixed(2)}');
    // TODO: Appliquer le volume au lecteur ambiance
  }

  // === GESTION WAKELOCK POUR HONOR/HUAWEI ===

  /// Active le WakeLock pour les appareils Honor/Huawei
  Future<void> _enableWakeLockForHonorDevices() async {
    try {
      // Vérifier si le WakeLock est déjà activé
      if (_isWakeLockEnabled) return;

      // Activer le WakeLock pour maintenir l'écran éveillé pendant la lecture
      await WakelockPlus.enable();

      _isWakeLockEnabled = true;
      LoggingService.i('🔋 WakeLock activé pour appareils Honor/Huawei');
    } catch (e) {
      LoggingService.e('Erreur activation WakeLock', e);
    }
  }

  /// Désactive le WakeLock
  Future<void> _disableWakeLock() async {
    try {
      if (!_isWakeLockEnabled) return;

      await WakelockPlus.disable();
      _isWakeLockEnabled = false;

      LoggingService.i('🔋 WakeLock désactivé');
    } catch (e) {
      LoggingService.e('Erreur désactivation WakeLock', e);
    }
  }

  // === GETTERS POUR L'UI ===

  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  double get audiobookVolume => _audiobookVolume;
  double get ambientVolume => _ambientVolume;
  Audiobook? get currentAudiobook => _currentAudiobook;
  LibrivoxBook? get currentLibrivoxBook => _currentLibrivoxBook;
  String? get currentAmbientUrl => _currentAmbientUrl;

  // === NETTOYAGE ===

  @override
  Future<void> onTaskRemoved() async {
    LoggingService.w('Tâche supprimée, arrêt audio');
    await stop();
  }

  void dispose() {
    _player.dispose();
    LoggingService.i('BookTuneAudioHandler disposed');
  }
}
