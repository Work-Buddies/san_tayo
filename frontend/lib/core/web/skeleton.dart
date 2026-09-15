import 'package:flutter/material.dart';

import '../network/api_client.dart';
import 'dashboard.dart' as web_dash;
import 'sign_in_up.dart' as web_auth;

/// Web entry shell — no UI template yet; only handles auth redirect.
class WebSkeleton extends StatefulWidget {
  const WebSkeleton({super.key});

  @override
  State<WebSkeleton> createState() => _WebSkeletonState();
}

class _WebSkeletonState extends State<WebSkeleton> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _app_preload();
    });
  }

  /**
   * @uses: Checks login state and routes to the matching web screen.
   * @author: Kai Yaneza
   * Date: 2026-09-11
   */
  Future<void> _app_preload() async {
    final started_at = DateTime.now();

    final is_logged_in = auth_token != null && auth_token!.isNotEmpty;
    final Widget next = is_logged_in
        ? const web_dash.Dashboard()
        : const web_auth.SignInUp();

    // Keep skeleton visible for at least 1 second.
    final elapsed   = DateTime.now().difference(started_at);
    final remaining = const Duration(seconds: 1) - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SizedBox.shrink(),
    );
  }
}
