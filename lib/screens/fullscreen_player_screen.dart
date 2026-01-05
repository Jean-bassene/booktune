import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';

class FullscreenPlayerScreen extends StatelessWidget {
  const FullscreenPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<PlayerProvider>(
        builder: (context, player, child) {
          if (player.currentAudiobook == null) {
            return const SizedBox.expand(
              child: Center(
                child: Text(
                  'Aucun audiobook',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          }

          return GestureDetector(
            onDoubleTap: player.togglePlayPause,
            onHorizontalDragEnd: (details) {
              // Swipe gauche = avancer 30s
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! < -500) {
                final newPosition = player.position.inSeconds + 30;
                final maxDuration = player.currentAudiobook!.duration;
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
            child: SafeArea(
              child: Stack(
                children: [
                  // Contenu principal
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // En-tête avec bouton retour
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_down),
                              color: Colors.white,
                              iconSize: 32,
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Text(
                              'Lecteur',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 56),
                          ],
                        ),
                      ),

                      // Artwork central
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildCoverArt(),
                        ),
                      ),

                      // Infos du livre
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            Text(
                              player.currentAudiobook!.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              player.currentAudiobook!.author,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Progress bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 6,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 10,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 15,
                                ),
                              ),
                              child: Slider(
                                min: 0,
                                max: player.currentAudiobook!.duration
                                    .toDouble(),
                                value: player.position.inSeconds.toDouble(),
                                activeColor: Colors.purple.shade500,
                                inactiveColor: Colors.white.withOpacity(0.2),
                                onChanged: (value) {
                                  player.seek(Duration(seconds: value.toInt()));
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(
                                    Duration(
                                      seconds: player.position.inSeconds,
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _formatDuration(
                                    Duration(
                                      seconds:
                                          player.currentAudiobook!.duration,
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Contrôles de playback
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Reculer 30s
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: () {
                                  final newPosition =
                                      player.position.inSeconds - 30;
                                  if (newPosition >= 0) {
                                    player.seek(
                                      Duration(seconds: newPosition),
                                    );
                                  } else {
                                    player.seek(Duration.zero);
                                  }
                                },
                                icon: const Icon(Icons.replay_30),
                                color: Colors.white,
                                iconSize: 32,
                              ),
                            ),
                            const SizedBox(width: 24),

                            // Play/Pause
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.purple.shade500,
                                    Colors.pink.shade500
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.purple.shade500.withOpacity(0.6),
                                    blurRadius: 25,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: player.togglePlayPause,
                                icon: Icon(
                                  player.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  size: 44,
                                ),
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(width: 24),

                            // Avancer 30s
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: () {
                                  final newPosition =
                                      player.position.inSeconds + 30;
                                  final maxDuration =
                                      player.currentAudiobook!.duration;
                                  if (newPosition <= maxDuration) {
                                    player.seek(
                                      Duration(seconds: newPosition),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.forward_30),
                                color: Colors.white,
                                iconSize: 32,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Volume slider
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                          ),
                          child: Slider(
                            min: 0,
                            max: 1,
                            value: player.audiobookVolume,
                            activeColor: Colors.purple.shade500,
                            inactiveColor: Colors.white.withOpacity(0.2),
                            onChanged: (value) =>
                                player.setAudiobookVolume(value),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCoverArt() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.shade700,
                Colors.deepPurple.shade900,
                Colors.purple.shade800,
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.audiotrack,
              size: 120,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours == 0) {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}
