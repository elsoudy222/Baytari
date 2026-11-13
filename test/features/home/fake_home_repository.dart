/// A fake [HomeRepository] for tests: no Supabase, no network.
///
/// The behaviour is controlled by setting its fields before the
/// test runs: [reportsToReturn] / [commentsToReturn] are what the
/// list calls return, [failure] makes every call fail with that
/// failure, and [calls] records which methods ran. Toggle methods
/// ([toggleHelper], [toggleCommentLike]) flip their stored state
/// and return it, so Cubit tests can assert the count moves by
/// +-1; [setReportStatus] stores the last status set.
library;

import 'dart:typed_data';

import 'package:baytari/core/errors/failures.dart';
import 'package:baytari/core/errors/result.dart';
import 'package:baytari/features/home/domain/entities/report.dart';
import 'package:baytari/features/home/domain/entities/report_author.dart';
import 'package:baytari/features/home/domain/entities/report_comment.dart';
import 'package:baytari/features/home/domain/entities/report_enums.dart';
import 'package:baytari/features/home/domain/repositories/home_repository.dart';

const ReportAuthor testAuthor = ReportAuthor(
  id: 'author-1',
  fullName: 'Merhan Assem',
  username: 'merhan',
  avatarUrl: null,
);

Report testReport({
  String id = 'report-1',
  ReportCategory category = ReportCategory.stray,
  ReportPriority priority = ReportPriority.high,
  AnimalType animalType = AnimalType.dog,
  String description = 'A small brown dog with a red collar',
  String? locationText = '45 Nile Street, Cairo',
  int helpersCount = 5,
  int commentsCount = 2,
  ReportStatus? myStatus,
  bool isHelper = false,
}) {
  return Report(
    id: id,
    author: testAuthor,
    category: category,
    priority: priority,
    animalType: animalType,
    description: description,
    locationText: locationText,
    photoUrls: const <String>['https://example.com/dog.jpg'],
    helpersCount: helpersCount,
    commentsCount: commentsCount,
    myStatus: myStatus,
    isHelper: isHelper,
    createdAt: DateTime(2026, 11, 13, 10),
  );
}

ReportComment testComment({
  String id = 'comment-1',
  String reportId = 'report-1',
  String? parentId,
  String body = 'I am on my way to check on this animal.',
  ReportStatus? status,
  int likeCount = 0,
  bool likedByMe = false,
  List<ReportComment> replies = const <ReportComment>[],
}) {
  return ReportComment(
    id: id,
    reportId: reportId,
    author: testAuthor,
    body: body,
    parentId: parentId,
    status: status,
    likeCount: likeCount,
    likedByMe: likedByMe,
    replies: replies,
    createdAt: DateTime(2026, 11, 13, 11),
  );
}

class FakeHomeRepository implements HomeRepository {
  List<Report> reportsToReturn = <Report>[];
  Report? reportToReturn;
  List<ReportComment> commentsToReturn = <ReportComment>[];
  ReportComment? commentToReturn;
  Failure? failure;
  final List<String> calls = <String>[];

  /// The helper state the fake returns (one entry per report the
  /// user is helping — toggled by toggleHelper).
  final Set<String> helpedReports = <String>{};

  /// The like state the fake returns (one entry per liked
  /// comment — toggled by toggleCommentLike).
  final Set<String> likedComments = <String>{};

  ReportCategory? lastRequestedCategory;

  @override
  Future<Result<List<Report>>> getReports({ReportCategory? category}) async {
    calls.add('getReports');
    lastRequestedCategory = category;
    if (failure != null) {
      return FailureResult<List<Report>>(failure!);
    }
    return Success<List<Report>>(reportsToReturn);
  }

  @override
  Future<Result<Report>> getReport(String reportId) async {
    calls.add('getReport');
    if (failure != null) {
      return FailureResult<Report>(failure!);
    }
    return Success<Report>(reportToReturn ?? testReport(id: reportId));
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
    calls.add('createReport');
    if (failure != null) {
      return FailureResult<Report>(failure!);
    }
    return Success<Report>(
      reportToReturn ??
          testReport(category: category, priority: priority, description: description),
    );
  }

  @override
  Future<Result<bool>> toggleHelper(String reportId) async {
    calls.add('toggleHelper');
    if (failure != null) {
      return FailureResult<bool>(failure!);
    }
    if (helpedReports.contains(reportId)) {
      helpedReports.remove(reportId);
      return const Success<bool>(false);
    }
    helpedReports.add(reportId);
    return const Success<bool>(true);
  }

  @override
  Future<Result<ReportStatus>> setReportStatus(
    String reportId,
    ReportStatus status,
  ) async {
    calls.add('setReportStatus');
    if (failure != null) {
      return FailureResult<ReportStatus>(failure!);
    }
    return Success<ReportStatus>(status);
  }

  @override
  Future<Result<List<ReportComment>>> getComments(String reportId) async {
    calls.add('getComments');
    if (failure != null) {
      return FailureResult<List<ReportComment>>(failure!);
    }
    return Success<List<ReportComment>>(commentsToReturn);
  }

  @override
  Future<Result<ReportComment>> addComment({
    required String reportId,
    required String body,
    String? parentId,
  }) async {
    calls.add('addComment');
    if (failure != null) {
      return FailureResult<ReportComment>(failure!);
    }
    return Success<ReportComment>(
      commentToReturn ?? testComment(reportId: reportId, body: body, parentId: parentId),
    );
  }

  @override
  Future<Result<bool>> toggleCommentLike(String commentId) async {
    calls.add('toggleCommentLike');
    if (failure != null) {
      return FailureResult<bool>(failure!);
    }
    if (likedComments.contains(commentId)) {
      likedComments.remove(commentId);
      return const Success<bool>(false);
    }
    likedComments.add(commentId);
    return const Success<bool>(true);
  }
}
