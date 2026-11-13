/// Use case: create a report (with photos).
///
/// The description is validated here, not in the widget: a use
/// case is unit-testable, a widget is not. The repository does
/// the upload + insert; this class only refuses an empty
/// description before any network call happens.
library;

import 'dart:typed_data';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../entities/report.dart';
import '../entities/report_enums.dart';
import '../repositories/home_repository.dart';

class CreateReportUseCase {
  const CreateReportUseCase(this._repository);

  final HomeRepository _repository;

  Future<Result<Report>> call({
    required ReportCategory category,
    required ReportPriority priority,
    required AnimalType animalType,
    required String description,
    String? locationText,
    List<Uint8List> photos = const <Uint8List>[],
  }) {
    // A report without a description is useless to the helpers
    // who would read it — fail fast, before uploading anything.
    if (description.trim().isEmpty) {
      return Future.value(
        const FailureResult<Report>(
          ValidationFailure('Description is required.'),
        ),
      );
    }
    return _repository.createReport(
      category: category,
      priority: priority,
      animalType: animalType,
      description: description.trim(),
      locationText: locationText?.trim(),
      photos: photos,
    );
  }
}
