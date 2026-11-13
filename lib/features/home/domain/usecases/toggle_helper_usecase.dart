/// Use case: toggle "Help" on a report.
///
/// Returns the new state (true = the user is now helping). The
/// repository inserts or deletes the `report_helpers` row; the
/// Cubit updates the helpers count from the returned value.
library;

import '../../../../core/errors/result.dart';
import '../repositories/home_repository.dart';

class ToggleHelperUseCase {
  const ToggleHelperUseCase(this._repository);

  final HomeRepository _repository;

  Future<Result<bool>> call(String reportId) {
    return _repository.toggleHelper(reportId);
  }
}
