// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'We Coach';

  @override
  String get appSubtitle => 'Your relationship journey together';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get logout => 'Logout';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get welcomeTitle => 'Welcome to your journey together';

  @override
  String get welcomeMessage =>
      'This is your main conversation space where you and your partner can share thoughts, feelings, and receive guidance from Coach Sarah, your AI coach.';

  @override
  String get shareThoughts =>
      'Share what\'s on your mind. Coach Sarah is here to help guide your conversation.';

  @override
  String get conversations => 'Conversations';

  @override
  String get profile => 'Profile';

  @override
  String get mainConversation => 'Main Conversation';

  @override
  String get otherConversations => 'Other Conversations';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get send => 'Send';

  @override
  String get typing => 'Typing';

  @override
  String get partnerTyping => 'Partner is typing';

  @override
  String get partnersTyping => 'Partners are typing';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get invitePartner => 'Invite Partner';

  @override
  String get inviteYourPartner => 'Invite Your Partner';

  @override
  String get sendInvitation => 'Send Invitation';

  @override
  String get invitePartnerDescription =>
      'Invite your partner to join you on We Counsel. They will receive an email with instructions to create their account and connect with you.';

  @override
  String get partnerEmailAddress => 'Partner\'s Email Address';

  @override
  String get enterPartnerEmail => 'Enter your partner\'s email address';

  @override
  String get pleaseEnterPartnerEmail => 'Please enter your partner\'s email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email address';

  @override
  String get cannotInviteYourself => 'You cannot invite yourself';

  @override
  String get personalMessageOptional => 'Personal Message (Optional)';

  @override
  String get addPersonalMessage =>
      'Add a personal message to your invitation...';

  @override
  String get invitationSent => 'Invitation Sent!';

  @override
  String invitationSentMessage(String email) {
    return 'An invitation has been sent to $email. They will receive an email with instructions to join you on We Counsel.';
  }

  @override
  String get failedToSendInvitation => 'Failed to send invitation';

  @override
  String get invitationSteps =>
      '1. Your partner will receive an email invitation\n2. They can click the link to create their account\n3. Once they accept, you\'ll both be connected\n4. You can start having conversations with AI guidance';

  @override
  String get ok => 'OK';

  @override
  String get waitingForPartner => 'Waiting for your partner to join...';

  @override
  String get waitingForPartnerTitle => 'Waiting for your partner';

  @override
  String waitingRoomGreeting(String name) {
    return 'Hi $name! Your coaching journey will begin once your partner joins you on We Coach.';
  }

  @override
  String get whatHappensNext => 'What happens next?';

  @override
  String get sendAnotherInvitation => 'Send Another Invitation';

  @override
  String get invitePartnerMessage =>
      'Share this invitation with your partner to start your counselling journey together.';

  @override
  String get createNewConversation => 'Create New Conversation';

  @override
  String get conversationTitle => 'Conversation Title';

  @override
  String get conversationTopic => 'Topic (Optional)';

  @override
  String get create => 'Create';

  @override
  String get failedToLoad => 'Failed to load';

  @override
  String get failedToSend => 'Failed to send message';

  @override
  String get startConversation =>
      'Start the conversation by sending a message!';

  @override
  String get startYourConversation => 'Start your conversation';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get mainConversationTitle => 'Main Conversation';

  @override
  String get mainConversationTopic => 'Your ongoing journey together';

  @override
  String get aiCounsellor => 'AI Counsellor';

  @override
  String get drSarahAiCounsellor => 'Coach Sarah (AI Coach)';

  @override
  String get startFirstConversationMessage =>
      'Start your first conversation with your partner and get guidance from our AI counsellor.';

  @override
  String get partnerInvitationMessage =>
      'Once your partner accepts the invitation and creates their account, you\'ll both have access to your main conversation thread where you can start sharing and receiving guidance from our AI counsellor.';

  @override
  String exerciseStepProgress(int current, int total) {
    return 'Step $current/$total';
  }

  @override
  String get exerciseYourTurn => 'Your turn!';

  @override
  String exerciseWaitingFor(String partnerName) {
    return 'Waiting for $partnerName...';
  }

  @override
  String get exerciseJoin => 'Join';

  @override
  String get exerciseView => 'View';
}
