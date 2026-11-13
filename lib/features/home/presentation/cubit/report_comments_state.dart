/// State of the comments screen.
///
/// [report] is the post the comments belong to (its header info
/// + the current user's status, for the chips). [comments] are
/// top-level comments with their replies attached
/// ([ReportComment.replies]). [replyingTo] is the comment the
/// user tapped "Reply" on — the composer shows "Replying to
/// {name}" until it is sent or cancelled. [isPosting] disables
/// the composer while a comment is being sent.
library;

import 'package:equatable/equatable.dart';

import '../../domain/entities/report.dart';
import '../../domain/entities/report_comment.dart';

enum ReportCommentsStatus { initial, loading, loaded, failure }

class ReportCommentsState extends Equatable {
  const ReportCommentsState({
    this.status = ReportCommentsStatus.initial,
    this.report,
    this.comments = const <ReportComment>[],
    this.replyingTo,
    this.isPosting = false,
    this.errorMessage,
  });

  final ReportCommentsStatus status;

  final Report? report;

  final List<ReportComment> comments;

  /// The comment being replied to (null = a top-level comment).
  final ReportComment? replyingTo;

  final bool isPosting;

  /// The last failure message (shown as a toast by the UI).
  final String? errorMessage;

  ReportCommentsState copyWith({
    ReportCommentsStatus? status,
    Report? report,
    List<ReportComment>? comments,
    ReportComment? replyingTo,
    bool clearReplyingTo = false,
    bool? isPosting,
    String? errorMessage,
  }) {
    return ReportCommentsState(
      status: status ?? this.status,
      report: report ?? this.report,
      comments: comments ?? this.comments,
      replyingTo: clearReplyingTo ? null : (replyingTo ?? this.replyingTo),
      isPosting: isPosting ?? this.isPosting,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    report,
    comments,
    replyingTo,
    isPosting,
    errorMessage,
  ];
}
