class AmbientMusic {
  final int? id;
  final String name;
  final String filePath;
  final int duration;
  final bool isLoop;
  final String category; // 'nature', 'music', 'custom'
  final DateTime dateImported;

  AmbientMusic({
    this.id,
    required this.name,
    required this.filePath,
    required this.duration,
    this.isLoop = true,
    this.category = 'custom',
    DateTime? dateImported,
  }) : dateImported = dateImported ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'filePath': filePath,
      'duration': duration,
      'isLoop': isLoop ? 1 : 0,
      'category': category,
      'dateImported': dateImported.millisecondsSinceEpoch,
    };
  }

  factory AmbientMusic.fromMap(Map<String, dynamic> map) {
    return AmbientMusic(
      id: map['id'],
      name: map['name'],
      filePath: map['filePath'],
      duration: map['duration'],
      isLoop: map['isLoop'] == 1,
      category: map['category'],
      dateImported: DateTime.fromMillisecondsSinceEpoch(map['dateImported']),
    );
  }
}
