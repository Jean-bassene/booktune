import '../services/logging_service.dart';

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
      description:
          json['description']?.toString() ?? 'No description available.',
      language: json['language']?.toString() ?? 'Unknown',
      coverUrl:
          'https://archive.org/services/get-item-image.php?identifier=${json['identifier']}',
    );
  }

  /// Factory constructor for parsing book data from LibriVox API search results
  factory LibrivoxBook.fromLibrivoxApiJson(Map<String, dynamic> json) {
    // Amélioration extraction auteurs
    String author = _extractAuthorFromJson(json);

    String librivoxId = json['id']?.toString() ?? '';
    String archiveOrgIdentifier = librivoxId;

    // Try to extract archive.org identifier from url_iarchive
    final String? urlIArchive = json['url_iarchive'];
    if (urlIArchive != null && urlIArchive.isNotEmpty) {
      final uri = Uri.tryParse(urlIArchive);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        archiveOrgIdentifier = uri.pathSegments.last;
      }
    }

    // Extraire la langue depuis le champ 'language' de l'API
    String language = _extractLanguageFromJson(json);

    // Calculer la durée totale si disponible
    Duration? totalDuration = _extractTotalDurationFromJson(json);

    return LibrivoxBook(
      id: archiveOrgIdentifier,
      title: json['title'] ?? 'Untitled',
      author: author,
      description: _extractDescriptionFromJson(json),
      language: language,
      totalDuration: totalDuration,
      librivoxUrl: json['url_librivox'],
    );
  }

  /// Extrait le nom de l'auteur depuis les données JSON de l'API
  static String _extractAuthorFromJson(Map<String, dynamic> json) {
    // Debug: afficher la structure complète des données auteur
    final authorFields = [
      'authors',
      'author',
      'creator',
      'author_name',
      'author_display_name',
      'contributor',
      'dc_creator',
      'dcterms_creator'
    ].where((field) => json.containsKey(field)).toList();

    if (authorFields.isNotEmpty) {
      LoggingService.d('Champs auteur trouvés: $authorFields');
      for (final field in authorFields) {
        LoggingService.d(
            '  $field: ${json[field]} (type: ${json[field]?.runtimeType})');
      }
    } else {
      LoggingService.d('Aucun champ auteur trouvé dans JSON');
    }

    // Essayer différents formats d'auteur dans l'API LibriVox

    // Format 1: Liste d'auteurs avec first_name/last_name
    if (json['authors'] != null && json['authors'] is List) {
      LoggingService.d('Traitement format 1: liste authors');
      final List<dynamic> authorsList = json['authors'];
      LoggingService.d(
          'Nombre d\'auteurs dans la liste: ${authorsList.length}');

      final authorNames = authorsList
          .map((a) {
            LoggingService.d(
                '  Traitement auteur: $a (type: ${a.runtimeType})');
            if (a is Map<String, dynamic>) {
              final firstName = a['first_name'] ?? '';
              final lastName = a['last_name'] ?? '';
              final displayName = a['display_name'] ?? '';
              final gutenbergAgentName = a['gutenberg_agent_name'] ?? '';

              LoggingService.d(
                  '    first_name: "$firstName", last_name: "$lastName", display_name: "$displayName"');

              // Essayer display_name en premier, puis construire depuis first/last
              if (displayName.isNotEmpty) {
                LoggingService.d(
                    '    Utilisation display_name: "$displayName"');
                return displayName.trim();
              } else if (firstName.isNotEmpty || lastName.isNotEmpty) {
                final constructed = '$firstName $lastName'.trim();
                LoggingService.d(
                    '    Construction depuis first/last: "$constructed"');
                return constructed;
              } else if (gutenbergAgentName.isNotEmpty) {
                LoggingService.d(
                    '    Utilisation gutenberg_agent_name: "$gutenbergAgentName"');
                return gutenbergAgentName.trim();
              }
            } else if (a is String) {
              LoggingService.d('    Auteur sous forme string: "$a"');
              return a.trim();
            }
            LoggingService.d('    Aucun nom extrait pour cet auteur');
            return '';
          })
          .where((name) => name.isNotEmpty)
          .toList();

      LoggingService.d('Noms d\'auteurs extraits: $authorNames');
      if (authorNames.isNotEmpty) {
        final result = authorNames.join(', ');
        LoggingService.d('Résultat format 1: "$result"');
        return result;
      }
    }

    // Format 2: Auteur simple (ancien format)
    if (json['author'] != null && json['author'] is String) {
      LoggingService.d('Traitement format 2: auteur simple');
      final authorStr = json['author'].toString().trim();
      LoggingService.d('Auteur simple trouvé: "$authorStr"');
      if (authorStr.isNotEmpty && authorStr != 'null') {
        LoggingService.d('Résultat format 2: "$authorStr"');
        return authorStr;
      }
    }

    // Format 3: Creator (format archive.org)
    if (json['creator'] != null) {
      LoggingService.d('Traitement format 3: creator');
      if (json['creator'] is List) {
        final creators = (json['creator'] as List).join(', ');
        LoggingService.d('Creators (liste): "$creators"');
        return creators;
      } else if (json['creator'] is String) {
        final creator = json['creator'].toString().trim();
        LoggingService.d('Creator (string): "$creator"');
        if (creator.isNotEmpty && creator != 'null') {
          LoggingService.d('Résultat format 3: "$creator"');
          return creator;
        }
      }
    }

    // Format 4: Chercher dans d'autres champs
    final possibleAuthorFields = [
      'author_name',
      'author_display_name',
      'contributor',
      'dc_creator',
      'dcterms_creator'
    ];

    for (final field in possibleAuthorFields) {
      if (json[field] != null) {
        LoggingService.d('Traitement format 4: champ "$field"');
        if (json[field] is List) {
          final authors = (json[field] as List)
              .where((a) => a != null)
              .map((a) => a.toString())
              .toList();
          LoggingService.d('Champ "$field" (liste): $authors');
          if (authors.isNotEmpty) {
            final result = authors.join(', ');
            LoggingService.d('Résultat format 4: "$result"');
            return result;
          }
        } else {
          final authorStr = json[field].toString().trim();
          LoggingService.d('Champ "$field" (string): "$authorStr"');
          if (authorStr.isNotEmpty && authorStr != 'null') {
            LoggingService.d('Résultat format 4: "$authorStr"');
            return authorStr;
          }
        }
      }
    }

    LoggingService.d('Aucun auteur trouvé, retour "Auteur inconnu"');
    return 'Auteur inconnu';
  }

  /// Extrait la langue depuis les données JSON
  static String _extractLanguageFromJson(Map<String, dynamic> json) {
    if (json['language'] != null) {
      final lang = json['language'].toString().trim();
      if (lang.isNotEmpty && lang != 'null') {
        // Convertir les codes de langue en noms lisibles
        switch (lang.toLowerCase()) {
          case 'en':
          case 'english':
            return 'Anglais';
          case 'fr':
          case 'french':
            return 'Français';
          case 'es':
          case 'spanish':
            return 'Espagnol';
          case 'de':
          case 'german':
            return 'Allemand';
          case 'it':
          case 'italian':
            return 'Italien';
          case 'pt':
          case 'portuguese':
            return 'Portugais';
          case 'ru':
          case 'russian':
            return 'Russe';
          case 'zh':
          case 'chinese':
            return 'Chinois';
          case 'ja':
          case 'japanese':
            return 'Japonais';
          default:
            return lang;
        }
      }
    }

    // Essayer d'autres champs de langue
    final possibleLangFields = ['language_code', 'lang', 'dcterms_language'];
    for (final field in possibleLangFields) {
      if (json[field] != null) {
        final lang = json[field].toString().trim();
        if (lang.isNotEmpty && lang != 'null') {
          return lang;
        }
      }
    }

    return 'Langue inconnue';
  }

  /// Extrait la durée totale depuis les données JSON
  static Duration? _extractTotalDurationFromJson(Map<String, dynamic> json) {
    // Chercher dans différents champs possibles
    final possibleDurationFields = [
      'total_duration',
      'duration',
      'total_time',
      'totaltime',
      'runtime',
      'length',
      'total_time_secs',
      'duration_seconds',
      'playtime',
      'time'
    ];

    // Debug: afficher tous les champs liés à la durée disponibles
    final durationFields = possibleDurationFields
        .where((field) => json.containsKey(field))
        .toList();
    if (durationFields.isNotEmpty) {
      LoggingService.d('Champs durée trouvés: $durationFields');
      for (final field in durationFields) {
        LoggingService.d('  $field: ${json[field]}');
      }
    } else {
      LoggingService.d('Aucun champ durée trouvé dans JSON');
    }

    for (final field in possibleDurationFields) {
      if (json[field] != null) {
        try {
          final durationStr = json[field].toString().trim();
          if (durationStr.isNotEmpty && durationStr != 'null') {
            LoggingService.d(
                'Tentative parsing durée "$field": "$durationStr"');
            // Essayer de parser comme durée (HH:MM:SS ou secondes)
            final parsed = _parseDurationString(durationStr);
            if (parsed != Duration.zero) {
              LoggingService.d('Durée parsée avec succès: $parsed');
              return parsed;
            }
          }
        } catch (e) {
          LoggingService.e('Erreur parsing champ durée $field', e);
          continue;
        }
      }
    }

    LoggingService.d('Aucune durée valide trouvée');
    return null;
  }

  /// Extrait la description depuis les données JSON
  static String _extractDescriptionFromJson(Map<String, dynamic> json) {
    final possibleDescFields = [
      'description',
      'summary',
      'synopsis',
      'about',
      'dcterms_description'
    ];

    for (final field in possibleDescFields) {
      if (json[field] != null) {
        final desc = json[field].toString().trim();
        if (desc.isNotEmpty && desc != 'null') {
          // Nettoyer les balises HTML si présentes
          return desc.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        }
      }
    }

    return 'Aucune description disponible.';
  }

  /// Parse une chaîne de durée en Duration
  static Duration _parseDurationString(String durationStr) {
    try {
      // Format HH:MM:SS
      if (durationStr.contains(':')) {
        final parts = durationStr.split(':');
        if (parts.length == 3) {
          return Duration(
            hours: int.parse(parts[0]),
            minutes: int.parse(parts[1]),
            seconds: int.parse(parts[2]),
          );
        } else if (parts.length == 2) {
          return Duration(
            minutes: int.parse(parts[0]),
            seconds: int.parse(parts[1]),
          );
        }
      }

      // Format en secondes (nombre décimal ou entier)
      final seconds = double.tryParse(durationStr);
      if (seconds != null) {
        return Duration(milliseconds: (seconds * 1000).round());
      }
    } catch (e) {
      // Ignorer les erreurs de parsing
    }

    return Duration.zero;
  }

  /// Formate la durée totale en texte lisible
  String get formattedTotalDuration {
    if (totalDuration == null) return '';

    final hours = totalDuration!.inHours;
    final minutes = totalDuration!.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h${minutes > 0 ? '$minutes' : ''}';
    } else {
      return '${minutes}min';
    }
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
