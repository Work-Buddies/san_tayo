import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:san_tayo/client_demo/client_demo_config.dart';
import 'package:san_tayo/client_demo/client_demo_responses.dart';
import 'package:san_tayo/client_demo/client_demo_store.dart';
import 'package:san_tayo/core/config/api_endpoints.dart';
import 'package:san_tayo/core/models/api_response.dart';
import 'package:san_tayo/core/network/api_client.dart';

List<Map<String, dynamic>>? _landmark_rows;

Future<ApiResponse> client_demo_api_request(
  String method,
  String endpoint, {
  Map<String, dynamic>? body,
  Map<String, String>? query,
}) async {
  final path = _normalize_path(endpoint);
  final verb = method.toUpperCase();

  switch (path) {
    case ApiEndpoints.health:
      if (verb == 'GET') {
        return client_demo_success('OK.');
      }
      break;

    case ApiEndpoints.last_table_updates:
      if (verb == 'GET') {
        final now = DateTime.now().toUtc().toIso8601String();
        return client_demo_success('Table updates retrieved.', [
          {'table_name': 'landmark', 'last_update': now},
        ]);
      }
      break;

    case ApiEndpoints.landmarks:
      if (verb == 'GET') {
        final rows = await _load_landmarks();
        return client_demo_success('Landmarks retrieved.', rows);
      }
      break;

    case ApiEndpoints.auth_register:
      if (verb == 'POST') {
        return _register(body);
      }
      break;

    case ApiEndpoints.auth_login:
      if (verb == 'POST') {
        return _login(body);
      }
      break;

    case ApiEndpoints.auth_verify_otp:
      if (verb == 'POST') {
        return _verify_otp(body);
      }
      break;

    case ApiEndpoints.auth_resend_otp:
      if (verb == 'POST') {
        return _resend_otp(body);
      }
      break;

    case ApiEndpoints.auth_me:
      if (verb == 'GET') {
        return _me();
      }
      break;

    case ApiEndpoints.auth_logout:
      if (verb == 'POST') {
        return _logout();
      }
      break;

    case ApiEndpoints.account_upgrade_business:
      if (verb == 'POST') {
        return _upgrade_business();
      }
      break;

    case ApiEndpoints.account_username:
      if (verb == 'PUT' || verb == 'PATCH') {
        return _update_username(body);
      }
      break;

    case ApiEndpoints.account_password:
      if (verb == 'PUT' || verb == 'PATCH') {
        return _update_password(body);
      }
      break;
  }

  return client_demo_fail('Demo mode does not implement $verb $path.');
}

String _normalize_path(String endpoint) {
  if (endpoint.isEmpty) {
    return endpoint;
  }
  return endpoint.startsWith('/') ? endpoint : '/$endpoint';
}

Future<List<Map<String, dynamic>>> _load_landmarks() async {
  if (_landmark_rows != null) {
    return _landmark_rows!;
  }

  final raw     = await rootBundle.loadString('assets/client_demo/landmarks.json');
  final decoded = jsonDecode(raw);
  if (decoded is! List) {
    _landmark_rows = [];
    return _landmark_rows!;
  }

  _landmark_rows = decoded
      .whereType<Map>()
      .map((row) => Map<String, dynamic>.from(row))
      .toList();
  return _landmark_rows!;
}

ApiResponse _register(Map<String, dynamic>? body) {
  final email    = body?['email']?.toString().trim() ?? '';
  final username = body?['username']?.toString().trim() ?? '';
  final password = body?['password']?.toString() ?? '';

  if (email.isEmpty || username.isEmpty || password.isEmpty) {
    return client_demo_fail('Email, username and password are required.');
  }

  try {
    final account = ClientDemoStore.instance.register_unverified(
      email:    email,
      username: username,
      password: password,
    );

    return client_demo_success('Registration successful. Check your email for the verification code.', {
      'account':            account,
      'email':              email,
      'needs_verification': true,
    });
  } on StateError catch (e) {
    if (e.message == 'email_taken') {
      return client_demo_fail('Email is already registered.');
    }
    if (e.message == 'username_taken') {
      return client_demo_fail('Username is already taken.');
    }
    rethrow;
  }
}

