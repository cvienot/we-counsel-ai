// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'We Counsel';

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
      'Ceci est votre espace de conversation principal où vous et votre partenaire pouvez partager vos pensées, sentiments et recevoir des conseils de Dr. Sarah, votre conseillère IA.';

  @override
  String get shareThoughts =>
      'Partagez ce qui vous préoccupe. Dr. Sarah est là pour vous aider à guider votre conversation.';

  @override
  String get conversations => 'Conversations';

  @override
  String get profile => 'Profil';

  @override
  String get mainConversation => 'Conversation Principale';

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
  String get invitePartner => 'Inviter Partenaire';

  @override
  String get waitingForPartner => 'En attente de votre partenaire...';

  @override
  String get waitingForPartnerTitle => 'En attente de votre partenaire';

  @override
  String waitingRoomGreeting(String name) {
    return 'Bonjour $name ! Votre parcours de conseil commencera une fois que votre partenaire vous rejoindra sur We Counsel.';
  }

  @override
  String get whatHappensNext => 'Que se passe-t-il ensuite ?';

  @override
  String get sendAnotherInvitation => 'Envoyer une autre invitation';

  @override
  String get invitePartnerMessage =>
      'Partagez cette invitation avec votre partenaire pour commencer votre parcours de conseil ensemble.';

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
  String get mainConversationTitle => 'Conversation Principale';

  @override
  String get mainConversationTopic => 'Votre voyage continu ensemble';

  @override
  String get aiCounsellor => 'Conseiller IA';

  @override
  String get drSarahAiCounsellor => 'Dr. Sarah (Conseiller IA)';

  @override
  String get startFirstConversationMessage =>
      'Commencez votre première conversation avec votre partenaire et recevez des conseils de notre conseiller IA.';

  @override
  String get partnerInvitationMessage =>
      'Une fois que votre partenaire accepte l\'invitation et crée son compte, vous aurez tous les deux accès à votre fil de conversation principal où vous pourrez commencer à partager et recevoir des conseils de notre conseiller IA.';
}
