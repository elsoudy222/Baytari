/// The Home remote data source CONTRACT (data layer).
///
/// The repository depends only on this abstract class, and the
/// only implementation is the Supabase one — that is the Clean
/// Architecture boundary: everything above it works with plain
/// [ReportModel]/[ReportCommentModel] objects and never sees a
/// Supabase type.
///
/// Conventions (same as AuthRemoteDataSource):
/// - Methods THROW [AppException] subclasses on failure (the
///   repository turns them into [Failure]s); they never return
///   a Result themselves.
/// - Photo arguments are raw bytes (`Uint8List`), never files:
///   the UI picks images with `image_picker` and hands over
///   bytes, so the data layer never imports `dart:io`.
library;

import 'dart:typed_data';

import '../models/report_comment_model.dart';
import '../models/report_model.dart';
import '../../domain/entities/report_enums.dart';

abstract class HomeRemoteDataSource {
  Future<List<ReportModel>> getReports({ReportCategory? category});

  Future<ReportModel> getReport(String reportId);

  Future<ReportModel> createReport({
    required ReportCategory category,
    required ReportPriority priority,
    required AnimalType animalType,
    required String description,
    String? locationText,
    List<Uint8List> photos = const <Uint8List>[],
  });

  /// Returns the new helpers state (true = now helping).
  Future<bool> toggleHelper(String reportId);

  Future<ReportStatus> setReportStatus(
    String reportId,
    ReportStatus status,
  );

  Future<List<ReportCommentModel>> getComments(String reportId);

  Future<ReportCommentModel> addComment({
    required String reportId,
    required String body,
    String? parentId,
  });

  /// Returns the new like state (true = now liked).
  Future<bool> toggleCommentLike(String commentId);
}
