/// Unit tests for [OnboardingCubit].
///
/// Proves the two behaviours the flow depends on: `markSeen()`
/// persists the flag in SharedPreferences (so the next launch skips
/// onboarding), and `continueAsGuest()` only changes the in-memory
/// state (guest mode is never persisted and creates no account).
library;

import 'package:baytari/core/services/app_settings_service.dart';
import 'package:baytari/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late OnboardingCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    cubit = OnboardingCubit(AppSettingsService(prefs));
  });

  tearDown(() async {
    await cubit.close();
  });

  test('starts unseen on first run', () {
    expect(cubit.state.seen, isFalse);
    expect(cubit.state.guestMode, isFalse);
  });

  test('markSeen persists the flag', () async {
    await cubit.markSeen();
    expect(cubit.state.seen, isTrue);
    // A fresh Cubit over the same prefs must read the saved value.
    final OnboardingCubit again = OnboardingCubit(
      AppSettingsService(prefs),
    );
    expect(again.state.seen, isTrue);
    await again.close();
  });

  test('continueAsGuest is session-only', () {
    cubit.continueAsGuest();
    expect(cubit.state.guestMode, isTrue);
    expect(prefs.getBool('baytari_onboarding_seen'), isNull);
  });
}
