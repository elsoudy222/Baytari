/// Cubit of the Create Report form.
///
/// The form state (choices + photos) lives here, not in the
/// widget, so the validation and the submit are unit-testable.
/// Submit validates first (category + priority + animal +
/// non-empty description) and only then calls the use case —
/// the use case re-validates the description as a second line
/// of defence, but the Cubit is what shows the form error.
///
/// On success the screen navigates back and the feed refreshes
/// (the screen owns that navigation, listening for
/// [CreateReportStatus.success]).
library;

import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/entities/report.dart';
import '../../domain/entities/report_enums.dart';
import '../../domain/usecases/create_report_usecase.dart';
import 'create_report_state.dart';

class CreateReportCubit extends Cubit<CreateReportState> {
  CreateReportCubit({required this._createReportUseCase})
    : super(const CreateReportState());

  final CreateReportUseCase _createReportUseCase;

  void selectCategory(ReportCategory category) {
    emit(state.copyWith(category: category));
  }

  void selectPriority(ReportPriority priority) {
    emit(state.copyWith(priority: priority));
  }

  void selectAnimalType(AnimalType animalType) {
    emit(state.copyWith(animalType: animalType));
  }

  void setDescription(String description) {
    emit(state.copyWith(description: description));
  }

  void setLocationText(String locationText) {
    emit(state.copyWith(locationText: locationText));
  }

  /// Appends picked photo bytes (the screen reads the picked
  /// files into bytes — the Cubit never touches `image_picker`).
  void addPhotos(List<Uint8List> bytes) {
    emit(state.copyWith(photos: <Uint8List>[...state.photos, ...bytes]));
  }

  void removePhoto(int index) {
    final List<Uint8List> updated = List<Uint8List>.of(state.photos)
      ..removeAt(index);
    emit(state.copyWith(photos: updated));
  }

  /// Validates the form, then creates the report. Returns
  /// immediately (with a failure state) when anything required
  /// is missing — no network call is made in that case.
  Future<void> submit() async {
    if (state.status == CreateReportStatus.submitting) return;
    final String? validationError = _validate();
    if (validationError != null) {
      emit(
        state.copyWith(
          status: CreateReportStatus.failure,
          errorMessage: validationError,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: CreateReportStatus.submitting,
        errorMessage: null,
      ),
    );
    final Result<Report> result = await _createReportUseCase(
      category: state.category!,
      priority: state.priority!,
      animalType: state.animalType!,
      description: state.description,
      locationText: state.locationText.isEmpty
          ? null
          : state.locationText,
      photos: state.photos,
    );
    switch (result) {
      case Success():
        emit(state.copyWith(status: CreateReportStatus.success));
      case FailureResult(:final failure):
        emit(
          state.copyWith(
            status: CreateReportStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }

  /// The form rules (see the task: description required, and
  /// category / priority / animal must all be picked). The
  /// returned string is a message KEY the UI translates through
  /// the ARB files — never a hardcoded user-facing sentence.
  String? _validate() {
    if (state.category == null ||
        state.priority == null ||
        state.animalType == null) {
      return 'formIncomplete';
    }
    if (state.description.trim().isEmpty) {
      return 'descriptionRequired';
    }
    return null;
  }
}
