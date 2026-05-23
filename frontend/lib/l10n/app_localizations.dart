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

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'We Connect'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your relationship journey together'**
  String get appSubtitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

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

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to your journey together'**
  String get welcomeTitle;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'This is your main conversation space where you and your partner can share thoughts, feelings, and receive guidance from Coach Sarah, your AI coach.'**
  String get welcomeMessage;

  /// No description provided for @shareThoughts.
  ///
  /// In en, this message translates to:
  /// **'Share what\'s on your mind. Coach Sarah is here to help guide your conversation.'**
  String get shareThoughts;

  /// No description provided for @conversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get conversations;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @mainConversation.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get mainConversation;

  /// No description provided for @otherConversations.
  ///
  /// In en, this message translates to:
  /// **'Other Conversations'**
  String get otherConversations;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @typing.
  ///
  /// In en, this message translates to:
  /// **'Typing'**
  String get typing;

  /// No description provided for @partnerTyping.
  ///
  /// In en, this message translates to:
  /// **'Partner is typing'**
  String get partnerTyping;

  /// No description provided for @partnersTyping.
  ///
  /// In en, this message translates to:
  /// **'Partners are typing'**
  String get partnersTyping;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @invitePartner.
  ///
  /// In en, this message translates to:
  /// **'Invite Partner'**
  String get invitePartner;

  /// No description provided for @inviteYourPartner.
  ///
  /// In en, this message translates to:
  /// **'Invite Your Partner'**
  String get inviteYourPartner;

  /// No description provided for @sendInvitation.
  ///
  /// In en, this message translates to:
  /// **'Send Invitation'**
  String get sendInvitation;

  /// No description provided for @invitePartnerDescription.
  ///
  /// In en, this message translates to:
  /// **'Invite your partner to join you on We Connect. They will receive an email with instructions to create their account and connect with you.'**
  String get invitePartnerDescription;

  /// No description provided for @partnerEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Partner\'s Email Address'**
  String get partnerEmailAddress;

  /// No description provided for @enterPartnerEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your partner\'s email address'**
  String get enterPartnerEmail;

  /// No description provided for @pleaseEnterPartnerEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your partner\'s email'**
  String get pleaseEnterPartnerEmail;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get pleaseEnterValidEmail;

  /// No description provided for @cannotInviteYourself.
  ///
  /// In en, this message translates to:
  /// **'You cannot invite yourself'**
  String get cannotInviteYourself;

  /// No description provided for @personalMessageOptional.
  ///
  /// In en, this message translates to:
  /// **'Personal Message (Optional)'**
  String get personalMessageOptional;

  /// No description provided for @addPersonalMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a personal message to your invitation...'**
  String get addPersonalMessage;

  /// No description provided for @invitationSent.
  ///
  /// In en, this message translates to:
  /// **'Invitation Sent!'**
  String get invitationSent;

  /// No description provided for @invitationSentMessage.
  ///
  /// In en, this message translates to:
  /// **'An invitation has been sent to {email}. They will receive an email with instructions to join you on We Connect.'**
  String invitationSentMessage(String email);

  /// No description provided for @failedToSendInvitation.
  ///
  /// In en, this message translates to:
  /// **'Failed to send invitation'**
  String get failedToSendInvitation;

  /// No description provided for @invitationSteps.
  ///
  /// In en, this message translates to:
  /// **'1. Your partner will receive an email invitation\n2. They can click the link to create their account\n3. Once they accept, you\'ll both be connected\n4. You can start having conversations with AI guidance'**
  String get invitationSteps;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @waitingForPartner.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your partner to join...'**
  String get waitingForPartner;

  /// No description provided for @waitingForPartnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your partner'**
  String get waitingForPartnerTitle;

  /// No description provided for @waitingRoomGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi {name}! Your coaching journey will begin once your partner joins you on We Connect.'**
  String waitingRoomGreeting(String name);

  /// No description provided for @whatHappensNext.
  ///
  /// In en, this message translates to:
  /// **'What happens next?'**
  String get whatHappensNext;

  /// No description provided for @sendAnotherInvitation.
  ///
  /// In en, this message translates to:
  /// **'Send Another Invitation'**
  String get sendAnotherInvitation;

  /// No description provided for @getStartedTitle.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStartedTitle;

  /// No description provided for @getStartedGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi {name}! To begin your coaching journey, invite your partner to join you on We Connect.'**
  String getStartedGreeting(String name);

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get howItWorks;

  /// No description provided for @getStartedExplanation.
  ///
  /// In en, this message translates to:
  /// **'Send an invitation to your partner by email. Once they create their account and accept, you\'ll both be connected and can start your coaching sessions together.'**
  String get getStartedExplanation;

  /// No description provided for @invitePartnerButton.
  ///
  /// In en, this message translates to:
  /// **'Invite Your Partner'**
  String get invitePartnerButton;

  /// No description provided for @pendingInvitationInfo.
  ///
  /// In en, this message translates to:
  /// **'An invitation was sent to {email}. Once they create their account and accept, you\'ll be connected.'**
  String pendingInvitationInfo(String email);

  /// No description provided for @invitePartnerMessage.
  ///
  /// In en, this message translates to:
  /// **'Share this invitation with your partner to start your relationship communication journey together.'**
  String get invitePartnerMessage;

  /// No description provided for @createNewConversation.
  ///
  /// In en, this message translates to:
  /// **'Create New Conversation'**
  String get createNewConversation;

  /// No description provided for @conversationTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversation Title'**
  String get conversationTitle;

  /// No description provided for @conversationTopic.
  ///
  /// In en, this message translates to:
  /// **'Topic (Optional)'**
  String get conversationTopic;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get failedToLoad;

  /// No description provided for @failedToSend.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message'**
  String get failedToSend;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start the conversation by sending a message!'**
  String get startConversation;

  /// No description provided for @startYourConversation.
  ///
  /// In en, this message translates to:
  /// **'Start your conversation'**
  String get startYourConversation;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @mainConversationTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get mainConversationTitle;

  /// No description provided for @mainConversationTopic.
  ///
  /// In en, this message translates to:
  /// **'Your journey together'**
  String get mainConversationTopic;

  /// No description provided for @aiCounsellor.
  ///
  /// In en, this message translates to:
  /// **'AI Coach'**
  String get aiCounsellor;

  /// No description provided for @drSarahAiCounsellor.
  ///
  /// In en, this message translates to:
  /// **'Coach Sarah (AI Coach)'**
  String get drSarahAiCounsellor;

  /// No description provided for @startFirstConversationMessage.
  ///
  /// In en, this message translates to:
  /// **'Start your first conversation with your partner and get guidance from our AI relationship coach.'**
  String get startFirstConversationMessage;

  /// No description provided for @partnerInvitationMessage.
  ///
  /// In en, this message translates to:
  /// **'Once your partner accepts the invitation and creates their account, you\'ll both have access to your conversation where you can start sharing and receiving guidance from our AI relationship coach.'**
  String get partnerInvitationMessage;

  /// No description provided for @exerciseStepProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {current}/{total}'**
  String exerciseStepProgress(int current, int total);

  /// No description provided for @exerciseYourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn!'**
  String get exerciseYourTurn;

  /// No description provided for @exerciseWaitingFor.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {partnerName}...'**
  String exerciseWaitingFor(String partnerName);

  /// No description provided for @exerciseJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get exerciseJoin;

  /// No description provided for @exerciseView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get exerciseView;

  /// No description provided for @progressDashboard.
  ///
  /// In en, this message translates to:
  /// **'Progress Dashboard'**
  String get progressDashboard;

  /// No description provided for @relationshipHealth.
  ///
  /// In en, this message translates to:
  /// **'Relationship Health'**
  String get relationshipHealth;

  /// No description provided for @healthGreat.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get healthGreat;

  /// No description provided for @healthGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get healthGood;

  /// No description provided for @healthGettingStarted.
  ///
  /// In en, this message translates to:
  /// **'Getting Started'**
  String get healthGettingStarted;

  /// No description provided for @healthScoreDescription.
  ///
  /// In en, this message translates to:
  /// **'Based on your conversations, exercises, and engagement'**
  String get healthScoreDescription;

  /// No description provided for @activityStreak.
  ///
  /// In en, this message translates to:
  /// **'Activity Streak'**
  String get activityStreak;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @best.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get best;

  /// No description provided for @totalDaysActive.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalDaysActive;

  /// No description provided for @weeklyActivity.
  ///
  /// In en, this message translates to:
  /// **'Weekly Activity'**
  String get weeklyActivity;

  /// No description provided for @noActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No activity yet this week'**
  String get noActivityYet;

  /// No description provided for @exerciseProgress.
  ///
  /// In en, this message translates to:
  /// **'Exercise Progress'**
  String get exerciseProgress;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @exercisesCompleted.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exercisesCompleted;

  /// No description provided for @aiSessions.
  ///
  /// In en, this message translates to:
  /// **'AI Sessions'**
  String get aiSessions;

  /// No description provided for @completionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion Rate'**
  String get completionRate;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @totalStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get totalStarted;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @byCategory.
  ///
  /// In en, this message translates to:
  /// **'By Category'**
  String get byCategory;

  /// No description provided for @yourJourney.
  ///
  /// In en, this message translates to:
  /// **'Your Journey'**
  String get yourJourney;

  /// No description provided for @viewProgress.
  ///
  /// In en, this message translates to:
  /// **'View Progress'**
  String get viewProgress;

  /// No description provided for @trackYourJourney.
  ///
  /// In en, this message translates to:
  /// **'Track your relationship journey and growth'**
  String get trackYourJourney;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}!'**
  String welcomeBack(String name);

  /// No description provided for @connectedWith.
  ///
  /// In en, this message translates to:
  /// **'You\'re connected with {name}'**
  String connectedWith(String name);

  /// No description provided for @invitePartnerPrompt.
  ///
  /// In en, this message translates to:
  /// **'Invite your partner to start your relationship communication journey together'**
  String get invitePartnerPrompt;

  /// No description provided for @pendingInvitationTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitation Pending'**
  String get pendingInvitationTitle;

  /// No description provided for @pendingInvitationMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ve sent an invitation to {email}. We\'re waiting for them to accept.'**
  String pendingInvitationMessage(String email);

  /// No description provided for @resendInvitation.
  ///
  /// In en, this message translates to:
  /// **'Resend Invitation'**
  String get resendInvitation;

  /// No description provided for @sendInvitationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send an invitation to start coaching together'**
  String get sendInvitationSubtitle;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @mainThread.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get mainThread;

  /// No description provided for @continueMainConversation.
  ///
  /// In en, this message translates to:
  /// **'Continue your conversation with your partner'**
  String get continueMainConversation;

  /// No description provided for @viewAllConversations.
  ///
  /// In en, this message translates to:
  /// **'View all your conversation threads'**
  String get viewAllConversations;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get profileSettings;

  /// No description provided for @manageAccountPreferences.
  ///
  /// In en, this message translates to:
  /// **'Manage your account and preferences'**
  String get manageAccountPreferences;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccess;

  /// No description provided for @failedToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get failedToUpdateProfile;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @pleaseEnterFirstName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your first name'**
  String get pleaseEnterFirstName;

  /// No description provided for @pleaseEnterLastName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your last name'**
  String get pleaseEnterLastName;

  /// No description provided for @emailCannotBeChanged.
  ///
  /// In en, this message translates to:
  /// **'Email cannot be changed'**
  String get emailCannotBeChanged;

  /// No description provided for @relationshipStatus.
  ///
  /// In en, this message translates to:
  /// **'Relationship Status'**
  String get relationshipStatus;

  /// No description provided for @noPartnerConnected.
  ///
  /// In en, this message translates to:
  /// **'No partner connected'**
  String get noPartnerConnected;

  /// No description provided for @exerciseHistory.
  ///
  /// In en, this message translates to:
  /// **'Exercise History'**
  String get exerciseHistory;

  /// No description provided for @viewPastExercises.
  ///
  /// In en, this message translates to:
  /// **'View past exercises and summaries'**
  String get viewPastExercises;

  /// No description provided for @paymentPortal.
  ///
  /// In en, this message translates to:
  /// **'Payment Portal'**
  String get paymentPortal;

  /// No description provided for @manageSubscriptionBilling.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription and billing'**
  String get manageSubscriptionBilling;

  /// No description provided for @billingHistory.
  ///
  /// In en, this message translates to:
  /// **'Billing History'**
  String get billingHistory;

  /// No description provided for @viewInvoicesPayments.
  ///
  /// In en, this message translates to:
  /// **'View invoices and payments'**
  String get viewInvoicesPayments;

  /// No description provided for @changePlan.
  ///
  /// In en, this message translates to:
  /// **'Change Plan'**
  String get changePlan;

  /// No description provided for @upgradeOrChangeSubscription.
  ///
  /// In en, this message translates to:
  /// **'Upgrade or change subscription'**
  String get upgradeOrChangeSubscription;

  /// No description provided for @welcomeToApp.
  ///
  /// In en, this message translates to:
  /// **'Welcome to We Connect'**
  String get welcomeToApp;

  /// No description provided for @strengthenRelationship.
  ///
  /// In en, this message translates to:
  /// **'Strengthen your relationship together'**
  String get strengthenRelationship;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @noAccountSignUp.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get noAccountSignUp;

  /// No description provided for @loginJoinedPartner.
  ///
  /// In en, this message translates to:
  /// **'Successfully logged in and joined your partner!'**
  String get loginJoinedPartner;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @joinApp.
  ///
  /// In en, this message translates to:
  /// **'Join We Connect'**
  String get joinApp;

  /// No description provided for @startJourneyBetterComm.
  ///
  /// In en, this message translates to:
  /// **'Start your journey to better communication'**
  String get startJourneyBetterComm;

  /// No description provided for @pleaseEnterAPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get pleaseEnterAPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @pleaseConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @serviceDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This service provides relationship communication support only. It is NOT therapy or a substitute for professional mental health services.'**
  String get serviceDisclaimer;

  /// No description provided for @iAgreeToThe.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get iAgreeToThe;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @andPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **' and the '**
  String get andPrivacyPolicy;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @mustAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'You must accept the Terms of Service and Privacy Policy to create an account'**
  String get mustAcceptTerms;

  /// No description provided for @accountCreatedJoinedPartner.
  ///
  /// In en, this message translates to:
  /// **'Account created and successfully joined your partner!'**
  String get accountCreatedJoinedPartner;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registrationFailed;

  /// No description provided for @emailAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists. Please log in or use a different email.'**
  String get emailAlreadyExists;

  /// No description provided for @alreadyHaveAccountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccountSignIn;

  /// No description provided for @joinYourPartner.
  ///
  /// In en, this message translates to:
  /// **'Join Your Partner'**
  String get joinYourPartner;

  /// No description provided for @youveBeenInvited.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been invited!'**
  String get youveBeenInvited;

  /// No description provided for @partnerInvitedYou.
  ///
  /// In en, this message translates to:
  /// **'Your partner has invited you to join We Connect. Create an account or sign in to start your relationship coaching journey together.'**
  String get partnerInvitedYou;

  /// No description provided for @alreadySignedInAccept.
  ///
  /// In en, this message translates to:
  /// **'You\'re already signed in. Click below to accept the invitation.'**
  String get alreadySignedInAccept;

  /// No description provided for @acceptInvitation.
  ///
  /// In en, this message translates to:
  /// **'Accept Invitation'**
  String get acceptInvitation;

  /// No description provided for @invitationInfoSteps.
  ///
  /// In en, this message translates to:
  /// **'• If you already have an account, sign in to connect with your partner\n• If you\'re new, create an account to get started\n• Once connected, you can start conversations together'**
  String get invitationInfoSteps;

  /// No description provided for @successfullyJoinedPartner.
  ///
  /// In en, this message translates to:
  /// **'Successfully joined your partner!'**
  String get successfullyJoinedPartner;

  /// No description provided for @failedToAcceptInvitation.
  ///
  /// In en, this message translates to:
  /// **'Failed to accept invitation'**
  String get failedToAcceptInvitation;

  /// No description provided for @failedToLoadTerms.
  ///
  /// In en, this message translates to:
  /// **'Failed to load Terms of Service'**
  String get failedToLoadTerms;

  /// No description provided for @conversationCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Conversation created successfully'**
  String get conversationCreatedSuccess;

  /// No description provided for @failedToCreateConversation.
  ///
  /// In en, this message translates to:
  /// **'Failed to create conversation'**
  String get failedToCreateConversation;

  /// No description provided for @messageCount.
  ///
  /// In en, this message translates to:
  /// **'{count} messages'**
  String messageCount(int count);

  /// No description provided for @needToInvitePartner.
  ///
  /// In en, this message translates to:
  /// **'You need to invite and connect with your partner before you can start conversations.'**
  String get needToInvitePartner;

  /// No description provided for @noConversationsYet.
  ///
  /// In en, this message translates to:
  /// **'No Conversations Yet'**
  String get noConversationsYet;

  /// No description provided for @newConversation.
  ///
  /// In en, this message translates to:
  /// **'New Conversation'**
  String get newConversation;

  /// No description provided for @conversationTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Communication Issues'**
  String get conversationTitleHint;

  /// No description provided for @pleaseEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get pleaseEnterTitle;

  /// No description provided for @conversationTopicHint.
  ///
  /// In en, this message translates to:
  /// **'What would you like to discuss?'**
  String get conversationTopicHint;

  /// No description provided for @crisisResources.
  ///
  /// In en, this message translates to:
  /// **'Crisis Resources'**
  String get crisisResources;

  /// No description provided for @chooseYourPlan.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Plan'**
  String get chooseYourPlan;

  /// No description provided for @startYourJourneyTogether.
  ///
  /// In en, this message translates to:
  /// **'Start Your Journey Together'**
  String get startYourJourneyTogether;

  /// No description provided for @choosePlanDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan that fits your needs. You can change your plan at any time.'**
  String get choosePlanDescription;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @forever.
  ///
  /// In en, this message translates to:
  /// **'forever'**
  String get forever;

  /// No description provided for @tryAiCoach.
  ///
  /// In en, this message translates to:
  /// **'Try the AI relationship coach'**
  String get tryAiCoach;

  /// No description provided for @aiMessagesPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{count} AI messages per month'**
  String aiMessagesPerMonth(int count);

  /// No description provided for @unlimitedPartnerMessaging.
  ///
  /// In en, this message translates to:
  /// **'Unlimited partner messaging'**
  String get unlimitedPartnerMessaging;

  /// No description provided for @basicExercises.
  ///
  /// In en, this message translates to:
  /// **'Basic exercises'**
  String get basicExercises;

  /// No description provided for @essential.
  ///
  /// In en, this message translates to:
  /// **'Essential'**
  String get essential;

  /// No description provided for @regularSupport.
  ///
  /// In en, this message translates to:
  /// **'Regular support for your relationship'**
  String get regularSupport;

  /// No description provided for @allFreeFeatures.
  ///
  /// In en, this message translates to:
  /// **'All Free features'**
  String get allFreeFeatures;

  /// No description provided for @guidedExercises.
  ///
  /// In en, this message translates to:
  /// **'Guided exercises'**
  String get guidedExercises;

  /// No description provided for @conversationSummaries.
  ///
  /// In en, this message translates to:
  /// **'Conversation summaries'**
  String get conversationSummaries;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @unlimitedAccess.
  ///
  /// In en, this message translates to:
  /// **'Unlimited access to all features'**
  String get unlimitedAccess;

  /// No description provided for @unlimitedAiMessages.
  ///
  /// In en, this message translates to:
  /// **'Unlimited AI messages'**
  String get unlimitedAiMessages;

  /// No description provided for @allEssentialFeatures.
  ///
  /// In en, this message translates to:
  /// **'All Essential features'**
  String get allEssentialFeatures;

  /// No description provided for @prioritySupport.
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get prioritySupport;

  /// No description provided for @advancedInsights.
  ///
  /// In en, this message translates to:
  /// **'Advanced insights'**
  String get advancedInsights;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'POPULAR'**
  String get popular;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'CURRENT PLAN'**
  String get currentPlan;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @annual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get annual;

  /// No description provided for @save20.
  ///
  /// In en, this message translates to:
  /// **'Save 20%'**
  String get save20;

  /// No description provided for @freeTrialInfo.
  ///
  /// In en, this message translates to:
  /// **'7-day free trial • Cancel anytime'**
  String get freeTrialInfo;

  /// No description provided for @currentPlanButton.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get currentPlanButton;

  /// No description provided for @continueWithFree.
  ///
  /// In en, this message translates to:
  /// **'Continue with Free'**
  String get continueWithFree;

  /// No description provided for @startFreeTrial.
  ///
  /// In en, this message translates to:
  /// **'Start Free Trial'**
  String get startFreeTrial;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get perMonth;

  /// No description provided for @perYear.
  ///
  /// In en, this message translates to:
  /// **'/year'**
  String get perYear;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get manageSubscription;

  /// No description provided for @upgradePlan.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Plan'**
  String get upgradePlan;

  /// No description provided for @aboutPaymentPortal.
  ///
  /// In en, this message translates to:
  /// **'About Payment Portal'**
  String get aboutPaymentPortal;

  /// No description provided for @paymentPortalDescription.
  ///
  /// In en, this message translates to:
  /// **'You can manage your subscription, update payment methods, and view billing history through our secure payment portal powered by Stripe.'**
  String get paymentPortalDescription;

  /// No description provided for @couldNotOpenPaymentPortal.
  ///
  /// In en, this message translates to:
  /// **'Could not open payment portal'**
  String get couldNotOpenPaymentPortal;

  /// No description provided for @failedToOpenPortal.
  ///
  /// In en, this message translates to:
  /// **'Failed to open portal'**
  String get failedToOpenPortal;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @noBillingHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No billing history yet'**
  String get noBillingHistoryYet;

  /// No description provided for @invoicesWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your invoices will appear here once you make a payment.'**
  String get invoicesWillAppearHere;

  /// No description provided for @viewInvoice.
  ///
  /// In en, this message translates to:
  /// **'View Invoice'**
  String get viewInvoice;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @void_.
  ///
  /// In en, this message translates to:
  /// **'Void'**
  String get void_;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @invoiceUrlNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Invoice URL not available'**
  String get invoiceUrlNotAvailable;

  /// No description provided for @couldNotOpenInvoice.
  ///
  /// In en, this message translates to:
  /// **'Could not open invoice'**
  String get couldNotOpenInvoice;

  /// No description provided for @failedToLoadBillingHistory.
  ///
  /// In en, this message translates to:
  /// **'Failed to load billing history'**
  String get failedToLoadBillingHistory;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful!'**
  String get paymentSuccessful;

  /// No description provided for @subscriptionActivated.
  ///
  /// In en, this message translates to:
  /// **'Your subscription has been activated.\nEnjoy your enhanced coaching experience!'**
  String get subscriptionActivated;

  /// No description provided for @viewPaymentPortal.
  ///
  /// In en, this message translates to:
  /// **'View Payment Portal'**
  String get viewPaymentPortal;

  /// No description provided for @guidedExercise.
  ///
  /// In en, this message translates to:
  /// **'Guided Exercise'**
  String get guidedExercise;

  /// No description provided for @exerciseComplete.
  ///
  /// In en, this message translates to:
  /// **'Exercise Complete'**
  String get exerciseComplete;

  /// No description provided for @exerciseCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise Complete! ✨'**
  String get exerciseCompleteTitle;

  /// No description provided for @greatWorkCompleting.
  ///
  /// In en, this message translates to:
  /// **'Great work on completing \"{name}\"!'**
  String greatWorkCompleting(String name);

  /// No description provided for @keyTakeaways.
  ///
  /// In en, this message translates to:
  /// **'Key Takeaways'**
  String get keyTakeaways;

  /// No description provided for @generatingSummary.
  ///
  /// In en, this message translates to:
  /// **'Generating your summary...'**
  String get generatingSummary;

  /// No description provided for @returnToConversation.
  ///
  /// In en, this message translates to:
  /// **'Return to Conversation'**
  String get returnToConversation;

  /// No description provided for @instruction.
  ///
  /// In en, this message translates to:
  /// **'Instruction'**
  String get instruction;

  /// No description provided for @guidance.
  ///
  /// In en, this message translates to:
  /// **'Guidance'**
  String get guidance;

  /// No description provided for @conversationSoFar.
  ///
  /// In en, this message translates to:
  /// **'Conversation So Far'**
  String get conversationSoFar;

  /// No description provided for @waitingForPartnerResponse.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your partner to respond...'**
  String get waitingForPartnerResponse;

  /// No description provided for @typeYourResponseHere.
  ///
  /// In en, this message translates to:
  /// **'Type your response here...'**
  String get typeYourResponseHere;

  /// No description provided for @waitingForYourPartner.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your partner...'**
  String get waitingForYourPartner;

  /// No description provided for @completeExercise.
  ///
  /// In en, this message translates to:
  /// **'Complete Exercise'**
  String get completeExercise;

  /// No description provided for @nextStep.
  ///
  /// In en, this message translates to:
  /// **'Next Step'**
  String get nextStep;

  /// No description provided for @leaveExercise.
  ///
  /// In en, this message translates to:
  /// **'Leave Exercise?'**
  String get leaveExercise;

  /// No description provided for @leaveExerciseConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave? Your progress will be saved.'**
  String get leaveExerciseConfirmation;

  /// No description provided for @stay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stay;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @pleaseEnterResponse.
  ///
  /// In en, this message translates to:
  /// **'Please enter a response'**
  String get pleaseEnterResponse;

  /// No description provided for @noExercisesYet.
  ///
  /// In en, this message translates to:
  /// **'No exercises yet'**
  String get noExercisesYet;

  /// No description provided for @completeExercisePrompt.
  ///
  /// In en, this message translates to:
  /// **'Complete an exercise with your partner\nto see it here.'**
  String get completeExercisePrompt;

  /// No description provided for @noSummaryAvailable.
  ///
  /// In en, this message translates to:
  /// **'No summary available.'**
  String get noSummaryAvailable;

  /// No description provided for @failedToLoadHistory.
  ///
  /// In en, this message translates to:
  /// **'Failed to load history'**
  String get failedToLoadHistory;

  /// No description provided for @inProgressStatus.
  ///
  /// In en, this message translates to:
  /// **'In progress ({current}/{total})'**
  String inProgressStatus(int current, int total);

  /// No description provided for @notAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'Not authenticated'**
  String get notAuthenticated;

  /// No description provided for @exerciseNotFound.
  ///
  /// In en, this message translates to:
  /// **'Exercise not found'**
  String get exerciseNotFound;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @categoryCommunication.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get categoryCommunication;

  /// No description provided for @categoryAppreciation.
  ///
  /// In en, this message translates to:
  /// **'Appreciation'**
  String get categoryAppreciation;

  /// No description provided for @categoryConflict.
  ///
  /// In en, this message translates to:
  /// **'Conflict'**
  String get categoryConflict;

  /// No description provided for @categoryEmotional.
  ///
  /// In en, this message translates to:
  /// **'Emotional'**
  String get categoryEmotional;

  /// No description provided for @importantInformation.
  ///
  /// In en, this message translates to:
  /// **'Important Information'**
  String get importantInformation;

  /// No description provided for @disclaimerText.
  ///
  /// In en, this message translates to:
  /// **'This AI provides relationship communication support only. It is NOT therapy or a substitute for professional mental health services. In case of crisis, please contact emergency services.'**
  String get disclaimerText;

  /// No description provided for @needImmediateHelp.
  ///
  /// In en, this message translates to:
  /// **'Need Immediate Help?'**
  String get needImmediateHelp;

  /// No description provided for @crisisDialogText.
  ///
  /// In en, this message translates to:
  /// **'If you or your partner are in crisis or experiencing a mental health emergency, please contact:'**
  String get crisisDialogText;

  /// No description provided for @emergencyServices.
  ///
  /// In en, this message translates to:
  /// **'Emergency Services'**
  String get emergencyServices;

  /// No description provided for @crisisHotlines.
  ///
  /// In en, this message translates to:
  /// **'24/7 Crisis Hotlines'**
  String get crisisHotlines;

  /// No description provided for @crisisHotlinesList.
  ///
  /// In en, this message translates to:
  /// **'• National Suicide Prevention: 988\n• Crisis Text Line: Text HOME to 741741\n• International Association for Suicide Prevention: https://www.iasp.info/resources/Crisis_Centres/'**
  String get crisisHotlinesList;

  /// No description provided for @appProvidesSupport.
  ///
  /// In en, this message translates to:
  /// **'This app provides communication support only. It is not a substitute for professional help.'**
  String get appProvidesSupport;

  /// No description provided for @iUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I Understand'**
  String get iUnderstand;

  /// No description provided for @guidedExerciseSuggestion.
  ///
  /// In en, this message translates to:
  /// **'🎯 Guided Exercise'**
  String get guidedExerciseSuggestion;

  /// No description provided for @tapToStartExercise.
  ///
  /// In en, this message translates to:
  /// **'Tap to start the guided exercise'**
  String get tapToStartExercise;

  /// No description provided for @continueExercise.
  ///
  /// In en, this message translates to:
  /// **'Continue Exercise'**
  String get continueExercise;

  /// No description provided for @tryGuidedExercise.
  ///
  /// In en, this message translates to:
  /// **'Try a Guided Exercise'**
  String get tryGuidedExercise;

  /// No description provided for @exerciseInProgress.
  ///
  /// In en, this message translates to:
  /// **'You have an exercise in progress'**
  String get exerciseInProgress;

  /// No description provided for @practiceSkillsTogether.
  ///
  /// In en, this message translates to:
  /// **'Practice communication skills together'**
  String get practiceSkillsTogether;

  /// No description provided for @chooseAnExercise.
  ///
  /// In en, this message translates to:
  /// **'Choose an Exercise'**
  String get chooseAnExercise;

  /// No description provided for @practiceSkillsWithExercises.
  ///
  /// In en, this message translates to:
  /// **'Practice skills together with guided exercises'**
  String get practiceSkillsWithExercises;

  /// No description provided for @noExercisesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No exercises available'**
  String get noExercisesAvailable;

  /// No description provided for @userIsTyping.
  ///
  /// In en, this message translates to:
  /// **'{name} is typing'**
  String userIsTyping(String name);

  /// No description provided for @aiCoach.
  ///
  /// In en, this message translates to:
  /// **'AI Coach'**
  String get aiCoach;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we\'ll send you a link to reset your password.'**
  String get forgotPasswordDescription;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'If an account with that email exists, a password reset link has been sent.'**
  String get resetLinkSent;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get resetPasswordTitle;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password has been reset successfully. You can now sign in.'**
  String get passwordResetSuccess;

  /// No description provided for @invalidResetLink.
  ///
  /// In en, this message translates to:
  /// **'This password reset link is invalid or has expired.'**
  String get invalidResetLink;

  /// No description provided for @pleaseEnterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a new password'**
  String get pleaseEnterNewPassword;

  /// No description provided for @checkYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkYourEmail;

  /// No description provided for @errorSendingMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message. Please try again.'**
  String get errorSendingMessage;

  /// No description provided for @errorLoadingMessages.
  ///
  /// In en, this message translates to:
  /// **'Failed to load messages.'**
  String get errorLoadingMessages;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorOpeningPaymentPage.
  ///
  /// In en, this message translates to:
  /// **'Could not open payment page.'**
  String get errorOpeningPaymentPage;

  /// No description provided for @errorStartingCheckout.
  ///
  /// In en, this message translates to:
  /// **'Failed to start checkout. Please try again.'**
  String get errorStartingCheckout;

  /// No description provided for @errorLoadingSummary.
  ///
  /// In en, this message translates to:
  /// **'Failed to load summary.'**
  String get errorLoadingSummary;

  /// No description provided for @errorSubmittingResponse.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit response. Please try again.'**
  String get errorSubmittingResponse;
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
