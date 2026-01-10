import 'dart:async';
import 'package:audio_service/audio_service.dart';
import '../models/audiobook.dart';
import '../models/librivox_book.dart';
import '../providers/player_provider.dart';

class MediaNotificationService {
  static PlayerProvider? _playerProvider;

  static void setPlayerProvider(PlayerProvider provider) {
    _playerProvider = provider;
  }

  static Future<void> init() async {
    await AudioService.init(
      builder: () => _AudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.booktune.audio',
        androidNotificationChannelName: 'BookTune Audio Playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  }

  static Future<void> updateMediaItem(Audiobook audiobook,
      {String? chapterTitle}) async {
    if (AudioService.running) {
      final mediaItem = MediaItem(
        id: audiobook.id?.toString() ?? 'unknown',
        album: 'BookTune',
        title: chapterTitle ?? audiobook.title,
        artist: audiobook.author,
        duration: audiobook.duration != null
            ? Duration(seconds: audiobook.duration!)
            : null,
      );
      await AudioServiceBackground.setMediaItem(mediaItem);
    }
  }

  static Future<void> updateMediaItemFromLibrivox(
      LibrivoxBook book, String chapterTitle) async {
    if (AudioService.running) {
      final mediaItem = MediaItem(
        id: book.id,
        album: 'LibriVox',
        title: chapterTitle,
        artist: book.author,
      );
      await AudioServiceBackground.setMediaItem(mediaItem);
    }
  }

  static Future<void> updatePlaybackState(
      bool isPlaying, Duration position, Duration? duration) async {
    if (AudioService.running) {
      await AudioServiceBackground.setState(
        controls: [
          MediaControl.skipToPrevious,
          isPlaying ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        processingState: AudioProcessingState.ready,
        playing: isPlaying,
        position: position,
        speed: 1.0,
      );
    }
  }
}

class _AudioHandler extends BaseAudioHandler with SeekHandler {
  @override
  Future<void> play() async {
    await MediaNotificationService._playerProvider?.togglePlayPause();
  }

  @override
  Future<void> pause() async {
    await MediaNotificationService._playerProvider?.togglePlayPause();
  }

  @override
  Future<void> stop() async {
    await MediaNotificationService._playerProvider?.togglePlayPause();
  }

  @override
  Future<void> seek(Duration position) async {
    await MediaNotificationService._playerProvider?.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    await MediaNotificationService._playerProvider?.playNextChapter();
  }

  @override
  Future<void> skipToPrevious() async {
    await MediaNotificationService._playerProvider?.playPreviousChapter();
  }
}
