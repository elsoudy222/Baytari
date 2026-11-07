/// The OTP input from the Figma OTP screens (sign-up
/// verification + forgot-password verification).
///
/// Single-digit boxes in a row; typing a digit jumps to the
/// next box, deleting jumps back. The parent reads the code with
/// [OtpCodeController.code]. When [hasError] is true the boxes
/// turn red, matching the Figma "Wrong Code" state (`OTP-1.png`).
///
/// The Figma screens show 4 boxes, but the boxes here are 6:
/// Supabase email OTP codes are 6 digits at minimum (the length
/// is configurable in the dashboard only between 6 and 10), so
/// 4 boxes could never accept a real code. Six boxes match the
/// Supabase default; the layout (mint border, rounded boxes)
/// is otherwise exactly the Figma style.
///
/// Pure UI: no Supabase, no Cubit — the parent screen calls the
/// Cubit when the user taps Verify.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';

/// Owns the digit controllers and exposes the joined code.
class OtpCodeController {
  OtpCodeController()
    : _controllers = List<TextEditingController>.generate(
        length,
        (_) => TextEditingController(),
      ),
      _focusNodes = List<FocusNode>.generate(length, (_) => FocusNode());

  /// Number of boxes. Six, to match Supabase's default OTP
  /// length (6–10 configurable, never less than 6).
  static const int length = 6;

  final List<TextEditingController> _controllers;
  final List<FocusNode> _focusNodes;

  /// The digits joined, e.g. "164203". Shorter while incomplete.
  String get code => _controllers.map((c) => c.text).join();

  bool get isComplete => code.length == length;

  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
  }

  List<TextEditingController> get controllers => _controllers;
  List<FocusNode> get focusNodes => _focusNodes;
}

class OtpCodeInput extends StatelessWidget {
  const OtpCodeInput({
    required this.controller,
    super.key,
    this.hasError = false,
    this.onCompleted,
  });

  final OtpCodeController controller;
  final bool hasError;
  final VoidCallback? onCompleted;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      // Digits are always left-to-right, even in Arabic (RTL).
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List<Widget>.generate(OtpCodeController.length, (index) {
          return SizedBox(
            width: 64,
            height: 64,
            child: TextField(
              controller: controller.controllers[index],
              focusNode: controller.focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              buildCounter:
                  (
                    context, {
                    required int currentLength,
                    required bool isFocused,
                    required int? maxLength,
                  }) => null,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: Theme.of(context).textTheme.headlineSmall,
              decoration: InputDecoration(
                filled: true,
                fillColor: context.isDark
                    ? AppColors.darkBackground
                    : AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError
                        ? context.colors.error
                        : AppColors.mintBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError
                        ? context.colors.error
                        : AppColors.mintBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError
                        ? context.colors.error
                        : AppColors.primary,
                  ),
                ),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  // Jump forward; on the last box, report completion.
                  if (index < OtpCodeController.length - 1) {
                    controller.focusNodes[index + 1].requestFocus();
                  } else {
                    controller.focusNodes[index].unfocus();
                    onCompleted?.call();
                  }
                } else if (index > 0) {
                  // Deleting an empty box jumps back.
                  controller.focusNodes[index - 1].requestFocus();
                }
              },
            ),
          );
        }),
      ),
    );
  }
}
