/// The comments screen of a report (Figma's "Home - comment").
/// Route: /home/report/:id/comments.
///
/// Top to bottom, like Figma:
/// - header: "{author} and {N} Helpers" + chevron + star icon
///   (the star is the report's "Help" — filled when the user is
///   helping)
/// - the report's "Share Status Update" chips (the selected one
///   is highlighted; tapping one sets the user's status)
/// - the comments, oldest first, one level of replies indented
///   under their parent
/// - the composer at the bottom: "Write a comment ..." + send
///   button, with a "Replying to {name}" indicator (with cancel)
///   while replying.
///
/// The [ReportCommentsCubit] is created here from GetIt and
/// loads the report + comments once.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/dialogs/app_toast.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/report_comment.dart';
import '../../domain/entities/report_enums.dart';
import '../cubit/report_comments_cubit.dart';
import '../cubit/report_comments_state.dart';
import '../utils/report_display.dart';
import '../widgets/comment_bubble.dart';

class ReportCommentsScreen extends StatelessWidget {
  const ReportCommentsScreen({required this.reportId, super.key});

  final String reportId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReportCommentsCubit>(
      create: (_) => sl<ReportCommentsCubit>()..load(reportId),
      child: _ReportCommentsView(reportId: reportId),
    );
  }
}

class _ReportCommentsView extends StatefulWidget {
  const _ReportCommentsView({required this.reportId});

  /// The report id, kept so the Retry button can reload after a
  /// failed load (the Cubit itself does not remember it).
  final String reportId;

  @override
  State<_ReportCommentsView> createState() => _ReportCommentsViewState();
}

class _ReportCommentsViewState extends State<_ReportCommentsView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<ReportCommentsCubit, ReportCommentsState>(
      listenWhen: (previous, current) =>
          current.errorMessage != null &&
          current.errorMessage != previous.errorMessage,
      listener: (context, state) {
        showAppToast(context, l10n.authError, isError: true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<ReportCommentsCubit, ReportCommentsState>(
            builder: (context, state) {
              final report = state.report;
              if (report == null) return Text(l10n.commentsTitle);
              // "Merhan Assem and 18 Helpers" — the author plus
              // the helpers count (Figma's header).
              return Text(
                l10n.commentsHeader(
                  report.author.displayName,
                  report.helpersCount,
                ),
              );
            },
          ),
        ),
        body: BlocBuilder<ReportCommentsCubit, ReportCommentsState>(
          builder: (context, state) {
            switch (state.status) {
              case ReportCommentsStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case ReportCommentsStatus.failure:
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(l10n.errorTitle),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => context
                            .read<ReportCommentsCubit>()
                            .load(widget.reportId),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                );
              case ReportCommentsStatus.initial:
              case ReportCommentsStatus.loaded:
                return Column(
                  children: <Widget>[
                    if (state.report != null)
                      _StatusChipsRow(reportId: state.report!.id),
                    Expanded(
                      child: state.comments.isEmpty
                          ? Center(
                              child: Text(l10n.noCommentsYet),
                            )
                          : ListView.builder(
                              itemCount: state.comments.length,
                              itemBuilder: (context, index) {
                                final ReportComment comment =
                                    state.comments[index];
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: <Widget>[
                                    CommentBubble(
                                      comment: comment,
                                      onLikePressed: () => context
                                          .read<ReportCommentsCubit>()
                                          .toggleLike(comment.id),
                                      onReplyPressed: () => context
                                          .read<ReportCommentsCubit>()
                                          .setReplyingTo(comment),
                                    ),
                                    // One level of replies, indented
                                    // under their parent (Figma).
                                    for (final ReportComment reply
                                        in comment.replies)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 40,
                                        ),
                                        child: CommentBubble(
                                          comment: reply,
                                          onLikePressed: () => context
                                              .read<ReportCommentsCubit>()
                                              .toggleLike(reply.id),
                                          onReplyPressed: () => context
                                              .read<ReportCommentsCubit>()
                                              .setReplyingTo(reply),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                    ),
                    _Composer(
                      controller: _controller,
                      isPosting: state.isPosting,
                      replyingTo: state.replyingTo,
                      onCancelReply: () => context
                          .read<ReportCommentsCubit>()
                          .setReplyingTo(null),
                      onSend: () {
                        final String text = _controller.text;
                        if (text.trim().isEmpty) return;
                        context
                            .read<ReportCommentsCubit>()
                            .postComment(text);
                        _controller.clear();
                      },
                    ),
                  ],
                );
            }
          },
        ),
      ),
    );
  }
}

/// The report's "Share Status Update" chips above the comments.
/// Same chips as on the post card; the selected one (the user's
/// current status) is filled primary.
class _StatusChipsRow extends StatelessWidget {
  const _StatusChipsRow({required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<ReportCommentsCubit, ReportCommentsState>(
      builder: (context, state) {
        final report = state.report;
        if (report == null) return const SizedBox.shrink();
        final ColorScheme scheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.shareStatusUpdate,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final ReportStatus status
                      in ReportStatus.chipsFor(report.category))
                    ChoiceChip(
                      label: Text(reportStatusLabel(l10n, status)),
                      selected: report.myStatus == status,
                      onSelected: (_) => context
                          .read<ReportCommentsCubit>()
                          .setStatus(status),
                      selectedColor: scheme.primary,
                      backgroundColor: reportStatusChipColor(status),
                      labelStyle: TextStyle(
                        color: report.myStatus == status
                            ? scheme.onPrimary
                            : AppColors.heading,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                ],
              ),
              const Divider(height: 24),
            ],
          ),
        );
      },
    );
  }
}

/// The bottom composer: "Write a comment ..." + send button.
/// While replying, a "Replying to {name}" line with a cancel X
/// sits above the field (Figma shows the reply target inline).
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isPosting,
    required this.replyingTo,
    required this.onCancelReply,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isPosting;
  final ReportComment? replyingTo;
  final VoidCallback onCancelReply;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            top: BorderSide(color: scheme.outlineVariant),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (replyingTo != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        l10n.replyingTo(
                          replyingTo!.author.displayName,
                        ),
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onCancelReply,
                      child: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
              ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: l10n.writeComment,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: isPosting ? null : onSend,
                  icon: isPosting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
