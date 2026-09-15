class ApiEndpoints {
  // Public — no client key or token needed, used as the reachability probe.
  static const String health = '/health';

  // Auth — register issues an OTP instead of a token; verify_otp is what returns the token.
  static const String auth_register   = '/auth/register';
  static const String auth_login      = '/auth/login';
  static const String auth_verify_otp = '/auth/verify-otp';
  static const String auth_resend_otp = '/auth/resend-otp';
  static const String auth_me         = '/auth/me';
}
