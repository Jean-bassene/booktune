import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeMetadata {
  final String title;
  final String author;
  final int durationSeconds;
  final String videoId;

  YoutubeMetadata({
    required this.title,
    required this.author,
    required this.durationSeconds,
    required this.videoId,
  });
}

class YoutubeMetadataService {
  static final _yt = YoutubeExplode();

  /// Extrait les métadonnées d'une vidéo YouTube à partir de l'URL
  /// Retourne null si l'URL est invalide ou si la vidéo n'existe pas
  static Future<YoutubeMetadata?> getMetadata(String url) async {
    try {
      // Valide et récupère l'ID vidéo
      final videoId = _extractVideoId(url);
      if (videoId == null || videoId.isEmpty) {
        return null;
      }

      // Récupère les informations de la vidéo
      final video = await _yt.videos.get(videoId);

      return YoutubeMetadata(
        title: video.title,
        author: video.author,
        durationSeconds: video.duration?.inSeconds ?? 0,
        videoId: videoId,
      );
    } catch (e) {
      print('Erreur lors de la récupération des métadonnées YouTube: $e');
      return null;
    }
  }

  /// Valide si une URL est une URL YouTube valide
  static bool isValidYoutubeUrl(String url) {
    final videoId = _extractVideoId(url);
    return videoId != null && videoId.isNotEmpty;
  }

  // Extract video id from common YouTube URL formats
  // Supports: https://www.youtube.com/watch?v=ID, https://youtu.be/ID, with extra params
  static String? _extractVideoId(String url) {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return null;

      // Short link youtu.be/ID
      if (uri.host.contains('youtu.be')) {
        final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
        return id;
      }

      // Standard link youtube.com/watch?v=ID
      if (uri.queryParameters.containsKey('v')) {
        return uri.queryParameters['v'];
      }

      // embed or other formats: look for last path segment
      if (uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Dispose des ressources
  static void dispose() {
    _yt.close();
  }
}
