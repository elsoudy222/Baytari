/// One comment bubble (Figma's "Home - comment" screen).
///
/// Layout: avatar on the left, the bubble on the right. The
/// bubble colour comes from the commenter's status (yellow =
/// Sighted, mint = Rescued, peach = Couldn't find, theme
/// surface = no status) and the status label under the name
/// uses the matching colour. Under the bubble: time + Like /
/// unlike + Reply + the like count with a thumbs-up (shown only
/// when someone liked it).
///
/// Replies are rendered by the parent list, indented under
/// their parent — this widget renders exactly one comment.
library;

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/report_comment.dart';
import '../utils/report_display.dart';

class CommentBubble extends StatelessWidget {
  const CommentBubble({
    required this.comment,
    required this.onLikePressed,
    required this.onReplyPressed,
    super.key,
  });

  final ReportComment comment;

  final VoidCallback onLikePressed;

  final VoidCallback onReplyPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 20,
            backgroundImage: comment.author.avatarUrl != null
                ? NetworkImage(comment.author.avatarUrl!)
                : null,
            child: comment.author.avatarUrl == null
                ? const Icon(Icons.person_outlined, size: 20)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color:
                        commentBubbleColor(comment.status) ??
                        scheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        comment.author.displayName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (comment.status != null) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          reportStatusLabel(l10n, comment.status!),
                          style: TextStyle(
                            color: commentStatusLabelColor(
                              comment.status!,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(comment.body),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    Text(
                      relativeTime(comment.createdAt, l10n.localeName),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: onLikePressed,
                      child: Text(
                        comment.likedByMe ? l10n.unlike : l10n.like,
                        style: TextStyle(
                          color: comment.likedByMe
                              ? scheme.error
                              : scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: onReplyPressed,
                      child: Text(
                        l10n.reply,
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (comment.likeCount > 0) ...<Widget>[
                      const SizedBox(width: 20),
                      Text('${comment.likeCount}'),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.thumb_up,
                        size: 16,
                        color: scheme.primary,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
