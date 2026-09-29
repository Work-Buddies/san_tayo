/// Client demo mode: no Laravel server; API calls are handled in [client_demo_api.dart].
///
/// Turn on for client test APKs:
/// - set [kClientDemoForce] to true, or
/// - build with `--dart-define=CLIENT_DEMO=true`
///
/// Demo auth: register normally, then enter OTP **0000** (four zeros). Login uses the
/// email/password you registered with.
const bool kClientDemoForce = true;

const bool kClientDemoFromDefine =
    bool.fromEnvironment('CLIENT_DEMO', defaultValue: false);

bool get is_client_demo_enabled => kClientDemoForce || kClientDemoFromDefine;

/// Fixed OTP accepted by the demo verify endpoint (matches the 4-digit UI).
const String kClientDemoOtpCode = '0000';
