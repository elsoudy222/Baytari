/// Data model for a comment row — the JSON <-> [ReportComment]
/// converter.
///
/// The data source asks Supabase for comments with the author
/// embedded (`author:profiles!author_id(...)`) and the likes
/// embedded (`comment_likes(user_id)`), so one query carries
/// everything a bubble needs. The like count is the embedded
/// list's length; [ReportComment.likedByMe] is the current
/// user's presence in it.
///
/// The flat list is grouped into a tree by [groupReplies]: the
/// table stores only `parent_id`, the UI renders one nested
/// level, so top-level comments carry their replies in
/// [ReportComment.replies].
library;

import '../../domain/entities/report_author.dart';
import '../../domain/entities/report_comment.dart';
import '../../domain/entities/report_enums.dart';

class ReportCommentModel extends ReportComment {
  const ReportCommentModel({
    required super.id,
    required super.reportId,
    required super.author,
    required super.body,
    super.parentId,
    super.status,
    super.likeCount,
    super.likedByMe,
    super.replies,
    super.createdAt,
  });

  /// Builds a model from one row of `report_comments` with its
  /// embedded author and likes. [currentUserId] (null for guests)
  /// decides [ReportComment.likedByMe].
  factory ReportCommentModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final Map<String, dynamic>? authorJson =
        json['author'] as Map<String, dynamic>?;
    final List<dynamic> likeRows =
        json['comment_likes'] as List<dynamic>? ?? <dynamic>[];
    return ReportCommentModel(
      id: json['id'] as String? ?? '',
      reportId: json['report_id'] as String? ?? '',
      author: ReportAuthor(
        id: authorJson?['id'] as String? ?? '',
        fullName: authorJson?['full_name'] as String? ?? '',
        username: authorJson?['username'] as String?,
        avatarUrl: authorJson?['avatar_url'] as String?,
      ),
      body: json['body'] as String? ?? '',
      parentId: json['parent_id'] as String?,
      status: ReportStatus.fromString(json['status'] as String?),
      likeCount: likeRows.length,
      likedByMe:
          currentUserId != null &&
          likeRows.any(
            (row) =>
                (row as Map<String, dynamic>)['user_id'] ==
                currentUserId,
          ),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String),
    );
  }

  /// Groups a flat list (oldest first) into top-level comments
  /// with their replies attached. A reply whose parent is missing
  /// (deleted) is dropped — it has nowhere to render.
  static List<ReportComment> groupReplies(
    List<ReportCommentModel> flat,
  ) {
    final Map<String, ReportComment> topLevel =
        <String, ReportComment>{};
    final Map<String, List<ReportComment>> repliesByParent =
        <String, List<ReportComment>>{};
    for (final ReportCommentModel comment in flat) {
      final String? parentId = comment.parentId;
      if (parentId == null) {
        topLevel[comment.id] = comment;
      } else {
        (repliesByParent[parentId] ??= <ReportComment>[]).add(comment);
      }
    }
    return topLevel.values
        .map(
          (comment) => comment.copyWith(
            replies: repliesByParent[comment.id] ?? const <ReportComment>[],
          ),
        )
        .toList();
  }
}
