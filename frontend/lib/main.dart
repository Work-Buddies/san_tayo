import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/mobile/splash_screen.dart';
import 'core/web/skeleton.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // On phones, drop the system navigation bar but keep the status bar. The bar is only hidden,
  // not disabled — a swipe from the bottom edge still pulls it back up on demand.
  if (isMobilePhone) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
  }

  runApp(const SanTayoApp());
}

/// True for Android/iOS native builds; false on web and desktop.
bool get isMobilePhone {
  if (kIsWeb) {
    return false;
  }

  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

class SanTayoApp extends StatelessWidget {
  const SanTayoApp({super.key});

  final ColorScheme customColorScheme = const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF800000),      // Your main brand maroon/red
    onPrimary: Colors.white,               // Text color on top of primary buttons
    secondary: Color(0xFFCEDAA8),    // Accents / secondary actions
    onSecondary: Color(0xFF141414),
    surface: Color(0xFFF1EEE6),      // Card and page backgrounds
    onSurface: Color(0xFF141414),    // Default text color across the app
    error: Color(0xFFBA1A1A),        // Destructive actions/errors
    onError: Colors.white,
  );

  final TextTheme customTextTheme = const TextTheme(
    // ===========================================================================
    // DISPLAY STYLES (Special branding & massive text)
    // ===========================================================================
    
    /// The "Sa'n Tayo?" wordmark — the only place MoreSugar is used.
    displayLarge: TextStyle(
      fontFamily: 'MoreSugar',
      fontWeight: FontWeight.w700,
      fontSize: 46,
      height: 1.1,
    ),

    /// Alternative large display for promotions or hero screens.
    displayMedium: TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w700,
      fontSize: 36,
      height: 1.2,
      letterSpacing: -0.5,
    ),

    // ===========================================================================
    // HEADLINE STYLES (Major section headers)
    // ===========================================================================

    /// Section headers such as "Sign Up" and "Account Verification"
    headlineLarge: TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w700,
      fontSize: 32,
      height: 1.25,
      letterSpacing: -0.5,
    ),

    /// Mid-sized category headers or modal titles
    headlineMedium: TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w600,
      fontSize: 26,
      height: 1.3,
    ),

    /// Small section or card headings
    headlineSmall: TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w600,
      fontSize: 22,
      height: 1.3,
    ),

    // ===========================================================================
    // TITLE STYLES (Subheaders & list items)
    // ===========================================================================

    /// Sub-headers or distinct list tile titles
    titleLarge: TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w600,
      fontSize: 18,
      height: 1.4,
    ),

    /// Settings list titles, profile options, or bold inline text
    titleMedium: TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w500,
      fontSize: 16,
      height: 1.4,
    ),

    /// Subtitles under list titles or minor metadata headers
    titleSmall: TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w500,
      fontSize: 14,
      height: 1.4,
    ),

    // ===========================================================================
    // BODY STYLES (Paragraphs, fields, and text inputs)
    // ===========================================================================

    /// Standard body paragraphs, form field inputs, and heavy text blocks
    bodyLarge: TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w400,
      fontSize: 16,
      height: 1.5, // Essential for comfortable mobile reading
    ),

    /// Secondary body text (slightly smaller for dense screens)
    bodyMedium: TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w400,
      fontSize: 14,
      height: 1.5,
    ),

    /// Small caption, helper text, or placeholder hints (Functional minimum floor)
    bodySmall: TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w400,
      fontSize: 12,
      height: 1.4,
    ),

    // ===========================================================================
    // LABEL STYLES (Buttons, tags, and precise metadata)
    // ===========================================================================

    /// Main primary action buttons
    labelLarge: TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w600,
      fontSize: 16, // Kept large for excellent hit-target clarity
      letterSpacing: 0.5,
    ),

    /// Secondary buttons, chips, tabs, or form field labels
    labelMedium: TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w500,
      fontSize: 14,
      letterSpacing: 0.5,
    ),

    /// Smallest tags, badges, time-stamps, or fine print
    labelSmall: TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w500,
      fontSize: 11,
      letterSpacing: 0.5,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Sa'n Tayo",
      theme: ThemeData(
        colorScheme: customColorScheme,
        textTheme: customTextTheme,
        // Anything not covered by customTextTheme still falls back to Poppins.
        fontFamily: 'Poppins',
        useMaterial3: true,
      ),
      // Mobile phone shows the branded splash; everything else uses the web shell.
      home: isMobilePhone ? const SplashScreen() : const WebSkeleton(),
    );
  }
}
