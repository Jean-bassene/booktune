import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ambient_music.dart';
import '../services/ambient_presets_service.dart';
import '../providers/player_provider.dart';

class AmbientPresetsScreen extends StatelessWidget {
  const AmbientPresetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Ambiances'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<PlayerProvider>(
        builder: (context, playerProvider, _) {
          final categories = AmbientPresetsService.getCategories();
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final ambients = AmbientPresetsService.getPresetsByCategory(category);
              
              return _buildCategorySection(
                context,
                category,
                ambients,
                playerProvider,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String category,
    List<AmbientMusic> ambients,
    PlayerProvider playerProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            _getCategoryTitle(category),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...ambients.map((ambient) => _buildAmbientCard(
          context,
          ambient,
          playerProvider,
        )),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAmbientCard(
    BuildContext context,
    AmbientMusic ambient,
    PlayerProvider playerProvider,
  ) {
    final isCurrentAmbient = playerProvider.currentAmbientMusic?.filePath == ambient.filePath;
    final description = AmbientPresetsService.getDescription(ambient.filePath);

    return Card(
      color: isCurrentAmbient 
          ? Colors.purple.shade700 
          : Colors.grey.shade900,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.shade600,
          child: Icon(
            _getCategoryIcon(ambient.category),
            color: Colors.white,
          ),
        ),
        title: Text(
          ambient.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: description != null
            ? Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              )
            : null,
        trailing: isCurrentAmbient
            ? IconButton(
                icon: const Icon(Icons.stop, color: Colors.white),
                onPressed: () => playerProvider.stopAmbient(),
              )
            : IconButton(
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                onPressed: () => playerProvider.loadAndPlayAmbient(ambient),
              ),
      ),
    );
  }

  String _getCategoryTitle(String category) {
    switch (category) {
      case 'nature':
        return '🌿 Nature';
      case 'cozy':
        return '🔥 Cosy';
      case 'urban':
        return '🏙️ Urbain';
      default:
        return category;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'nature':
        return Icons.nature;
      case 'cozy':
        return Icons.fireplace;
      case 'urban':
        return Icons.location_city;
      default:
        return Icons.music_note;
    }
  }
}