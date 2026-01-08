import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/librivox_book.dart';

class LibrivoxService {
  final http.Client _httpClient;
  final String _librivoxApiBaseUrl = 'https://librivox.org/api/feed/audiobooks'; // No trailing slash
  final String _archiveBaseUrl = 'https://archive.org'; // Keep this for getBookDetails

  LibrivoxService({required http.Client httpClient})
      : _httpClient = httpClient;


  /// Fetches recent books from the LibriVox API.
  Future<List<LibrivoxBook>> getRecentBooks() async {
    try {
      final url = Uri.parse('$_librivoxApiBaseUrl?format=json');
      final response = await _httpClient.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<LibrivoxBook> books = [];
        if (data != null && data['books'] is List) {
          for (final bookData in data['books']) {
            if (bookData['id'] != null) {
              books.add(LibrivoxBook.fromLibrivoxApiJson(bookData));
            }
          }
        }
        return books;
      } else {
        debugPrint('Failed to load recent books from LibriVox API. Status: ${response.statusCode}, Body: ${response.body}');
        print('Failed to load recent books from LibriVox API. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load recent books from LibriVox API');
      }
    } catch (e) {
      print('Error fetching recent books from LibriVox API: $e');
      rethrow;
    }
  }


  /// Searches for audiobooks on LibriVox using the LibriVox API.
  Future<List<LibrivoxBook>> searchBooks(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse('$_librivoxApiBaseUrl/search?title=$encodedQuery&format=json');
      
      final response = await _httpClient.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<LibrivoxBook> books = [];
        if (data != null && data['books'] is List) {
          for (final bookData in data['books']) {
            if (bookData['id'] != null) {
              books.add(LibrivoxBook.fromLibrivoxApiJson(bookData));
            }
          }
        }
        return books;
      } else {
        debugPrint('Failed to search books from LibriVox API. Status: ${response.statusCode}, Body: ${response.body}');
        print('Failed to search books from LibriVox API. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to search books from LibriVox API');
      }
    } catch (e) {
      print('Error searching LibriVox API: $e');
      rethrow;
    }
  }

  /// Fetches the details for a single audiobook from the archive.org API.
  Future<LibrivoxBook?> getBookDetails(String bookId) async {
    try {
      final url = Uri.parse('$_archiveBaseUrl/metadata/$bookId');
      print('[getBookDetails] Fetching details for bookId: $bookId from URL: $url');
      final response = await _httpClient.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final server = data['server'];
        final dir = data['dir'];
        final metadata = data['metadata'];

        final dynamic filesData = data['files'];
        List<Map<String, dynamic>> fileList = [];

        if (filesData is Map<String, dynamic>) {
          // If 'files' is a map, extract its values
          fileList = filesData.values.whereType<Map<String, dynamic>>().toList();
        } else if (filesData is List<dynamic>) {
          // If 'files' is a list, cast each element to Map<String, dynamic>
          fileList = filesData.whereType<Map<String, dynamic>>().toList();
        }

        if (server == null || dir == null || metadata == null) {
          print('[getBookDetails] Incomplete metadata for bookId: $bookId. Server: $server, Dir: $dir, Metadata: $metadata');
          return null;
        }

        // Make chapter finding more robust by trying multiple formats.
        var mp3Files = fileList.where((file) => file['format'] == '128Kbps MP3').toList();
        if (mp3Files.isEmpty) {
          mp3Files = fileList.where((file) => file['format'] == '64Kbps MP3').toList();
        }
        if (mp3Files.isEmpty) {
          mp3Files = fileList.where((file) => (file['format'] ?? '').toString().contains('MP3')).toList();
        }
        
        mp3Files.sort((a, b) => (a['track'] ?? '999').compareTo(b['track'] ?? '999'));

        final chapters = <LibrivoxChapter>[];
        for (var file in mp3Files) {
          chapters.add(LibrivoxChapter(
            title: file['title'] ?? 'Unknown Chapter',
            url: 'https://$server$dir/${file['name']}',
            trackNumber: int.tryParse(file['track']?.split('/').first ?? '0') ?? 0,
            duration: _parseDuration(file['length']),
          ));
        }

        final identifier = metadata['identifier'];
        return LibrivoxBook(
          id: identifier,
          title: metadata['title'] ?? 'Untitled',
          author: metadata['creator'] ?? 'Unknown Author',
          description: metadata['description']?.toString() ?? 'No description available.',
          language: metadata['language'] ?? 'Unknown',
          coverUrl: 'https://archive.org/services/get-item-image.php?identifier=$identifier',
          totalDuration: _parseDuration(metadata['runtime']),
          chapters: chapters,
        );
      } else {
        print('[getBookDetails] Failed to load book details for id: $bookId. Status: ${response.statusCode}, Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting book details from archive.org: $e');
      return null;
    }
  }

  /// Parses a duration string (e.g., "1:23:45", "23:45", "45.123") into a Duration object.
  Duration _parseDuration(String? durationString) {

    if (durationString == null || durationString.isEmpty) {
      return Duration.zero;
    }
    
    try {
      // Handle format "HH:MM:SS" or "MM:SS"
      if (durationString.contains(':')) {
        final parts = durationString.split(':');
        if (parts.length == 3) {
          return Duration(hours: int.parse(parts[0]), minutes: int.parse(parts[1]), seconds: double.parse(parts[2]).round());
        } else if (parts.length == 2) {
          return Duration(minutes: int.parse(parts[0]), seconds: double.parse(parts[1]).round());
        }
      }
      
      // Handle format "SS.ms" (seconds with milliseconds)
      final seconds = double.tryParse(durationString);
      if (seconds != null) {
        return Duration(milliseconds: (seconds * 1000).round());
      }
    } catch (e) {
      print('Error parsing duration string "$durationString": $e');
    }
    
    return Duration.zero;
  }
}

