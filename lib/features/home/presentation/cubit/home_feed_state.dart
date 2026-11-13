/// State of the Home feed.
///
/// The Cubit keeps TWO lists: [allReports] (everything the
/// server returned for the selected category) and [reports] (the
/// visible list after the client-side filters). The split exists
/// because the text search and the priority/animal filters run
/// client-side over the loaded reports — re-querying the server
/// on every keystroke would be wasteful, and the feed is small
/// enough to filter in memory.
library;

import 'package:equatable/equatable.dart';

import '../../domain/entities/report.dart';
import '../../domain/entities/report_enums.dart';

enum HomeFeedStatus { initial, loading, loaded, failure }

class HomeFeedState extends Equatable {
  const HomeFeedState({
    this.status = HomeFeedStatus.initial,
    this.allReports = const <Report>[],
    this.reports = const <Report>[],
    this.category,
    this.searchQuery = '',
    this.priorityFilter,
    this.animalFilter,
    this.errorMessage,
  });

  final HomeFeedStatus status;

  /// Everything loaded from the server (for the selected
  /// category). Never shown directly — [reports] is the
  /// filtered view of this list.
  final List<Report> allReports;

  /// The reports actually shown, after search + priority +
  /// animal filters.
  final List<Report> reports;

  /// The selected category chip (null = "All"). This one filters
  /// server-side: changing it reloads from the server.
  final ReportCategory? category;

  /// The search box text (matched against description, location
  /// and author name, client-side).
  final String searchQuery;

  /// The priority chosen in the filter sheet (null = any).
  final ReportPriority? priorityFilter;

  /// The animal type chosen in the filter sheet (null = any).
  final AnimalType? animalFilter;

  /// The last failure message (shown as a toast by the UI).
  final String? errorMessage;

  HomeFeedState copyWith({
    HomeFeedStatus? status,
    List<Report>? allReports,
    List<Report>? reports,
    ReportCategory? category,
    bool clearCategory = false,
    String? searchQuery,
    ReportPriority? priorityFilter,
    bool clearPriorityFilter = false,
    AnimalType? animalFilter,
    bool clearAnimalFilter = false,
    String? errorMessage,
  }) {
    return HomeFeedState(
      status: status ?? this.status,
      allReports: allReports ?? this.allReports,
      reports: reports ?? this.reports,
      category: clearCategory ? null : (category ?? this.category),
      searchQuery: searchQuery ?? this.searchQuery,
      priorityFilter: clearPriorityFilter
          ? null
          : (priorityFilter ?? this.priorityFilter),
      animalFilter: clearAnimalFilter
          ? null
          : (animalFilter ?? this.animalFilter),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    allReports,
    reports,
    category,
    searchQuery,
    priorityFilter,
    animalFilter,
    errorMessage,
  ];
}
