import '../config/api_endpoints.dart';
import '../models/api_response.dart';
import '../network/api_client.dart';
import 'app_cache.dart';

/// Skip a network refresh when the device already synced today and the
/// newest last_table_updates stamp is still yesterday (or older).
bool should_skip_cache_update(DateTime? last_updated, DateTime? server_max, DateTime now) {
  if (last_updated == null || server_max == null) {
    return false;
  }

  final today    = DateTime(now.year, now.month, now.day);
  final last_day = DateTime(last_updated.year, last_updated.month, last_updated.day);
  final max_day  = DateTime(server_max.year, server_max.month, server_max.day);

  if (last_day != today) {
    return false;
  }

  return max_day.isBefore(today);
}

/// Tables whose last_update is newer than the device stamp. A null stamp means every table.
List<String> stale_table_names(DateTime? last_updated, Map<String, DateTime> table_updates) {
  if (last_updated == null) {
    return table_updates.keys.toList();
  }

  return table_updates.entries
      .where((entry) => entry.value.isAfter(last_updated))
      .map((entry) => entry.key)
      .toList();
}

/// Pull last_table_updates, then refresh only the tables this app knows how to fetch.
Future<void> sync_app_cache() async {
  final last_updated = await get_cache_last_updated();
  final stamp_res    = await api_request('GET', ApiEndpoints.last_table_updates);

  if (stamp_res.code != 1) {
    return;
  }

  final table_updates = _parse_table_updates(stamp_res);
  DateTime? server_max;
  for (final stamp in table_updates.values) {
    if (server_max == null || stamp.isAfter(server_max)) {
      server_max = stamp;
    }
  }

  final now = DateTime.now();
  if (should_skip_cache_update(last_updated, server_max, now)) {
    return;
  }

  final fetchers = <String, Future<bool> Function()>{
    'landmark': _fetch_and_cache_landmarks,
  };

  final wanted = last_updated == null
      ? fetchers.keys
      : stale_table_names(last_updated, table_updates).where(fetchers.containsKey);

  var all_ok = true;
  var ran    = false;
  for (final table in wanted) {
    ran    = true;
    all_ok = await fetchers[table]!() && all_ok;
  }

  if (ran && all_ok) {
    await set_cache_last_updated(now);
  }
}

Map<String, DateTime> _parse_table_updates(ApiResponse res) {
  final rows = res.data;
  if (rows is! List) {
    return {};
  }

  final updates = <String, DateTime>{};
  for (final row in rows) {
    if (row is! Map) {
      continue;
    }

    final name = row['table_name']?.toString();
    final at   = DateTime.tryParse(row['last_update']?.toString() ?? '');
    if (name == null || name.isEmpty || at == null) {
      continue;
    }

    final existing = updates[name];
    if (existing == null || at.isAfter(existing)) {
      updates[name] = at;
    }
  }

  return updates;
}

Future<bool> _fetch_and_cache_landmarks() async {
  final res = await api_request('GET', ApiEndpoints.landmarks);
  if (res.code != 1 || res.data is! List) {
    return false;
  }

  final rows = (res.data as List)
      .whereType<Map>()
      .map((row) => Map<String, dynamic>.from(row))
      .toList();

  await save_cached_table('landmark', rows);
  return true;
}
