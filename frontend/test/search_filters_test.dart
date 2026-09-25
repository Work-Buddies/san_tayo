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
}
