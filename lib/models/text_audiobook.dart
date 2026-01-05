class TextAudiobook {
  final int? id;
  final String title;
  final String author;
  final String sourceType; // 'txt', 'epub', 'pdf', 'youtube'
  final String content; // Texte complet
  final int totalCharacters;
  final int lastPosition; // Position en caractères
  final DateTime dateImported;
  final String? youtubeUrl;
  final double duration; // Durée estimée en secondes

  TextAudiobook({
    this.id,
    required this.title,
    required this.author,
    required this.sourceType,
    required this.content,
    required this.totalCharacters,
    this.lastPosition = 0,
    required this.dateImported,
    this.youtubeUrl,
    this.duration = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'sourceType': sourceType,
      'content': content,
      'totalCharacters': totalCharacters,
      'lastPosition': lastPosition,
      'dateImported': dateImported.toIso8601String(),
      'youtubeUrl': youtubeUrl,
      'duration': duration,
    };
  }

  static TextAudiobook fromMap(Map<String, dynamic> map) {
    return TextAudiobook(
      id: map['id'],
      title: map['title'],
      author: map['author'],
      sourceType: map['sourceType'],
      content: map['content'],
      totalCharacters: map['totalCharacters'],
      lastPosition: map['lastPosition'] ?? 0,
      dateImported: DateTime.parse(map['dateImported']),
      youtubeUrl: map['youtubeUrl'],
      duration: (map['duration'] ?? 0).toDouble(),
    );
  }

  TextAudiobook copyWith({
    int? id,
    String? title,
    String? author,
    String? sourceType,
    String? content,
    int? totalCharacters,
    int? lastPosition,
    DateTime? dateImported,
    String? youtubeUrl,
    double? duration,
  }) {
    return TextAudiobook(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      sourceType: sourceType ?? this.sourceType,
      content: content ?? this.content,
      totalCharacters: totalCharacters ?? this.totalCharacters,
      lastPosition: lastPosition ?? this.lastPosition,
      dateImported: dateImported ?? this.dateImported,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      duration: duration ?? this.duration,
    );
  }
}
