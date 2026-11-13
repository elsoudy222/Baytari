/// The home repository IMPLEMENTATION (data layer).
///
/// Implements the domain contract [HomeRepository] by delegating
/// to the [HomeRemoteDataSource]. Its only other job is error
/// mapping: data-source exceptions become domain [Failure]s,
/// wrapped in a [Result], so Cubits and use cases never see a
/// Supabase type.
///
/// Mapping table (same as AuthRepositoryImpl):
/// - [AuthException]            -> [AuthFailure]
/// - [SupabaseNotConfiguredException] -> [NotConfiguredFailure]
/// - [ServerException] / anything else -> [ServerFailure]
///
/// One extra rule: `getComments` groups the flat list into a
/// tree here (not in the Cubit) — the repository owns the shape
/// of the data, the Cubit only owns the state machine.
library;

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/report.dart';
import '../../domain/entities/report_comment.dart';
import '../../domain/entities/report_enums.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';
import '../models/report_comment_model.dart';
import '../models/report_model.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._remoteDataSource);

  final HomeRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<Report>>> getReports({ReportCategory? category}) async {
    try {
      final List<ReportModel> reports =
          await _remoteDataSource.getReports(category: category);
      return Success<List<Report>>(reports);
    } on AppException catch (e) {
      return FailureResult<List<Report>>(_mapException(e));
    } on supabase.PostgrestException catch (e) {
      return FailureResult<List<Report>>(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<Report>> getReport(String reportId) async {
    try {
      final ReportModel report =
          await _remoteDataSource.getReport(reportId);
      return Success<Report>(report);
    } on AppException catch (e) {
      return FailureResult<Report>(_mapException(e));
    } on supabase.PostgrestException catch (e) {
      return FailureResult<Report>(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<Report>> createReport({
    required ReportCategory category,
    required ReportPriority priority,
    required AnimalType animalType,
    required String description,
    String? locationText,
    List<Uint8List> photos = const <Uint8List>[],
  }) async {
    try {
      final ReportModel report = await _remoteDataSource.createReport(
        category: category,
        priority: priority,
        animalType: animalType,
        description: description,
        locationText: locationText,
        photos: photos,
      );
      return Success<Report>(report);
    } on AppException catch (e) {
      return FailureResult<Report>(_mapException(e));
    } on supabase.PostgrestException catch (e) {
      return FailureResult<Report>(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<bool>> toggleHelper(String reportId) async {
    try {
      final bool isHelper =
          await _remoteDataSource.toggleHelper(reportId);
      return Success<bool>(isHelper);
    } on AppException catch (e) {
      return FailureResult<bool>(_mapException(e));
    } on supabase.PostgrestException catch (e) {
      return FailureResult<bool>(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<ReportStatus>> setReportStatus(
    String reportId,
    ReportStatus status,
  ) async {
    try {
      final ReportStatus saved =
          await _remoteDataSource.setReportStatus(reportId, status);
      return Success<ReportStatus>(saved);
    } on AppException catch (e) {
      return FailureResult<ReportStatus>(_mapException(e));
    } on supabase.PostgrestException catch (e) {
      return FailureResult<ReportStatus>(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<List<ReportComment>>> getComments(String reportId) async {
    try {
      final List<ReportCommentModel> flat =
          await _remoteDataSource.getComments(reportId);
      // The table is flat; the tree (replies under their parent)
      // is built here so the Cubit and UI always see the same
      // shape.
      return Success<List<ReportComment>>(
        ReportCommentModel.groupReplies(flat),
      );
    } on AppException catch (e) {
      return FailureResult<List<ReportComment>>(_mapException(e));
    } on supabase.PostgrestException catch (e) {
      return FailureResult<List<ReportComment>>(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<ReportComment>> addComment({
    required String reportId,
    required String body,
    String? parentId,
  }) async {
    try {
      final ReportCommentModel comment =
          await _remoteDataSource.addComment(
            reportId: reportId,
            body: body,
            parentId: parentId,
          );
      return Success<ReportComment>(comment);
    } on AppException catch (e) {
      return FailureResult<ReportComment>(_mapException(e));
    } on supabase.PostgrestException catch (e) {
      return FailureResult<ReportComment>(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<bool>> toggleCommentLike(String commentId) async {
    try {
      final bool liked =
          await _remoteDataSource.toggleCommentLike(commentId);
      return Success<bool>(liked);
    } on AppException catch (e) {
      return FailureResult<bool>(_mapException(e));
    } on supabase.PostgrestException catch (e) {
      return FailureResult<bool>(ServerFailure(e.message));
    }
  }

  /// Maps a data-source exception to the domain Failure the
  /// Cubit switches on. The message is technical (for logs);
  /// the user-facing text comes from the ARB files.
  Failure _mapException(AppException e) {
    return switch (e) {
      AuthException(:final message) => AuthFailure(message),
      SupabaseNotConfiguredException(:final message) =>
        NotConfiguredFailure(message),
      _ => ServerFailure(e.message),
    };
  }
}
