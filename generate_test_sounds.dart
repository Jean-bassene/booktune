import 'dart:io';
import 'dart:math';

class AmbientSoundGenerator {
  /// Génère des fichiers audio de test basiques
  static Future<void> generateTestSounds() async {
    final ambientDir = Directory('assets/ambient');
    if (!await ambientDir.exists()) {
      await ambientDir.create(recursive: true);
    }

    // Créer des fichiers de test minimalistes
    final sounds = {
      'rain.mp3': _generateRainData(),
      'forest.mp3': _generateForestData(),
      'ocean.mp3': _generateOceanData(),
      'fireplace.mp3': _generateFireplaceData(),
      'cafe.mp3': _generateCafeData(),
    };

    for (final entry in sounds.entries) {
      final file = File('assets/ambient/${entry.key}');
      await file.writeAsBytes(entry.value);
      print('✓ ${entry.key} généré');
    }
  }

  static List<int> _generateRainData() {
    // Génère un fichier MP3 minimal avec métadonnées
    return _createMinimalMp3('Pluie douce', 180);
  }

  static List<int> _generateForestData() {
    return _createMinimalMp3('Forêt mystique', 240);
  }

  static List<int> _generateOceanData() {
    return _createMinimalMp3('Vagues océan', 300);
  }

  static List<int> _generateFireplaceData() {
    return _createMinimalMp3('Feu de cheminée', 200);
  }

  static List<int> _generateCafeData() {
    return _createMinimalMp3('Café ambiance', 220);
  }

  /// Crée un fichier MP3 minimal valide
  static List<int> _createMinimalMp3(String title, int durationSeconds) {
    // En-tête MP3 basique + métadonnées ID3
    final header = <int>[
      // ID3v2 header
      0x49, 0x44, 0x33, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      // Frame MP3 minimal
      0xFF, 0xFB, 0x90, 0x00,
    ];
    
    // Ajouter des données audio silencieuses
    final audioData = List.filled(durationSeconds * 100, 0x00);
    
    return [...header, ...audioData];
  }
}

void main() async {
  print('Génération des sons d\'ambiance de test...');
  await AmbientSoundGenerator.generateTestSounds();
  print('✅ Génération terminée !');
}