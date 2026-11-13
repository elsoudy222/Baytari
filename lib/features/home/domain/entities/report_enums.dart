/// The fixed vocabularies of the Home feed — the values stored in
/// the database for reports and statuses (migration
/// 20261107000003_home_feed).
///
/// These are plain Dart enums (no Flutter imports): the domain
/// layer defines *what* the values are, and the data layer maps
/// them to/from the snake_case strings in the database. The
/// `value` of each entry is exactly the string stored in the DB —
/// renaming a Dart entry without renaming its `value` is safe.
///
/// The status chips differ per report category in Figma, so
/// [ReportStatus.chipsFor] returns the chip set for a category:
/// - stray: Sighted / Rescued / In Shelter / at VET / Couldn't find
/// - lost: Sighted / In Safe Hands / Not Found
/// - adoption: Interested / Ready to Adopt / In Process / Adopted
library;

/// What kind of report: a stray animal, a lost pet, or an animal
/// looking for a home. The feed's filter chips are these three
/// (plus "All").
enum ReportCategory {
  stray('stray'),
  lost('lost'),
  adoption('adoption');

  const ReportCategory(this.value);

  /// The string stored in the `reports.category` column.
  final String value;

  static ReportCategory fromString(String? value) {
    return ReportCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReportCategory.stray,
    );
  }
}

/// How urgent a report is (Figma shows all four on the post
/// header: "High Priority / Stray Animal / Dog").
enum ReportPriority {
  urgent('urgent'),
  high('high'),
  mid('mid'),
  low('low');

  const ReportPriority(this.value);

  /// The string stored in the `reports.priority` column.
  final String value;

  static ReportPriority fromString(String? value) {
    return ReportPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReportPriority.mid,
    );
  }
}

/// The animal in a report. Only dog/cat have their own chip in
/// Figma; anything else is "other".
enum AnimalType {
  dog('dog'),
  cat('cat'),
  other('other');

  const AnimalType(this.value);

  /// The string stored in the `reports.animal_type` column.
  final String value;

  static AnimalType fromString(String? value) {
    return AnimalType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AnimalType.other,
    );
  }
}

/// A user's latest status on a report — the "Share Status Update"
/// chips. One row per (report, user) in `report_statuses`, and a
/// copy of it is stored on each comment the user writes (so the
/// comment bubble keeps its colour and label even if the user
/// changes status later).
enum ReportStatus {
  sighted('sighted'),
  rescued('rescued'),
  inShelter('in_shelter'),
  atVet('at_vet'),
  couldntFind('couldnt_find'),
  inSafeHands('in_safe_hands'),
  notFound('not_found'),
  interested('interested'),
  readyToAdopt('ready_to_adopt'),
  inProcess('in_process'),
  adopted('adopted');

  const ReportStatus(this.value);

  /// The string stored in the `report_statuses.status` and
  /// `report_comments.status` columns.
  final String value;

  static ReportStatus? fromString(String? value) {
    if (value == null) return null;
    for (final status in ReportStatus.values) {
      if (status.value == value) return status;
    }
    return null;
  }

  /// The chips Figma shows under "Share Status Update" for a
  /// report of [category]. Each category has its own set — a
  /// stray report never shows "Adopted", an adoption report never
  /// shows "Couldn't find".
  static List<ReportStatus> chipsFor(ReportCategory category) {
    return switch (category) {
      ReportCategory.stray => <ReportStatus>[
        sighted,
        rescued,
        inShelter,
        atVet,
        couldntFind,
      ],
      ReportCategory.lost => <ReportStatus>[
        sighted,
        inSafeHands,
        notFound,
      ],
      ReportCategory.adoption => <ReportStatus>[
        interested,
        readyToAdopt,
        inProcess,
        adopted,
      ],
    };
  }
}
