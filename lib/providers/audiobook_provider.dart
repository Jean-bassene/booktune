import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/audiobook.dart';
import '../models/ambient_music.dart';
import '../services/database_service.dart';
import '../services/ambient_presets_service.dart';
import '../services/logging_service.dart';

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

  /// Charge tous les livres audio avec vérification des fichiers
  Future<void> loadAudiobooks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final rawBooks = await _db.getAllAudiobooks();
      LoggingService.i('Livres chargés depuis BDD: ${rawBooks.length}');

      // Vérifier l'existence des fichiers et filtrer les livres invalides
      final validBooks = <Audiobook>[];
      final invalidBooks = <Audiobook>[];

      for (final book in rawBooks) {
        final fileExists = await _checkFileExists(book.filePath);
        if (fileExists) {
          validBooks.add(book);
        } else {
          invalidBooks.add(book);
          LoggingService.w(
              'Fichier manquant pour livre: ${book.title} (${book.filePath})');
        }
      }

      // Supprimer les livres avec fichiers manquants de la BDD
      if (invalidBooks.isNotEmpty) {
        LoggingService.i(
            'Suppression de ${invalidBooks.length} livres avec fichiers manquants');
        for (final book in invalidBooks) {
          await _db.deleteAudiobook(book.id!);
        }
      }

      _audiobooks = validBooks;
      LoggingService.i(
          'Livres valides après vérification: ${_audiobooks.length}');
    } catch (e) {
      _error = 'Erreur de chargement: $e';
      LoggingService.e('Erreur loadAudiobooks', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge toutes les musiques d'ambiance + presets avec vérification
  Future<void> loadAmbientMusic() async {
    try {
      final rawMusic = await _db.getAllAmbientMusic();
      LoggingService.i('Musiques chargées depuis BDD: ${rawMusic.length}');

      // Vérifier l'existence des fichiers pour les musiques non-packagées
      final validMusic = <AmbientMusic>[];
      final invalidMusic = <AmbientMusic>[];

      for (final music in rawMusic) {
        // Les musiques packagées (assets) n'ont pas besoin de vérification
        if (music.filePath.startsWith('assets/')) {
          validMusic.add(music);
        } else {
          // Vérifier l'existence des fichiers importés
          final fileExists = await _checkFileExists(music.filePath);
          if (fileExists) {
            validMusic.add(music);
          } else {
            invalidMusic.add(music);
            LoggingService.w(
                'Fichier manquant pour musique: ${music.name} (${music.filePath})');
          }
        }
      }

      // Supprimer les musiques avec fichiers manquants de la BDD
      if (invalidMusic.isNotEmpty) {
        LoggingService.i(
            'Suppression de ${invalidMusic.length} musiques avec fichiers manquants');
        for (final music in invalidMusic) {
          await _db.deleteAmbientMusic(music.id!);
        }
      }

      _ambientMusic = validMusic;
      LoggingService.i(
          'Musiques valides après vérification: ${_ambientMusic.length}');

      await _initializePresets();
      notifyListeners();
    } catch (e) {
      LoggingService.e('Erreur chargement musiques', e);
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

  /// Vérifie si un fichier existe
  Future<bool> _checkFileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      LoggingService.w('Erreur vérification fichier: $filePath', e);
      return false;
    }
  }
}
