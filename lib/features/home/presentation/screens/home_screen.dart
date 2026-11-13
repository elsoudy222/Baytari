/// The Home feed screen (Figma's "Home - community member").
/// This replaces the M0 placeholder that used to live here.
///
/// Top to bottom, like Figma:
/// - header: the user's avatar + "Welcome, {first name}" (guests
///   see "Welcome" with no name) + chat and bell icons
///   (coming soon for now)
/// - search bar (mic = coming soon, sliders = filter sheet)
/// - filter chips: All / Stray / Lost / Adoption (server-side)
/// - the "Report an Animal" mint card
/// - the feed: report posts, newest first, with pull-to-refresh
///
/// The [HomeFeedCubit] is created here from GetIt and loads the
/// feed once. Errors arrive as [HomeFeedState.errorMessage] and
/// are shown as toasts by the [BlocListener] — the list itself
/// keeps whatever it had, so a failed refresh never blanks the
/// feed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/dialogs/app_toast.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/entities/report_enums.dart';
import '../cubit/home_feed_cubit.dart';
import '../cubit/home_feed_state.dart';
import '../utils/report_display.dart';
import '../widgets/report_animal_card.dart';
import '../widgets/report_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeFeedCubit>(
      create: (_) => sl<HomeFeedCubit>()..loadReports(),
      child: const _HomeFeedView(),
    );
  }
}

class _HomeFeedView extends StatelessWidget {
  const _HomeFeedView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<HomeFeedCubit, HomeFeedState>(
      listenWhen: (previous, current) =>
          current.errorMessage != null &&
          current.errorMessage != previous.errorMessage,
      listener: (context, state) {
        showAppToast(context, l10n.authError, isError: true);
      },
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () => context.read<HomeFeedCubit>().refresh(),
          child: CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: _FeedHeader(
                    onChatPressed: () =>
                        showAppToast(context, l10n.comingSoon),
                    onBellPressed: () =>
                        showAppToast(context, l10n.comingSoon),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _SearchBar(
                  onChanged: (query) => context
                      .read<HomeFeedCubit>()
                      .setSearchQuery(query),
                  onMicPressed: () =>
                      showAppToast(context, l10n.comingSoon),
                  onFilterPressed: () =>
                      _openFilterSheet(context),
                ),
              ),
              const SliverToBoxAdapter(child: _CategoryChips()),
              SliverToBoxAdapter(
                child: ReportAnimalCard(
                  onReportPressed: () {
                    // After creating a report the feed refreshes
                    // so the new post appears at the top.
                    context.push(AppRoutes.createReport).then(
                      (_) {
                        if (context.mounted) {
                          context.read<HomeFeedCubit>().refresh();
                        }
                      },
                    );
                  },
                ),
              ),
              const _FeedSlivers(),
            ],
          ),
        ),
      ),
    );
  }

  /// The filter sheet: priority + animal type chips that combine
  /// with the category chips (all client-side — no reload).
  Future<void> _openFilterSheet(BuildContext context) {
    final HomeFeedCubit cubit = context.read<HomeFeedCubit>();
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return _FilterSheet(
          initialPriority: cubit.state.priorityFilter,
          initialAnimal: cubit.state.animalFilter,
          onApply: (priority, animal) {
            cubit.setFilters(priority: priority, animal: animal);
            Navigator.of(sheetContext).pop();
          },
          onClear: () {
            cubit.setFilters(priority: null, animal: null);
            Navigator.of(sheetContext).pop();
          },
        );
      },
    );
  }
}

/// Avatar + "Welcome, {first name}" + chat and bell icons.
/// The avatar comes from the signed-in user's profile
/// (`avatar_url`); guests get a person icon and no name.
class _FeedHeader extends StatelessWidget {
  const _FeedHeader({
    required this.onChatPressed,
    required this.onBellPressed,
  });

