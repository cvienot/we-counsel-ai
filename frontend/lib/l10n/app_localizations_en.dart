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
  String get mainConversation => 'Conversation';

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
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get invitePartner => 'Invite Partner';

  @override
  String get inviteYourPartner => 'Invite Your Partner';

  @override
  String get sendInvitation => 'Send Invitation';

  @override
  String get invitePartnerDescription =>
      'Invite your partner to join you on We Connect. They will receive an email with instructions to create their account and connect with you.';

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
    return 'An invitation has been sent to $email. They will receive an email with instructions to join you on We Connect.';
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
  String get mainConversationTitle => 'Conversation';

  @override
  String get mainConversationTopic => 'Your journey together';

  @override
  String get aiCounsellor => 'AI Counsellor';

  @override
  String get drSarahAiCounsellor => 'Coach Sarah (AI Coach)';

  @override
  String get startFirstConversationMessage =>
      'Start your first conversation with your partner and get guidance from our AI counsellor.';

  @override
  String get partnerInvitationMessage =>
      'Once your partner accepts the invitation and creates their account, you\'ll both have access to your conversation where you can start sharing and receiving guidance from our AI counsellor.';

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

  @override
  String get progressDashboard => 'Progress Dashboard';

  @override
  String get relationshipHealth => 'Relationship Health';

  @override
  String get healthGreat => 'Great';

  @override
  String get healthGood => 'Good';

  @override
  String get healthGettingStarted => 'Getting Started';

  @override
  String get healthScoreDescription =>
      'Based on your conversations, exercises, and engagement';

  @override
  String get activityStreak => 'Activity Streak';

  @override
  String get days => 'days';

  @override
  String get best => 'Best';

  @override
  String get totalDaysActive => 'Total';

  @override
  String get weeklyActivity => 'Weekly Activity';

  @override
  String get noActivityYet => 'No activity yet this week';

  @override
  String get exerciseProgress => 'Exercise Progress';

  @override
  String get messages => 'Messages';

  @override
  String get exercisesCompleted => 'Exercises';

  @override
  String get aiSessions => 'AI Sessions';

  @override
  String get completionRate => 'Completion Rate';

  @override
  String get completed => 'Completed';

  @override
  String get totalStarted => 'Started';

  @override
  String get thisMonth => 'This Month';

  @override
  String get byCategory => 'By Category';

  @override
  String get yourJourney => 'Your Journey';

  @override
  String get viewProgress => 'View Progress';

  @override
  String get trackYourJourney => 'Track your relationship journey and growth';

  @override
  String welcomeBack(String name) {
    return 'Welcome back, $name!';
  }

  @override
  String connectedWith(String name) {
    return 'You\'re connected with $name';
  }

  @override
  String get invitePartnerPrompt =>
      'Invite your partner to start your counselling journey together';

  @override
  String get pendingInvitationTitle => 'Invitation Pending';

  @override
  String pendingInvitationMessage(String email) {
    return 'You\'ve sent an invitation to $email. We\'re waiting for them to accept.';
  }

  @override
  String get resendInvitation => 'Resend Invitation';

  @override
  String get sendInvitationSubtitle =>
      'Send an invitation to start counselling together';

  @override
  String get getStarted => 'Get Started';

  @override
  String get mainThread => 'Conversation';

  @override
  String get continueMainConversation =>
      'Continue your conversation with your partner';

  @override
  String get viewAllConversations => 'View all your conversation threads';

  @override
  String get profileSettings => 'Profile Settings';

  @override
  String get manageAccountPreferences => 'Manage your account and preferences';

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully';

  @override
  String get failedToUpdateProfile => 'Failed to update profile';

  @override
  String get logoutConfirmation => 'Are you sure you want to logout?';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get pleaseEnterFirstName => 'Please enter your first name';

  @override
  String get pleaseEnterLastName => 'Please enter your last name';

  @override
  String get emailCannotBeChanged => 'Email cannot be changed';

  @override
  String get relationshipStatus => 'Relationship Status';

  @override
  String get noPartnerConnected => 'No partner connected';

  @override
  String get exerciseHistory => 'Exercise History';

  @override
  String get viewPastExercises => 'View past exercises and summaries';

  @override
  String get paymentPortal => 'Payment Portal';

  @override
  String get manageSubscriptionBilling => 'Manage subscription and billing';

  @override
  String get billingHistory => 'Billing History';

  @override
  String get viewInvoicesPayments => 'View invoices and payments';

  @override
  String get changePlan => 'Change Plan';

  @override
  String get upgradeOrChangeSubscription => 'Upgrade or change subscription';

  @override
  String get welcomeToApp => 'Welcome to We Coach';

  @override
  String get strengthenRelationship => 'Strengthen your relationship together';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get signIn => 'Sign In';

  @override
  String get noAccountSignUp => 'Don\'t have an account? Sign up';

  @override
  String get loginJoinedPartner =>
      'Successfully logged in and joined your partner!';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get createAccount => 'Create Account';

  @override
  String get joinApp => 'Join We Coach';

  @override
  String get startJourneyBetterComm =>
      'Start your journey to better communication';

  @override
  String get pleaseEnterAPassword => 'Please enter a password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get pleaseConfirmPassword => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get serviceDisclaimer =>
      'This service provides relationship communication support only. It is NOT therapy or a substitute for professional mental health services.';

  @override
  String get iAgreeToThe => 'I agree to the ';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get mustAcceptTerms =>
      'You must accept the Terms of Service to create an account';

  @override
  String get accountCreatedJoinedPartner =>
      'Account created and successfully joined your partner!';

  @override
  String get registrationFailed => 'Registration failed';

  @override
  String get alreadyHaveAccountSignIn => 'Already have an account? Sign in';

  @override
  String get joinYourPartner => 'Join Your Partner';

  @override
  String get youveBeenInvited => 'You\'ve been invited!';

  @override
  String get partnerInvitedYou =>
      'Your partner has invited you to join We Coach. Create an account or sign in to start your relationship coaching journey together.';

  @override
  String get alreadySignedInAccept =>
      'You\'re already signed in. Click below to accept the invitation.';

  @override
  String get acceptInvitation => 'Accept Invitation';

  @override
  String get invitationInfoSteps =>
      '• If you already have an account, sign in to connect with your partner\n• If you\'re new, create an account to get started\n• Once connected, you can start conversations together';

  @override
  String get successfullyJoinedPartner => 'Successfully joined your partner!';

  @override
  String get failedToAcceptInvitation => 'Failed to accept invitation';

  @override
  String get failedToLoadTerms => 'Failed to load Terms of Service';

  @override
  String get conversationCreatedSuccess => 'Conversation created successfully';

  @override
  String get failedToCreateConversation => 'Failed to create conversation';

  @override
  String messageCount(int count) {
    return '$count messages';
  }

  @override
  String get needToInvitePartner =>
      'You need to invite and connect with your partner before you can start conversations.';

  @override
  String get noConversationsYet => 'No Conversations Yet';

  @override
  String get newConversation => 'New Conversation';

  @override
  String get conversationTitleHint => 'e.g., Communication Issues';

  @override
  String get pleaseEnterTitle => 'Please enter a title';

  @override
  String get conversationTopicHint => 'What would you like to discuss?';

  @override
  String get crisisResources => 'Crisis Resources';

  @override
  String get chooseYourPlan => 'Choose Your Plan';

  @override
  String get startYourJourneyTogether => 'Start Your Journey Together';

  @override
  String get choosePlanDescription =>
      'Choose a plan that fits your needs. You can change your plan at any time.';

  @override
  String get free => 'Free';

  @override
  String get forever => 'forever';

  @override
  String get tryAiCoach => 'Try the AI relationship coach';

  @override
  String aiMessagesPerMonth(int count) {
    return '$count AI messages per month';
  }

  @override
  String get unlimitedPartnerMessaging => 'Unlimited partner messaging';

  @override
  String get basicExercises => 'Basic exercises';

  @override
  String get essential => 'Essential';

  @override
  String get regularSupport => 'Regular support for your relationship';

  @override
  String get allFreeFeatures => 'All Free features';

  @override
  String get guidedExercises => 'Guided exercises';

  @override
  String get conversationSummaries => 'Conversation summaries';

  @override
  String get premium => 'Premium';

  @override
  String get unlimitedAccess => 'Unlimited access to all features';

  @override
  String get unlimitedAiMessages => 'Unlimited AI messages';

  @override
  String get allEssentialFeatures => 'All Essential features';

  @override
  String get prioritySupport => 'Priority support';

  @override
  String get advancedInsights => 'Advanced insights';

  @override
  String get popular => 'POPULAR';

  @override
  String get currentPlan => 'CURRENT PLAN';

  @override
  String get monthly => 'Monthly';

  @override
  String get annual => 'Annual';

  @override
  String get save20 => 'Save 20%';

  @override
  String get freeTrialInfo => '7-day free trial • Cancel anytime';

  @override
  String get currentPlanButton => 'Current Plan';

  @override
  String get continueWithFree => 'Continue with Free';

  @override
  String get startFreeTrial => 'Start Free Trial';

  @override
  String get perMonth => '/month';

  @override
  String get perYear => '/year';

  @override
  String get manageSubscription => 'Manage Subscription';

  @override
  String get upgradePlan => 'Upgrade Plan';

  @override
  String get aboutPaymentPortal => 'About Payment Portal';

  @override
  String get paymentPortalDescription =>
      'You can manage your subscription, update payment methods, and view billing history through our secure payment portal powered by Stripe.';

  @override
  String get couldNotOpenPaymentPortal => 'Could not open payment portal';

  @override
  String get failedToOpenPortal => 'Failed to open portal';

  @override
  String get refresh => 'Refresh';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get noBillingHistoryYet => 'No billing history yet';

  @override
  String get invoicesWillAppearHere =>
      'Your invoices will appear here once you make a payment.';

  @override
  String get viewInvoice => 'View Invoice';

  @override
  String get paid => 'Paid';

  @override
  String get pending => 'Pending';

  @override
  String get void_ => 'Void';

  @override
  String get failed => 'Failed';

  @override
  String get subscription => 'Subscription';

  @override
  String get invoiceUrlNotAvailable => 'Invoice URL not available';

  @override
  String get couldNotOpenInvoice => 'Could not open invoice';

  @override
  String get failedToLoadBillingHistory => 'Failed to load billing history';

  @override
  String get paymentSuccessful => 'Payment Successful!';

  @override
  String get subscriptionActivated =>
      'Your subscription has been activated.\nEnjoy your enhanced coaching experience!';

  @override
  String get viewPaymentPortal => 'View Payment Portal';

  @override
  String get guidedExercise => 'Guided Exercise';

  @override
  String get exerciseComplete => 'Exercise Complete';

  @override
  String get exerciseCompleteTitle => 'Exercise Complete! ✨';

  @override
  String greatWorkCompleting(String name) {
    return 'Great work on completing \"$name\"!';
  }

  @override
  String get keyTakeaways => 'Key Takeaways';

  @override
  String get generatingSummary => 'Generating your summary...';

  @override
  String get returnToConversation => 'Return to Conversation';

  @override
  String get instruction => 'Instruction';

  @override
  String get guidance => 'Guidance';

  @override
  String get conversationSoFar => 'Conversation So Far';

  @override
  String get waitingForPartnerResponse =>
      'Waiting for your partner to respond...';

  @override
  String get typeYourResponseHere => 'Type your response here...';

  @override
  String get waitingForYourPartner => 'Waiting for your partner...';

  @override
  String get completeExercise => 'Complete Exercise';

  @override
  String get nextStep => 'Next Step';

  @override
  String get leaveExercise => 'Leave Exercise?';

  @override
  String get leaveExerciseConfirmation =>
      'Are you sure you want to leave? Your progress will be saved.';

  @override
  String get stay => 'Stay';

  @override
  String get leave => 'Leave';

  @override
  String get pleaseEnterResponse => 'Please enter a response';

  @override
  String get noExercisesYet => 'No exercises yet';

  @override
  String get completeExercisePrompt =>
      'Complete an exercise with your partner\nto see it here.';

  @override
  String get noSummaryAvailable => 'No summary available.';

  @override
  String get failedToLoadHistory => 'Failed to load history';

  @override
  String inProgressStatus(int current, int total) {
    return 'In progress ($current/$total)';
  }

  @override
  String get notAuthenticated => 'Not authenticated';

  @override
  String get exerciseNotFound => 'Exercise not found';

  @override
  String get goBack => 'Go Back';

  @override
  String get categoryCommunication => 'Communication';

  @override
  String get categoryAppreciation => 'Appreciation';

  @override
  String get categoryConflict => 'Conflict';

  @override
  String get categoryEmotional => 'Emotional';

  @override
  String get importantInformation => 'Important Information';

  @override
  String get disclaimerText =>
      'This AI provides relationship communication support only. It is NOT therapy or a substitute for professional mental health services. In case of crisis, please contact emergency services.';

  @override
  String get needImmediateHelp => 'Need Immediate Help?';

  @override
  String get crisisDialogText =>
      'If you or your partner are in crisis or experiencing a mental health emergency, please contact:';

  @override
  String get emergencyServices => 'Emergency Services';

  @override
  String get crisisHotlines => '24/7 Crisis Hotlines';

  @override
  String get crisisHotlinesList =>
      '• National Suicide Prevention: 988\n• Crisis Text Line: Text HOME to 741741\n• International Association for Suicide Prevention: https://www.iasp.info/resources/Crisis_Centres/';

  @override
  String get appProvidesSupport =>
      'This app provides communication support only. It is not a substitute for professional help.';

  @override
  String get iUnderstand => 'I Understand';

  @override
  String get guidedExerciseSuggestion => '🎯 Guided Exercise';

  @override
  String get tapToStartExercise => 'Tap to start the guided exercise';

  @override
  String get continueExercise => 'Continue Exercise';

  @override
  String get tryGuidedExercise => 'Try a Guided Exercise';

  @override
  String get exerciseInProgress => 'You have an exercise in progress';

  @override
  String get practiceSkillsTogether => 'Practice communication skills together';

  @override
  String get chooseAnExercise => 'Choose an Exercise';

  @override
  String get practiceSkillsWithExercises =>
      'Practice skills together with guided exercises';

  @override
  String get noExercisesAvailable => 'No exercises available';

  @override
  String userIsTyping(String name) {
    return '$name is typing';
  }

  @override
  String get aiCoach => 'AI Coach';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get forgotPasswordTitle => 'Reset Password';

  @override
  String get forgotPasswordDescription =>
      'Enter your email address and we\'ll send you a link to reset your password.';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get resetLinkSent =>
      'If an account with that email exists, a password reset link has been sent.';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get resetPasswordTitle => 'Set New Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get passwordResetSuccess =>
      'Password has been reset successfully. You can now sign in.';

  @override
  String get invalidResetLink =>
      'This password reset link is invalid or has expired.';

  @override
  String get pleaseEnterNewPassword => 'Please enter a new password';

  @override
  String get checkYourEmail => 'Check your email';

  @override
  String get errorSendingMessage => 'Failed to send message. Please try again.';

  @override
  String get errorLoadingMessages => 'Failed to load messages.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorOpeningPaymentPage => 'Could not open payment page.';

  @override
  String get errorStartingCheckout =>
      'Failed to start checkout. Please try again.';

  @override
  String get errorLoadingSummary => 'Failed to load summary.';

  @override
  String get errorSubmittingResponse =>
      'Failed to submit response. Please try again.';
}
