import 'dart:math';

import 'package:san_tayo/core/network/api_client.dart';

/// In-memory demo accounts and tokens. Cleared when the app process ends.
class ClientDemoStore {
  ClientDemoStore._();

  static final ClientDemoStore instance = ClientDemoStore._();

  final Map<String, _DemoAccount> _by_email = {};
  final Map<String, String> _token_to_email = {};

  Map<String, dynamic>? account_for_token(String? token) {
    if (token == null || token.isEmpty) {
      return null;
    }

    final email = _token_to_email[token];
    if (email == null) {
      return null;
    }

    return _by_email[email]?.to_json();
  }

  Map<String, dynamic>? lookup_account_json(String email) {
    return _by_email[email.trim().toLowerCase()]?.to_json();
  }

  String? auth_level_for_email(String email) {
    return _by_email[email.trim().toLowerCase()]?.auth_level;
  }

  String issue_token(String email) {
    final key   = email.trim().toLowerCase();
    final token = 'demo_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
    _token_to_email[token] = key;
    return token;
  }

  void revoke_token(String? token) {
    if (token == null || token.isEmpty) {
      return;
    }
    _token_to_email.remove(token);
  }

  Map<String, dynamic> register_unverified({
    required String email,
    required String username,
    required String password,
  }) {
    final key = email.trim().toLowerCase();
    if (_by_email.containsKey(key)) {
      throw StateError('email_taken');
    }

    for (final row in _by_email.values) {
      if (row.username.toLowerCase() == username.trim().toLowerCase()) {
        throw StateError('username_taken');
      }
    }

    final account = _DemoAccount(
      id:         'demo-${key.hashCode.abs()}',
      email:      email.trim(),
      username:   username.trim(),
      password:   password,
      auth_level: 'unverified',
      created_at: DateTime.now().toUtc().toIso8601String(),
    );
    _by_email[key] = account;

    return account.to_json();
  }

  Map<String, dynamic>? login({
    required String email,
    required String password,
  }) {
    final account = _by_email[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      return null;
    }

    return account.to_json();
  }

  Map<String, dynamic>? verify_otp({
    required String email,
    required String code,
    required String expected_code,
  }) {
    if (code != expected_code) {
      return null;
    }

    final key = email.trim().toLowerCase();
    final row = _by_email[key];
    if (row == null) {
      return null;
    }

    if (row.auth_level != 'unverified') {
      throw StateError('already_verified');
    }

    row.auth_level = 'user';
    return row.to_json();
  }

  Map<String, dynamic>? update_username(String? token, String username) {
    final row = _row_for_token(token);
    if (row == null) {
      return null;
    }

    final next = username.trim();
    for (final other in _by_email.values) {
      if (other != row && other.username.toLowerCase() == next.toLowerCase()) {
        throw StateError('username_taken');
      }
    }

    row.username = next;
    return row.to_json();
  }

  Map<String, dynamic>? upgrade_business(String? token) {
    final row = _row_for_token(token);
    if (row == null) {
      return null;
    }

    if (row.auth_level != 'user') {
      throw StateError('not_user');
    }

    row.auth_level = 'business';
    return row.to_json();
  }

  bool change_password(String? token, String new_password) {
    final row = _row_for_token(token);
    if (row == null) {
      return false;
    }

    row.password = new_password;
    return true;
  }

  /// Restores in-memory maps after a cold start when secure storage still holds a demo token.
  void rehydrate_from_session(String token, Map<String, dynamic> account) {
    final email = account['email']?.toString().trim() ?? '';
    if (email.isEmpty) {
      return;
    }

    final key = email.toLowerCase();
    _token_to_email[token] = key;

    if (_by_email.containsKey(key)) {
      return;
    }

    _by_email[key] = _DemoAccount(
      id:         account['id']?.toString() ?? 'demo-rehydrate',
      email:      email,
      username:   account['username']?.toString() ?? 'user',
      password:   '',
      auth_level: account['auth_level']?.toString() ?? 'user',
      created_at: account['created_at']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
    );
  }

  _DemoAccount? _row_for_token(String? token) {
    final resolved = token ?? auth_token;
    final email    = _token_to_email[resolved];
    if (email == null) {
      return null;
    }
    return _by_email[email];
  }
}

class _DemoAccount {
  final String id;
  final String email;
  String username;
  String password;
  String auth_level;
  final String created_at;

  _DemoAccount({
    required this.id,
    required this.email,
    required this.username,
    required this.password,
    required this.auth_level,
    required this.created_at,
  });

  Map<String, dynamic> to_json() {
    return {
      'id':         id,
      'email':      email,
      'username':   username,
      'auth_level': auth_level,
      'created_at': created_at,
    };
  }
}
