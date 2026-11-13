/// Display helpers for the Home feed: localized labels and
/// colours for report categories, priorities, animal types and
/// statuses, plus the relative time ("3h", "1d", "Dec 6, 2024")
/// shown on posts and comments.
///
/// All user-facing text comes from the ARB files through
/// [AppLocalizations] — nothing here is a hardcoded string.
/// Colours come from [AppColors] (the Figma palette) — nothing
/// here is a hardcoded hex value.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/report_enums.dart';

/// The short chip label for a category (the feed's filter chips:
/// "Stray", "Lost", "Adoption").
String reportCategoryChipLabel(
  AppLocalizations l10n,
  ReportCategory category,
) {
  return switch (category) {
    ReportCategory.stray => l10n.filterStray,
    ReportCategory.lost => l10n.filterLost,
    ReportCategory.adoption => l10n.filterAdoption,
  };
}

/// The noun in the post header line ("High Priority /
/// Stray Animal / Dog"): stray reports say "Stray Animal",
/// lost reports say "Lost Pet", adoption reports say
/// "Adoptable".
String reportCategoryNoun(
  AppLocalizations l10n,
  ReportCategory category,
) {
  return switch (category) {
    ReportCategory.stray => l10n.categoryStrayAnimal,
    ReportCategory.lost => l10n.categoryLostPet,
    ReportCategory.adoption => l10n.categoryAdoptable,
  };
}

/// The priority word in the post header line ("High Priority",
/// "Urgent", ...).
String reportPriorityLabel(
  AppLocalizations l10n,
  ReportPriority priority,
) {
  return switch (priority) {
    ReportPriority.urgent => l10n.priorityUrgent,
    ReportPriority.high => l10n.priorityHigh,
    ReportPriority.mid => l10n.priorityMid,
    ReportPriority.low => l10n.priorityLow,
  };
}

/// The colour of the priority word: urgent/high are red, mid is
/// brown, low is teal (sampled from Figma).
Color reportPriorityColor(ReportPriority priority) {
  return switch (priority) {
    ReportPriority.urgent || ReportPriority.high => AppColors.error,
    ReportPriority.mid => AppColors.priorityMid,
    ReportPriority.low => AppColors.primary,
  };
}

/// "Dog" / "Cat" / "Other".
String animalTypeLabel(AppLocalizations l10n, AnimalType animal) {
  return switch (animal) {
    AnimalType.dog => l10n.animalDog,
    AnimalType.cat => l10n.animalCat,
    AnimalType.other => l10n.animalOther,
  };
}

/// The label of a "Share Status Update" chip ("Sighted",
/// "Rescued", "In Shelter", "at VET", ...).
String reportStatusLabel(AppLocalizations l10n, ReportStatus status) {
  return switch (status) {
    ReportStatus.sighted => l10n.statusSighted,
    ReportStatus.rescued => l10n.statusRescued,
    ReportStatus.inShelter => l10n.statusInShelter,
    ReportStatus.atVet => l10n.statusAtVet,
    ReportStatus.couldntFind => l10n.statusCouldntFind,
    ReportStatus.inSafeHands => l10n.statusInSafeHands,
    ReportStatus.notFound => l10n.statusNotFound,
    ReportStatus.interested => l10n.statusInterested,
    ReportStatus.readyToAdopt => l10n.statusReadyToAdopt,
    ReportStatus.inProcess => l10n.statusInProcess,
    ReportStatus.adopted => l10n.statusAdopted,
  };
}

/// The chip background for a status: yellow for "Sighted"-like
/// statuses, mint teal for the positive/rescue ones, peach for
/// the negative ones ("Couldn't find", "Not Found").
Color reportStatusChipColor(ReportStatus status) {
  return switch (status) {
    ReportStatus.sighted || ReportStatus.interested => AppColors.statusYellow,
    ReportStatus.couldntFind || ReportStatus.notFound =>
      AppColors.statusPeach,
    _ => AppColors.mint,
  };
}

/// The comment bubble background for a status: the same colours
/// as the chips (yellow / mint / peach). Null means "no status"
/// — the widget then uses the theme surface (Figma's plain white
/// bubble in light mode).
Color? commentBubbleColor(ReportStatus? status) {
  if (status == null) return null;
  return reportStatusChipColor(status);
}

/// The colour of the status label under a commenter's name:
/// brown for "Sighted"-like statuses, teal for the rescue ones,
/// red for the negative ones (Figma's comment screen).
Color commentStatusLabelColor(ReportStatus status) {
  return switch (status) {
    ReportStatus.sighted || ReportStatus.interested =>
      AppColors.priorityMid,
    ReportStatus.couldntFind || ReportStatus.notFound => AppColors.error,
    _ => AppColors.primary,
  };
}

/// A short relative time for posts and comments, like Figma:
/// "1m", "3h", "1d" for the last week, then a short date
/// ("Dec 6, 2024"). A null date (should not happen — the
/// database always sets created_at) shows nothing.
String relativeTime(DateTime? date, String localeName) {
  if (date == null) return '';
  final Duration diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return '1m';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return DateFormat.yMMMd(localeName).format(date);
}
