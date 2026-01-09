import 'package:flutter_test/flutter_test.dart';
import 'package:booktune/services/cache_service.dart';

void main() {
  group('CacheService Tests', () {
    test('formatSize formats bytes correctly', () {
      expect(CacheService.formatSize(500), '500 B');
      expect(CacheService.formatSize(1024), '1.0 KB');
      expect(CacheService.formatSize(1536), '1.5 KB');
      expect(CacheService.formatSize(1024 * 1024), '1.0 MB');
      expect(CacheService.formatSize(1024 * 1024 * 2), '2.0 MB');
    });

    test('CacheService singleton pattern', () {
      final instance1 = CacheService();
      final instance2 = CacheService();

      expect(instance1, same(instance2));
    });
  });
}

final url = 'https://example.com/audio/test';
