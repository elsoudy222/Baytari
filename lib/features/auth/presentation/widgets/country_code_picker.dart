/// Country-code picker for the phone field (Figma `country_code.png`).
///
/// The design shows a searchable list of flags + dial codes with
/// Egypt (+20) at the top. The phone number itself is stored on
/// the profile, but OTPs go to EMAIL only (phone OTP needs an SMS
/// provider — out of v1, see the Arabic doc), so this picker only
/// chooses the dial prefix, it never triggers an SMS.
///
/// Country names are proper nouns kept in English here (data, not
/// user-facing copy that needs translation — the same way a
/// currency list keeps "USD"). The list is intentionally short:
/// Egypt first, then the most common countries for our users.
library;

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';

/// One country: dial code + flag (emoji) + English name.
class CountryCode {
  const CountryCode({
    required this.name,
    required this.dialCode,
    required this.flag,
  });

  final String name;
  final String dialCode;
  final String flag;
}

/// Egypt first (the app's home market), then common countries.
const List<CountryCode> countryCodes = <CountryCode>[
  CountryCode(name: 'Egypt', dialCode: '+20', flag: '🇪🇬'),
  CountryCode(name: 'Saudi Arabia', dialCode: '+966', flag: '🇸🇦'),
  CountryCode(name: 'United Arab Emirates', dialCode: '+971', flag: '🇦🇪'),
  CountryCode(name: 'Jordan', dialCode: '+962', flag: '🇯🇴'),
  CountryCode(name: 'Lebanon', dialCode: '+961', flag: '🇱🇧'),
  CountryCode(name: 'United States', dialCode: '+1', flag: '🇺🇸'),
  CountryCode(name: 'United Kingdom', dialCode: '+44', flag: '🇬🇧'),
  CountryCode(name: 'Germany', dialCode: '+49', flag: '🇩🇪'),
  CountryCode(name: 'France', dialCode: '+33', flag: '🇫🇷'),
];

/// Shows the country list as a bottom sheet and returns the
/// picked country (or null when dismissed).
Future<CountryCode?> showCountryCodePicker(BuildContext context) {
  return showModalBottomSheet<CountryCode>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      final l10n = context.l10n;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                l10n.selectCountry,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: context.isDark
                      ? AppColors.darkHeading
                      : AppColors.heading,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: countryCodes.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final CountryCode country = countryCodes[index];
                    return ListTile(
                      leading: Text(
                        country.flag,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(country.name),
                      trailing: Text(
                        country.dialCode,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.subtitle),
                      ),
                      onTap: () => Navigator.of(context).pop(country),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
