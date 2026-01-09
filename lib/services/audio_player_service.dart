import 'package:just_audio/just_audio.dart';
import 'dart:async';

class AudioPlayerService {
  // Lecteur principal pour le livre audio
  final AudioPlayer _audiobookPlayer = AudioPlayer();

  // Lecteur pour la musique d'ambiance
  final AudioPlayer _ambientPlayer = AudioPlayer();

  // Flag pour éviter les appels concurrents
  bool _isLoading = false;

  // Flag pour savoir si la musique d'ambiance est chargée
  bool _ambientLoaded = false;

  // Streams pour l'état de lecture
  Stream<Duration> get positionStream => _audiobookPlayer.positionStream;
  Stream<Duration?> get durationStream => _audiobookPlayer.durationStream;
  Stream<PlayerState> get playerStateStream =>
      _audiobookPlayer.playerStateStream;

  // Stream pour détecter la fin de la lecture
  Stream<bool> get playbackCompletedStream =>
      _audiobookPlayer.playbackEventStream
          .map((event) => event.processingState == ProcessingState.completed);

  // État actuel
  bool get isPlaying => _audiobookPlayer.playing;
  Duration get position => _audiobookPlayer.position;
  Duration? get duration => _audiobookPlayer.duration;

  /// Charge un livre audio (local ou réseau)
  Future<void> loadAudiobook(String path, {bool isNetwork = false}) async {
    // Éviter les appels concurrents
    if (_isLoading) {
      print('Chargement déjà en cours, ignoré');
      return;
    }

    _isLoading = true;
    try {
      // Arrêter la lecture actuelle avant de charger
      await _audiobookPlayer.stop();

      if (isNetwork) {
        await _audiobookPlayer.setUrl(path);
      } else {
        await _audiobookPlayer.setFilePath(path);
      }
      print('Livre audio chargé: $path');
    } catch (e) {
      print('Erreur chargement livre audio: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// Charge une musique d'ambiance (asset ou fichier local)
  Future<void> loadAmbientMusic(String filePath) async {
    try {
      if (filePath.startsWith('assets/')) {
        // Charger depuis les assets
        await _ambientPlayer.setAsset(filePath);
      } else {
        // Charger depuis le système de fichiers
        await _ambientPlayer.setFilePath(filePath);
      }
      // Configuration pour boucler
      await _ambientPlayer.setLoopMode(LoopMode.one);
      _ambientLoaded = true;
      print('Musique d\'ambiance chargée: $filePath');
    } catch (e) {
      print('Erreur chargement musique: $e');
      _ambientLoaded = false;
      rethrow;
    }
  }

  /// Démarre la lecture
  Future<void> play() async {
    await _audiobookPlayer.play();
    if (_ambientLoaded) {
      await _ambientPlayer.play();
    }
  }

  /// Met en pause
  Future<void> pause() async {
    await _audiobookPlayer.pause();
    await _ambientPlayer.pause();
  }

  /// Arrête la lecture
  Future<void> stop() async {
    await _audiobookPlayer.stop();
    await _ambientPlayer.stop();
  }

  /// Cherche à une position spécifique
  Future<void> seek(Duration position) async {
    await _audiobookPlayer.seek(position);
  }

  /// Avance de X secondes
  Future<void> skipForward(int seconds) async {
    final newPosition = position + Duration(seconds: seconds);
    if (duration != null && newPosition < duration!) {
      await seek(newPosition);
    }
  }

  /// Recule de X secondes
  Future<void> skipBackward(int seconds) async {
    final newPosition = position - Duration(seconds: seconds);
    if (newPosition.isNegative) {
      await seek(Duration.zero);
    } else {
      await seek(newPosition);
    }
  }

  /// Définit le volume du livre audio (0.0 à 1.0)
  Future<void> setAudiobookVolume(double volume) async {
    await _audiobookPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Définit le volume de la musique d'ambiance (0.0 à 1.0)
  Future<void> setAmbientVolume(double volume) async {
    await _ambientPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Définit la vitesse de lecture (0.5 à 2.0)
  Future<void> setSpeed(double speed) async {
    await _audiobookPlayer.setSpeed(speed.clamp(0.5, 2.0));
  }

  /// Arrête la musique d'ambiance
  Future<void> stopAmbient() async {
    await _ambientPlayer.stop();
    _ambientLoaded = false;
  }

  /// Libère les ressources
  Future<void> dispose() async {
    await _audiobookPlayer.dispose();
    await _ambientPlayer.dispose();
  }
}
