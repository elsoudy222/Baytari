/// Cubit of the comments screen.
///
/// Loads the report (header + the user's status for the chips)
/// and its comments, then handles posting, liking and replying.
/// A posted comment is appended locally (to the parent's replies
/// when it is a reply) instead of reloading the whole list, so
/// the composer stays put and the new comment appears at once.
///
/// Like toggles are optimistic in one direction only: the count
/// and the Like/unlike label change only AFTER the server
/// confirms, so a failed tap never leaves the UI lying.
library;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/entities/report.dart';
import '../../domain/entities/report_comment.dart';
import '../../domain/entities/report_enums.dart';
import '../../domain/usecases/add_comment_usecase.dart';
import '../../domain/usecases/get_comments_usecase.dart';
import '../../domain/usecases/get_report_usecase.dart';
import '../../domain/usecases/set_report_status_usecase.dart';
import '../../domain/usecases/toggle_comment_like_usecase.dart';
import 'report_comments_state.dart';

class ReportCommentsCubit extends Cubit<ReportCommentsState> {
  ReportCommentsCubit({
    required this._getReportUseCase,
    required this._getCommentsUseCase,
    required this._addCommentUseCase,
    required this._toggleCommentLikeUseCase,
    required this._setReportStatusUseCase,
  }) : super(const ReportCommentsState());

  final GetReportUseCase _getReportUseCase;
  final GetCommentsUseCase _getCommentsUseCase;
  final AddCommentUseCase _addCommentUseCase;
  final ToggleCommentLikeUseCase _toggleCommentLikeUseCase;
  final SetReportStatusUseCase _setReportStatusUseCase;

  /// Loads the report and its comments. The two calls are
  /// independent, so they run one after the other and the first
  /// failure wins (the screen shows one error state, not two).
  Future<void> load(String reportId) async {
    emit(state.copyWith(status: ReportCommentsStatus.loading));
    final Result<Report> reportResult = await _getReportUseCase(
      reportId,
    );
    if (reportResult is FailureResult<Report>) {
      emit(
        state.copyWith(
          status: ReportCommentsStatus.failure,
          errorMessage: reportResult.failure.message,
        ),
      );
      return;
    }
    final Result<List<ReportComment>> commentsResult =
        await _getCommentsUseCase(reportId);
    switch (commentsResult) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: ReportCommentsStatus.loaded,
            report: (reportResult as Success<Report>).value,
            comments: value,
            errorMessage: null,
          ),
        );
      case FailureResult(:final failure):
        emit(
          state.copyWith(
            status: ReportCommentsStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }

  /// The user tapped "Reply" under a comment (or the X to
  /// cancel). The composer shows "Replying to {name}" while
  /// [comment] is set.
  void setReplyingTo(ReportComment? comment) {
    emit(
      state.copyWith(
        replyingTo: comment,
        clearReplyingTo: comment == null,
      ),
    );
  }

  /// Posts the composer text. A reply goes under
  /// [ReportCommentsState.replyingTo]; a top-level comment is
  /// appended at the end (oldest-first order). The reply target
  /// is cleared on success only — on failure the text and the
  /// target stay, so the user can retry.
  Future<void> postComment(String body) async {
    if (state.report == null || state.isPosting) return;
    emit(state.copyWith(isPosting: true));
    final Result<ReportComment> result = await _addCommentUseCase(
      reportId: state.report!.id,
      body: body,
      parentId: state.replyingTo?.id,
    );
    switch (result) {
      case Success(:final value):
        final ReportComment? parent = state.replyingTo;
        final List<ReportComment> updated;
        if (parent == null) {
          updated = <ReportComment>[...state.comments, value];
        } else {
          updated = state.comments
              .map(
                (comment) => comment.id == parent.id
                    ? comment.copyWith(
                        replies: <ReportComment>[
                          ...comment.replies,
                          value,
                        ],
                      )
                    : comment,
              )
              .toList();
        }
        emit(
          state.copyWith(
            comments: updated,
            clearReplyingTo: true,
            isPosting: false,
            errorMessage: null,
          ),
        );
      case FailureResult(:final failure):
        emit(
          state.copyWith(
            isPosting: false,
            errorMessage: failure.message,
          ),
        );
    }
  }

  /// Likes / unlikes a comment (top-level or a reply — the
  /// lookup walks both levels). The count moves by +-1 and the
  /// label flips only after the server confirms.
  Future<void> toggleLike(String commentId) async {
    final Result<bool> result = await _toggleCommentLikeUseCase(
      commentId,
    );
    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            comments: _updateComment(
              state.comments,
              commentId,
              (comment) => comment.copyWith(
                likedByMe: value,
                likeCount: comment.likeCount + (value ? 1 : -1),
              ),
            ),
            errorMessage: null,
          ),
        );
      case FailureResult(:final failure):
        emit(state.copyWith(errorMessage: failure.message));
    }
  }

  /// A "Share Status Update" chip was tapped on this screen:
  /// sets the user's status and highlights the chip (the report
  /// in state carries [Report.myStatus]).
  Future<void> setStatus(ReportStatus status) async {
    final Report? report = state.report;
    if (report == null) return;
    final Result<ReportStatus> result = await _setReportStatusUseCase(
      report.id,
      status,
    );
    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            report: report.copyWith(myStatus: value),
            errorMessage: null,
          ),
        );
      case FailureResult(:final failure):
        emit(state.copyWith(errorMessage: failure.message));
    }
  }

  /// Applies [update] to the comment with [commentId], whether
  /// it is top-level or a reply of one.
  static List<ReportComment> _updateComment(
    List<ReportComment> comments,
    String commentId,
    ReportComment Function(ReportComment comment) update,
  ) {
    return comments.map((comment) {
      if (comment.id == commentId) return update(comment);
      return comment.copyWith(
        replies: comment.replies
            .map(
              (reply) => reply.id == commentId ? update(reply) : reply,
            )
            .toList(),
      );
    }).toList();
  }
}
