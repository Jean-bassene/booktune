import 'librivox_book.dart';

/// Modèle pour les livres LibriVox téléchargés localement
class DownloadedBook {
  final String id;
  final String title;
  final String author;
  final String description;
  final String language;
  final int totalTimeSeconds;
  final String? coverUrl;
  final DateTime downloadDate;
  final String localCoverPath;
  final List<DownloadedChapter> chapters;
  final int totalSizeBytes;
  final String genre;

  DownloadedBook({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.language,
    required this.totalTimeSeconds,
    required this.coverUrl,
    required this.downloadDate,
    required this.localCoverPath,
    required this.chapters,
    required this.totalSizeBytes,
    required this.genre,
  });

  /// Crée un DownloadedBook depuis un LibrivoxBook
  factory DownloadedBook.fromLibrivoxBook(
    LibrivoxBook book,
    String localCoverPath,
    List<DownloadedChapter> downloadedChapters,
  ) {
    return DownloadedBook(
      id: book.id,
      title: book.title,
      author: book.author,
      description: book.description,
      language: book.language ?? 'Unknown',
      totalTimeSeconds: book.totalDuration?.inSeconds ?? 0,
      coverUrl: book.coverUrl,
      downloadDate: DateTime.now(),
      localCoverPath: localCoverPath,
      chapters: downloadedChapters,
      totalSizeBytes: downloadedChapters.fold(
          0, (sum, chapter) => sum + chapter.fileSizeBytes),
      genre: 'Audiobook', // Genre par défaut
    );
  }

  /// Convertit en Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'language': language,
      'totalTimeSeconds': totalTimeSeconds,
      'coverUrl': coverUrl,
      'downloadDate': downloadDate.toIso8601String(),
      'localCoverPath': localCoverPath,
      'totalSizeBytes': totalSizeBytes,
      'genre': genre,
      'chaptersCount': chapters.length,
    };
  }

  /// Crée depuis un Map de base de données
  factory DownloadedBook.fromMap(
      Map<String, dynamic> map, List<DownloadedChapter> chapters) {
    return DownloadedBook(
      id: map['id'],
      title: map['title'],
      author: map['author'],
      description: map['description'],
      language: map['language'],
      totalTimeSeconds: map['totalTimeSeconds'],
      coverUrl: map['coverUrl'],
      downloadDate: DateTime.parse(map['downloadDate']),
      localCoverPath: map['localCoverPath'],
      chapters: chapters,
      totalSizeBytes: map['totalSizeBytes'],
      genre: map['genre'],
    );
  }

  /// Calcule la progression d'écoute (0.0 à 1.0)
  double get listeningProgress {
    if (chapters.isEmpty || totalTimeSeconds <= 0) return 0.0;

    int totalListenedSeconds = 0;
    for (final chapter in chapters) {
      totalListenedSeconds += chapter.listenedSeconds;
    }

    // Éviter division par zéro et valeurs infinies
    final progress = totalListenedSeconds / totalTimeSeconds;
    return progress.isFinite ? progress.clamp(0.0, 1.0) : 0.0;
  }

  /// Vérifie si le livre est terminé
  bool get isCompleted =>
      listeningProgress >= 0.95; // 95% considéré comme terminé

  /// Formatte la taille totale en texte lisible
  String get formattedSize {
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = totalSizeBytes.toDouble();
    int unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  /// Formatte la durée totale
  String get formattedDuration {
    final hours = totalTimeSeconds ~/ 3600;
    final minutes = (totalTimeSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Crée une copie avec des modifications
  DownloadedBook copyWith({
    String? title,
    String? author,
    String? description,
    String? language,
    List<DownloadedChapter>? chapters,
  }) {
    return DownloadedBook(
      id: id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      language: language ?? this.language,
      totalTimeSeconds: totalTimeSeconds,
      coverUrl: coverUrl,
      downloadDate: downloadDate,
      localCoverPath: localCoverPath,
      chapters: chapters ?? this.chapters,
      totalSizeBytes: chapters != null
          ? chapters.fold(0, (sum, chapter) => sum + chapter.fileSizeBytes)
          : totalSizeBytes,
      genre: genre,
    );
  }
}

/// Modèle pour les chapitres téléchargés
class DownloadedChapter {
  final String id;
  final String title;
  final Duration duration;
  final String localFilePath;
  final int fileSizeBytes;
  final int listenedSeconds; // Progression d'écoute en secondes
  final DateTime downloadDate;

  DownloadedChapter({
    required this.id,
    required this.title,
    required this.duration,
    required this.localFilePath,
    required this.fileSizeBytes,
    this.listenedSeconds = 0,
    DateTime? downloadDate,
  }) : downloadDate = downloadDate ?? DateTime.now();

  /// Crée depuis un LibrivoxChapter
  factory DownloadedChapter.fromLibrivoxChapter(
    LibrivoxChapter chapter,
    String localFilePath,
    int fileSizeBytes,
  ) {
    // Créer un ID unique basé sur l'URL et le numéro de piste
    final id = '${chapter.url.hashCode}_${chapter.trackNumber}';
    return DownloadedChapter(
      id: id,
      title: chapter.title,
      duration: chapter.duration,
      localFilePath: localFilePath,
      fileSizeBytes: fileSizeBytes,
    );
  }

  /// Convertit en Map pour la base de données
  Map<String, dynamic> toMap(String bookId) {
    return {
      'id': id,
      'bookId': bookId,
      'title': title,
      'durationSeconds': duration.inSeconds,
      'localFilePath': localFilePath,
      'fileSizeBytes': fileSizeBytes,
      'listenedSeconds': listenedSeconds,
      'downloadDate': downloadDate.toIso8601String(),
    };
  }

  /// Crée depuis un Map de base de données
  factory DownloadedChapter.fromMap(Map<String, dynamic> map) {
    return DownloadedChapter(
      id: map['id'],
      title: map['title'],
      duration: Duration(seconds: map['durationSeconds']),
      localFilePath: map['localFilePath'],
      fileSizeBytes: map['fileSizeBytes'],
      listenedSeconds: map['listenedSeconds'],
      downloadDate: DateTime.parse(map['downloadDate']),
    );
  }

  /// Met à jour la progression d'écoute
  DownloadedChapter updateProgress(int newListenedSeconds) {
    return DownloadedChapter(
      id: id,
      title: title,
      duration: duration,
      localFilePath: localFilePath,
      fileSizeBytes: fileSizeBytes,
      listenedSeconds: newListenedSeconds,
      downloadDate: downloadDate,
    );
  }

  /// Vérifie si le chapitre est terminé
  bool get isCompleted => listenedSeconds >= (duration.inSeconds * 0.95);
}

/// État de téléchargement
enum DownloadStatus {
  notStarted,
  downloading,
  paused,
  completed,
  failed,
}

/// Représente un téléchargement en cours
class DownloadProgress {
  final String bookId;
  final String chapterId;
  final DownloadStatus status;
  final double progress; // 0.0 à 1.0
  final int downloadedBytes;
  final int totalBytes;
  final String? errorMessage;

  DownloadProgress({
    required this.bookId,
    required this.chapterId,
    required this.status,
    required this.progress,
    required this.downloadedBytes,
    required this.totalBytes,
    this.errorMessage,
  });

  DownloadProgress copyWith({
    DownloadStatus? status,
    double? progress,
    int? downloadedBytes,
    int? totalBytes,
    String? errorMessage,
  }) {
    return DownloadProgress(
      bookId: bookId,
      chapterId: chapterId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
