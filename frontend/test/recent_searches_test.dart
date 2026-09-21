import 'package:flutter_test/flutter_test.dart';
import 'package:san_tayo/core/cache/app_cache.dart';

void main() {
  group('merge_recent_search', () {
    test('ignores blank queries', () {
      expect(merge_recent_search(['Chicken'], '   '), ['Chicken']);
    });

    test('puts a new query first and drops the case-insensitive duplicate', () {
      expect(
        merge_recent_search(['Chicken', 'Isaw'], 'chicken'),
        ['chicken', 'Isaw'],
      );
    });

    test('caps the list at the recent search limit', () {
      final current = List<String>.generate(recent_search_limit, (i) => 'q$i');
      final merged  = merge_recent_search(current, 'lugaw');

      expect(merged.first, 'lugaw');
      expect(merged.length, recent_search_limit);
      expect(merged, isNot(contains('q${recent_search_limit - 1}')));
    });
  });
}
