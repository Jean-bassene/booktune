class Audiobook {
  final int? id;
  final String title;
  final String author;
  final String filePath;
  final int? duration; // en secondes
  final String? coverArtPath;
  final int lastPosition; // en secondes
  final DateTime dateImported;
  final int? fileSize;
  final bool isFavorite;
  final bool isNetwork;

  Audiobook({
    this.id,
    required this.title,
    required this.author,
    required this.filePath,
    this.duration,
    this.coverArtPath,
    this.lastPosition = 0,
    DateTime? dateImported,
    this.fileSize,
    this.isFavorite = false,
    this.isNetwork = false,
  }) : dateImported = dateImported ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'filePath': filePath,
      'duration': duration,
      'coverArtPath': coverArtPath,
      'lastPosition': lastPosition,
      'dateImported': dateImported.millisecondsSinceEpoch,
      'fileSize': fileSize,
      'isFavorite': isFavorite ? 1 : 0,
      'isNetwork': isNetwork ? 1 : 0,
    };
  }

  factory Audiobook.fromMap(Map<String, dynamic> map) {
    // VALIDER ET CORRIGER LES DONNÉES CORROMPUES
    final rawDuration = map['duration'];
    final rawLastPosition = map['lastPosition'] ?? 0;

    // Valider et corriger duration
    final duration =
        (rawDuration is int && rawDuration > 0) ? rawDuration : null;

    // Valider et corriger lastPosition
    final lastPosition = (rawLastPosition is int && rawLastPosition >= 0)
        ? (duration != null && rawLastPosition > duration ? 0 : rawLastPosition)
        : 0;

    return Audiobook(
      id: map['id'],
      title: map['title'] ?? 'Titre inconnu',
      author: map['author'] ?? 'Auteur inconnu',
      filePath: map['filePath'] ?? '',
      duration: duration,
      coverArtPath: map['coverArtPath'],
      lastPosition: lastPosition,
      dateImported: map['dateImported'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dateImported'])
          : DateTime.now(),
      fileSize: map['fileSize'],
      isFavorite: (map['isFavorite'] ?? 0) == 1,
      isNetwork: (map['isNetwork'] ?? 0) == 1,
    );
  }

  Audiobook copyWith({
    int? id,
    String? title,
    String? author,
    String? filePath,
    int? duration,
    String? coverArtPath,
    int? lastPosition,
    DateTime? dateImported,
    int? fileSize,
    bool? isFavorite,
    bool? isNetwork,
  }) {
    return Audiobook(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
      coverArtPath: coverArtPath ?? this.coverArtPath,
      lastPosition: lastPosition ?? this.lastPosition,
      dateImported: dateImported ?? this.dateImported,
      fileSize: fileSize ?? this.fileSize,
      isFavorite: isFavorite ?? this.isFavorite,
      isNetwork: isNetwork ?? this.isNetwork,
    );
  }
}
