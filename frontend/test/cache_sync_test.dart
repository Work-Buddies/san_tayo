import 'package:flutter_test/flutter_test.dart';
import 'package:san_tayo/core/cache/app_cache.dart';
import 'package:san_tayo/core/cache/cache_sync.dart';

void main() {
  final now      = DateTime(2026, 9, 19, 14, 30);
  final today    = DateTime(2026, 9, 19, 8);
  final yesterday = DateTime(2026, 9, 18, 22);

  group('should_skip_cache_update', () {
    test('skips when last_updated is today and the server max is yesterday', () {
      expect(should_skip_cache_update(today, yesterday, now), isTrue);
    });

    test('refreshes when last_updated is today and the server max is also today', () {
      expect(should_skip_cache_update(today, now, now), isFalse);
    });

    test('refreshes when last_updated is yesterday', () {
      expect(should_skip_cache_update(yesterday, yesterday, now), isFalse);
    });

    test('refreshes when the device has never synced', () {
      expect(should_skip_cache_update(null, yesterday, now), isFalse);
    });

    test('refreshes when the server has no stamps', () {
      expect(should_skip_cache_update(today, null, now), isFalse);
    });
  });

  group('stale_table_names', () {
    final stamps = {
      'landmark': DateTime(2026, 9, 19, 10),
      'barangay': DateTime(2026, 9, 17, 10),
    };

    test('returns every table when last_updated is missing', () {
      expect(stale_table_names(null, stamps), ['landmark', 'barangay']);
    });

    test('returns only tables newer than last_updated', () {
      expect(stale_table_names(DateTime(2026, 9, 18, 12), stamps), ['landmark']);
    });

    test('returns nothing when every stamp is older than last_updated', () {
      expect(stale_table_names(DateTime(2026, 9, 19, 12), stamps), isEmpty);
    });
  });

  group('resolve_selected_landmark', () {
    final ucn = {
      'id':   'ucn-1',
      'name': default_landmark_name,
    };
    final beach = {
      'id':   'beach-1',
      'name': 'Bagasbas Beach',
    };

    test('keeps a cached pick that is still in the list', () {
      expect(resolve_selected_landmark(beach, [ucn, beach])['id'], 'beach-1');
    });

    test('falls back to University of Camarines Norte when the pick is gone', () {
      expect(resolve_selected_landmark(beach, [ucn])['id'], 'ucn-1');
    });

    test('defaults to University of Camarines Norte with no cache', () {
      expect(resolve_selected_landmark(null, [ucn, beach])['id'], 'ucn-1');
    });
  });
}
