// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'सेवा अनुस्मारक';

  @override
  String get loginSubtitle => 'सेवा अनुस्मारक प्रबंधन के लिए साइन इन करें';

  @override
  String get dashboard => 'डैशबोर्ड';

  @override
  String get account => 'खाता';

  @override
  String get services => 'सेवाएँ';

  @override
  String get remindersTooltip => 'अनुस्मारक';

  @override
  String get assignServiceTooltip => 'सेवा असाइन करें';

  @override
  String get language => 'भाषा';

  @override
  String get languageTitle => 'ऐप की भाषा';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी (Hindi)';

  @override
  String get signedInAs => 'इस रूप में साइन इन';

  @override
  String get subscriptionAndBilling => 'सदस्यता और बिलिंग';

  @override
  String get plansAndPricing => 'योजनाएँ और मूल्य';

  @override
  String get plansSubtitle => 'मुफ़्त ट्रायल · ₹299 · ₹499';

  @override
  String get trialEndedHint =>
      'आपका 3 महीने का मुफ़्त ट्रायल समाप्त हो गया है। जारी रखने के लिए ₹299 या ₹499 चुनें — ₹499 में WhatsApp स्वचालन और PDF रसीद शामिल है।';

  @override
  String get business => 'व्यवसाय';

  @override
  String get customers => 'ग्राहक';

  @override
  String get customersSubtitle => 'अपनी ग्राहक सूची प्रबंधित करें';

  @override
  String get packages => 'पैकेज';

  @override
  String get packagesSubtitle => 'आपकी सेवा पैकेज';

  @override
  String get reports => 'रिपोर्ट';

  @override
  String get reportsSubtitle => 'कमाई और प्रदर्शन';

  @override
  String get notifications => 'सूचनाएँ';

  @override
  String get enableNotifications => 'सूचनाएँ चालू करें';

  @override
  String get enableNotificationsSubtitle =>
      'विज़िट अनुस्मारक और सुबह की जानकारी';

  @override
  String get morningBriefing => 'सुबह की जानकारी';

  @override
  String get morningBriefingSubtitle => 'प्रतिदिन सुबह 8:00 बजे';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get signOutConfirmTitle => 'साइन आउट';

  @override
  String get signOutConfirmBody => 'क्या आप वाकई साइन आउट करना चाहते हैं?';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get email => 'ईमेल';

  @override
  String get mobileOtp => 'मोबाइल OTP';

  @override
  String get password => 'पासवर्ड';

  @override
  String get signIn => 'साइन इन';

  @override
  String get sendOtp => 'OTP भेजें';

  @override
  String get verifyAndSignIn => 'सत्यापित करें और साइन इन करें';

  @override
  String otpSentTo(String phone) {
    return '$phone पर OTP भेजा गया';
  }

  @override
  String get otpSmsHint => 'SMS से 6 अंकों का कोड दर्ज करें';

  @override
  String get changeNumber => 'नंबर बदलें';

  @override
  String get mobileNumber => 'मोबाइल नंबर';

  @override
  String get countryCodeHint => 'कंट्री कोड शामिल करें, उदा. भारत के लिए +91';

  @override
  String get newHere => 'नए हैं? ';

  @override
  String get createAccount => 'खाता बनाएँ';

  @override
  String get couldNotLoadPlan => 'योजना लोड नहीं हो सकी';

  @override
  String get notificationsEnabledSnack =>
      'सूचनाएँ चालू। सुबह 8:00 बजे की जानकारी सेट है।';

  @override
  String get morningBriefingScheduledSnack =>
      'सुबह 8:00 बजे की दैनिक जानकारी निर्धारित है।';
}