ApiResponse _login(Map<String, dynamic>? body) {
  final email    = body?['email']?.toString().trim() ?? '';
  final password = body?['password']?.toString() ?? '';

  if (email.isEmpty || password.isEmpty) {
    return client_demo_fail('Email and password are required.');
  }

  final account = ClientDemoStore.instance.login(email: email, password: password);
  if (account == null) {
    return client_demo_fail('Invalid email or password.');
  }

  if (account['auth_level'] == 'unverified') {
    return client_demo_fail(
      'This account is not verified yet. Enter the code we sent to your email.',
      data: {
        'email':              email,
        'needs_verification': true,
      },
    );
  }

  final token = ClientDemoStore.instance.issue_token(email);
  return client_demo_success('Login successful.', {
    'account': account,
    'token':   token,
  });
}

ApiResponse _verify_otp(Map<String, dynamic>? body) {
  final email = body?['email']?.toString().trim() ?? '';
  final code  = body?['code']?.toString().trim() ?? '';

  if (email.isEmpty || code.isEmpty) {
    return client_demo_fail('Email and verification code are required.');
  }

  try {
    final account = ClientDemoStore.instance.verify_otp(
      email:         email,
      code:          code,
      expected_code: kClientDemoOtpCode,
    );

    if (account == null) {
      return client_demo_fail('The verification code is incorrect or has expired.');
    }

    final token = ClientDemoStore.instance.issue_token(email);
    return client_demo_success('Account verified.', {
      'account': account,
      'token':   token,
    });
  } on StateError catch (e) {
    if (e.message == 'already_verified') {
      return client_demo_fail('This account is already verified.');
    }
    rethrow;
  }
}

ApiResponse _resend_otp(Map<String, dynamic>? body) {
  final email = body?['email']?.toString().trim() ?? '';
  if (email.isEmpty) {
    return client_demo_fail('Email is required.');
  }

  final account = ClientDemoStore.instance.lookup_account_json(email);
  if (account == null) {
    return client_demo_fail('Account not found.');
  }

  if (ClientDemoStore.instance.auth_level_for_email(email) != 'unverified') {
    return client_demo_fail('This account is already verified.');
  }

  return client_demo_success('A new verification code has been sent.', {
    'email':       email,
    'retry_after': 120,
  });
}

ApiResponse _me() {
  final account = ClientDemoStore.instance.account_for_token(auth_token);
  if (account == null) {
    return client_demo_fail('Account not found.');
  }

  return client_demo_success('Account retrieved.', account);
}

ApiResponse _logout() {
  ClientDemoStore.instance.revoke_token(auth_token);
  return client_demo_success('Logout successful.');
}

ApiResponse _upgrade_business() {
  try {
    final account = ClientDemoStore.instance.upgrade_business(auth_token);
    if (account == null) {
      return client_demo_fail('Account not found.');
    }
    return client_demo_success('Account upgraded to business.', account);
  } on StateError catch (e) {
    if (e.message == 'not_user') {
      return client_demo_fail('Only user accounts can be upgraded to business.');
    }
    rethrow;
  }
}

ApiResponse _update_username(Map<String, dynamic>? body) {
  final username = body?['username']?.toString().trim() ?? '';
  if (username.isEmpty) {
    return client_demo_fail('Username is required.');
  }

  try {
    final account = ClientDemoStore.instance.update_username(auth_token, username);
    if (account == null) {
      return client_demo_fail('Account not found.');
    }
    return client_demo_success('Username updated.', account);
  } on StateError catch (e) {
    if (e.message == 'username_taken') {
      return client_demo_fail('Username is already taken.');
    }
    rethrow;
  }
}

ApiResponse _update_password(Map<String, dynamic>? body) {
  final new_password = body?['new_password']?.toString() ?? '';
  if (new_password.isEmpty) {
    return client_demo_fail('New password is required.');
  }

  final ok = ClientDemoStore.instance.change_password(auth_token, new_password);
  if (!ok) {
    return client_demo_fail('Account not found.');
  }

  return client_demo_success('Password updated.');
}
