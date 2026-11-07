/// App toast — the one way the app shows a short message.
///
/// The user asked for a toast instead of a SnackBar everywhere
/// ("بدل ما تظهر snackbar عاوزك تضيف Toast"). A toast floats over
/// the screen and disappears on its own; unlike a SnackBar it does
/// not need a `ScaffoldMessenger`, does not push content up, and
/// does not stay on screen waiting to be swiped away — which fits
/// the auth flows here (short confirmations like "code sent" or
/// "profile saved", and validation errors).
///
/// This is the *only* place that talks to the toast plugin
/// (`fluttertoast`, a real native toast on Android/iOS). Every
/// screen and widget calls [showAppToast] instead of building its
/// own `SnackBar`, so the look stays identical everywhere:
/// - normal message: dark-teal background ([AppColors.heading]),
///   white text, at the bottom of the screen;
/// - error (`isError: true`): red background ([AppColors.error]).
///
/// The plugin call is guarded: in widget tests there is no native
/// platform channel, so `showToast` would throw
/// `MissingPluginException`. The `try/catch` inside the async
/// helper swallows that, so a toast can never crash a screen or a
/// test — in production the toast shows normally, in tests it
/// simply does nothing.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../theme/app_colors.dart';

/// Shows a short themed toast with [message].
///
/// Pass `isError: true` for validation / failure messages (red
/// background); the default is the dark-teal info style. The call
/// is fire-and-forget: it never throws and never blocks the caller.
void showAppToast(BuildContext context, String message, {bool isError = false}) {
  // `context` is kept in the signature so call sites read like the
  // old `ScaffoldMessenger.of(context)` calls and a future version
  // can theme the toast from the widget tree if needed. It is not
  // used by the plugin itself.
  unawaited(_showToast(message, isError: isError));
}

/// The guarded plugin call: `showToast` needs the native side,
/// which does not exist in widget tests.
Future<void> _showToast(String message, {required bool isError}) async {
  try {
    await Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isError ? AppColors.error : AppColors.heading,
      textColor: Colors.white,
      fontSize: 14,
    );
  } catch (_) {
    // No native toast available (widget tests, or a platform
    // without the plugin): a missing toast must never break the
    // flow that tried to show it.
  }
}
