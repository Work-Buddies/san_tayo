import 'package:flutter_test/flutter_test.dart';
import 'package:san_tayo/core/mobile/search_query.dart';

void main() {
  final listings = [
    {
      'id': '1',
      'name': 'Everything Chicken',
      'description': 'Adobo and fried chicken skin.',
      'nearestLandmark': 'University of Camarines Norte',
      'minPrice': 45,
      'food_types': [
        {'name': 'Fried Food'},
        {'name': 'Soup'},
      ],
      'menu': [
        {'item': 'Chicken Adobo'},
      ],
    },
    {
      'id': '2',
      'name': 'Halo-Halo Haven',
      'description': 'Dessert stall.',
      'nearestLandmark': 'Bagasbas Beach',
      'minPrice': 80,
      'food_types': [
        {'name': 'Dessert'},
      ],
      'menu': [
        {'item': 'Halo-Halo'},
      ],
    },
  ];

  test('keeps a listing that matches query, landmark, food type, and budget', () {
    final matches = filter_listings(
      listings,
      const SearchQuery(
        text: 'chicken',
        landmark_name: 'University of Camarines Norte',
        food_types: ['Fried food'],
        max_price: 50,
      ),
    );

    expect(matches.map((row) => row['id']), ['1']);
  });

  test('drops a listing outside the budget or landmark', () {
    final matches = filter_listings(
      listings,
      const SearchQuery(
        landmark_name: 'Bagasbas Beach',
        min_price: 50,
        max_price: 100,
      ),
    );

    expect(matches.map((row) => row['id']), ['2']);
  });

  test('parse_budget_range prefers the custom from–to over a chip', () {
    final range = parse_budget_range('₱100–₱200', '30', '60');
    expect(range.min, 30);
    expect(range.max, 60);
  });

  test('matches listings that have any of the selected food types', () {
    final matches = filter_listings(
      listings,
      const SearchQuery(
        food_types: ['Soup', 'Dessert'],
      ),
    );

    expect(matches.map((row) => row['id']), ['1', '2']);
  });

   test('a cleared landmark keeps places from anywhere', () {
    final matches = filter_listings(
      listings,
      const SearchQuery(),
    );

    expect(matches.map((row) => row['id']), ['1', '2']);
  });

  test('magkano matches any menu price, not only the lowest', () {
    final matches = filter_listings(
      [
        {
          'id': '3',
          'name': 'Mixed Menu',
          'nearestLandmark': 'University of Camarines Norte',
          'minPrice': 45,
          'menu': [
            {'item': 'Goto', 'price': '45.00'},
            {'item': 'Lechon Kawali', 'price': '175.00'},
          ],
        },
      ],
      const SearchQuery(min_price: 100, max_price: 200),
    );

    expect(matches.map((row) => row['id']), ['3']);
  });

  test('ilan keeps a listing whose pax tag covers the party size', () {
    final matches = filter_listings(
      [
        {
          'id': '4',
          'name': 'Small Table',
          'nearestLandmark': 'Plaza',
          'minPrice': 50,
          'food_types': [
            {'name': 'Soup', 'type': 'foodtype'},
            {'name': '2 pax', 'type': 'pax'},
          ],
        },
        {
          'id': '5',
          'name': 'Barkada Hall',
          'nearestLandmark': 'Plaza',
          'minPrice': 80,
          'food_types': [
            {'name': '5+ pax', 'type': 'pax'},
          ],
        },
      ],
      const SearchQuery(party_size: 6),
    );

    expect(matches.map((row) => row['id']), ['5']);
  });

  test('budget_fields_from_range restores a chip and a custom range', () {
    final chip = budget_fields_from_range(null, 50);
    expect(chip.preset, 'Under ₱50');
    expect(chip.from, '');

    final custom = budget_fields_from_range(30, 60);
    expect(custom.preset, isNull);
    expect(custom.from, '30');
    expect(custom.to, '60');
  });
}
