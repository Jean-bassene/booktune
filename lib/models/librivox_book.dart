class LibrivoxBook {
  final String id;
  final String title;
  final String author;
  final String description;
  final String? coverUrl;
  final String? language;
  final Duration? totalDuration;
  final List<LibrivoxChapter> chapters;
  final String? librivoxUrl;

  LibrivoxBook({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    this.coverUrl,
    this.language,
    this.totalDuration,
    this.chapters = const [],
    this.librivoxUrl,
  });

  /// Constructor for parsing search results from archive.org API
  factory LibrivoxBook.fromArchiveOrgJson(Map<String, dynamic> json) {
    String author = 'Unknown Author';
    if (json['creator'] != null) {
      if (json['creator'] is List) {
        author = (json['creator'] as List).join(', ');
      } else {
        author = json['creator'];
      }
    }

    return LibrivoxBook(
      id: json['identifier'],
      title: json['title'] ?? 'Untitled',
      author: author,
      description: json['description']?.toString() ?? 'No description available.',
      language: json['language']?.toString() ?? 'Unknown',
      coverUrl: 'https://archive.org/services/get-item-image.php?identifier=${json['identifier']}',
    );
  }

  /// Factory constructor for parsing book data from LibriVox API search results
  factory LibrivoxBook.fromLibrivoxApiJson(Map<String, dynamic> json) {
    String author = 'Unknown Author';
    if (json['authors'] != null && json['authors'] is List) {
      final List<dynamic> authorsList = json['authors'];
      author = authorsList.map((a) {
        final firstName = a['first_name'] ?? '';
        final lastName = a['last_name'] ?? '';
        return '$firstName $lastName'.trim();
      }).where((name) => name.isNotEmpty).join(', ');
      if (author.isEmpty) {
        author = 'Unknown Author';
      }
    }

    String librivoxId = json['id']?.toString() ?? '';
    String archiveOrgIdentifier = librivoxId; // Default to librivoxId

    // Try to extract archive.org identifier from url_iarchive
    final String? urlIArchive = json['url_iarchive'];
    if (urlIArchive != null && urlIArchive.isNotEmpty) {
      // Example: https://archive.org/details/some_identifier
      final uri = Uri.tryParse(urlIArchive);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        archiveOrgIdentifier = uri.pathSegments.last;
      }
    }

    return LibrivoxBook(
      id: archiveOrgIdentifier, // Use archive.org identifier here
      title: json['title'] ?? 'Untitled',
      author: author,
      description: json['description']?.toString() ?? 'No description available.',
      language: null, // Language not available from LibriVox API search results directly
      librivoxUrl: json['url_librivox'],
      // coverUrl, language, totalDuration, chapters will be null and filled by archive.org details
    );
  }
}

class LibrivoxChapter {
  final String title;
  final String url;
  final int trackNumber;
  final Duration duration;

  LibrivoxChapter({
    required this.title,
    required this.url,
    required this.trackNumber,
    required this.duration,
  });
}
