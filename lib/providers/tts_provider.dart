import 'package:flutter/foundation.dart';
import '../models/text_audiobook.dart';
import '../services/database_service.dart';
import '../services/text_to_speech_service.dart';
import '../services/text_import_service.dart';

class TtsProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final TextToSpeechService _tts = TextToSpeechService();
  final TextImportService _importService = TextImportService();

  List<TextAudiobook> _textAudiobooks = [];
  TextAudiobook? _currentAudiobook;
  bool _isPlaying = false;
  int _currentCharPosition = 0;
  double _speechRate = 1.0;
  bool _isPremium = false;

  // Freemium limits
  static const int maxFreeYouTubeImports = 5;

  // Getters
  List<TextAudiobook> get textAudiobooks => _textAudiobooks;
  TextAudiobook? get currentAudiobook => _currentAudiobook;
  bool get isPlaying => _isPlaying;
  int get currentCharPosition => _currentCharPosition;
  double get speechRate => _speechRate;
  bool get isPremium => _isPremium;

  int get youtubeImportCount =>
      _textAudiobooks.where((a) => a.sourceType == 'youtube').length;
  bool get canImportYouTube =>
      _isPremium || youtubeImportCount < maxFreeYouTubeImports;
  int get youtubeImportsRemaining => maxFreeYouTubeImports - youtubeImportCount;

  TtsProvider() {
    _init();
  }

  Future<void> _init() async {
    await _tts.initialize();
    await loadTextAudiobooks();
    await _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    final premiumStr = await _db.getUserPreference('premium');
    _isPremium = premiumStr == 'true';
    notifyListeners();
  }

  Future<void> loadTextAudiobooks() async {
    try {
      _textAudiobooks = await _db.getAllTextAudiobooks();
      notifyListeners();
    } catch (e) {
      print('Erreur chargement audiobooks TTS: $e');
    }
  }

  Future<void> importTextFile() async {
    try {
      final audiobook = await _importService.importTextFile();
      if (audiobook != null) {
        await _db.insertTextAudiobook(audiobook);
        await loadTextAudiobooks();
      }
    } catch (e) {
      print('Erreur import fichier texte: $e');
    }
  }

  Future<bool> addYouTubeAudiobook(
    String title,
    String author,
    String youtubeUrl,
    double durationSeconds,
  ) async {
    if (!canImportYouTube) {
      print('Limite YouTube atteinte. Passer à premium pour plus.');
      return false;
    }

    try {
      final audiobook = _importService.createYouTubeAudiobook(
        title,
        author,
        youtubeUrl,
        durationSeconds,
      );
      await _db.insertTextAudiobook(audiobook);
      await loadTextAudiobooks();
      return true;
    } catch (e) {
      print('Erreur ajout YouTube: $e');
      return false;
    }
  }

  Future<void> playAudiobook(TextAudiobook audiobook) async {
    try {
      _currentAudiobook = audiobook;
      _currentCharPosition = audiobook.lastPosition;
      notifyListeners();

      // Reprendre à partir de la position sauvegardée
      final textToSpeak = _importService.getChunkFromPosition(
        audiobook.content,
        _currentCharPosition,
      );

      if (textToSpeak.isNotEmpty) {
        await _tts.speak(textToSpeak);
        _isPlaying = true;
        notifyListeners();
      }
    } catch (e) {
      print('Erreur lecture audiobook TTS: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _tts.pause();
      _isPlaying = false;
    } else {
      await _tts.resume();
      _isPlaying = true;
    }
    notifyListeners();
  }

  Future<void> stop() async {
    await _tts.stop();
    _isPlaying = false;
    if (_currentAudiobook != null) {
      await _db.updateTextAudiobookPosition(
        _currentAudiobook!.id!,
        _currentCharPosition,
      );
    }
    notifyListeners();
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    await _tts.setSpeechRate(rate);
    notifyListeners();
  }

  Future<void> updatePosition(int charPosition) async {
    _currentCharPosition = charPosition;
    if (_currentAudiobook != null) {
      await _db.updateTextAudiobookPosition(
        _currentAudiobook!.id!,
        charPosition,
      );
    }
    notifyListeners();
  }

  Future<void> deleteTextAudiobook(int id) async {
    try {
      await _db.deleteTextAudiobook(id);
      await loadTextAudiobooks();
    } catch (e) {
      print('Erreur suppression audiobook TTS: $e');
    }
  }

  Future<void> setPremiumStatus(bool isPremium) async {
    _isPremium = isPremium;
    await _db.setUserPreference('premium', isPremium ? 'true' : 'false');
    notifyListeners();
  }

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }
}
