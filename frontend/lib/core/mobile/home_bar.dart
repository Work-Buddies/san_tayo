import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// True for Android/iOS native builds; false on web and desktop.
bool get isMobilePhone {
  if (kIsWeb) {
    return false;
  }

  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

/// Search screen subscribes so any page pushed over it hides the home bar.
final RouteObserver<PageRoute<dynamic>> home_bar_observer =
    RouteObserver<PageRoute<dynamic>>();

const MethodChannel _home_bar_channel = MethodChannel('san_tayo/home_bar');

bool _keep_home_bar = false;
bool _apply_queued  = false;
Future<void> _apply_chain = Future<void>.value();

/// Leaves the system home bar on screen.
void show_home_bar() {
  _keep_home_bar = true;
  _apply_home_bar();
}

/// Sticky hide: a bottom swipe shows the home bar, then it hides itself.
void hide_home_bar() {
  _keep_home_bar = false;
  _apply_home_bar();
}

/// Re-applies the current choice after the app returns to the foreground.
void sync_home_bar() {
  _apply_home_bar();
}

// Serializes platform calls so a fast show/hide can't land out of order.
void _apply_home_bar() {
  if (_apply_queued) {
    return;
  }
  _apply_queued = true;
  _apply_chain = _apply_chain.then((_) async {
    _apply_queued = false;
    final keep = _keep_home_bar;
    try {
      await _commit_home_bar(keep);
    } catch (_) {
      // The next show/hide queues another apply.
    }
    if (keep != _keep_home_bar) {
      _apply_home_bar();
    }
  });
}

Future<void> _commit_home_bar(bool keep) async {
  if (!isMobilePhone) {
    return;
  }

  if (keep) {
    await _show_home_bar();
    return;
  }

  await _hide_home_bar();
}

Future<void> _show_home_bar() async {
  // Android keeps the status bar hidden. iOS already shows it, so only the
  // home indicator comes back.
  if (defaultTargetPlatform == TargetPlatform.android) {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: const [SystemUiOverlay.bottom],
    );
    await _android_home_bar('show');
    return;
  }

  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: const [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );
}

Future<void> _hide_home_bar() async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await _android_home_bar('hide');
    return;
  }

  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: const [SystemUiOverlay.top],
  );
}

Future<void> _android_home_bar(String method) async {
  try {
    await _home_bar_channel.invokeMethod<void>(method);
  } on MissingPluginException {
    // Activity handler is not attached yet. Resume applies the current choice.
  }
}
