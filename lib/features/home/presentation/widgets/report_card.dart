/// One post of the Home feed (Figma's "Home - community
/// member" screen), top to bottom:
/// - header: author avatar + name, the coloured
///   "Priority / Category / Animal" line, time, "..." menu
/// - description (truncated with "show more")
/// - location line with a pin icon
/// - photo grid ([ReportPhotoGrid])
/// - "Share Status Update" + the status chips of this report's
///   category (the selected chip is highlighted)
/// - helpers / comments counts
/// - action row: Help / comment / Send
///
/// The card is stateless except for the "show more" toggle —
/// every action is a callback, so the card never talks to a
/// Cubit or a repository itself.
library;

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/report.dart';
import '../../domain/entities/report_enums.dart';
import '../utils/report_display.dart';
import 'report_photo_grid.dart';

class ReportCard extends StatefulWidget {
  const ReportCard({
    required this.report,
    required this.onHelpPressed,
    required this.onCommentPressed,
    required this.onSendPressed,
    required this.onStatusSelected,
    required this.onMorePressed,
    super.key,
  });

  final Report report;

  /// "Help" was tapped (toggles the current user as a helper).
  final VoidCallback onHelpPressed;

  /// "comment" was tapped (opens the comments screen).
  final VoidCallback onCommentPressed;

  /// "Send" was tapped (sharing — coming soon for now).
  final VoidCallback onSendPressed;

  /// A status chip was tapped.
  final ValueChanged<ReportStatus> onStatusSelected;

  /// The "..." menu was tapped (coming soon for now).
  final VoidCallback onMorePressed;

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  /// Whether the full description is shown. Descriptions longer
  /// than ~3 lines are truncated until "show more" is tapped.
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final Report report = widget.report;
    final bool isLong = report.description.length > 140;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _PostHeader(
            report: report,
            onMorePressed: widget.onMorePressed,
          ),
          const SizedBox(height: 12),
          Text(
            report.description,
            maxLines: _expanded ? null : 3,
            overflow: _expanded ? null : TextOverflow.ellipsis,
          ),
          // "show more" / "show less" — only for long texts.
          if (isLong)
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _expanded ? l10n.showLess : l10n.showMore,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (report.locationText != null &&
              report.locationText!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    report.locationText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (report.photoUrls.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            ReportPhotoGrid(photoUrls: report.photoUrls),
          ],
          const SizedBox(height: 16),
          Text(
            l10n.shareStatusUpdate,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _StatusChips(
            category: report.category,
            selected: report.myStatus,
            onSelected: widget.onStatusSelected,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(l10n.helpersCount(report.helpersCount)),
              Text(l10n.commentsCount(report.commentsCount)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          _ActionRow(
            isHelper: report.isHelper,
            onHelpPressed: widget.onHelpPressed,
            onCommentPressed: widget.onCommentPressed,
            onSendPressed: widget.onSendPressed,
          ),
        ],
      ),
    );
  }
}

/// Avatar + name + "Priority / Category / Animal" line + time.
/// The priority word is coloured (red = urgent/high, brown =
/// mid, teal = low) exactly like Figma.
class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.report, required this.onMorePressed});

  final Report report;
  final VoidCallback onMorePressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CircleAvatar(
          radius: 24,
          backgroundImage: report.author.avatarUrl != null
              ? NetworkImage(report.author.avatarUrl!)
              : null,
          child: report.author.avatarUrl == null
              ? const Icon(Icons.person_outlined)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                report.author.displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      '${reportPriorityLabel(l10n, report.priority)}'
                      ' / ${reportCategoryNoun(l10n, report.category)}'
                      ' / ${animalTypeLabel(l10n, report.animalType)}',
                      style: TextStyle(
                        color: reportPriorityColor(report.priority),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    relativeTime(
                      report.createdAt,
                      l10n.localeName,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.subtitle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onMorePressed,
          icon: const Icon(Icons.more_horiz),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

/// The "Share Status Update" chips. The selected chip (the
/// user's current status) is filled primary with white text;
/// the others are the pastel status colours with dark text.
class _StatusChips extends StatelessWidget {
  const _StatusChips({
    required this.category,
    required this.selected,
    required this.onSelected,
  });

  final ReportCategory category;
  final ReportStatus? selected;
  final ValueChanged<ReportStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final ReportStatus status in ReportStatus.chipsFor(category))
          ChoiceChip(
            label: Text(reportStatusLabel(l10n, status)),
            selected: selected == status,
            onSelected: (_) => onSelected(status),
            selectedColor: scheme.primary,
            backgroundColor: reportStatusChipColor(status),
            labelStyle: TextStyle(
              color: selected == status
                  ? scheme.onPrimary
                  : AppColors.heading,
              fontWeight: FontWeight.w600,
            ),
            // No border on the pastel chips (Figma's chips are
            // borderless); the selected one gets the primary fill.
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
      ],
    );
  }
}

/// Help / comment / Send, spread across the width like Figma.
/// "Help" is filled when the user is already helping.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.isHelper,
    required this.onHelpPressed,
    required this.onCommentPressed,
    required this.onSendPressed,
  });

  final bool isHelper;
  final VoidCallback onHelpPressed;
  final VoidCallback onCommentPressed;
  final VoidCallback onSendPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final Color primary = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        TextButton.icon(
          onPressed: onHelpPressed,
          icon: Icon(
            isHelper ? Icons.star : Icons.star_border,
            color: primary,
          ),
          label: Text(
            l10n.help,
            style: TextStyle(color: primary, fontWeight: FontWeight.w600),
          ),
        ),
        TextButton.icon(
          onPressed: onCommentPressed,
          icon: Icon(Icons.chat_bubble_outline, color: primary),
          label: Text(
            l10n.comment,
            style: TextStyle(color: primary, fontWeight: FontWeight.w600),
          ),
        ),
        TextButton.icon(
          onPressed: onSendPressed,
          icon: Icon(Icons.send_outlined, color: primary),
          label: Text(
            l10n.send,
            style: TextStyle(color: primary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
