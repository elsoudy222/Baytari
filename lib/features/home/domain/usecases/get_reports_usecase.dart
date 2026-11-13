/// Use case: load the Home feed (newest first).
///
/// One action, one repository call. The [category] filter is
/// applied server-side; the text search is applied client-side
/// by the Cubit over the loaded reports.
library;

import '../../../../core/errors/result.dart';
import '../entities/report.dart';
import '../entities/report_enums.dart';
import '../repositories/home_repository.dart';

class GetReportsUseCase {
  const GetReportsUseCase(this._repository);

  final HomeRepository _repository;

  Future<Result<List<Report>>> call({ReportCategory? category}) {
    return _repository.getReports(category: category);
  }
}
