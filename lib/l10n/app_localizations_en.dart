// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Service Reminder';

  @override
  String get loginSubtitle => 'Sign in to manage your service reminders';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get account => 'Account';

  @override
  String get services => 'Services';

  @override
  String get remindersTooltip => 'Reminders';

  @override
  String get assignServiceTooltip => 'Assign service';

  @override
  String get language => 'Language';

  @override
  String get languageTitle => 'App language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी (Hindi)';

  @override
  String get signedInAs => 'Signed in as';

  @override
  String get subscriptionAndBilling => 'Subscription & billing';

  @override
  String get plansAndPricing => 'Plans & pricing';

  @override
  String get plansSubtitle => 'Free trial · ₹299 · ₹499';

  @override
  String get trialEndedHint =>
      'Your 3‑month trial has ended. Choose ₹299 or ₹499 to continue — ₹499 includes WhatsApp automation and PDF receipts.';

  @override
  String get business => 'Business';

  @override
  String get customers => 'Customers';

  @override
  String get customersSubtitle => 'Manage your customer list';

  @override
  String get packages => 'Packages';

  @override
  String get packagesSubtitle => 'Service packages you offer';

  @override
  String get reports => 'Reports';

  @override
  String get reportsSubtitle => 'Earnings and performance';

  @override
  String get notifications => 'Notifications';

  @override
  String get enableNotifications => 'Enable notifications';

  @override
  String get enableNotificationsSubtitle =>
      'Allow visit reminders and morning briefing';

  @override
  String get morningBriefing => 'Morning briefing';

  @override
  String get morningBriefingSubtitle => 'Daily reminder at 8:00 AM';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirmTitle => 'Sign out';

  @override
  String get signOutConfirmBody => 'Are you sure you want to sign out?';

  @override
  String get cancel => 'Cancel';

  @override
  String get email => 'Email';

  @override
  String get mobileOtp => 'Mobile OTP';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get verifyAndSignIn => 'Verify & Sign in';

  @override
  String otpSentTo(String phone) {
    return 'OTP sent to $phone';
  }

  @override
  String get otpSmsHint => 'Enter the 6-digit code from your SMS';

  @override
  String get changeNumber => 'Change number';

  @override
  String get mobileNumber => 'Mobile number';

  @override
  String get countryCodeHint => 'Include country code, e.g. +91 for India';

  @override
  String get newHere => 'New here? ';

  @override
  String get createAccount => 'Create an account';

  @override
  String get couldNotLoadPlan => 'Could not load plan';

  @override
  String get notificationsEnabledSnack =>
      'Notifications enabled. Morning briefing set for 8:00 AM.';

  @override
  String get morningBriefingScheduledSnack =>
      'Morning briefing scheduled for 8:00 AM daily.';
}
