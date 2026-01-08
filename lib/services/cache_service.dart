import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'logging_service.dart';

/// Service de gestion du cache pour les fichiers audio réseau
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  Directory? _cacheDirectory;

  /// Initialise le répertoire de cache
  Future<void> _init() async {
    if (_cacheDirectory == null) {
      _cacheDirectory = await getTemporaryDirectory();
      LoggingService.i('Cache initialisé: ${_cacheDirectory!.path}');
    }
  }

  /// Récupère ou crée le fichier de cache pour une URL
  Future<File> getCachedFile(String url) async {
    await _init();

    // Créer un nom de fichier unique à partir de l'URL
    final fileName = _generateFileName(url);
    final cacheFile = File('${_cacheDirectory!.path}/$fileName');

    return cacheFile;
  }

  /// Génère un nom de fichier unique à partir de l'URL
  String _generateFileName(String url) {
    // Utiliser le hash de l'URL pour éviter les caractères spéciaux
    final hash = url.hashCode.abs().toString();
    final extension = url.contains('.mp3') ? '.mp3' : '.audio';
    return 'audio_$hash$extension';
  }

  /// Vérifie si un fichier est en cache
  Future<bool> isCached(String url) async {
    try {
      final cacheFile = await getCachedFile(url);
      return await cacheFile.exists();
    } catch (e) {
      LoggingService.e('Erreur vérification cache', e);
      return false;
    }
  }

  /// Récupère la taille du cache
  Future<int> getCacheSize() async {
    await _init();
    int totalSize = 0;

    if (_cacheDirectory!.existsSync()) {
      final entities = await _cacheDirectory!.list().toList();
      for (final entity in entities) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    }

    return totalSize;
  }

  /// Formate la taille en bytes en format lisible
  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Vide le cache
  Future<void> clearCache() async {
    await _init();

    if (_cacheDirectory!.existsSync()) {
      final entities = await _cacheDirectory!.list().toList();
      for (final entity in entities) {
        try {
          if (entity is File) {
            await entity.delete();
          }
        } catch (e) {
          LoggingService.w('Erreur suppression fichier cache', e);
        }
      }
      LoggingService.i('Cache vidé');
    }
  }

  /// Supprime un fichier spécifique du cache
  Future<void> removeFromCache(String url) async {
    try {
      final cacheFile = await getCachedFile(url);
      if (await cacheFile.exists()) {
        await cacheFile.delete();
        LoggingService.d('Fichier retiré du cache: $url');
      }
    } catch (e) {
      LoggingService.e('Erreur suppression cache', e);
    }
  }
}
