import 'package:flutter/foundation.dart';
import '../models/audiobook.dart';
import '../models/ambient_music.dart';
import '../services/database_service.dart';

class AudiobookProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<Audiobook> _audiobooks = [];
  List<AmbientMusic> _ambientMusic = [];
  bool _isLoading = false;
  String? _error;

  List<Audiobook> get audiobooks => _audiobooks;
  List<AmbientMusic> get ambientMusic => _ambientMusic;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Charge tous les livres audio
  Future<void> loadAudiobooks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _audiobooks = await _db.getAllAudiobooks();
    } catch (e) {
      _error = 'Erreur de chargement: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge toutes les musiques d'ambiance
  Future<void> loadAmbientMusic() async {
    try {
      _ambientMusic = await _db.getAllAmbientMusic();
      notifyListeners();
    } catch (e) {
      print('Erreur chargement musiques: $e');
    }
  }

  /// Ajoute un livre audio
  Future<void> addAudiobook(Audiobook audiobook) async {
    try {
      await _db.insertAudiobook(audiobook);
      await loadAudiobooks();
    } catch (e) {
      _error = 'Erreur d\'ajout: $e';
      notifyListeners();
    }
  }

  /// Ajoute une musique d'ambiance
  Future<void> addAmbientMusic(AmbientMusic music) async {
    try {
      await _db.insertAmbientMusic(music);
      await loadAmbientMusic();
    } catch (e) {
      print('Erreur ajout musique: $e');
    }
  }

  /// Met à jour la position d'un livre audio
  Future<void> updatePosition(int id, int position) async {
    try {
      await _db.updateAudiobookPosition(id, position);
      final index = _audiobooks.indexWhere((a) => a.id == id);
      if (index != -1) {
        _audiobooks[index] =
            _audiobooks[index].copyWith(lastPosition: position);
        notifyListeners();
      }
    } catch (e) {
      print('Erreur mise à jour position: $e');
    }
  }

  /// Basculer le statut favoris d'un livre
  Future<void> toggleFavorite(int id) async {
    try {
      final audiobook = _audiobooks.firstWhere((book) => book.id == id);
      final newFavoriteStatus = !audiobook.isFavorite;
      
      await _db.updateAudiobookFavorite(id, newFavoriteStatus);
      
      // Mettre à jour localement
      final index = _audiobooks.indexWhere((book) => book.id == id);
      if (index != -1) {
        _audiobooks[index] = audiobook.copyWith(isFavorite: newFavoriteStatus);
        notifyListeners();
      }
    } catch (e) {
      print('Erreur basculement favoris: $e');
    }
  }

  /// Supprime un livre audio
  Future<void> deleteAudiobook(int id) async {
    try {
      await _db.deleteAudiobook(id);
      await loadAudiobooks();
    } catch (e) {
      _error = 'Erreur de suppression: $e';
      notifyListeners();
    }
  }

  /// Supprime une musique d'ambiance
  Future<void> deleteAmbientMusic(int id) async {
    try {
      await _db.deleteAmbientMusic(id);
      await loadAmbientMusic();
    } catch (e) {
      print('Erreur suppression musique: $e');
    }
  }
}
