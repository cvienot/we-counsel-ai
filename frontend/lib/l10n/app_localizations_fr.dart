// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'We Connect';

  @override
  String get appSubtitle => 'Votre parcours relationnel ensemble';

  @override
  String get login => 'Connexion';

  @override
  String get register => 'S\'inscrire';

  @override
  String get logout => 'Déconnexion';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get firstName => 'Prénom';

  @override
  String get lastName => 'Nom';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get welcomeTitle => 'Bienvenue dans votre parcours ensemble';

  @override
  String get welcomeMessage =>
      'Ceci est votre espace de conversation principal où vous et votre partenaire pouvez partager vos pensées, sentiments et recevoir des conseils de Coach Sarah, votre coach IA.';

  @override
  String get shareThoughts =>
      'Partagez ce qui vous préoccupe. Coach Sarah est là pour vous aider à guider votre conversation.';

  @override
  String get conversations => 'Conversations';

  @override
  String get profile => 'Profil';

  @override
  String get mainConversation => 'Conversation';

  @override
  String get otherConversations => 'Autres Conversations';

  @override
  String get typeMessage => 'Tapez un message...';

  @override
  String get send => 'Envoyer';

  @override
  String get typing => 'En train d\'écrire';

  @override
  String get partnerTyping => 'Le partenaire écrit';

  @override
  String get partnersTyping => 'Les partenaires écrivent';

  @override
  String get loading => 'Chargement...';

  @override
  String get error => 'Erreur';

  @override
  String get retry => 'Réessayer';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Sauvegarder';

  @override
  String get close => 'Fermer';

  @override
  String get back => 'Retour';

  @override
  String get startupTakingLong => 'La connexion prend plus de temps que prévu.';

  @override
  String get startupTakingLongHelp =>
      'Vous pouvez relancer la vérification de session ou vous reconnecter.';

  @override
  String get signInAgain => 'Se reconnecter';

  @override
  String get invitePartner => 'Inviter Partenaire';

  @override
  String get inviteYourPartner => 'Invitez votre partenaire';

  @override
  String get sendInvitation => 'Envoyer l\'invitation';

  @override
  String get invitePartnerDescription =>
      'Invitez votre partenaire à vous rejoindre sur We Connect. Il recevra un e-mail avec les instructions pour créer son compte et se connecter avec vous.';

  @override
  String get partnerEmailAddress => 'Adresse e-mail du partenaire';

  @override
  String get enterPartnerEmail =>
      'Entrez l\'adresse e-mail de votre partenaire';

  @override
  String get pleaseEnterPartnerEmail =>
      'Veuillez entrer l\'e-mail de votre partenaire';

  @override
  String get pleaseEnterValidEmail =>
      'Veuillez entrer une adresse e-mail valide';

  @override
  String get cannotInviteYourself =>
      'Vous ne pouvez pas vous inviter vous-même';

  @override
  String get personalMessageOptional => 'Message personnel (optionnel)';

  @override
  String get addPersonalMessage =>
      'Ajoutez un message personnel à votre invitation...';

  @override
  String get invitationSent => 'Invitation envoyée !';

  @override
  String invitationSentMessage(String email) {
    return 'Une invitation a été envoyée à $email. Il recevra un e-mail avec les instructions pour vous rejoindre sur We Connect.';
  }

  @override
  String get failedToSendInvitation => 'Échec de l\'envoi de l\'invitation';

  @override
  String get invitationSteps =>
      '1. Votre partenaire recevra une invitation par e-mail\n2. Il pourra cliquer sur le lien pour créer son compte\n3. Une fois accepté, vous serez tous les deux connectés\n4. Vous pourrez commencer à avoir des conversations avec l\'aide de l\'IA';

  @override
  String get ok => 'OK';

  @override
  String get waitingForPartner => 'En attente de votre partenaire...';

  @override
  String get waitingForPartnerTitle => 'En attente de votre partenaire';

  @override
  String waitingRoomGreeting(String name) {
    return 'Bonjour $name ! Votre parcours de coaching commencera une fois que votre partenaire vous rejoindra sur We Connect.';
  }

  @override
  String get whatHappensNext => 'Que se passe-t-il ensuite ?';

  @override
  String get sendAnotherInvitation => 'Envoyer une autre invitation';

  @override
  String get getStartedTitle => 'Pour commencer';

  @override
  String getStartedGreeting(String name) {
    return 'Bonjour $name ! Pour commencer votre parcours de coaching, invitez votre partenaire à vous rejoindre sur We Connect.';
  }

  @override
  String get howItWorks => 'Comment ça marche';

  @override
  String get getStartedExplanation =>
      'Envoyez une invitation à votre partenaire par e-mail. Une fois son compte créé et l\'invitation acceptée, vous serez connectés et pourrez commencer vos séances de coaching ensemble.';

  @override
  String get invitePartnerButton => 'Inviter votre partenaire';

  @override
  String pendingInvitationInfo(String email) {
    return 'Une invitation a été envoyée à $email. Une fois son compte créé et accepté, vous serez connectés.';
  }

  @override
  String get invitePartnerMessage =>
      'Partagez cette invitation avec votre partenaire pour commencer votre parcours de communication relationnelle ensemble.';

  @override
  String get prepareFirstConversation => 'Préparer une première conversation';

  @override
  String get soloPreparationTitle => 'Préparer votre première conversation';

  @override
  String get soloPreparationIntro =>
      'Vous pouvez commencer seul(e) en clarifiant ce que vous voulez dire. Sauvegardez un brouillon, puis utilisez-le quand vous inviterez votre partenaire.';

  @override
  String get soloTopicLabel => 'De quoi voulez-vous parler ?';

  @override
  String get soloTopicHint => 'Exemple : la façon dont on organise nos soirées';

  @override
  String get soloFeelingLabel => 'Qu\'est-ce que vous ressentez ?';

  @override
  String get soloFeelingHint =>
      'Exemple : je me sens à distance et un peu découragé(e)';

  @override
  String get soloNeedLabel =>
      'Qu\'est-ce qui vous aiderait à vous sentir entendu(e) ?';

  @override
  String get soloNeedHint =>
      'Exemple : j\'ai besoin qu\'on s\'écoute sans se couper';

  @override
  String get soloNextStepLabel =>
      'Quelle petite prochaine étape semble réaliste ?';

  @override
  String get soloNextStepHint =>
      'Exemple : une discussion calme de 15 minutes ce week-end';

  @override
  String get soloInvitationPreviewTitle => 'Aperçu de l\'invitation';

  @override
  String get soloSaveDraft => 'Sauvegarder le brouillon';

  @override
  String get soloUseForInvitation => 'Utiliser dans l\'invitation partenaire';

  @override
  String get soloDraftSaved => 'Brouillon sauvegardé';

  @override
  String get soloSafetyNote =>
      'S\'il y a peur, violence, emprise ou danger immédiat, privilégiez la sécurité et contactez une aide qualifiée avant toute conversation guidée.';

  @override
  String get soloDraftFallbackTopic => 'quelque chose d\'important entre nous';

  @override
  String get soloDraftFallbackFeeling =>
      'j\'aimerais qu\'on ralentisse et qu\'on se comprenne mieux';

  @override
  String get soloDraftFallbackNeed =>
      'j\'ai besoin d\'un espace plus calme où chacun peut se sentir entendu';

  @override
  String get soloDraftFallbackNextStep =>
      'essayer une courte conversation guidée ensemble';

  @override
  String soloInvitationDraft(
    String topic,
    String feeling,
    String need,
    String nextStep,
  ) {
    return 'J\'aimerais qu\'on parle de $topic. Je ressens : $feeling. Ce qui m\'aiderait, c\'est : $need. Est-ce que tu serais d\'accord pour $nextStep avec moi sur We Connect ?';
  }

  @override
  String get createNewConversation => 'Créer Nouvelle Conversation';

  @override
  String get conversationTitle => 'Titre de la Conversation';

  @override
  String get conversationTopic => 'Sujet (Optionnel)';

  @override
  String get create => 'Créer';

  @override
  String get failedToLoad => 'Échec du chargement';

  @override
  String get failedToSend => 'Échec de l\'envoi du message';

  @override
  String get startConversation =>
      'Commencez la conversation en envoyant un message !';

  @override
  String get startYourConversation => 'Commencez votre conversation';

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get selectLanguage => 'Sélectionner la Langue';

  @override
  String get mainConversationTitle => 'Conversation';

  @override
  String get mainConversationTopic => 'Votre parcours ensemble';

  @override
  String get aiCounsellor => 'Coach IA';

  @override
  String get drSarahAiCounsellor => 'Coach Sarah (Coach IA)';

  @override
  String get startFirstConversationMessage =>
      'Commencez votre première conversation avec votre partenaire et recevez l\'accompagnement de notre coach relationnel IA.';

  @override
  String get partnerInvitationMessage =>
      'Une fois que votre partenaire accepte l\'invitation et crée son compte, vous aurez tous les deux accès à votre conversation où vous pourrez commencer à partager et recevoir l\'accompagnement de notre coach relationnel IA.';

  @override
  String exerciseStepProgress(int current, int total) {
    return 'Étape $current/$total';
  }

  @override
  String get exerciseYourTurn => 'À vous !';

  @override
  String exerciseWaitingFor(String partnerName) {
    return 'En attente de $partnerName...';
  }

  @override
  String get exerciseJoin => 'Rejoindre';

  @override
  String get exerciseView => 'Voir';

  @override
  String get progressDashboard => 'Tableau de Progression';

  @override
  String get relationshipHealth => 'Santé Relationnelle';

  @override
  String get healthGreat => 'Excellent';

  @override
  String get healthGood => 'Bien';

  @override
  String get healthGettingStarted => 'Premiers Pas';

  @override
  String get healthScoreDescription =>
      'Basé sur vos conversations, exercices et engagement';

  @override
  String get activityStreak => 'Série d\'Activité';

  @override
  String get days => 'jours';

  @override
  String get best => 'Record';

  @override
  String get totalDaysActive => 'Total';

  @override
  String get weeklyActivity => 'Activité Hebdomadaire';

  @override
  String get noActivityYet => 'Pas encore d\'activité cette semaine';

  @override
  String get exerciseProgress => 'Progrès des Exercices';

  @override
  String get messages => 'Messages';

  @override
  String get exercisesCompleted => 'Exercices';

  @override
  String get aiSessions => 'Sessions IA';

  @override
  String get completionRate => 'Taux de Complétion';

  @override
  String get completed => 'Terminés';

  @override
  String get totalStarted => 'Commencés';

  @override
  String get thisMonth => 'Ce Mois';

  @override
  String get byCategory => 'Par Catégorie';

  @override
  String get yourJourney => 'Votre Parcours';

  @override
  String get viewProgress => 'Voir la Progression';

  @override
  String get trackYourJourney =>
      'Suivez votre parcours relationnel et votre croissance';

  @override
  String welcomeBack(String name) {
    return 'Bienvenue, $name !';
  }

  @override
  String connectedWith(String name) {
    return 'Vous êtes connecté(e) avec $name';
  }

  @override
  String get invitePartnerPrompt =>
      'Invitez votre partenaire pour commencer votre parcours de communication relationnelle ensemble';

  @override
  String get pendingInvitationTitle => 'Invitation en attente';

  @override
  String pendingInvitationMessage(String email) {
    return 'Vous avez envoyé une invitation à $email. Nous attendons qu\'il/elle accepte.';
  }

  @override
  String get resendInvitation => 'Renvoyer l\'invitation';

  @override
  String get sendInvitationSubtitle =>
      'Envoyez une invitation pour commencer le coaching ensemble';

  @override
  String get getStarted => 'Commencer';

  @override
  String get mainThread => 'Conversation';

  @override
  String get continueMainConversation =>
      'Continuez votre conversation avec votre partenaire';

  @override
  String get viewAllConversations => 'Voir tous vos fils de conversation';

  @override
  String get profileSettings => 'Paramètres du Profil';

  @override
  String get manageAccountPreferences =>
      'Gérez votre compte et vos préférences';

  @override
  String get profileUpdatedSuccess => 'Profil mis à jour avec succès';

  @override
  String get failedToUpdateProfile => 'Échec de la mise à jour du profil';

  @override
  String get logoutConfirmation =>
      'Êtes-vous sûr(e) de vouloir vous déconnecter ?';

  @override
  String get personalInformation => 'Informations Personnelles';

  @override
  String get pleaseEnterFirstName => 'Veuillez entrer votre prénom';

  @override
  String get pleaseEnterLastName => 'Veuillez entrer votre nom';

  @override
  String get emailCannotBeChanged => 'L\'e-mail ne peut pas être modifié';

  @override
  String get relationshipStatus => 'Statut Relationnel';

  @override
  String get noPartnerConnected => 'Aucun partenaire connecté';

  @override
  String get exerciseHistory => 'Historique des Exercices';

  @override
  String get viewPastExercises => 'Voir les exercices passés et leurs résumés';

  @override
  String get paymentPortal => 'Portail de Paiement';

  @override
  String get manageSubscriptionBilling =>
      'Gérer l\'abonnement et la facturation';

  @override
  String get billingHistory => 'Historique de Facturation';

  @override
  String get viewInvoicesPayments => 'Voir les factures et paiements';

  @override
  String get changePlan => 'Changer de Plan';

  @override
  String get upgradeOrChangeSubscription =>
      'Améliorer ou changer d\'abonnement';

  @override
  String get welcomeToApp => 'Bienvenue sur We Connect';

  @override
  String get strengthenRelationship => 'Renforcez votre relation ensemble';

  @override
  String get whyAiForCouplesTitle => 'Pourquoi l\'IA pour les couples ?';

  @override
  String get whyAiForCouplesIntro =>
      'La technologie éloigne souvent les partenaires dans des mondes séparés. We Connect est conçu pour l\'inverse : un espace partagé où les deux voix peuvent être entendues.';

  @override
  String get whyAiForCouplesSharedSpaceTitle => 'Conçu autour du couple';

  @override
  String get whyAiForCouplesSharedSpaceText =>
      'Le coach voit la conversation comme quelque chose que vous construisez ensemble. Il aide à ralentir les schémas, refléter les deux points de vue et éviter de devenir l\'écho d\'une seule personne.';

  @override
  String get whyAiForCouplesTechTitle => 'Une technologie qui vous rapproche';

  @override
  String get whyAiForCouplesTechText =>
      'Votre téléphone peut être autre chose qu\'une distraction. Utilisé avec intention, il peut devenir un lieu pour faire une pause, pratiquer et revenir l\'un vers l\'autre.';

  @override
  String get whyAiForCouplesSafety =>
      'Le coaching par IA ne remplace pas une thérapie et ne prend pas parti. Il aide les couples à parler avec plus d\'attention et à transformer les schémas récurrents en petites prochaines étapes.';

  @override
  String get pleaseEnterEmail => 'Veuillez entrer votre e-mail';

  @override
  String get pleaseEnterPassword => 'Veuillez entrer votre mot de passe';

  @override
  String get signIn => 'Se Connecter';

  @override
  String get noAccountSignUp => 'Pas encore de compte ? Inscrivez-vous';

  @override
  String get loginJoinedPartner => 'Connexion réussie et partenaire rejoint !';

  @override
  String get loginFailed => 'Échec de la connexion';

  @override
  String get createAccount => 'Créer un Compte';

  @override
  String get joinApp => 'Rejoindre We Connect';

  @override
  String get startJourneyBetterComm =>
      'Commencez votre parcours vers une meilleure communication';

  @override
  String get learnMoreOnWebsite => 'En savoir plus sur le site We Connect';

  @override
  String get pleaseEnterAPassword => 'Veuillez entrer un mot de passe';

  @override
  String get passwordMinLength =>
      'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get pleaseConfirmPassword => 'Veuillez confirmer votre mot de passe';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get serviceDisclaimer =>
      'Ce service fournit uniquement un soutien à la communication relationnelle. Ce n\'est PAS une thérapie ni un substitut aux services de santé mentale professionnels.';

  @override
  String get iAgreeToThe => 'J\'accepte les ';

  @override
  String get termsOfService => 'Conditions d\'Utilisation';

  @override
  String get andPrivacyPolicy => ' et la ';

  @override
  String get privacyPolicy => 'Politique de Confidentialité';

  @override
  String get mustAcceptTerms =>
      'Vous devez accepter les Conditions d\'Utilisation et la Politique de Confidentialité pour créer un compte';

  @override
  String get accountCreatedJoinedPartner =>
      'Compte créé et partenaire rejoint avec succès !';

  @override
  String get registrationFailed => 'Échec de l\'inscription';

  @override
  String get emailAlreadyExists =>
      'Un compte avec cet email existe déjà. Veuillez vous connecter ou utiliser un autre email.';

  @override
  String get alreadyHaveAccountSignIn =>
      'Vous avez déjà un compte ? Connectez-vous';

  @override
  String get joinYourPartner => 'Rejoignez votre Partenaire';

  @override
  String get youveBeenInvited => 'Vous avez été invité(e) !';

  @override
  String get partnerInvitedYou =>
      'Votre partenaire vous a invité(e) à rejoindre We Connect. Créez un compte ou connectez-vous pour commencer votre parcours de coaching relationnel ensemble.';

  @override
  String get alreadySignedInAccept =>
      'Vous êtes déjà connecté(e). Cliquez ci-dessous pour accepter l\'invitation.';

  @override
  String get acceptInvitation => 'Accepter l\'Invitation';

  @override
  String get invitationInfoSteps =>
      '• Si vous avez déjà un compte, connectez-vous pour vous lier à votre partenaire\n• Si vous êtes nouveau, créez un compte pour commencer\n• Une fois connectés, vous pourrez avoir des conversations ensemble';

  @override
  String get successfullyJoinedPartner => 'Partenaire rejoint avec succès !';

  @override
  String get failedToAcceptInvitation =>
      'Échec de l\'acceptation de l\'invitation';

  @override
  String get failedToLoadTerms =>
      'Échec du chargement des Conditions d\'Utilisation';

  @override
  String get conversationCreatedSuccess => 'Conversation créée avec succès';

  @override
  String get failedToCreateConversation =>
      'Échec de la création de la conversation';

  @override
  String messageCount(int count) {
    return '$count messages';
  }

  @override
  String get needToInvitePartner =>
      'Vous devez inviter et vous connecter avec votre partenaire avant de pouvoir commencer des conversations.';

  @override
  String get noConversationsYet => 'Aucune Conversation';

  @override
  String get newConversation => 'Nouvelle Conversation';

  @override
  String get conversationTitleHint => 'ex. Problèmes de Communication';

  @override
  String get pleaseEnterTitle => 'Veuillez entrer un titre';

  @override
  String get conversationTopicHint => 'De quoi souhaitez-vous discuter ?';

  @override
  String get crisisResources => 'Ressources de Crise';

  @override
  String get chooseYourPlan => 'Choisissez Votre Plan';

  @override
  String get startYourJourneyTogether => 'Commencez Votre Parcours Ensemble';

  @override
  String get choosePlanDescription =>
      'Choisissez un plan adapté à vos besoins. Vous pouvez changer de plan à tout moment.';

  @override
  String get free => 'Gratuit';

  @override
  String get forever => 'pour toujours';

  @override
  String get tryAiCoach => 'Essayez le coach relationnel IA';

  @override
  String aiMessagesPerMonth(int count) {
    return '$count messages IA par mois';
  }

  @override
  String get unlimitedPartnerMessaging =>
      'Messages illimités avec le partenaire';

  @override
  String get basicExercises => 'Exercices de base';

  @override
  String get essential => 'Essentiel';

  @override
  String get regularSupport => 'Un soutien régulier pour votre relation';

  @override
  String get allFreeFeatures => 'Toutes les fonctionnalités gratuites';

  @override
  String get guidedExercises => 'Exercices guidés';

  @override
  String get conversationSummaries => 'Résumés de conversation';

  @override
  String get premium => 'Premium';

  @override
  String get unlimitedAccess => 'Accès illimité à toutes les fonctionnalités';

  @override
  String get unlimitedAiMessages => 'Messages IA illimités';

  @override
  String get allEssentialFeatures => 'Toutes les fonctionnalités Essentiel';

  @override
  String get prioritySupport => 'Support prioritaire';

  @override
  String get advancedInsights => 'Analyses avancées';

  @override
  String get popular => 'POPULAIRE';

  @override
  String get currentPlan => 'PLAN ACTUEL';

  @override
  String get monthly => 'Mensuel';

  @override
  String get annual => 'Annuel';

  @override
  String get save20 => 'Économisez 20%';

  @override
  String get freeTrialInfo =>
      'Essai gratuit de 7 jours • Annulez à tout moment';

  @override
  String get currentPlanButton => 'Plan Actuel';

  @override
  String get continueWithFree => 'Continuer en Gratuit';

  @override
  String get startFreeTrial => 'Commencer l\'Essai Gratuit';

  @override
  String get perMonth => '/mois';

  @override
  String get perYear => '/an';

  @override
  String get manageSubscription => 'Gérer l\'Abonnement';

  @override
  String get upgradePlan => 'Améliorer le Plan';

  @override
  String get aboutPaymentPortal => 'À Propos du Portail de Paiement';

  @override
  String get paymentPortalDescription =>
      'Vous pouvez gérer votre abonnement, mettre à jour vos moyens de paiement et consulter votre historique de facturation via notre portail de paiement sécurisé propulsé par Stripe.';

  @override
  String get couldNotOpenPaymentPortal =>
      'Impossible d\'ouvrir le portail de paiement';

  @override
  String get failedToOpenPortal => 'Échec de l\'ouverture du portail';

  @override
  String get refresh => 'Actualiser';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get noBillingHistoryYet => 'Aucun historique de facturation';

  @override
  String get invoicesWillAppearHere =>
      'Vos factures apparaîtront ici une fois que vous aurez effectué un paiement.';

  @override
  String get viewInvoice => 'Voir la Facture';

  @override
  String get paid => 'Payé';

  @override
  String get pending => 'En attente';

  @override
  String get void_ => 'Annulé';

  @override
  String get failed => 'Échoué';

  @override
  String get subscription => 'Abonnement';

  @override
  String get invoiceUrlNotAvailable => 'URL de la facture non disponible';

  @override
  String get couldNotOpenInvoice => 'Impossible d\'ouvrir la facture';

  @override
  String get failedToLoadBillingHistory =>
      'Échec du chargement de l\'historique de facturation';

  @override
  String get paymentSuccessful => 'Paiement Réussi !';

  @override
  String get subscriptionActivated =>
      'Votre abonnement a été activé.\nProfitez de votre expérience de coaching améliorée !';

  @override
  String get viewPaymentPortal => 'Voir le Portail de Paiement';

  @override
  String get guidedExercise => 'Exercice Guidé';

  @override
  String get exerciseComplete => 'Exercice Terminé';

  @override
  String get exerciseCompleteTitle => 'Exercice Terminé ! ✨';

  @override
  String greatWorkCompleting(String name) {
    return 'Excellent travail en complétant \"$name\" !';
  }

  @override
  String get keyTakeaways => 'Points Clés';

  @override
  String get generatingSummary => 'Génération de votre résumé...';

  @override
  String get returnToConversation => 'Retour à la Conversation';

  @override
  String get instruction => 'Instruction';

  @override
  String get guidance => 'Conseils';

  @override
  String get conversationSoFar => 'Conversation Jusqu\'ici';

  @override
  String get waitingForPartnerResponse =>
      'En attente de la réponse de votre partenaire...';

  @override
  String get typeYourResponseHere => 'Tapez votre réponse ici...';

  @override
  String get waitingForYourPartner => 'En attente de votre partenaire...';

  @override
  String get completeExercise => 'Terminer l\'Exercice';

  @override
  String get nextStep => 'Étape Suivante';

  @override
  String get leaveExercise => 'Quitter l\'Exercice ?';

  @override
  String get leaveExerciseConfirmation =>
      'Êtes-vous sûr(e) de vouloir quitter ? Votre progression sera sauvegardée.';

  @override
  String get stay => 'Rester';

  @override
  String get leave => 'Quitter';

  @override
  String get pleaseEnterResponse => 'Veuillez entrer une réponse';

  @override
  String get noExercisesYet => 'Aucun exercice pour le moment';

  @override
  String get completeExercisePrompt =>
      'Complétez un exercice avec votre partenaire\npour le voir ici.';

  @override
  String get noSummaryAvailable => 'Aucun résumé disponible.';

  @override
  String get failedToLoadHistory => 'Échec du chargement de l\'historique';

  @override
  String inProgressStatus(int current, int total) {
    return 'En cours ($current/$total)';
  }

  @override
  String get notAuthenticated => 'Non authentifié';

  @override
  String get exerciseNotFound => 'Exercice introuvable';

  @override
  String get goBack => 'Retour';

  @override
  String get categoryCommunication => 'Communication';

  @override
  String get categoryAppreciation => 'Appréciation';

  @override
  String get categoryConflict => 'Conflit';

  @override
  String get categoryEmotional => 'Émotionnel';

  @override
  String get importantInformation => 'Information Importante';

  @override
  String get disclaimerText =>
      'Cette IA fournit uniquement un soutien à la communication relationnelle. Ce n\'est PAS une thérapie ni un substitut aux services de santé mentale professionnels. En cas de crise, veuillez contacter les services d\'urgence.';

  @override
  String get needImmediateHelp => 'Besoin d\'Aide Immédiate ?';

  @override
  String get crisisDialogText =>
      'Si vous ou votre partenaire êtes en crise ou vivez une urgence de santé mentale, veuillez contacter :';

  @override
  String get emergencyServices => 'Services d\'Urgence';

  @override
  String get crisisHotlines => 'Lignes de Crise 24h/24';

  @override
  String get crisisHotlinesList =>
      '• SOS Amitié : 09 72 39 40 50\n• Fil Santé Jeunes : 0 800 235 236\n• Numéro national de prévention du suicide : 3114';

  @override
  String get appProvidesSupport =>
      'Cette application fournit uniquement un soutien à la communication. Ce n\'est pas un substitut à l\'aide professionnelle.';

  @override
  String get iUnderstand => 'Je Comprends';

  @override
  String get guidedExerciseSuggestion => '🎯 Exercice Guidé';

  @override
  String get tapToStartExercise => 'Appuyez pour démarrer l\'exercice guidé';

  @override
  String get continueExercise => 'Continuer l\'Exercice';

  @override
  String get tryGuidedExercise => 'Essayer un Exercice Guidé';

  @override
  String get exerciseInProgress => 'Vous avez un exercice en cours';

  @override
  String get practiceSkillsTogether =>
      'Pratiquez des compétences de communication ensemble';

  @override
  String get chooseAnExercise => 'Choisir un Exercice';

  @override
  String get practiceSkillsWithExercises =>
      'Pratiquez des compétences ensemble avec des exercices guidés';

  @override
  String get noExercisesAvailable => 'Aucun exercice disponible';

  @override
  String userIsTyping(String name) {
    return '$name est en train d\'écrire';
  }

  @override
  String get aiCoach => 'Coach IA';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get forgotPasswordTitle => 'Réinitialiser le mot de passe';

  @override
  String get forgotPasswordDescription =>
      'Entrez votre adresse e-mail et nous vous enverrons un lien pour réinitialiser votre mot de passe.';

  @override
  String get sendResetLink => 'Envoyer le lien';

  @override
  String get resetLinkSent =>
      'Si un compte avec cet e-mail existe, un lien de réinitialisation a été envoyé.';

  @override
  String get backToLogin => 'Retour à la connexion';

  @override
  String get resetPasswordTitle => 'Nouveau mot de passe';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get confirmNewPassword => 'Confirmer le nouveau mot de passe';

  @override
  String get resetPassword => 'Réinitialiser le mot de passe';

  @override
  String get passwordResetSuccess =>
      'Le mot de passe a été réinitialisé avec succès. Vous pouvez maintenant vous connecter.';

  @override
  String get invalidResetLink =>
      'Ce lien de réinitialisation est invalide ou a expiré.';

  @override
  String get pleaseEnterNewPassword =>
      'Veuillez entrer un nouveau mot de passe';

  @override
  String get checkYourEmail => 'Vérifiez votre e-mail';

  @override
  String get errorSendingMessage =>
      'Impossible d\'envoyer le message. Veuillez réessayer.';

  @override
  String get errorLoadingMessages => 'Impossible de charger les messages.';

  @override
  String get errorGeneric => 'Une erreur est survenue. Veuillez réessayer.';

  @override
  String get errorOpeningPaymentPage =>
      'Impossible d\'ouvrir la page de paiement.';

  @override
  String get errorStartingCheckout =>
      'Impossible de démarrer le paiement. Veuillez réessayer.';

  @override
  String get errorLoadingSummary => 'Impossible de charger le résumé.';

  @override
  String get errorSubmittingResponse =>
      'Impossible d\'envoyer la réponse. Veuillez réessayer.';
}
