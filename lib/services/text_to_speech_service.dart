import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  double _speechRate = 1.0;
  bool _isSpeaking = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(_speechRate);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _isInitialized = true;
    } catch (e) {
      print('Erreur initialisation TTS: $e');
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _tts.speak(text);
      _isSpeaking = true;
    } catch (e) {
      print('Erreur lecture TTS: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _tts.pause();
      _isSpeaking = false;
    } catch (e) {
      print('Erreur pause TTS: $e');
    }
  }

  Future<void> resume() async {
    try {
      await _tts.speak(''); // Ou utiliser une autre API pour reprendre
      _isSpeaking = true;
    } catch (e) {
      print('Erreur reprise TTS: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
    } catch (e) {
      print('Erreur arrêt TTS: $e');
    }
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    try {
      await _tts.setSpeechRate(rate);
    } catch (e) {
      print('Erreur vitesse TTS: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _tts.setVolume(volume);
    } catch (e) {
      print('Erreur volume TTS: $e');
    }
  }

  Future<List<dynamic>> getAvailableVoices() async {
    try {
      return await _tts.getVoices;
    } catch (e) {
      print('Erreur récupération voix: $e');
      return [];
    }
  }

  Future<void> setVoice(Map<String, String> voice) async {
    try {
      await _tts.setVoice(voice);
    } catch (e) {
      print('Erreur définition voix: $e');
    }
  }

  bool get isSpeaking => _isSpeaking;
  double get speechRate => _speechRate;

  void dispose() {
    _tts.stop();
    _tts.stop();
  }
}
