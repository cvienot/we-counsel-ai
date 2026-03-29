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
  /// **'We Coach'**
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
  /// **'This is your main conversation space where you and your partner can share thoughts, feelings, and receive guidance from Coach Sarah, your AI coach.'**
  String get welcomeMessage;

  /// Placeholder message when no messages
  ///
  /// In en, this message translates to:
  /// **'Share what\'s on your mind. Coach Sarah is here to help guide your conversation.'**
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

  /// Invite partner screen title
  ///
  /// In en, this message translates to:
  /// **'Invite Your Partner'**
  String get inviteYourPartner;

  /// Send invitation card title
  ///
  /// In en, this message translates to:
  /// **'Send Invitation'**
  String get sendInvitation;

  /// Invite partner description text
  ///
  /// In en, this message translates to:
  /// **'Invite your partner to join you on We Connect. They will receive an email with instructions to create their account and connect with you.'**
  String get invitePartnerDescription;

  /// Partner email field label
  ///
  /// In en, this message translates to:
  /// **'Partner\'s Email Address'**
  String get partnerEmailAddress;

  /// Partner email field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your partner\'s email address'**
  String get enterPartnerEmail;

  /// Partner email validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your partner\'s email'**
  String get pleaseEnterPartnerEmail;

  /// Email format validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get pleaseEnterValidEmail;

  /// Self-invite validation error
  ///
  /// In en, this message translates to:
  /// **'You cannot invite yourself'**
  String get cannotInviteYourself;

  /// Personal message field label
  ///
  /// In en, this message translates to:
  /// **'Personal Message (Optional)'**
  String get personalMessageOptional;

  /// Personal message field hint
  ///
  /// In en, this message translates to:
  /// **'Add a personal message to your invitation...'**
  String get addPersonalMessage;

  /// Invitation sent dialog title
  ///
  /// In en, this message translates to:
  /// **'Invitation Sent!'**
  String get invitationSent;

  /// Invitation sent success message
  ///
  /// In en, this message translates to:
  /// **'An invitation has been sent to {email}. They will receive an email with instructions to join you on We Connect.'**
  String invitationSentMessage(String email);

  /// Failed to send invitation error prefix
  ///
  /// In en, this message translates to:
  /// **'Failed to send invitation'**
  String get failedToSendInvitation;

  /// Invitation process steps
  ///
  /// In en, this message translates to:
  /// **'1. Your partner will receive an email invitation\n2. They can click the link to create their account\n3. Once they accept, you\'ll both be connected\n4. You can start having conversations with AI guidance'**
  String get invitationSteps;

  /// OK button text
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

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
  /// **'Hi {name}! Your coaching journey will begin once your partner joins you on We Coach.'**
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

  /// Coach Sarah AI Coach full name
  ///
  /// In en, this message translates to:
  /// **'Coach Sarah (AI Coach)'**
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

  /// Exercise step progress indicator
  ///
  /// In en, this message translates to:
  /// **'Step {current}/{total}'**
  String exerciseStepProgress(int current, int total);

  /// Indicator that it is the current user turn in the exercise
  ///
  /// In en, this message translates to:
  /// **'Your turn!'**
  String get exerciseYourTurn;

  /// Indicator that the exercise is waiting for partner
  ///
  /// In en, this message translates to:
  /// **'Waiting for {partnerName}...'**
  String exerciseWaitingFor(String partnerName);

  /// Button to join an active exercise
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get exerciseJoin;

  /// Button to view an active exercise while waiting
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get exerciseView;

  /// Progress dashboard screen title
  ///
  /// In en, this message translates to:
  /// **'Progress Dashboard'**
  String get progressDashboard;

  /// Relationship health score label
  ///
  /// In en, this message translates to:
  /// **'Relationship Health'**
  String get relationshipHealth;

  /// Health score label for high scores
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get healthGreat;

  /// Health score label for medium scores
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get healthGood;

  /// Health score label for low scores
  ///
  /// In en, this message translates to:
  /// **'Getting Started'**
  String get healthGettingStarted;

  /// Description of how health score is calculated
  ///
  /// In en, this message translates to:
  /// **'Based on your conversations, exercises, and engagement'**
  String get healthScoreDescription;

  /// Activity streak card title
  ///
  /// In en, this message translates to:
  /// **'Activity Streak'**
  String get activityStreak;

  /// Days unit label
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// Best streak label
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get best;

  /// Total active days label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalDaysActive;

  /// Weekly activity section title
  ///
  /// In en, this message translates to:
  /// **'Weekly Activity'**
  String get weeklyActivity;

  /// Empty state for weekly activity
  ///
  /// In en, this message translates to:
  /// **'No activity yet this week'**
  String get noActivityYet;

  /// Exercise progress section title
  ///
  /// In en, this message translates to:
  /// **'Exercise Progress'**
  String get exerciseProgress;

  /// Messages stat label
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// Exercises completed stat label
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exercisesCompleted;

  /// AI sessions stat label
  ///
  /// In en, this message translates to:
  /// **'AI Sessions'**
  String get aiSessions;

  /// Exercise completion rate label
  ///
  /// In en, this message translates to:
  /// **'Completion Rate'**
  String get completionRate;

  /// Completed count label
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// Total started exercises label
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get totalStarted;

  /// This month label
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// By category section label
  ///
  /// In en, this message translates to:
  /// **'By Category'**
  String get byCategory;

  /// View progress button label
  ///
  /// In en, this message translates to:
  /// **'View Progress'**
  String get viewProgress;

  /// Progress dashboard card subtitle
  ///
  /// In en, this message translates to:
  /// **'Track your relationship journey and growth'**
  String get trackYourJourney;
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
