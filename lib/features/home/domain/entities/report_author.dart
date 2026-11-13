/// The public face of a user in the Home feed — the fields the
/// feed needs to show a report or comment author: name, username
/// and avatar. This is deliberately a small value object, NOT the
/// full [Profile]: the feed never needs (and should never display)
/// a stranger's email or phone.
///
/// The data layer builds it from the embedded `profiles` row that
/// comes back with each report/comment (migration 3's B8 policy
/// lets any user read these fields of any profile).
library;

import 'package:equatable/equatable.dart';

class ReportAuthor extends Equatable {
  const ReportAuthor({
    required this.id,
    required this.fullName,
    this.username,
    this.avatarUrl,
  });

  /// The author's profile id (= their auth user id).
  final String id;

  /// Display name, e.g. "Merhan Assem".
  final String fullName;

  /// The username picked at sign-up (may be null for old accounts).
  final String? username;

  /// Public URL of the avatar photo (may be null — the UI then
  /// shows a person icon).
  final String? avatarUrl;

  /// The name shown in the feed. The username is preferred when
  /// the full name is empty (old accounts created before the
  /// username step existed).
  String get displayName {
    if (fullName.trim().isNotEmpty) return fullName.trim();
    if (username != null && username!.trim().isNotEmpty) {
      return username!.trim();
    }
    return '';
  }

  @override
  List<Object?> get props => <Object?>[id, fullName, username, avatarUrl];
}
