/// The "Report an Animal" card at the top of the Home feed
/// (Figma's "Home - community member" screen).
///
/// A mint card: title + description + the "Report Animal"
/// button on the left, the illustration on the right. The
/// illustration reuses the stray-animal SVG already in the app
/// (`assets/images/onboarding_1.svg` — the girl holding the
/// orange cat from the Figma export): it is the same artwork
/// family as Figma's report card (a girl holding a cat next to
/// a phone with a map), and no closer illustration exists in
/// the assets or on Drive.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';

class ReportAnimalCard extends StatelessWidget {
  const ReportAnimalCard({required this.onReportPressed, super.key});

  final VoidCallback onReportPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.reportAnimalTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(l10n.reportAnimalDescription),
                const SizedBox(height: 16),
                AppButton(
                  label: l10n.reportAnimalButton,
                  onPressed: onReportPressed,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SvgPicture.asset(
            'assets/images/onboarding_1.svg',
            width: 110,
            height: 150,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
