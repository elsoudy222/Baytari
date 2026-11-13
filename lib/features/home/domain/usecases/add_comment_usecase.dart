/// Use case: post a comment (or a reply when [parentId] is set).
///
/// An empty comment is refused here, before any network call —
/// the same validation-first pattern as [CreateReportUseCase].
library;

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../entities/report_comment.dart';
import '../repositories/home_repository.dart';

class AddCommentUseCase {
  const AddCommentUseCase(this._repository);

  final HomeRepository _repository;

  Future<Result<ReportComment>> call({
    required String reportId,
    required String body,
    String? parentId,
  }) {
    if (body.trim().isEmpty) {
      return Future.value(
        const FailureResult<ReportComment>(
          ValidationFailure('Comment is empty.'),
        ),
      );
    }
    return _repository.addComment(
      reportId: reportId,
      body: body.trim(),
      parentId: parentId,
    );
  }
}
