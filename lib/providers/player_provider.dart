import 'package:flutter/foundation.dart';
import '../models/audiobook.dart';
import '../models/ambient_music.dart';
import '../services/audio_player_service.dart';
import 'audiobook_provider.dart';
import 'dart:async';

class PlayerProvider with ChangeNotifier {
  final AudioPlayerService _audioService = AudioPlayerService();
  AudiobookProvider? _audiobookProvider;

  Audiobook? _currentAudiobook;
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

  // Position save timer
  Timer? _positionSaveTimer;

  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _stateSubscription;

  // Getters
  Audiobook? get currentAudiobook => _currentAudiobook;
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
      notifyListeners();
    });
  }

  /// Charge et joue un livre audio
  Future<void> loadAndPlayAudiobook(Audiobook audiobook) async {
    try {
      _currentAudiobook = audiobook;
      notifyListeners();

      await _audioService.loadAudiobook(audiobook.filePath);

      // Reprendre à la dernière position
      if (audiobook.lastPosition > 0) {
        await _audioService.seek(Duration(seconds: audiobook.lastPosition));
      }

      await _audioService.setAudiobookVolume(_audiobookVolume);
      await _audioService.play();

      // Démarrer la sauvegarde automatique de position toutes les 5 secondes
      _startPositionSaving();
    } catch (e) {
      print('Erreur chargement audiobook: $e');
    }
  }

  /// Démarrer la sauvegarde automatique de position
  void _startPositionSaving() {
    _positionSaveTimer?.cancel();
    _positionSaveTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_currentAudiobook != null && _position.inSeconds > 0) {
        try {
          _audiobookProvider?.updatePosition(
            _currentAudiobook!.id!,
            _position.inSeconds,
          );
        } catch (e) {
          print('Erreur sauvegarde position: $e');
        }
      }
    });
  }

  /// Setter pour AudiobookProvider
  void setAudiobookProvider(AudiobookProvider provider) {
    _audiobookProvider = provider;
  }

  /// Charge et joue une musique d'ambiance
  Future<void> loadAndPlayAmbient(AmbientMusic music) async {
    try {
      _currentAmbientMusic = music;
      notifyListeners();

      await _audioService.loadAmbientMusic(music.filePath);
      await _audioService.setAmbientVolume(_ambientVolume);

      if (_isPlaying) {
        await _audioService.play();
      }
    } catch (e) {
      print('Erreur chargement musique: $e');
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
    if (_isPlaying) {
      await _audioService.pause();
    } else {
      await _audioService.play();
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
        await togglePlayPause(); // Stop playback
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

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _positionSaveTimer?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _stateSubscription?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}
