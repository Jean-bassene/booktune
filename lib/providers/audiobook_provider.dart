import 'package:flutter/foundation.dart';
import '../models/audiobook.dart';
import '../models/ambient_music.dart';
import '../services/database_service.dart';
import '../services/ambient_presets_service.dart';
import '../services/logging_service.dart';
import '../services/premium_service.dart';

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
      LoggingService.e('Erreur loadAudiobooks', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge toutes les musiques d'ambiance + presets
  Future<void> loadAmbientMusic() async {
    try {
      _ambientMusic = await _db.getAllAmbientMusic();

      // Si la BDD est vide ou corrompue, forcer l'initialisation des presets
      if (_ambientMusic.isEmpty) {
        await _initializePresets();
        // Recharger après initialisation
        _ambientMusic = await _db.getAllAmbientMusic();
      } else {
        // Vérifier que tous les presets sont présents
        await _initializePresets();
      }

      notifyListeners();
    } catch (e) {
      LoggingService.e('Erreur chargement musiques - mode secours activé', e);

      // MODE DE SECOURS : charger directement les presets si BDD cassée
      try {
        _ambientMusic = AmbientPresetsService.getPresetAmbients();
        LoggingService.i(
            'Mode secours ambiances activé: ${_ambientMusic.length} musiques chargées');
        notifyListeners();
      } catch (fallbackError) {
        LoggingService.e('Erreur mode secours ambiances', fallbackError);
      }
    }
  }

  /// Initialise les ambiances pré-packagées (toujours, même si elles existent déjà)
  Future<void> initializePresets() async {
    try {
      await _initializePresets();
      notifyListeners();
    } catch (e) {
      LoggingService.e('Erreur initialisation presets', e);
    }
  }

  /// Initialise les ambiances pré-packagées si nécessaire
  Future<void> _initializePresets() async {
    try {
      final presets = AmbientPresetsService.getPresetAmbients();

      for (final preset in presets) {
        final exists =
            _ambientMusic.any((music) => music.filePath == preset.filePath);

        if (!exists) {
          await _db.insertAmbientMusic(preset);
          _ambientMusic.add(preset);
        }
      }
    } catch (e) {
      LoggingService.e('Erreur initialisation presets', e);

      // Vérifier si c'est une erreur de DB corrompue
      if (e.toString().contains('READONLY') ||
          e.toString().contains('readonly')) {
        LoggingService.w(
            'Base de données corrompue détectée - tentative de réparation');

        try {
          // Essayer de réparer la DB automatiquement
          await _repairDatabase();
          LoggingService.i('Base de données réparée avec succès');

          // Réessayer l'initialisation après réparation
          final presets = AmbientPresetsService.getPresetAmbients();
          for (final preset in presets) {
            final exists =
                _ambientMusic.any((music) => music.filePath == preset.filePath);
            if (!exists) {
              await _db.insertAmbientMusic(preset);
              _ambientMusic.add(preset);
            }
          }
          LoggingService.i('Presets réinitialisés après réparation DB');
        } catch (repairError) {
          LoggingService.e('Échec réparation DB automatique', repairError);
          LoggingService.w(
              'Mode secours : utilisation des presets en mémoire seulement');

          // Mode secours : charger directement les presets sans DB
          _ambientMusic.clear();
          _ambientMusic.addAll(AmbientPresetsService.getPresetAmbients());
        }
      }
    }
  }

  /// Répare automatiquement la base de données corrompue
  Future<void> _repairDatabase() async {
    try {
      LoggingService.i('Réparation base de données...');

      // Fermer toutes les connexions
      await _db.close();

      // Supprimer les fichiers DB corrompus (si possible)
      // Note: Sur mobile, on ne peut pas supprimer directement les fichiers
      // La DB sera recréée automatiquement à la prochaine ouverture

      // Forcer la recréation en réinitialisant l'instance
      await DatabaseService.resetInstance();

      LoggingService.i('Base de données réparée');
    } catch (e) {
      LoggingService.e('Erreur réparation DB', e);
      rethrow;
    }
  }

  /// Ajoute un livre audio
  Future<void> addAudiobook(Audiobook audiobook) async {
    try {
      final newId = await _db.insertAudiobook(audiobook);
      final newAudiobook = audiobook.copyWith(id: newId);
      _audiobooks.add(newAudiobook);
      notifyListeners();
    } catch (e) {
      _error = 'Erreur d\'ajout: $e';
      LoggingService.e('Erreur addAudiobook', e);
      notifyListeners();
    }
  }

  /// Ajoute une musique d'ambiance
  Future<void> addAmbientMusic(AmbientMusic music) async {
    try {
      final newId = await _db.insertAmbientMusic(music);
      _ambientMusic.add(music.copyWith(id: newId));
      notifyListeners();
    } catch (e) {
      LoggingService.e('Erreur ajout musique', e);
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
      LoggingService.e('Erreur mise à jour position', e);
    }
  }

  /// Basculer le statut favoris d'un livre
  Future<void> toggleFavorite(int id) async {
    try {
      final audiobook = _audiobooks.firstWhere((book) => book.id == id);
      final newFavoriteStatus = !audiobook.isFavorite;

      await _db.updateAudiobookFavorite(id, newFavoriteStatus);

      final index = _audiobooks.indexWhere((book) => book.id == id);
      if (index != -1) {
        _audiobooks[index] = audiobook.copyWith(isFavorite: newFavoriteStatus);
        notifyListeners();
      }
    } catch (e) {
      LoggingService.e('Erreur basculement favoris', e);
    }
  }

  /// Supprime un livre audio
  Future<void> deleteAudiobook(int id) async {
    try {
      await _db.deleteAudiobook(id);
      _audiobooks.removeWhere((book) => book.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Erreur de suppression: $e';
      LoggingService.e('Erreur deleteAudiobook', e);
      notifyListeners();
    }
  }

  /// Vérifie si l'utilisateur peut importer une ambiance personnalisée
  bool get canImportAmbience => premiumService.canImportAmbience;

  /// Nombre d'imports d'ambiances restants
  int get remainingCustomAmbiences => premiumService.remainingCustomAmbiences;

  /// Message d'avertissement pour limitation ambiances
  String get ambienceLimitationMessage =>
      premiumService.getLimitationMessage('custom_ambience');

  /// Ajoute une musique d'ambiance personnalisée (avec vérification premium)
  Future<bool> addCustomAmbientMusic(AmbientMusic music) async {
    if (!canImportAmbience) {
      LoggingService.w('Import ambiance refusé - limite atteinte');
      return false;
    }

    try {
      final newId = await _db.insertAmbientMusic(music);
      _ambientMusic.add(music.copyWith(id: newId));

      // Incrémenter le compteur premium
      await premiumService.incrementCustomAmbiences();

      notifyListeners();
      LoggingService.i('Ambiance personnalisée ajoutée: ${music.name}');
      return true;
    } catch (e) {
      LoggingService.e('Erreur ajout ambiance personnalisée', e);
      return false;
    }
  }

  /// Supprime une musique d'ambiance
  Future<void> deleteAmbientMusic(int id) async {
    try {
      await _db.deleteAmbientMusic(id);
      _ambientMusic.removeWhere((music) => music.id == id);
      notifyListeners();
    } catch (e) {
      LoggingService.e('Erreur suppression musique', e);
    }
  }
}
