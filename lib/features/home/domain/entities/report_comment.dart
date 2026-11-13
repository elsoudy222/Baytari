/// A comment on a report — one row of `report_comments`
/// (migration 20261107000003).
///
/// [parentId] is null for a top-level comment and set for a reply;
/// the UI renders exactly one nested level (replies to replies
/// are not allowed). [status] is the commenter's status when they
/// wrote it — it decides the bubble colour and the label under
/// the name (yellow = Sighted, mint = Rescued, peach =
/// Couldn't find, white = no status). [likeCount] is the row
/// count of `comment_likes` (no counter column is stored), and
/// [likedByMe] tells the UI whether to show "Like" or "unlike".
/// [replies] is filled by the data layer (or by the Cubit) from
/// the flat list — the table itself stores only [parentId].
library;

import 'package:equatable/equatable.dart';

import 'report_author.dart';
import 'report_enums.dart';

class ReportComment extends Equatable {
  const ReportComment({
    required this.id,
    required this.reportId,
    required this.author,
    required this.body,
    this.parentId,
    this.status,
    this.likeCount = 0,
    this.likedByMe = false,
    this.replies = const <ReportComment>[],
    this.createdAt,
  });

  final String id;

  final String reportId;

  /// Who wrote the comment (name + avatar for the bubble header).
  final ReportAuthor author;

  /// The comment text.
  final String body;

  /// Null = top-level comment; otherwise the id of the comment
  /// this one replies to.
  final String? parentId;

  /// The commenter's status when they wrote it (null = no status,
  /// plain white bubble in Figma).
  final ReportStatus? status;

  /// How many users liked this comment.
  final int likeCount;

  /// Whether the current user liked this comment.
  final bool likedByMe;

  /// Replies to this comment (only filled for top-level comments).
  final List<ReportComment> replies;

  final DateTime? createdAt;

  ReportComment copyWith({
    String? id,
    String? reportId,
    ReportAuthor? author,
    String? body,
    String? parentId,
    ReportStatus? status,
    int? likeCount,
    bool? likedByMe,
    List<ReportComment>? replies,
    DateTime? createdAt,
  }) {
    return ReportComment(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      author: author ?? this.author,
      body: body ?? this.body,
      parentId: parentId ?? this.parentId,
      status: status ?? this.status,
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
      replies: replies ?? this.replies,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    reportId,
    author,
    body,
    parentId,
    status,
    likeCount,
    likedByMe,
    replies,
    createdAt,
  ];
}
