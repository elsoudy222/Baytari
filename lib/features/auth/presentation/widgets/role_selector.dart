/// Role picker for the register screen: owner or vet.
///
/// A [SegmentedButton] with exactly the two roles the M1 register
/// screen offers. `staff_vet` / `clinic_admin` are never offered
/// here — those accounts are created by a clinic admin in a later
/// stage, not by self-registration.
library;

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/user_role.dart';

class RoleSelector extends StatelessWidget {
  const RoleSelector({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final UserRole selected;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SegmentedButton<UserRole>(
      segments: <ButtonSegment<UserRole>>[
        ButtonSegment<UserRole>(
          value: UserRole.owner,
          label: Text(l10n.roleOwner),
        ),
        ButtonSegment<UserRole>(
          value: UserRole.vet,
          label: Text(l10n.roleVet),
        ),
      ],
      selected: <UserRole>{selected},
      onSelectionChanged: (Set<UserRole> selection) {
        onChanged(selection.first);
      },
    );
  }
}
