# Onboarding — Splash + Onboarding + Get Started

UI-only feature (presentation + core theme/logo). No domain/data code:
the flow is decided by [OnboardingCubit] (persisted "seen" flag +
session-only guest mode) and the router guard in `AppRouter`.

## Screens

- `splash_screen.dart` — entry route `/splash`, ~2s, then routes on:
  onboarding (first run), home (signed in / guest), get-started (else).
- `onboarding_screen.dart` — 4 Figma pages in order, with Skip and
  Get Started (advances / finishes on the last page).
- `get_started_screen.dart` — Log In / Sign Up / Join as a guest.

## Design

Palette sampled from the Figma screenshots the user sent
(`AppColors`): teal `#3E8E83`, orange `#F15B2A`, dark teal heading
`#223F3C`, peach blob `#F2DEC5`, mint card `#EAF6F2`, background
`#FAFAFA`. The illustrations are simplified placeholders (blob +
icon) in that palette — not the Figma artwork. The logo is v3:
`assets/images/baytari_logo.png` (wide lockup: dog + cat icon,
"Baytari" wordmark with an orange paw on the "i", "بيطري" underneath)
and `assets/images/baytari_mark.png` (icon only, transparent
background), rendered by `core/widgets/baytari_logo.dart`. v3 uses
solid app-palette colours (orange dog `#F15B2A`, teal cat `#3E8E83`,
"Bayt" dark teal `#223F3C` + "tari" teal) — the v2 gradient is gone.
The old `baytari_logo.svg` (v1 pin mark) is no longer referenced by
any code.
