/// Use case: load one report with its photos, counts and the
/// current user's status/helper state (the comments screen
/// header).
library;

import '../../../../core/errors/result.dart';
import '../entities/report.dart';
import '../repositories/home_repository.dart';

class GetReportUseCase {
  const GetReportUseCase(this._repository);

  final HomeRepository _repository;

  Future<Result<Report>> call(String reportId) {
    return _repository.getReport(reportId);
  }
}
