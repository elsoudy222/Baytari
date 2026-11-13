import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Baytari'**
  String get appTitle;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @authError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authError;

  /// No description provided for @authNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Supabase is not configured, so sign-in is unavailable in demo mode.'**
  String get authNotConfigured;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailConfirmationSent.
  ///
  /// In en, this message translates to:
  /// **'Account created! Check your email to confirm it, then sign in.'**
  String get emailConfirmationSent;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyTitle;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorTitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @getStartedMessage.
  ///
  /// In en, this message translates to:
  /// **'Join Baytari today to help stray animals and connect with local services near you'**
  String get getStartedMessage;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @homeDescription.
  ///
  /// In en, this message translates to:
  /// **'This is the M0 scaffold. Features will be added one at a time: auth, pets, vets, appointments, schedule, dashboard and settings.'**
  String get homeDescription;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get invalidPhone;

  /// No description provided for @joinAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Join as a guest'**
  String get joinAsGuest;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logout;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get myProfile;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get nameRequired;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @onboardingSubtitle1.
  ///
  /// In en, this message translates to:
  /// **'Join us in providing care and finding homes for stray animals in your community'**
  String get onboardingSubtitle1;

  /// No description provided for @onboardingSubtitle2.
  ///
  /// In en, this message translates to:
  /// **'Easily locate and book appointments with nearby vet clinics and animal shelters.'**
  String get onboardingSubtitle2;

  /// No description provided for @onboardingSubtitle3.
  ///
  /// In en, this message translates to:
  /// **'Connect with a passionate community dedicated to the welfare of stray animals.'**
  String get onboardingSubtitle3;

  /// No description provided for @onboardingSubtitle4.
  ///
  /// In en, this message translates to:
  /// **'Join us today and make a difference in the lives of stray animals.'**
  String get onboardingSubtitle4;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Helping Stray Animals'**
  String get onboardingTitle1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Vet Clinics'**
  String get onboardingTitle2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Community of Helpers'**
  String get onboardingTitle3;

  /// No description provided for @onboardingTitle4.
  ///
  /// In en, this message translates to:
  /// **'Make an Impact'**
  String get onboardingTitle4;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phoneOptional;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get register;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Pet owner'**
  String get roleOwner;

  /// No description provided for @roleVet.
  ///
  /// In en, this message translates to:
  /// **'Veterinarian'**
  String get roleVet;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Choose your role'**
  String get selectRole;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @supabaseConfigured.
  ///
  /// In en, this message translates to:
  /// **'Supabase is configured.'**
  String get supabaseConfigured;

  /// No description provided for @supabaseNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Supabase is not configured yet. The app is running in demo mode.'**
  String get supabaseNotConfigured;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Baytari'**
  String get welcome;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Find a vet and book an appointment for your pet.'**
  String get welcomeMessage;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeBack;

  /// No description provided for @emailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Email or Phone Number'**
  String get emailOrPhone;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPassword;

  /// No description provided for @orLogInWith.
  ///
  /// In en, this message translates to:
  /// **'or log in with'**
  String get orLogInWith;

  /// No description provided for @orSignUpWith.
  ///
  /// In en, this message translates to:
  /// **'or sign up with'**
  String get orSignUpWith;

  /// No description provided for @socialComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Social sign-in is coming soon'**
  String get socialComingSoon;

  /// No description provided for @termsAgreement.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our'**
  String get termsAgreement;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @communityMember.
  ///
  /// In en, this message translates to:
  /// **'Community Member'**
  String get communityMember;

  /// No description provided for @veterinarian.
  ///
  /// In en, this message translates to:
  /// **'Veterinarian'**
  String get veterinarian;

  /// No description provided for @shelter.
  ///
  /// In en, this message translates to:
  /// **'Shelter'**
  String get shelter;

  /// No description provided for @accountInformation.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get accountInformation;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @setYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Set Your Password'**
  String get setYourPassword;

  /// No description provided for @createPassword.
  ///
  /// In en, this message translates to:
  /// **'Create Password'**
  String get createPassword;

  /// No description provided for @passwordRuleLength.
  ///
  /// In en, this message translates to:
  /// **'at least 8 characters.'**
  String get passwordRuleLength;

  /// No description provided for @passwordRuleCase.
  ///
  /// In en, this message translates to:
  /// **'uppercase and lowercase letters'**
  String get passwordRuleCase;

  /// No description provided for @passwordRuleNumber.
  ///
  /// In en, this message translates to:
  /// **'at least one number'**
  String get passwordRuleNumber;

  /// No description provided for @verifyYourEmail.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a verification code to your Email. Please enter the code below to verify your Email'**
  String get verifyYourEmail;

  /// No description provided for @didNotReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive code?'**
  String get didNotReceiveCode;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get verifyCode;

  /// No description provided for @wrongCode.
  ///
  /// In en, this message translates to:
  /// **'Wrong Code. Please try again or reset your code.'**
  String get wrongCode;

  /// No description provided for @clinicOwner.
  ///
  /// In en, this message translates to:
  /// **'Clinic owner'**
  String get clinicOwner;

  /// No description provided for @staffVet.
  ///
  /// In en, this message translates to:
  /// **'Staff vet'**
  String get staffVet;

  /// No description provided for @pickClinic.
  ///
  /// In en, this message translates to:
  /// **'Pick the clinic you work with'**
  String get pickClinic;

  /// No description provided for @shelterOwner.
  ///
  /// In en, this message translates to:
  /// **'Shelter owner'**
  String get shelterOwner;

  /// No description provided for @shelterWorker.
  ///
  /// In en, this message translates to:
  /// **'Shelter worker'**
  String get shelterWorker;

  /// No description provided for @pickShelter.
  ///
  /// In en, this message translates to:
  /// **'Pick the shelter you work with'**
  String get pickShelter;

  /// No description provided for @workplaceComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Clinics and shelters will be added soon — your choice is saved as a note for now.'**
  String get workplaceComingSoon;

  /// No description provided for @verifyYourLicense.
  ///
  /// In en, this message translates to:
  /// **'Verify Your License'**
  String get verifyYourLicense;

  /// No description provided for @takeLicensePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to take a photo of your license'**
  String get takeLicensePhoto;

  /// No description provided for @uploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get uploadPhoto;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @choosePhotoSource.
  ///
  /// In en, this message translates to:
  /// **'Choose how to add the photo'**
  String get choosePhotoSource;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @welcomeToBaytari.
  ///
  /// In en, this message translates to:
  /// **'Welcome To Baytari!'**
  String get welcomeToBaytari;

  /// No description provided for @pickUsernameMessage.
  ///
  /// In en, this message translates to:
  /// **'Let\'s make your profile unique! Pick a username that represents you within our community. This will be your identity as you explore, report, and connect with others on Baytari.'**
  String get pickUsernameMessage;

  /// No description provided for @addProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Profile Photo'**
  String get addProfilePhoto;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please pick a username'**
  String get usernameRequired;

  /// No description provided for @usernameTaken.
  ///
  /// In en, this message translates to:
  /// **'This username is already taken, please pick another one'**
  String get usernameTaken;

  /// No description provided for @accountReady.
  ///
  /// In en, this message translates to:
  /// **'Welcome! Your Account is Ready'**
  String get accountReady;

  /// No description provided for @accountReadyCommunity.
  ///
  /// In en, this message translates to:
  /// **'You can now start exploring the app and connecting with your local community!'**
  String get accountReadyCommunity;

  /// No description provided for @accountReadyVet.
  ///
  /// In en, this message translates to:
  /// **'You can now manage your clinic, take appointments, and connect with the community.'**
  String get accountReadyVet;

  /// No description provided for @goToHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get goToHome;

  /// No description provided for @resetYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Your Password'**
  String get resetYourPassword;

  /// No description provided for @resetPasswordMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address below to receive a one-time password (OTP) for resetting your password'**
  String get resetPasswordMessage;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get enterVerificationCode;

  /// No description provided for @enterVerificationCodeMessage.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a verification code to your email. Please enter the code below to reset your password'**
  String get enterVerificationCodeMessage;

  /// No description provided for @createNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Create New Password'**
  String get createNewPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your Password Was Reset Successfully!'**
  String get passwordResetSuccess;

  /// No description provided for @passwordResetSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your password has been successfully reset. You can now sign in using your new password'**
  String get passwordResetSuccessMessage;

  /// No description provided for @selectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select country'**
  String get selectCountry;

  /// No description provided for @otpSent.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent'**
  String get otpSent;

  /// No description provided for @licenseRequired.
  ///
  /// In en, this message translates to:
  /// **'Please upload a photo of your license to continue'**
  String get licenseRequired;

  /// No description provided for @emailOnlyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verification codes are sent to your email'**
  String get emailOnlyOtp;

  /// No description provided for @termsAnd.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get termsAnd;

  /// No description provided for @homeWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome,'**
  String get homeWelcome;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchHint;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterStray.
  ///
  /// In en, this message translates to:
  /// **'Stray'**
  String get filterStray;

  /// No description provided for @filterLost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get filterLost;

  /// No description provided for @filterAdoption.
  ///
  /// In en, this message translates to:
  /// **'Adoption'**
  String get filterAdoption;

  /// No description provided for @reportAnimalTitle.
  ///
  /// In en, this message translates to:
  /// **'Report an Animal'**
  String get reportAnimalTitle;

  /// No description provided for @reportAnimalDescription.
  ///
  /// In en, this message translates to:
  /// **'Help us locate and assist stray animals. Report an animal\'s sighting or condition here.'**
  String get reportAnimalDescription;

  /// No description provided for @reportAnimalButton.
  ///
  /// In en, this message translates to:
  /// **'Report Animal'**
  String get reportAnimalButton;

  /// No description provided for @shareStatusUpdate.
  ///
  /// In en, this message translates to:
  /// **'Share Status Update'**
  String get shareStatusUpdate;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'comment'**
  String get comment;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'show more'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'show less'**
  String get showLess;

  /// No description provided for @categoryStrayAnimal.
  ///
  /// In en, this message translates to:
  /// **'Stray Animal'**
  String get categoryStrayAnimal;

  /// No description provided for @categoryLostPet.
  ///
  /// In en, this message translates to:
  /// **'Lost Pet'**
  String get categoryLostPet;

  /// No description provided for @categoryAdoptable.
  ///
  /// In en, this message translates to:
  /// **'Adoptable'**
  String get categoryAdoptable;

  /// No description provided for @priorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get priorityUrgent;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High Priority'**
  String get priorityHigh;

  /// No description provided for @priorityMid.
  ///
  /// In en, this message translates to:
  /// **'Mid Priority'**
  String get priorityMid;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low Priority'**
  String get priorityLow;

  /// No description provided for @animalDog.
  ///
  /// In en, this message translates to:
  /// **'Dog'**
  String get animalDog;

  /// No description provided for @animalCat.
  ///
  /// In en, this message translates to:
  /// **'Cat'**
  String get animalCat;

  /// No description provided for @animalOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get animalOther;

  /// No description provided for @statusSighted.
  ///
  /// In en, this message translates to:
  /// **'Sighted'**
  String get statusSighted;

  /// No description provided for @statusRescued.
  ///
  /// In en, this message translates to:
  /// **'Rescued'**
  String get statusRescued;

  /// No description provided for @statusInShelter.
  ///
  /// In en, this message translates to:
  /// **'In Shelter'**
  String get statusInShelter;

  /// No description provided for @statusAtVet.
  ///
  /// In en, this message translates to:
  /// **'at VET'**
  String get statusAtVet;

  /// No description provided for @statusCouldntFind.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find'**
  String get statusCouldntFind;

  /// No description provided for @statusInSafeHands.
  ///
  /// In en, this message translates to:
  /// **'In Safe Hands'**
  String get statusInSafeHands;

  /// No description provided for @statusNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not Found'**
  String get statusNotFound;

  /// No description provided for @statusInterested.
  ///
  /// In en, this message translates to:
  /// **'Interested'**
  String get statusInterested;

  /// No description provided for @statusReadyToAdopt.
  ///
  /// In en, this message translates to:
  /// **'Ready to Adopt'**
  String get statusReadyToAdopt;

  /// No description provided for @statusInProcess.
  ///
  /// In en, this message translates to:
  /// **'In Process'**
  String get statusInProcess;

  /// No description provided for @statusAdopted.
  ///
  /// In en, this message translates to:
  /// **'Adopted'**
  String get statusAdopted;

  /// No description provided for @mapTab.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapTab;

  /// No description provided for @communityTab.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get communityTab;

  /// No description provided for @vetsTab.
  ///
  /// In en, this message translates to:
  /// **'Vets'**
  String get vetsTab;

  /// No description provided for @sheltersTab.
  ///
  /// In en, this message translates to:
  /// **'Shelters'**
  String get sheltersTab;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @comingSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'This section is coming soon.'**
  String get comingSoonMessage;

  /// No description provided for @shareComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Sharing is coming soon'**
  String get shareComingSoon;

  /// No description provided for @noReports.
  ///
  /// In en, this message translates to:
  /// **'No reports yet'**
  String get noReports;

  /// No description provided for @noReportsMessage.
  ///
  /// In en, this message translates to:
  /// **'Be the first to report an animal that needs help.'**
  String get noReportsMessage;

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterTitle;

  /// No description provided for @filterPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get filterPriority;

  /// No description provided for @filterAnimal.
  ///
  /// In en, this message translates to:
  /// **'Animal type'**
  String get filterAnimal;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearFilters;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyFilters;

  /// No description provided for @createReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report an Animal'**
  String get createReportTitle;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @priorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priorityLabel;

  /// No description provided for @animalTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Animal type'**
  String get animalTypeLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the animal, its condition and where you saw it...'**
  String get descriptionHint;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @locationHint.
  ///
  /// In en, this message translates to:
  /// **'Street, area, city'**
  String get locationHint;

  /// No description provided for @addPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get addPhotos;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get submitReport;

  /// No description provided for @reportCreated.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Thank you for helping!'**
  String get reportCreated;

  /// No description provided for @formIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Please choose a category, priority and animal type'**
  String get formIncomplete;

  /// No description provided for @descriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Please describe the animal'**
  String get descriptionRequired;

  /// No description provided for @commentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsTitle;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Be the first to help!'**
  String get noCommentsYet;

  /// No description provided for @writeComment.
  ///
  /// In en, this message translates to:
  /// **'Write a comment ...'**
  String get writeComment;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @unlike.
  ///
  /// In en, this message translates to:
  /// **'unlike'**
  String get unlike;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @helpersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} helpers'**
  String helpersCount(int count);

  /// No description provided for @commentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} comments'**
  String commentsCount(int count);

  /// No description provided for @commentsHeader.
  ///
  /// In en, this message translates to:
  /// **'{author} and {count} Helpers'**
  String commentsHeader(String author, int count);

  /// No description provided for @replyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String replyingTo(String name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
