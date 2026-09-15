import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';

/// How long a signed-in session survives without the app being opened. The window is
/// rolling: every successful app launch re-stamps the timestamp, so an active user
/// never gets kicked out.
const int session_max_days = 30;

const String _key_token     = 'auth_token';
const String _key_last_seen = 'last_seen_at';
const String _key_account   = 'account';

// v11 defaults to AES-GCM on Android and the Keychain on iOS, so no options needed.
const FlutterSecureStorage _storage = FlutterSecureStorage();

/// Account payload from the last successful auth call. Kept so an offline launch can
/// still render the dashboard without hitting the server.
Map<String, dynamic>? cached_account;

/// True when the stored session has gone stale and should be discarded.
/// Pure so the 30-day rule can be tested without touching storage.
bool session_is_expired(DateTime? last_seen_at, DateTime now) {
  if (last_seen_at == null) {
    return true;
  }

  return now.difference(last_seen_at).inDays >= session_max_days;
}

/// Persist a freshly issued token and refresh the rolling window.
Future<void> save_session(String? token, dynamic account) async {
  if (token == null || token.isEmpty) {
    return;
  }

  auth_token     = token;
  cached_account = account is Map<String, dynamic> ? account : null;

  await _storage.write(key: _key_token, value: token);
  await _storage.write(key: _key_last_seen, value: DateTime.now().toIso8601String());

  if (cached_account != null) {
    await _storage.write(key: _key_account, value: jsonEncode(cached_account));
  }
}

/// Restore a stored session into memory. Returns false when there is nothing stored or
/// the rolling window has lapsed, in which case the stored values are wiped.
Future<bool> load_session() async {
  final token     = await _storage.read(key: _key_token);
  final last_seen = await _storage.read(key: _key_last_seen);

  if (token == null || token.isEmpty) {
    return false;
  }

  if (session_is_expired(DateTime.tryParse(last_seen ?? ''), DateTime.now())) {
    await clear_session();
    return false;
  }

  auth_token = token;

  final account_json = await _storage.read(key: _key_account);
  if (account_json != null && account_json.isNotEmpty) {
    final decoded  = jsonDecode(account_json);
    cached_account = decoded is Map<String, dynamic> ? decoded : null;
  }

  // Opening the app counts as activity, so push the expiry window forward.
  await touch_session();

  return true;
}

/// Re-stamp the rolling window without changing the token.
Future<void> touch_session() async {
  await _storage.write(key: _key_last_seen, value: DateTime.now().toIso8601String());
}

/// Replace the cached account after a successful /auth/me refresh.
Future<void> cache_account(dynamic account) async {
  if (account is! Map<String, dynamic>) {
    return;
  }

  cached_account = account;
  await _storage.write(key: _key_account, value: jsonEncode(account));
}

/// Drop everything. Used when the server rejects the token or the window lapses.
Future<void> clear_session() async {
  auth_token     = null;
  cached_account = null;

  await _storage.delete(key: _key_token);
  await _storage.delete(key: _key_last_seen);
  await _storage.delete(key: _key_account);
}
