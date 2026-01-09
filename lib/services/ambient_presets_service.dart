import '../models/ambient_music.dart';

class AmbientPresetsService {
  static const List<Map<String, dynamic>> _presets = [
    {
      'name': 'Nebula',
      'filePath': 'assets/ambient/Nebula.mp3',
      'category': 'space',
      'duration': 180, // 3 minutes
      'description': 'Ambiance spatiale relaxante',
    },
    {
      'name': 'Piano doux',
      'filePath': 'assets/ambient/piano.mp3',
      'category': 'music',
      'duration': 240, // 4 minutes
      'description': 'Mélodies apaisantes au piano',
    },
    {
      'name': 'Rising',
      'filePath': 'assets/ambient/Rising.mp3',
      'category': 'inspirational',
      'duration': 300, // 5 minutes
      'description': 'Musique motivante et uplifting',
    },
    {
      'name': 'Sunrise',
      'filePath': 'assets/ambient/Sunrise.mp3',
      'category': 'nature',
      'duration': 200, // 3.3 minutes
      'description': 'Lever du soleil paisible',
    },
  ];

  /// Obtenir toutes les ambiances pré-packagées
  static List<AmbientMusic> getPresetAmbients() {
    return _presets.map((preset) {
      return AmbientMusic(
        name: preset['name'],
        filePath: preset['filePath'],
        duration: preset['duration'],
        category: preset['category'],
        isLoop: true,
        dateImported: DateTime.now(),
      );
    }).toList();
  }

  /// Obtenir ambiances par catégorie
  static List<AmbientMusic> getPresetsByCategory(String category) {
    return getPresetAmbients()
        .where((ambient) => ambient.category == category)
        .toList();
  }

  /// Obtenir toutes les catégories disponibles
  static List<String> getCategories() {
    return _presets
        .map((preset) => preset['category'] as String)
        .toSet()
        .toList();
  }

  /// Vérifier si un fichier est une ambiance pré-packagée
  static bool isPresetAmbient(String filePath) {
    return _presets.any((preset) => preset['filePath'] == filePath);
  }

  /// Obtenir la description d'une ambiance
  static String? getDescription(String filePath) {
    final preset = _presets.firstWhere(
      (preset) => preset['filePath'] == filePath,
      orElse: () => {},
    );
    return preset['description'];
  }
}
