/// The Home repository CONTRACT (domain layer).
///
/// The Cubit and use cases depend only on this abstract class —
/// never on the Supabase implementation. That is what makes the
/// feed testable: tests register a fake [HomeRepository] instead
/// of the real one.
///
/// Conventions (same as AuthRepository):
/// - Every method returns a [Result] — success carries the value,
///   failure carries a domain [Failure]. Nothing here throws.
/// - `createReport` takes raw photo bytes (not files): the UI
///   picks images with `image_picker` and hands over `Uint8List`s,
///   so the domain never imports `dart:io` or image_picker.
/// - Counts are computed by the implementation from the related
///   tables; there are no counter columns in the database.
library;

import 'dart:typed_data';

import '../../../../core/errors/result.dart';
import '../entities/report.dart';
import '../entities/report_comment.dart';
import '../entities/report_enums.dart';

abstract class HomeRepository {
  /// The feed, newest first. [category] filters server-side
  /// (null = all categories). The text search is done client-side
  /// by the Cubit, over the loaded reports.
  Future<Result<List<Report>>> getReports({ReportCategory? category});

  /// One report with its photos, counts and the current user's
  /// status/helper state (for the comments screen header).
  Future<Result<Report>> getReport(String reportId);

  /// Creates a report and uploads its photos to the
  /// `report-photos` bucket. Returns the created report.
  Future<Result<Report>> createReport({
    required ReportCategory category,
    required ReportPriority priority,
    required AnimalType animalType,
    required String description,
    String? locationText,
    List<Uint8List> photos = const <Uint8List>[],
  });

  /// Pressing "Help" again removes the user from the helpers.
  /// Returns the new helpers state (true = now helping).
  Future<Result<bool>> toggleHelper(String reportId);

  /// Sets the current user's status on a report (the "Share
  /// Status Update" chips). Upserts: tapping a chip twice keeps
  /// the same status, tapping another chip replaces it.
  Future<Result<ReportStatus>> setReportStatus(
    String reportId,
    ReportStatus status,
  );

  /// All comments of a report, oldest first, with one level of
  /// replies attached to their parents ([ReportComment.replies]).
  Future<Result<List<ReportComment>>> getComments(String reportId);

  /// Posts a comment (or a reply when [parentId] is set). The
  /// comment stores the user's current status on the report, so
  /// its bubble gets the right colour and label.
  Future<Result<ReportComment>> addComment({
    required String reportId,
    required String body,
    String? parentId,
  });

  /// Likes / unlikes a comment. Returns the new state
  /// (true = now liked).
  Future<Result<bool>> toggleCommentLike(String commentId);
}
