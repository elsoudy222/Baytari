/// The live password-rules checklist from the Figma
/// "Create New Password" screen (`Create_New_Password_Focused.png`).
///
/// Three rules, each with a check circle that turns green as soon
/// as the rule is satisfied while the user types:
/// - at least 8 characters
/// - uppercase and lowercase letters
/// - at least one number
///
/// Pure UI: the rules are evaluated by [Validators] (pure Dart),
/// this widget only draws the list for the current [password].
library;

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';

class PasswordRulesChecklist extends StatelessWidget {
  const PasswordRulesChecklist({required this.password, super.key});

  final String password;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // One entry per Figma rule: label + whether it is satisfied.
    final List<(String, bool)> rules = <(String, bool)>[
      (l10n.passwordRuleLength, Validators.hasMinLength8(password)),
      (l10n.passwordRuleCase, Validators.hasUpperAndLower(password)),
      (l10n.passwordRuleNumber, Validators.hasNumber(password)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rules
          .map(
            (rule) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: <Widget>[
                  Icon(
                    rule.$2
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    size: 18,
                    // Green when satisfied (Figma), grey otherwise.
                    color: rule.$2
                        ? AppColors.primary
                        : AppColors.subtitle,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    rule.$1,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(
                          color: rule.$2
                              ? AppColors.primary
                              : AppColors.subtitle,
                        ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
