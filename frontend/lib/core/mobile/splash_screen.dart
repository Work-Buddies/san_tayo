import 'package:flutter/material.dart';

import '../config/api_endpoints.dart';
import '../network/api_client.dart';
import '../network/session.dart';
import 'dashboard.dart' as mobile_dash;
import 'sign_in_up.dart' as mobile_auth;

/// Where the splash hands off once it knows the session state.
enum StartDestination {
  dashboard,
  sign_in_online,
  sign_in_offline,
}

/// Pure routing decision, kept separate from the IO so it can be unit tested.
///
/// [has_session] is whether a non-expired token was restored from storage.
/// [server_rejected] means the server answered and refused the token — the account was
/// deleted or the token revoked. A request that never reached the server is NOT a
/// rejection, otherwise every offline launch would silently sign the user out.
StartDestination decide_start({
  required bool has_session,
  required bool reachable,
  required bool server_rejected,
}) {
  if (!has_session) {
    return reachable ? StartDestination.sign_in_online : StartDestination.sign_in_offline;
  }

  if (server_rejected) {
    return StartDestination.sign_in_online;
  }

  // Either the server confirmed the token, or we could not reach it and fall back to
  // the cached session. Both land on the dashboard.
  return StartDestination.dashboard;
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _app_preload();
    });
  }

  Future<void> _app_preload() async {
    final started_at = DateTime.now();

    final destination = await _resolve_destination();

    // Keep splash visible for at least 1 second.
    final elapsed   = DateTime.now().difference(started_at);
    final remaining = const Duration(seconds: 1) - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    if (!mounted) {
      return;
    }

    final Widget next = switch (destination) {
      StartDestination.dashboard       => const mobile_dash.Dashboard(),
      StartDestination.sign_in_online  => const mobile_auth.SignInUp(),
      StartDestination.sign_in_offline => const mobile_auth.SignInUp(is_offline: true),
    };

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  /// Restore the stored session, then confirm it against the server when we can reach it.
  Future<StartDestination> _resolve_destination() async {
    final has_session = await load_session();

    if (!has_session) {
      // Nothing to validate — just find out whether signing in is even possible.
      final probe = await api_request('GET', ApiEndpoints.health);
      return decide_start(
        has_session:     false,
        reachable:       !probe.is_network_error,
        server_rejected: false,
      );
    }

    final me = await api_request('GET', ApiEndpoints.auth_me);

    if (me.code == 1) {
      await cache_account(me.data);
      return StartDestination.dashboard;
    }

    // Server answered and said no: the account is gone or the token was revoked.
    if (!me.is_network_error) {
      await clear_session();
    }

    return decide_start(
      has_session:     true,
      reachable:       !me.is_network_error,
      server_rejected: !me.is_network_error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            Image.asset(
              'assets/images/logo/logo_light.png',
              height: 160,
            ),
            Text("Sa'n Tayo?",
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
