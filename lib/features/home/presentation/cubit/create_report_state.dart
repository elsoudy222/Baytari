/// State of the Create Report form.
///
/// Category / priority / animal start unselected (null) on
/// purpose: the form validates that the user picked all three,
/// and a pre-selected default would silently submit a choice
/// the user never made. [photos] are the raw bytes of the
/// picked images (the Cubit never holds files or paths).
library;

import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../domain/entities/report_enums.dart';

enum CreateReportStatus { initial, submitting, success, failure }

class CreateReportState extends Equatable {
  const CreateReportState({
    this.status = CreateReportStatus.initial,
    this.category,
    this.priority,
    this.animalType,
    this.description = '',
    this.locationText = '',
    this.photos = const <Uint8List>[],
    this.errorMessage,
  });

  final CreateReportStatus status;

  final ReportCategory? category;

  final ReportPriority? priority;

  final AnimalType? animalType;

  final String description;

  final String locationText;

  final List<Uint8List> photos;

  /// The last failure/validation message (shown as a toast or
  /// under the form by the UI).
  final String? errorMessage;

  CreateReportState copyWith({
    CreateReportStatus? status,
    ReportCategory? category,
    ReportPriority? priority,
    AnimalType? animalType,
    String? description,
    String? locationText,
    List<Uint8List>? photos,
    String? errorMessage,
  }) {
    return CreateReportState(
      status: status ?? this.status,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      animalType: animalType ?? this.animalType,
      description: description ?? this.description,
      locationText: locationText ?? this.locationText,
      photos: photos ?? this.photos,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    category,
    priority,
    animalType,
    description,
    locationText,
    photos,
    errorMessage,
  ];
}
