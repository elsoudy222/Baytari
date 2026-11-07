/// Onboarding dependency registration (GetIt).
///
/// One factory registration: [OnboardingCubit] is created fresh per
/// request (like [AuthCubit]), from the already-registered
/// [AppSettingsService]. `BaytariApp` creates one instance and owns
/// it for the app's lifetime, passing it to the router so the auth
/// guard can let guests reach Home.
library;

import 'package:get_it/get_it.dart';

import '../../../../core/services/app_settings_service.dart';
import '../presentation/cubit/onboarding_cubit.dart';

void registerOnboarding(GetIt sl) {
  sl.registerFactory<OnboardingCubit>(
    () => OnboardingCubit(sl<AppSettingsService>()),
  );
}
