/// Cubit of the Home feed.
///
/// State machine: initial -> loading -> loaded / failure.
/// Every action goes through a use case and returns a
/// [Result]; the Cubit only translates that into state.
///
/// Filtering, in two places on purpose:
/// - Category (All / Stray / Lost / Adoption) filters
///   SERVER-side: changing it reloads from the server.
/// - Search text + priority/animal (filter sheet) filter
///   CLIENT-side over the loaded reports ([_applyFilters]).
///
/// Help and status actions update ONE report in place (no full
/// reload) and only re-apply the client-side filters — the feed
/// must not jump back to the top after a tap.
library;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/entities/report.dart';
import '../../domain/entities/report_enums.dart';
import '../../domain/usecases/get_reports_usecase.dart';
import '../../domain/usecases/set_report_status_usecase.dart';
import '../../domain/usecases/toggle_helper_usecase.dart';
import 'home_feed_state.dart';

class HomeFeedCubit extends Cubit<HomeFeedState> {
  HomeFeedCubit({
    required this._getReportsUseCase,
    required this._toggleHelperUseCase,
    required this._setReportStatusUseCase,
  }) : super(const HomeFeedState());

  final GetReportsUseCase _getReportsUseCase;
  final ToggleHelperUseCase _toggleHelperUseCase;
  final SetReportStatusUseCase _setReportStatusUseCase;

  /// Loads the feed for the currently selected category.
  /// Keeps the search/filters the user already set.
  Future<void> loadReports() async {
    emit(state.copyWith(status: HomeFeedStatus.loading));
    final Result<List<Report>> result = await _getReportsUseCase(
      category: state.category,
    );
    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            status: HomeFeedStatus.loaded,
            allReports: value,
            reports: _applyFilters(
              value,
              state.searchQuery,
              state.priorityFilter,
              state.animalFilter,
            ),
            errorMessage: null,
          ),
        );
      case FailureResult(:final failure):
        emit(
          state.copyWith(
            status: HomeFeedStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }

  /// Pull-to-refresh: same load, same filters.
  Future<void> refresh() => loadReports();

  /// A category chip was tapped (null = "All"). The category is
  /// set first, then the feed reloads — the category filter is
  /// server-side, so a tap is always a network reload.
  Future<void> selectCategory(ReportCategory? category) async {
    emit(
      state.copyWith(
        category: category,
        clearCategory: category == null,
      ),
    );
    await loadReports();
  }

  /// The search box changed. Client-side only: no network call,
  /// the visible list is recomputed from the loaded reports.
  void setSearchQuery(String query) {
    emit(
      state.copyWith(
        searchQuery: query,
        reports: _applyFilters(
          state.allReports,
          query,
          state.priorityFilter,
          state.animalFilter,
        ),
      ),
    );
  }

  /// The filter sheet was applied. Client-side only.
  void setFilters({ReportPriority? priority, AnimalType? animal}) {
    emit(
      state.copyWith(
        priorityFilter: priority,
        clearPriorityFilter: priority == null,
        animalFilter: animal,
        clearAnimalFilter: animal == null,
        reports: _applyFilters(
          state.allReports,
          state.searchQuery,
          priority,
          animal,
        ),
      ),
    );
  }

  /// "Help" on a post: toggles the current user as a helper.
  /// On success the one report is updated in place (count +-1,
  /// button state flips); on failure the list is untouched and
  /// the UI shows the error as a toast.
  Future<void> toggleHelper(String reportId) async {
    final Result<bool> result = await _toggleHelperUseCase(reportId);
    switch (result) {
      case Success(:final value):
        _updateReport(
          reportId,
          (report) => report.copyWith(
            isHelper: value,
            helpersCount: report.helpersCount + (value ? 1 : -1),
          ),
        );
      case FailureResult(:final failure):
        emit(state.copyWith(errorMessage: failure.message));
    }
  }

  /// A "Share Status Update" chip was tapped: sets the user's
  /// status on the report and highlights the chip.
  Future<void> setStatus(String reportId, ReportStatus status) async {
    final Result<ReportStatus> result = await _setReportStatusUseCase(
      reportId,
      status,
    );
    switch (result) {
      case Success(:final value):
        _updateReport(
          reportId,
          (report) => report.copyWith(myStatus: value),
        );
      case FailureResult(:final failure):
        emit(state.copyWith(errorMessage: failure.message));
    }
  }

  /// Replaces one report in [allReports] (by id) and recomputes
  /// the visible list. Used by [toggleHelper] and [setStatus].
  void _updateReport(
    String reportId,
    Report Function(Report report) update,
  ) {
    final List<Report> updated = state.allReports
        .map(
          (report) => report.id == reportId ? update(report) : report,
        )
        .toList();
    emit(
      state.copyWith(
        allReports: updated,
        reports: _applyFilters(
          updated,
          state.searchQuery,
          state.priorityFilter,
          state.animalFilter,
        ),
        errorMessage: null,
      ),
    );
  }

  /// The client-side filters, applied in order: priority, animal,
  /// then search text (description, location or author name,
  /// case-insensitive). An empty query matches everything.
  static List<Report> _applyFilters(
    List<Report> reports,
    String query,
    ReportPriority? priority,
    AnimalType? animal,
  ) {
    final String needle = query.trim().toLowerCase();
    return reports.where((report) {
      if (priority != null && report.priority != priority) {
        return false;
      }
      if (animal != null && report.animalType != animal) {
        return false;
      }
      if (needle.isEmpty) return true;
      return report.description.toLowerCase().contains(needle) ||
          (report.locationText?.toLowerCase().contains(needle) ??
              false) ||
          report.author.displayName.toLowerCase().contains(needle);
    }).toList();
  }
}
