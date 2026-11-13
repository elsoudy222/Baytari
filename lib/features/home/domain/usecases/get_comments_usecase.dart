/// Use case: load the comments of a report (oldest first, one
/// level of replies attached to their parents).
library;

import '../../../../core/errors/result.dart';
import '../entities/report_comment.dart';
import '../repositories/home_repository.dart';

class GetCommentsUseCase {
  const GetCommentsUseCase(this._repository);

  final HomeRepository _repository;

  Future<Result<List<ReportComment>>> call(String reportId) {
    return _repository.getComments(reportId);
  }
}
