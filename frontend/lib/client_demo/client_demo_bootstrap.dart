import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:san_tayo/client_demo/client_demo_config.dart';
import 'package:san_tayo/core/cache/app_cache.dart';
import 'package:san_tayo/core/network/api_client.dart';
import 'package:san_tayo/core/network/session.dart';

import 'client_demo_store.dart';

bool _bootstrapped = false;

/// Seeds landmark cache from bundled JSON when demo mode is on.
Future<void> client_demo_bootstrap_ensure_ready() async {
  if (!is_client_demo_enabled) {
    return;
  }

  if (_bootstrapped) {
    return;
  }

  final cached = await get_cached_table('landmark');
  if (cached.isNotEmpty) {
    _bootstrapped = true;
    return;
  }

  final raw     = await rootBundle.loadString('assets/client_demo/landmarks.json');
  final decoded = jsonDecode(raw);
  if (decoded is! List) {
    _bootstrapped = true;
    return;
  }

  final rows = decoded
      .whereType<Map>()
      .map((row) => Map<String, dynamic>.from(row))
      .toList();

  await save_cached_table('landmark', rows);
  await set_cache_last_updated(DateTime.now());
  _bootstrapped = true;
}

/// Keeps /auth/me working after the app restarts with a stored demo token.
void client_demo_rehydrate_session() {
  if (!is_client_demo_enabled) {
    return;
  }

  final token = auth_token;
  if (token == null || token.isEmpty || !token.startsWith('demo_')) {
    return;
  }

  if (cached_account == null) {
    return;
  }

  ClientDemoStore.instance.rehydrate_from_session(token, cached_account!);
}
