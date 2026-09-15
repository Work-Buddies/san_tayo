import 'package:flutter_test/flutter_test.dart';
import 'package:san_tayo/core/mobile/splash_screen.dart';
import 'package:san_tayo/core/network/session.dart';

void main() {
  group('session_is_expired', () {
    final now = DateTime(2026, 9, 14, 12);

    test('missing timestamp counts as expired', () {
      expect(session_is_expired(null, now), isTrue);
    });

    test('a session used moments ago is live', () {
      expect(session_is_expired(now.subtract(const Duration(minutes: 5)), now), isFalse);
    });

    test('day 29 is still live', () {
      expect(session_is_expired(now.subtract(const Duration(days: 29)), now), isFalse);
    });

    test('the 30 day boundary expires', () {
      expect(session_is_expired(now.subtract(const Duration(days: 30)), now), isTrue);
    });

    test('day 31 is expired', () {
      expect(session_is_expired(now.subtract(const Duration(days: 31)), now), isTrue);
    });
  });

  group('decide_start', () {
    test('no session and server reachable goes to sign in', () {
      final result = decide_start(
        has_session:     false,
        reachable:       true,
        server_rejected: false,
      );

      expect(result, StartDestination.sign_in_online);
    });

    test('no session and server unreachable goes to the locked sign in', () {
      final result = decide_start(
        has_session:     false,
        reachable:       false,
        server_rejected: false,
      );

      expect(result, StartDestination.sign_in_offline);
    });

    test('valid session confirmed by the server goes to the dashboard', () {
      final result = decide_start(
        has_session:     true,
        reachable:       true,
        server_rejected: false,
      );

      expect(result, StartDestination.dashboard);
    });

    // The case that matters most: being offline must never look like a revoked token.
    test('valid session with an unreachable server still goes to the dashboard', () {
      final result = decide_start(
        has_session:     true,
        reachable:       false,
        server_rejected: false,
      );

      expect(result, StartDestination.dashboard);
    });

    test('session rejected by the server goes back to sign in', () {
      final result = decide_start(
        has_session:     true,
        reachable:       true,
        server_rejected: true,
      );

      expect(result, StartDestination.sign_in_online);
    });
  });
}
