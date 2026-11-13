/// Use case: set the current user's status on a report (the
/// "Share Status Update" chips). Tapping a chip upserts the
/// user's row in `report_statuses`; tapping another chip replaces
/// it.
library;

import '../../../../core/errors/result.dart';
import '../entities/report_enums.dart';
import '../repositories/home_repository.dart';

class SetReportStatusUseCase {
  const SetReportStatusUseCase(this._repository);

  final HomeRepository _repository;

  Future<Result<ReportStatus>> call(
    String reportId,
    ReportStatus status,
  ) {
    return _repository.setReportStatus(reportId, status);
  }
}