  final VoidCallback onChatPressed;
  final VoidCallback onBellPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: <Widget>[
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              final String? avatarUrl = authState.profile?.avatarUrl;
              final String firstName =
                  authState.profile?.fullName.split(' ').first ?? '';
              return Row(
                children: <Widget>[
                  // The avatar is the stopgap path to the profile:
                  // Figma reaches Profile/Settings from its side
                  // Menu, which is not built yet, so tapping the
                  // avatar opens the profile for signed-in users
                  // and the login screen for guests (a guest has no
                  // profile to show).
                  GestureDetector(
                    onTap: () {
                      if (authState.status == AuthStatus.authenticated) {
                        context.go(AppRoutes.profile);
                      } else {
                        context.go(AppRoutes.login);
                      }
                    },
                    child: CircleAvatar(
                      radius: 24,
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? const Icon(Icons.person_outlined)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.homeWelcome,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (firstName.isNotEmpty)
                        Text(
                          firstName,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
          const Spacer(),
          IconButton(
            onPressed: onChatPressed,
            icon: Icon(Icons.chat_bubble_outline, color: scheme.primary),
          ),
          IconButton(
            onPressed: onBellPressed,
            icon: Icon(
              Icons.notifications_outlined,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Search field + mic + filter buttons (Figma's search row).
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.onChanged,
    required this.onMicPressed,
    required this.onFilterPressed,
  });

  final ValueChanged<String> onChanged;
  final VoidCallback onMicPressed;
  final VoidCallback onFilterPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: onMicPressed,
                  icon: Icon(Icons.mic_outlined, color: scheme.primary),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onFilterPressed,
            icon: Icon(Icons.tune, color: scheme.primary),
            style: IconButton.styleFrom(
              backgroundColor: scheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// All / Stray / Lost / Adoption. The selected chip is filled
/// primary; the others are white with a border. Tapping a chip
/// reloads the feed (the category filter is server-side).
class _CategoryChips extends StatelessWidget {
  const _CategoryChips();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<HomeFeedCubit, HomeFeedState>(
      builder: (context, state) {
        final HomeFeedCubit cubit = context.read<HomeFeedCubit>();
        final List<(String, ReportCategory?)> chips = <(String, ReportCategory?)>[
          (l10n.filterAll, null),
          (l10n.filterStray, ReportCategory.stray),
          (l10n.filterLost, ReportCategory.lost),
          (l10n.filterAdoption, ReportCategory.adoption),
        ];
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: <Widget>[
              for (final (String label, ReportCategory? category) in chips)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: state.category == category,
                    onSelected: (_) => cubit.selectCategory(category),
                    selectedColor:
                        Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: state.category == category
                          ? Theme.of(context).colorScheme.onPrimary
                          : AppColors.heading,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// The feed body, by state: a spinner on first load, an error
/// with Retry, an empty state with the Report CTA, or the list
/// of posts. A failed refresh keeps the old list (the error
/// arrives as a toast from the listener above).
class _FeedSlivers extends StatelessWidget {
  const _FeedSlivers();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<HomeFeedCubit, HomeFeedState>(
      builder: (context, state) {
        switch (state.status) {
          case HomeFeedStatus.loading when state.reports.isEmpty:
            return const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            );
          case HomeFeedStatus.failure when state.reports.isEmpty:
            return SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(l10n.errorTitle),
                    const SizedBox(height: 12),
                    AppButton(
                      label: l10n.retry,
                      onPressed: () =>
                          context.read<HomeFeedCubit>().refresh(),
                    ),
                  ],
                ),
              ),
            );
          case HomeFeedStatus.loaded when state.reports.isEmpty:
            return SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.pets_outlined, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noReports,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.noReportsMessage,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: l10n.reportAnimalButton,
                        onPressed: () =>
                            context.push(AppRoutes.createReport),
                      ),
                    ],
                  ),
                ),
              ),
            );
          default:
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final report = state.reports[index];
                  return ReportCard(
                    report: report,
                    onHelpPressed: () => context
                        .read<HomeFeedCubit>()
                        .toggleHelper(report.id),
                    onCommentPressed: () => context.push(
                      AppRoutes.reportComments(report.id),
                    ),
                    onSendPressed: () =>
                        showAppToast(context, l10n.shareComingSoon),
                    onStatusSelected: (status) => context
                        .read<HomeFeedCubit>()
                        .setStatus(report.id, status),
                    onMorePressed: () =>
                        showAppToast(context, l10n.comingSoon),
                  );
                },
                childCount: state.reports.length,
              ),
            );
        }
      },
    );
  }
}

/// The filter sheet: Priority chips (All + 4) and Animal chips
/// (All + 3). The choices are local until Apply — cancelling
/// the sheet changes nothing.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.initialPriority,
    required this.initialAnimal,
    required this.onApply,
    required this.onClear,
  });

  final ReportPriority? initialPriority;
  final AnimalType? initialAnimal;
  final void Function(ReportPriority?, AnimalType?) onApply;
  final VoidCallback onClear;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  ReportPriority? _priority;
  AnimalType? _animal;

  @override
  void initState() {
    super.initState();
    _priority = widget.initialPriority;
    _animal = widget.initialAnimal;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.filterTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.filterPriority,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: <Widget>[
                _SheetChip(
                  label: l10n.filterAll,
                  selected: _priority == null,
                  onTap: () => setState(() => _priority = null),
                ),
                for (final ReportPriority priority in ReportPriority.values)
                  _SheetChip(
                    label: reportPriorityLabel(l10n, priority),
                    selected: _priority == priority,
                    onTap: () => setState(() => _priority = priority),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.filterAnimal,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: <Widget>[
                _SheetChip(
                  label: l10n.filterAll,
                  selected: _animal == null,
                  onTap: () => setState(() => _animal = null),
                ),
                for (final AnimalType animal in AnimalType.values)
                  _SheetChip(
                    label: animalTypeLabel(l10n, animal),
                    selected: _animal == animal,
                    onTap: () => setState(() => _animal = animal),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onClear,
                    child: Text(l10n.clearFilters),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        widget.onApply(_priority, _animal),
                    child: Text(l10n.applyFilters),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SheetChip extends StatelessWidget {
  const _SheetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: scheme.primary,
      labelStyle: TextStyle(
        color: selected ? scheme.onPrimary : AppColors.heading,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(color: scheme.outlineVariant),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
