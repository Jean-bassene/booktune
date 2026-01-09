import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';

import 'package:booktune/models/librivox_book.dart';
import 'package:booktune/services/librivox_service.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LibrivoxService librivoxService;
  late MockHttpClient mockHttpClient;

  setUp(() {
    mockHttpClient = MockHttpClient();
    librivoxService = LibrivoxService(httpClient: mockHttpClient);
  });

  group('LibrivoxService', () {
    group('getRecentBooks', () {
      test('returns a list of LibrivoxBook on successful API call', () async {
        final mockResponse = {
          "response": {
            "docs": [
              {
                "identifier": "test_id_1",
                "title": "Test Book 1",
                "creator": "Author 1",
              }
            ]
          }
        };
        when(mockHttpClient.get(any)).thenAnswer(
            (_) async => http.Response(json.encode(mockResponse), 200));

        final books = await librivoxService.getRecentBooks();

        expect(books, isA<List<LibrivoxBook>>());
        expect(books.length, 1);
        expect(books.first.id, 'test_id_1');
      });
    });

    group('searchBooks', () {
      test('returns a list of LibrivoxBook on successful search', () async {
        final mockResponse = {
          "response": {
            "docs": [
              {
                "identifier": "search_id_1",
                "title": "Searched Book",
                "creator": "Search Author",
              }
            ]
          }
        };
        when(mockHttpClient.get(any)).thenAnswer(
            (_) async => http.Response(json.encode(mockResponse), 200));

        final books = await librivoxService.searchBooks('test');

        expect(books, isA<List<LibrivoxBook>>());
        expect(books.length, 1);
        expect(books.first.id, 'search_id_1');
      });
    });

    group('getBookDetails', () {
      test('returns a complete book from archive.org metadata API', () async {
        final mockResponse = {
          "server": "ia800506.us.archive.org",
          "dir": "/1/items/moby_dick_librivox",
          "metadata": {
            "identifier": "moby_dick_librivox",
            "title": "Moby Dick",
            "creator": "Herman Melville",
            "description": "The great American novel.",
            "language": "eng",
            "runtime": "24:31:07"
          },
          "files": {
            "/mobydick_00_melville_128kb.mp3": {
              "format": "128Kbps MP3",
              "track": "00",
              "title": "Etymology and Extracts",
              "length": "1753.60"
            },
            "/mobydick_01_melville_128kb.mp3": {
              "format": "128Kbps MP3",
              "track": "01",
              "title": "Chapter 1",
              "length": "1436.67"
            },
            "/not_an_mp3.jpg": {"format": "JPEG"}
          }
        };

        when(mockHttpClient.get(any)).thenAnswer(
            (_) async => http.Response(json.encode(mockResponse), 200));

        final book = await librivoxService.getBookDetails('moby_dick_librivox');

        expect(book, isA<LibrivoxBook>());
        expect(book?.id, 'moby_dick_librivox');
        expect(book?.author, 'Herman Melville');
        expect(book?.chapters.length, 2);
        expect(book?.totalDuration,
            const Duration(hours: 24, minutes: 31, seconds: 7));

        expect(book?.chapters[0].title, 'Etymology and Extracts');
        expect(book?.chapters[0].trackNumber, 0);
        expect(book?.chapters[0].duration, const Duration(seconds: 1753));
        expect(book?.chapters[0].url,
            'https://ia800506.us.archive.org/1/items/moby_dick_librivox//mobydick_00_melville_128kb.mp3');
      });

      test('returns null when metadata API throws an exception', () async {
        when(mockHttpClient.get(any))
            .thenAnswer((_) async => http.Response('Error', 500));

        final book = await librivoxService.getBookDetails('any_id');

        expect(book, isNull);
      });
    });
  });
}
