/// Unit tests for [HomeFeedCubit].
///
/// The Cubit is built with the real use cases and the fake
/// repository, so these tests prove the state machine and the
/// filtering rules — without Supabase, without widgets.
/// `bloc_test` is deliberately not used (no extra dependency):
/// the Cubit is driven directly and its `state` is asserted.
library;

import 'package:baytari/core/errors/failures.dart';
import 'package:baytari/features/home/domain/entities/report.dart';
import 'package:baytari/features/home/domain/entities/report_enums.dart';
import 'package:baytari/features/home/domain/usecases/get_reports_usecase.dart';
import 'package:baytari/features/home/domain/usecases/set_report_status_usecase.dart';
import 'package:baytari/features/home/domain/usecases/toggle_helper_usecase.dart';
import 'package:baytari/features/home/presentation/cubit/home_feed_cubit.dart';
import 'package:baytari/features/home/presentation/cubit/home_feed_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_home_repository.dart';

HomeFeedCubit buildCubit(FakeHomeRepository repository) {
  return HomeFeedCubit(
    getReportsUseCase: GetReportsUseCase(repository),
    toggleHelperUseCase: ToggleHelperUseCase(repository),
    setReportStatusUseCase: SetReportStatusUseCase(repository),
  );
}

void main() {
  late FakeHomeRepository repository;
  late HomeFeedCubit cubit;

  setUp(() {
    repository = FakeHomeRepository()
      ..reportsToReturn = <Report>[
        testReport(id: 'r1', description: 'Brown dog near the Nile'),
        testReport(
          id: 'r2',
          category: ReportCategory.lost,
          priority: ReportPriority.mid,
          animalType: AnimalType.cat,
          description: 'Lost white cat in Alexandria',
          locationText: 'Corniche Road, Alexandria',
        ),
        testReport(
          id: 'r3',
          category: ReportCategory.adoption,
          priority: ReportPriority.low,
          description: 'Puppies looking for a home',
        ),
      ];
    cubit = buildCubit(repository);
  });

  tearDown(() async {
    await cubit.close();
  });

  test('loadReports loads newest-first and reaches loaded', () async {
    await cubit.loadReports();
    expect(cubit.state.status, HomeFeedStatus.loaded);
    expect(cubit.state.reports.map((r) => r.id), <String>['r1', 'r2', 'r3']);
    expect(repository.calls, contains('getReports'));
  });

  test('loadReports failure reaches failure with the message', () async {
    repository.failure = const ServerFailure('boom');
    await cubit.loadReports();
    expect(cubit.state.status, HomeFeedStatus.failure);
    expect(cubit.state.errorMessage, 'boom');
  });

  test('selectCategory reloads server-side with that category', () async {
    await cubit.selectCategory(ReportCategory.lost);
    expect(repository.lastRequestedCategory, ReportCategory.lost);
    expect(cubit.state.category, ReportCategory.lost);
    await cubit.selectCategory(null);
    expect(repository.lastRequestedCategory, isNull);
    expect(cubit.state.category, isNull);
  });

  test('search matches description, location and author name', () async {
    await cubit.loadReports();
    cubit.setSearchQuery('alexandria');
    expect(cubit.state.reports.map((r) => r.id), <String>['r2']);
    cubit.setSearchQuery('MERHAN');
    expect(cubit.state.reports.length, 3);
    cubit.setSearchQuery('no-such-thing');
    expect(cubit.state.reports, isEmpty);
    cubit.setSearchQuery('');
    expect(cubit.state.reports.length, 3);
  });

  test('priority and animal filters combine with the search', () async {
    await cubit.loadReports();
    cubit.setFilters(priority: ReportPriority.low, animal: null);
    expect(cubit.state.reports.map((r) => r.id), <String>['r3']);
    cubit.setFilters(priority: null, animal: AnimalType.cat);
    expect(cubit.state.reports.map((r) => r.id), <String>['r2']);
    cubit.setFilters(priority: ReportPriority.high, animal: AnimalType.cat);
    expect(cubit.state.reports, isEmpty);
    cubit.setFilters(priority: null, animal: null);
    expect(cubit.state.reports.length, 3);
  });

  test('toggleHelper flips the button and moves the count', () async {
    await cubit.loadReports();
    await cubit.toggleHelper('r1');
    final report = cubit.state.reports.firstWhere((r) => r.id == 'r1');
    expect(report.isHelper, isTrue);
    expect(report.helpersCount, 6);
    await cubit.toggleHelper('r1');
    final again = cubit.state.reports.firstWhere((r) => r.id == 'r1');
    expect(again.isHelper, isFalse);
    expect(again.helpersCount, 5);
  });

  test('toggleHelper failure leaves the list untouched', () async {
    await cubit.loadReports();
    repository.failure = const ServerFailure('boom');
    await cubit.toggleHelper('r1');
    final report = cubit.state.reports.firstWhere((r) => r.id == 'r1');
    expect(report.isHelper, isFalse);
    expect(report.helpersCount, 5);
    expect(cubit.state.errorMessage, 'boom');
  });

  test('setStatus highlights the selected chip', () async {
    await cubit.loadReports();
    await cubit.setStatus('r1', ReportStatus.rescued);
    final report = cubit.state.reports.firstWhere((r) => r.id == 'r1');
    expect(report.myStatus, ReportStatus.rescued);
  });
}
