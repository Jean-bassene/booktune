import 'dart:io';
import 'dart:typed_data';

void main() async {
  print('Génération de fichiers MP3 valides...');
  
  final ambientDir = Directory('assets/ambient');
  if (!await ambientDir.exists()) {
    await ambientDir.create(recursive: true);
  }

  // En-tête MP3 valide pour un fichier silencieux
  final mp3Header = Uint8List.fromList([
    // ID3v2 header
    0x49, 0x44, 0x33, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    // MP3 frame header (MPEG-1 Layer 3, 128kbps, 44.1kHz, mono)
    0xFF, 0xFB, 0x90, 0x00,
    // Données audio silencieuses (frame MP3 valide)
    ...List.filled(417, 0x00), // Taille frame MP3 standard
  ]);

  final files = ['rain.mp3', 'forest.mp3', 'ocean.mp3', 'fireplace.mp3', 'cafe.mp3'];
  
  for (final fileName in files) {
    final file = File('assets/ambient/$fileName');
    
    // Créer un fichier MP3 de 3 secondes (environ 72 frames)
    final content = <int>[];
    content.addAll(mp3Header);
    
    // Ajouter plus de frames pour une durée de ~3 secondes
    for (int i = 0; i < 72; i++) {
      content.addAll([0xFF, 0xFB, 0x90, 0x00]); // Frame header
      content.addAll(List.filled(413, 0x00)); // Données silencieuses
    }
    
    await file.writeAsBytes(content);
    print('✓ $fileName créé (${content.length} bytes)');
  }
  
  print('✅ Tous les fichiers MP3 générés avec succès !');
}