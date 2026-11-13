/// A community report — one post of the Home feed (the `reports`
/// table, migration 20261107000003).
///
/// A report is a value object ([Equatable], immutable): the feed
/// never edits a report in place, it reloads the list after an
/// action (Help / status / new comment). The counts
/// ([helpersCount], [commentsCount]) are computed by the data
/// layer from the related tables — they are NOT stored columns,
/// so they can never drift out of sync with the rows.
///
/// [myStatus] and [isHelper] describe the CURRENT user (null /
/// false for guests and for users who never interacted with this
/// report): the UI highlights the selected status chip and the
/// Help button from these two fields.
library;

import 'package:equatable/equatable.dart';

import 'report_author.dart';
import 'report_enums.dart';

class Report extends Equatable {
  const Report({
    required this.id,
    required this.author,
    required this.category,
    required this.priority,
    required this.animalType,
    required this.description,
    this.locationText,
    this.latitude,
    this.longitude,
    this.photoUrls = const <String>[],
    this.helpersCount = 0,
    this.commentsCount = 0,
    this.myStatus,
    this.isHelper = false,
    this.createdAt,
  });

  final String id;

  /// Who wrote the report (name + avatar for the post header).
  final ReportAuthor author;

  final ReportCategory category;

  final ReportPriority priority;

  final AnimalType animalType;

  /// The free-text description ("A small brown dog with a red
  /// collar..."). Shown truncated with "show more" in the feed.
  final String description;

  /// Human-readable place ("45 Nile Street, Near Tahrir Square,
  /// Cairo"). Shown under the description with a pin icon.
  final String? locationText;

  /// Optional coordinates (kept for the Map tab later; the feed
  /// does not use them yet).
  final double? latitude;

  final double? longitude;

  /// Public URLs of the photos, in display order (the photo grid
  /// shows 1 full-width, 2 side-by-side, 3 with a "+N" overlay).
  final List<String> photoUrls;

  /// How many users pressed "Help" (row count of report_helpers).
  final int helpersCount;

  /// How many comments the report has (row count of
  /// report_comments, replies included).
  final int commentsCount;

  /// The current user's latest status on this report, if they set
  /// one (their row in report_statuses). Null = no status yet.
  final ReportStatus? myStatus;

  /// Whether the current user pressed "Help" on this report.
  final bool isHelper;

  final DateTime? createdAt;

  Report copyWith({
    String? id,
    ReportAuthor? author,
    ReportCategory? category,
    ReportPriority? priority,
    AnimalType? animalType,
    String? description,
    String? locationText,
    double? latitude,
    double? longitude,
    List<String>? photoUrls,
    int? helpersCount,
    int? commentsCount,
    ReportStatus? myStatus,
    bool? isHelper,
    DateTime? createdAt,
  }) {
    return Report(
      id: id ?? this.id,
      author: author ?? this.author,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      animalType: animalType ?? this.animalType,
      description: description ?? this.description,
      locationText: locationText ?? this.locationText,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoUrls: photoUrls ?? this.photoUrls,
      helpersCount: helpersCount ?? this.helpersCount,
      commentsCount: commentsCount ?? this.commentsCount,
      myStatus: myStatus ?? this.myStatus,
      isHelper: isHelper ?? this.isHelper,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    author,
    category,
    priority,
    animalType,
    description,
    locationText,
    latitude,
    longitude,
    photoUrls,
    helpersCount,
    commentsCount,
    myStatus,
    isHelper,
    createdAt,
  ];
}
