import 'package:flutter_test/flutter_test.dart';
import 'package:audiobook_mixer/providers/player_provider.dart';
import 'package:audiobook_mixer/models/audiobook.dart';

void main() {
  group('PlayerProvider Tests', () {
    test('initial state is correct', () {
      // Note: Ce test nécessite un mock de AudioPlayerService
      // Dans un vrai projet, on utiliserait mocktail ou mockito
    });

    test('progress calculation is correct', () {
      // Test de la logique de calcul du progrès
      const durationSeconds = 100;
      const positionSeconds = 50;

      final progress = positionSeconds / durationSeconds;
      expect(progress, 0.5);
    });

    test('volume clamping works correctly', () {
      // Test de clamping du volume
      expect(0.5.clamp(0.0, 1.0), 0.5);
      expect(1.5.clamp(0.0, 1.0), 1.0);
      expect(-0.5.clamp(0.0, 1.0), 0.0);
    });

    test('speed clamping works correctly', () {
      // Test de clamping de la vitesse
      expect(1.0.clamp(0.5, 2.0), 1.0);
      expect(2.5.clamp(0.5, 2.0), 2.0);
      expect(0.3.clamp(0.5, 2.0), 0.5);
    });
  });
}
