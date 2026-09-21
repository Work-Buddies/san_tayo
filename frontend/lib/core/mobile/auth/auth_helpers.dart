import 'package:flutter/material.dart';

import '../../network/session.dart';
import '../dashboard.dart';

/// Surface an API message to the user.
void showAuthMessage(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

/// Hide most of the local part of an email: juan.dela.cruz@gmail.com -> j**********ruz@gmail.com
String maskEmail(String email) {
  final at = email.indexOf('@');

  if (at < 2) {
    return email;
  }

  final local  = email.substring(0, at);
  final domain = email.substring(at);

  // Too short to keep a readable tail, so only the first character survives.
  if (local.length <= 4) {
    return '${local[0]}${'*' * (local.length - 1)}$domain';
  }

  return '${local[0]}${'*' * (local.length - 4)}${local.substring(local.length - 3)}$domain';
}

/// Persist the issued token so the session survives an app close, then drop the user on
/// the dashboard with no way back into auth.
Future<void> finishSignIn(BuildContext context, dynamic data) async {
  await save_session(data['token']?.toString(), data['account']);

  if (!context.mounted) {
    return;
  }

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const Dashboard()),
    (route) => false,
  );
}
