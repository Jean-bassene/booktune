import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/audiobook_provider.dart';
import '../widgets/volume_slider.dart';
import 'fullscreen_player_screen.dart';
import 'ambient_presets_screen.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.shade900,
            Colors.purple.shade900,
            Colors.deepPurple.shade900,
          ],
        ),
      ),
      child: SafeArea(
        child: Consumer<PlayerProvider>(
          builder: (context, player, child) {
            if (player.currentAudiobook == null) {
              return _buildNoAudiobookState();
            }

            return GestureDetector(
              onDoubleTap: player.togglePlayPause,
              onHorizontalDragEnd: (details) {
                // Swipe gauche = avancer 30s
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! < -500) {
                  final newPosition = player.position.inSeconds + 30;
                  final maxDuration = player.currentAudiobook!.duration ?? 0;
                  if (newPosition <= maxDuration) {
                    player.seek(Duration(seconds: newPosition));
                  }
                }
                // Swipe droite = reculer 30s
                else if (details.primaryVelocity != null &&
                    details.primaryVelocity! > 500) {
                  final newPosition = player.position.inSeconds - 30;
                  if (newPosition >= 0) {
                    player.seek(Duration(seconds: newPosition));
                  } else {
                    player.seek(Duration.zero);
                  }
                }
              },
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildArtwork(player),
                      const SizedBox(height: 30),
                      _buildTitle(player),
                      const SizedBox(height: 30),
                      _buildProgressBar(player),
                      const SizedBox(height: 30),
                      _buildPlaybackControls(player),
                      const SizedBox(height: 30),
                      _buildPlaybackSpeed(player),
                      const SizedBox(height: 20),
                      _buildSleepTimer(context, player),
                      const SizedBox(height: 30),
                      _buildVolumeControls(player),
                      const SizedBox(height: 30),
                      _buildAmbientSelector(context, player),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoAudiobookState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.headphones_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aucun livre en lecture',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sélectionnez un livre dans votre bibliothèque',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtwork(PlayerProvider player) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade600,
            Colors.indigo.shade800,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.shade900.withOpacity(0.5),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.book,
        size: 180,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTitle(PlayerProvider player) {
    return Column(
      children: [
        Text(
          player.currentAudiobook!.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          player.currentAudiobook!.author,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
          ),
          textAlign: TextAlign.center,
        ),
        if (player.chapterInfo.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Chapitre ${player.chapterInfo}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressBar(PlayerProvider player) {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: Colors.purple.shade400,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
            overlayColor: Colors.purple.shade400.withOpacity(0.2),
          ),
          child: Slider(
            value: player.progress.clamp(0.0, 1.0),
            onChanged: (value) {
              final newPosition = player.duration * value;
              player.seek(newPosition);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(player.position),
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
              Text(
                _formatDuration(player.duration),
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackControls(PlayerProvider player) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Chapitre précédent
        Container(
          decoration: BoxDecoration(
            color: (player.hasPreviousChapter)
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed:
                player.hasPreviousChapter ? player.playPreviousChapter : null,
            icon: const Icon(Icons.skip_previous),
            color: (player.hasPreviousChapter)
                ? Colors.white
                : Colors.white.withOpacity(0.3),
            iconSize: 32,
          ),
        ),
        const SizedBox(width: 12),

        // Reculer 15s
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: player.skipBackward,
            icon: const Icon(Icons.replay_10),
            color: Colors.white,
            iconSize: 32,
          ),
        ),
        const SizedBox(width: 20),

        // Play/Pause
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade500, Colors.pink.shade500],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.purple.shade500.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: IconButton(
            onPressed: player.togglePlayPause,
            icon: Icon(
              player.isPlaying ? Icons.pause : Icons.play_arrow,
              size: 40,
            ),
            color: Colors.white,
          ),
        ),

        const SizedBox(width: 20),

        // Avancer 15s
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: player.skipForward,
            icon: const Icon(Icons.forward_10),
            color: Colors.white,
            iconSize: 32,
          ),
        ),
        const SizedBox(width: 12),

        // Chapitre suivant
        Container(
          decoration: BoxDecoration(
            color: (player.hasNextChapter)
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: player.hasNextChapter ? player.playNextChapter : null,
            icon: const Icon(Icons.skip_next),
            color: (player.hasNextChapter)
                ? Colors.white
                : Colors.white.withOpacity(0.3),
            iconSize: 32,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackSpeed(PlayerProvider player) {
    final speeds = [1.0, 1.25, 1.5, 2.0];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.speed, color: Colors.purple, size: 20),
              SizedBox(width: 8),
              Text(
                'Vitesse de lecture',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: speeds.map((speed) {
              final isSelected = (player.playbackSpeed - speed).abs() < 0.01;
              return GestureDetector(
                onTap: () => player.setPlaybackSpeed(speed),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              Colors.purple.shade500,
                              Colors.pink.shade500,
                            ],
                          )
                        : null,
                    color: isSelected ? null : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    '${speed}x',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepTimer(BuildContext context, PlayerProvider player) {
    final timers = [5, 10, 15, 30, 60];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.timer, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Minuteur de sommeil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (player.hasSleepTimer)
                TextButton(
                  onPressed: player.cancelSleepTimer,
                  child: const Text(
                    'Annuler',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
          if (player.hasSleepTimer) ...[
            const SizedBox(height: 8),
            Text(
              'Arrêt dans ${player.sleepTimerMinutes} min',
              style: const TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: timers.map((minutes) {
              final isSelected = player.sleepTimerMinutes == minutes;
              return GestureDetector(
                onTap: () => player.setSleepTimer(minutes),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              Colors.orange.shade500,
                              Colors.deepOrange.shade500,
                            ],
                          )
                        : null,
                    color: isSelected ? null : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    '${minutes}m',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeControls(PlayerProvider player) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          VolumeSlider(
            label: 'Livre audio',
            icon: Icons.book,
            color: Colors.purple.shade400,
            value: player.audiobookVolume,
            onChanged: player.setAudiobookVolume,
          ),
          const SizedBox(height: 16),
          VolumeSlider(
            label: 'Musique d\'ambiance',
            icon: Icons.music_note,
            color: Colors.pink.shade400,
            value: player.ambientVolume,
            onChanged: player.setAmbientVolume,
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientSelector(BuildContext context, PlayerProvider player) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.music_note, color: Colors.purple, size: 20),
                SizedBox(width: 8),
                Text(
                  'Ambiance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AmbientPresetsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.library_music, size: 16),
                  label: const Text('Presets'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.purple.shade300,
                  ),
                ),
                if (player.currentAmbientMusic != null)
                  TextButton(
                    onPressed: player.stopAmbient,
                    child: const Text(
                      'Arrêter',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Consumer<AudiobookProvider>(
          builder: (context, audiobookProvider, child) {
            final ambientList = audiobookProvider.ambientMusic;

            if (ambientList.isEmpty) {
              return _buildNoAmbientMusic(context);
            }

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ambientList.map((music) {
                final isSelected = player.currentAmbientMusic?.id == music.id;
                return _buildAmbientChip(
                  context,
                  music.name,
                  music.id ?? 0, // Protection null
                  isSelected,
                  () async {
                    print(
                        '🔥 Clic sur ambiance: ${music.name} (${music.filePath})');
                    try {
                      await player.loadAndPlayAmbient(music);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().contains('Exception:')
                                  ? e.toString().split('Exception: ')[1]
                                  : e.toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.red.shade700,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    }
                  },
                  audiobookProvider,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNoAmbientMusic(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.white54, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Aucune musique d\'ambiance importée',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientChip(
    BuildContext context,
    String label,
    int musicId,
    bool isSelected,
    VoidCallback onTap,
    AudiobookProvider audiobookProvider,
  ) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () {
        _showDeleteAmbientDialog(context, label, musicId, audiobookProvider);
      },
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [Colors.purple.shade500, Colors.pink.shade500],
                    )
                  : null,
              color: isSelected ? null : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.2),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: () {
                _showDeleteAmbientDialog(
                    context, label, musicId, audiobookProvider);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade500,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAmbientDialog(
    BuildContext context,
    String musicName,
    int musicId,
    AudiobookProvider audiobookProvider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Supprimer l\'ambiance ?',
            style: TextStyle(color: Colors.white)),
        content: Text('Voulez-vous supprimer "$musicName" de vos ambiances ?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Annuler', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await audiobookProvider.deleteAmbientMusic(musicId);
                await audiobookProvider.loadAmbientMusic();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ambiance supprimée'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
