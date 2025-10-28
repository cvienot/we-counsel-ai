import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'We Counsel'**
  String get appTitle;

  /// The application subtitle
  ///
  /// In en, this message translates to:
  /// **'Your relationship journey together'**
  String get appSubtitle;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Register button text
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// First name field label
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// Last name field label
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Welcome message title
  ///
  /// In en, this message translates to:
  /// **'Welcome to your journey together'**
  String get welcomeTitle;

  /// Welcome message description
  ///
  /// In en, this message translates to:
  /// **'This is your main conversation space where you and your partner can share thoughts, feelings, and receive guidance from Dr. Sarah, your AI counsellor.'**
  String get welcomeMessage;

  /// Placeholder message when no messages
  ///
  /// In en, this message translates to:
  /// **'Share what\'s on your mind. Dr. Sarah is here to help guide your conversation.'**
  String get shareThoughts;

  /// Conversations screen title
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get conversations;

  /// Profile screen title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Main conversation title
  ///
  /// In en, this message translates to:
  /// **'Main Conversation'**
  String get mainConversation;

  /// Other conversations menu item
  ///
  /// In en, this message translates to:
  /// **'Other Conversations'**
  String get otherConversations;

  /// Message input placeholder
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// Send button text
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// Typing indicator text
  ///
  /// In en, this message translates to:
  /// **'Typing'**
  String get typing;

  /// Partner typing indicator
  ///
  /// In en, this message translates to:
  /// **'Partner is typing'**
  String get partnerTyping;

  /// Multiple partners typing indicator
  ///
  /// In en, this message translates to:
  /// **'Partners are typing'**
  String get partnersTyping;

  /// Loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Generic error title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Invite partner button text
  ///
  /// In en, this message translates to:
  /// **'Invite Partner'**
  String get invitePartner;

  /// Waiting for partner message
  ///
  /// In en, this message translates to:
  /// **'Waiting for your partner to join...'**
  String get waitingForPartner;

  /// Waiting room title
  ///
  /// In en, this message translates to:
  /// **'Waiting for your partner'**
  String get waitingForPartnerTitle;

  /// Waiting room greeting message
  ///
  /// In en, this message translates to:
  /// **'Hi {name}! Your counselling journey will begin once your partner joins you on We Counsel.'**
  String waitingRoomGreeting(String name);

  /// What happens next section title
  ///
  /// In en, this message translates to:
  /// **'What happens next?'**
  String get whatHappensNext;

  /// Send another invitation button
  ///
  /// In en, this message translates to:
  /// **'Send Another Invitation'**
  String get sendAnotherInvitation;

  /// Invite partner description
  ///
  /// In en, this message translates to:
  /// **'Share this invitation with your partner to start your counselling journey together.'**
  String get invitePartnerMessage;

  /// Create new conversation button
  ///
  /// In en, this message translates to:
  /// **'Create New Conversation'**
  String get createNewConversation;

  /// Conversation title field label
  ///
  /// In en, this message translates to:
  /// **'Conversation Title'**
  String get conversationTitle;

  /// Conversation topic field label
  ///
  /// In en, this message translates to:
  /// **'Topic (Optional)'**
  String get conversationTopic;

  /// Create button text
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Failed to load error message
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get failedToLoad;

  /// Failed to send message error
  ///
  /// In en, this message translates to:
  /// **'Failed to send message'**
  String get failedToSend;

  /// Empty conversation message
  ///
  /// In en, this message translates to:
  /// **'Start the conversation by sending a message!'**
  String get startConversation;

  /// Start conversation prompt message
  ///
  /// In en, this message translates to:
  /// **'Start your conversation'**
  String get startYourConversation;

  /// Settings menu item
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Language settings label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Language selection title
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Main conversation thread title
  ///
  /// In en, this message translates to:
  /// **'Main Conversation'**
  String get mainConversationTitle;

  /// Main conversation thread topic
  ///
  /// In en, this message translates to:
  /// **'Your ongoing journey together'**
  String get mainConversationTopic;

  /// AI Counsellor label
  ///
  /// In en, this message translates to:
  /// **'AI Counsellor'**
  String get aiCounsellor;

  /// Dr. Sarah AI Counsellor full name
  ///
  /// In en, this message translates to:
  /// **'Dr. Sarah (AI Counsellor)'**
  String get drSarahAiCounsellor;

  /// Message encouraging users to start their first conversation
  ///
  /// In en, this message translates to:
  /// **'Start your first conversation with your partner and get guidance from our AI counsellor.'**
  String get startFirstConversationMessage;

  /// Message explaining what happens after partner accepts invitation
  ///
  /// In en, this message translates to:
  /// **'Once your partner accepts the invitation and creates their account, you\'ll both have access to your main conversation thread where you can start sharing and receiving guidance from our AI counsellor.'**
  String get partnerInvitationMessage;
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
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
