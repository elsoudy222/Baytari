/// Data model for a report row — the JSON <-> [Report] converter.
///
/// The JSON here is NOT a plain row: the data source asks
/// Supabase for the report with its relations embedded in one
/// query (`author:profiles!author_id(...)`,
/// `report_photos(...)`, `report_helpers(...)`,
/// `report_comments(...)`, `report_statuses(...)`), so one row
/// carries everything the feed needs — author, photos, counts
/// and the current user's state — without N+1 queries.
///
/// Counts are derived from the embedded lists (a list's length),
/// never from a stored counter column.
library;

import '../../domain/entities/report.dart';
import '../../domain/entities/report_author.dart';
import '../../domain/entities/report_enums.dart';

class ReportModel extends Report {
  const ReportModel({
    required super.id,
    required super.author,
    required super.category,
    required super.priority,
    required super.animalType,
    required super.description,
    super.locationText,
    super.latitude,
    super.longitude,
    super.photoUrls,
    super.helpersCount,
    super.commentsCount,
    super.myStatus,
    super.isHelper,
    super.createdAt,
  });

  /// Builds a model from one row of the `reports` table with its
  /// embedded relations (see the class doc). [currentUserId] is
  /// the signed-in user's id (null for guests): it decides
  /// [Report.isHelper] and [Report.myStatus] from the embedded
  /// `report_helpers` / `report_statuses` lists. [photoUrlFor]
  /// turns a storage path into the public URL of the
  /// `report-photos` bucket — the table stores paths, not URLs.
  factory ReportModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
    String Function(String path)? photoUrlFor,
  }) {
    // The author comes back as an embedded `profiles` row
    // (aliased `author` in the select). A missing author (deleted
    // account) falls back to an empty name instead of crashing
    // the whole feed.
    final Map<String, dynamic>? authorJson =
        json['author'] as Map<String, dynamic>?;
    final ReportAuthor author = ReportAuthor(
      id: authorJson?['id'] as String? ?? '',
      fullName: authorJson?['full_name'] as String? ?? '',
      username: authorJson?['username'] as String?,
      avatarUrl: authorJson?['avatar_url'] as String?,
    );

    // Photos, ordered by `position` (the grid order in Figma).
    final List<Map<String, dynamic>> photoRows =
        (json['report_photos'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList()
          ..sort(
            (a, b) =>
                (a['position'] as int? ?? 0) -
                (b['position'] as int? ?? 0),
          );
    final List<String> photoUrls = photoRows
        .map((row) => row['storage_path'] as String? ?? '')
        .where((path) => path.isNotEmpty)
        .map((path) => photoUrlFor?.call(path) ?? path)
        .toList();

    // Helpers: the embedded list's length IS the count, and the
    // current user's presence in it IS the Help button state.
    final List<dynamic> helperRows =
        json['report_helpers'] as List<dynamic>? ?? <dynamic>[];
    final bool isHelper =
        currentUserId != null &&
        helperRows.any(
          (row) =>
              (row as Map<String, dynamic>)['user_id'] == currentUserId,
        );

    // The current user's latest status, if they set one.
    ReportStatus? myStatus;
    final List<dynamic> statusRows =
        json['report_statuses'] as List<dynamic>? ?? <dynamic>[];
    for (final row in statusRows) {
      final Map<String, dynamic> statusRow = row as Map<String, dynamic>;
      if (statusRow['user_id'] == currentUserId) {
        myStatus = ReportStatus.fromString(
          statusRow['status'] as String?,
        );
        break;
      }
    }

    return ReportModel(
      id: json['id'] as String? ?? '',
      author: author,
      category: ReportCategory.fromString(json['category'] as String?),
      priority: ReportPriority.fromString(json['priority'] as String?),
      animalType: AnimalType.fromString(json['animal_type'] as String?),
      description: json['description'] as String? ?? '',
      locationText: json['location_text'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      photoUrls: photoUrls,
      helpersCount: helperRows.length,
      commentsCount:
          (json['report_comments'] as List<dynamic>? ?? <dynamic>[])
              .length,
      myStatus: myStatus,
      isHelper: isHelper,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String),
    );
  }

  /// The map written to the `reports` table on INSERT. `id` is
  /// not included — the database generates it. Photos are
  /// uploaded separately and inserted into `report_photos`.
  Map<String, dynamic> toInsertJson(String authorId) {
    return <String, dynamic>{
      'author_id': authorId,
      'category': category.value,
      'priority': priority.value,
      'animal_type': animalType.value,
      'description': description,
      'location_text': locationText,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
