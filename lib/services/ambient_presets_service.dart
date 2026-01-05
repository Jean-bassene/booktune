import '../models/ambient_music.dart';

class AmbientPresetsService {
  static const List<Map<String, dynamic>> _presets = [
    {
      'name': 'Pluie douce',
      'filePath': 'assets/ambient/rain.mp3',
      'category': 'nature',
      'duration': 180, // 3 minutes
      'description': 'Pluie légère et apaisante',
    },
    {
      'name': 'Forêt mystique',
      'filePath': 'assets/ambient/forest.mp3',
      'category': 'nature',
      'duration': 240, // 4 minutes
      'description': 'Sons de la forêt avec oiseaux',
    },
    {
      'name': 'Vagues océan',
      'filePath': 'assets/ambient/ocean.mp3',
      'category': 'nature',
      'duration': 300, // 5 minutes
      'description': 'Vagues douces sur la plage',
    },
    {
      'name': 'Feu de cheminée',
      'filePath': 'assets/ambient/fireplace.mp3',
      'category': 'cozy',
      'duration': 200, // 3.3 minutes
      'description': 'Crépitement chaleureux du feu',
    },
    {
      'name': 'Café ambiance',
      'filePath': 'assets/ambient/cafe.mp3',
      'category': 'urban',
      'duration': 220, // 3.7 minutes
      'description': 'Ambiance café avec murmures',
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