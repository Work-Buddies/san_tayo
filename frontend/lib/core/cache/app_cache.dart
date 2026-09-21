import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Seed landmark shown until the user picks another, and again if their pick disappears.
const String default_landmark_name = 'University of Camarines Norte';

const String _key_last_updated       = 'last_updated';
const String _key_selected_landmark  = 'selected_landmark';
const String _key_recent_searches    = 'recent_searches';
const String _key_table_prefix       = 'cache_table_';
const int    recent_search_limit     = 10;

const FlutterSecureStorage _storage = FlutterSecureStorage();

/// When the device last completed a cache sync. Compared against last_table_updates.
Future<DateTime?> get_cache_last_updated() async {
  final raw = await _storage.read(key: _key_last_updated);
  if (raw == null || raw.isEmpty) {
    return null;
  }

  return DateTime.tryParse(raw);
}

Future<void> set_cache_last_updated(DateTime value) async {
  await _storage.write(key: _key_last_updated, value: value.toIso8601String());
}

Future<List<Map<String, dynamic>>> get_cached_table(String table_name) async {
  final raw = await _storage.read(key: '$_key_table_prefix$table_name');
  if (raw == null || raw.isEmpty) {
    return [];
  }

  final decoded = jsonDecode(raw);
  if (decoded is! List) {
    return [];
  }

  return decoded
      .whereType<Map>()
      .map((row) => Map<String, dynamic>.from(row))
      .toList();
}

Future<void> save_cached_table(String table_name, List<Map<String, dynamic>> rows) async {
  await _storage.write(key: '$_key_table_prefix$table_name', value: jsonEncode(rows));
}

Future<Map<String, dynamic>?> get_selected_landmark() async {
  final raw = await _storage.read(key: _key_selected_landmark);
  if (raw == null || raw.isEmpty) {
    return null;
  }

  final decoded = jsonDecode(raw);
  if (decoded is! Map) {
    return null;
  }

  return Map<String, dynamic>.from(decoded);
}

Future<void> save_selected_landmark(Map<String, dynamic> landmark) async {
  await _storage.write(key: _key_selected_landmark, value: jsonEncode(landmark));
}

/// Cached pick if it still exists in [landmarks], otherwise University of Camarines Norte.
Map<String, dynamic> resolve_selected_landmark(
  Map<String, dynamic>? cached,
  List<Map<String, dynamic>> landmarks,
) {
  if (cached != null && cached['id'] != null) {
    for (final landmark in landmarks) {
      if (landmark['id']?.toString() == cached['id'].toString()) {
        return landmark;
      }
    }
  }

  for (final landmark in landmarks) {
    if (landmark['name']?.toString().toLowerCase() == default_landmark_name.toLowerCase()) {
      return landmark;
    }
  }

  return cached ?? {'name': default_landmark_name};
}

/// Newest first, case-insensitive dedupe, capped at [max].
List<String> merge_recent_search(
  List<String> current,
  String query, {
  int max = recent_search_limit,
}) {
  final q = query.trim();
  if (q.isEmpty) {
    return current;
  }

  final next = <String>[q];
  for (final item in current) {
    if (item.toLowerCase() != q.toLowerCase()) {
      next.add(item);
    }
  }

  if (next.length > max) {
    return next.sublist(0, max);
  }

  return next;
}

Future<List<String>> get_recent_searches() async {
  final raw = await _storage.read(key: _key_recent_searches);
  if (raw == null || raw.isEmpty) {
    return [];
  }

  final decoded = jsonDecode(raw);
  if (decoded is! List) {
    return [];
  }

  return decoded
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

Future<void> save_recent_search(String query) async {
  final merged = merge_recent_search(await get_recent_searches(), query);
  await _storage.write(key: _key_recent_searches, value: jsonEncode(merged));
}

Future<void> clear_recent_searches() async {
  await _storage.delete(key: _key_recent_searches);
}
