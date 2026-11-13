/// The Create Report screen (the "Report Animal" button of the
/// "Report an Animal" card).
///
/// Form, top to bottom: category chips (Stray / Lost /
/// Adoption), priority chips (Urgent / High / Mid / Low),
/// animal chips (Dog / Cat / Other), description field,
/// location field (optional), photo picker (gallery, multiple),
/// Submit. The [CreateReportCubit] owns the choices and the
/// validation — the screen only renders them and reads the
/// picked files into bytes.
///
/// On success the screen pops (the feed refreshes behind it);
/// on failure a toast shows the error. The submit button is
/// disabled while submitting.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/dialogs/app_toast.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/report_enums.dart';
import '../cubit/create_report_cubit.dart';
import '../cubit/create_report_state.dart';
import '../utils/report_display.dart';

class CreateReportScreen extends StatelessWidget {
  const CreateReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CreateReportCubit>(
      create: (_) => sl<CreateReportCubit>(),
      child: const _CreateReportView(),
    );
  }
}

class _CreateReportView extends StatefulWidget {
  const _CreateReportView();

  @override
  State<_CreateReportView> createState() => _CreateReportViewState();
}

class _CreateReportViewState extends State<_CreateReportView> {
  final TextEditingController _descriptionController =
      TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// Opens the gallery picker (multiple images) and hands the
  /// bytes to the Cubit. The picker itself is UI work — the
  /// Cubit only ever sees bytes.
  Future<void> _pickPhotos() async {
    final List<XFile> files = await ImagePicker().pickMultiImage();
    if (files.isEmpty || !mounted) return;
    final List<Uint8List> bytes = <Uint8List>[];
    for (final XFile file in files) {
      bytes.add(await file.readAsBytes());
    }
    if (!mounted) return;
    context.read<CreateReportCubit>().addPhotos(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<CreateReportCubit, CreateReportState>(
      listenWhen: (previous, current) =>
          current.status != previous.status,
      listener: (context, state) {
        if (state.status == CreateReportStatus.success) {
          showAppToast(context, l10n.reportCreated);
          context.pop();
        } else if (state.status == CreateReportStatus.failure &&
            state.errorMessage != null) {
          // The Cubit returns a message KEY for validation
          // errors ('formIncomplete' / 'descriptionRequired') and
          // a technical message for server errors — translate
          // the keys, show the rest as-is.
          showAppToast(
            context,
            _errorText(l10n, state.errorMessage!),
            isError: true,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.createReportTitle)),
        body: BlocBuilder<CreateReportCubit, CreateReportState>(
          builder: (context, state) {
            final CreateReportCubit cubit = context.read<CreateReportCubit>();
            final bool submitting =
                state.status == CreateReportStatus.submitting;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _SectionLabel(l10n.categoryLabel),
                  const SizedBox(height: 8),
                  _ChoiceRow<ReportCategory>(
                    values: ReportCategory.values,
                    selected: state.category,
                    label: (category) =>
                        reportCategoryChipLabel(l10n, category),
                    onSelected: cubit.selectCategory,
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel(l10n.priorityLabel),
                  const SizedBox(height: 8),
                  _ChoiceRow<ReportPriority>(
                    values: ReportPriority.values,
                    selected: state.priority,
                    label: (priority) =>
                        reportPriorityLabel(l10n, priority),
                    onSelected: cubit.selectPriority,
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel(l10n.animalTypeLabel),
                  const SizedBox(height: 8),
                  _ChoiceRow<AnimalType>(
                    values: AnimalType.values,
                    selected: state.animalType,
                    label: (animal) => animalTypeLabel(l10n, animal),
                    onSelected: cubit.selectAnimalType,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _descriptionController,
                    onChanged: cubit.setDescription,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: l10n.descriptionLabel,
                      hintText: l10n.descriptionHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _locationController,
                    onChanged: cubit.setLocationText,
                    decoration: InputDecoration(
                      labelText: l10n.locationLabel,
                      hintText: l10n.locationHint,
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel(l10n.addPhotos),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (int i = 0; i < state.photos.length; i++)
                        Stack(
                          children: <Widget>[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                state.photos[i],
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => cubit.removePhoto(i),
                                child: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.black54,
                                  child: Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      OutlinedButton.icon(
                        onPressed: submitting ? null : _pickPhotos,
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: Text(l10n.addPhotos),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: submitting
                          ? l10n.loading
                          : l10n.submitReport,
                      onPressed: submitting ? null : cubit.submit,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Translates the Cubit's validation keys; any other message
  /// is a server error and is shown as-is.
  String _errorText(AppLocalizations l10n, String message) {
    return switch (message) {
      'formIncomplete' => l10n.formIncomplete,
      'descriptionRequired' => l10n.descriptionRequired,
      _ => message,
    };
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// A row of selectable chips for one enum (category, priority
/// or animal). The selected chip is filled primary.
class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<T> values;
  final T? selected;
  final String Function(T value) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final T value in values)
          ChoiceChip(
            label: Text(label(value)),
            selected: selected == value,
            onSelected: (_) => onSelected(value),
            selectedColor: scheme.primary,
            labelStyle: TextStyle(
              color: selected == value
                  ? scheme.onPrimary
                  : AppColors.heading,
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide(color: scheme.outlineVariant),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
      ],
    );
  }
}
