// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'We Coach';

  @override
  String get appSubtitle => 'Su viaje de relación juntos';

  @override
  String get login => 'Iniciar Sesión';

  @override
  String get register => 'Registrarse';

  @override
  String get logout => 'Cerrar Sesión';

  @override
  String get email => 'Correo Electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get firstName => 'Nombre';

  @override
  String get lastName => 'Apellido';

  @override
  String get confirmPassword => 'Confirmar Contraseña';

  @override
  String get welcomeTitle => 'Bienvenidos a su viaje juntos';

  @override
  String get welcomeMessage =>
      'Este es su espacio principal de conversación donde usted y su pareja pueden compartir pensamientos, sentimientos y recibir orientación de la Dra. Sarah, su consejera de IA.';

  @override
  String get shareThoughts =>
      'Comparte lo que tienes en mente. La Dra. Sarah está aquí para ayudar a guiar su conversación.';

  @override
  String get conversations => 'Conversaciones';

  @override
  String get profile => 'Perfil';

  @override
  String get mainConversation => 'Conversación Principal';

  @override
  String get otherConversations => 'Otras Conversaciones';

  @override
  String get typeMessage => 'Escriba un mensaje...';

  @override
  String get send => 'Enviar';

  @override
  String get typing => 'Escribiendo';

  @override
  String get partnerTyping => 'La pareja está escribiendo';

  @override
  String get partnersTyping => 'Las parejas están escribiendo';

  @override
  String get loading => 'Cargando...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Reintentar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get invitePartner => 'Invitar Pareja';

  @override
  String get inviteYourPartner => 'Invita a tu pareja';

  @override
  String get sendInvitation => 'Enviar invitación';

  @override
  String get invitePartnerDescription =>
      'Invita a tu pareja a unirse a ti en We Coach. Recibirá un correo electrónico con instrucciones para crear su cuenta y conectarse contigo.';

  @override
  String get partnerEmailAddress =>
      'Dirección de correo electrónico de la pareja';

  @override
  String get enterPartnerEmail =>
      'Ingresa la dirección de correo electrónico de tu pareja';

  @override
  String get pleaseEnterPartnerEmail =>
      'Por favor, ingresa el correo electrónico de tu pareja';

  @override
  String get pleaseEnterValidEmail =>
      'Por favor, ingresa una dirección de correo electrónico válida';

  @override
  String get cannotInviteYourself => 'No puedes invitarte a ti mismo';

  @override
  String get personalMessageOptional => 'Mensaje personal (opcional)';

  @override
  String get addPersonalMessage =>
      'Agrega un mensaje personal a tu invitación...';

  @override
  String get invitationSent => '¡Invitación enviada!';

  @override
  String invitationSentMessage(String email) {
    return 'Se ha enviado una invitación a $email. Recibirá un correo electrónico con instrucciones para unirse a ti en We Counsel.';
  }

  @override
  String get failedToSendInvitation => 'Error al enviar la invitación';

  @override
  String get invitationSteps =>
      '1. Tu pareja recibirá una invitación por correo electrónico\\n2. Puede hacer clic en el enlace para crear su cuenta\\n3. Una vez que la acepte, ambos estarán conectados\\n4. Pueden comenzar a tener conversaciones con orientación de IA';

  @override
  String get ok => 'OK';

  @override
  String get waitingForPartner => 'Esperando a su pareja...';

  @override
  String get waitingForPartnerTitle => 'Esperando a su pareja';

  @override
  String waitingRoomGreeting(String name) {
    return '¡Hola $name! Su viaje de coaching comenzará una vez que su pareja se una a usted en We Coach.';
  }

  @override
  String get whatHappensNext => '¿Qué sucede después?';

  @override
  String get sendAnotherInvitation => 'Enviar otra invitación';

  @override
  String get invitePartnerMessage =>
      'Comparta esta invitación con su pareja para comenzar su viaje de consejería juntos.';

  @override
  String get createNewConversation => 'Crear Nueva Conversación';

  @override
  String get conversationTitle => 'Título de la Conversación';

  @override
  String get conversationTopic => 'Tema (Opcional)';

  @override
  String get create => 'Crear';

  @override
  String get failedToLoad => 'Error al cargar';

  @override
  String get failedToSend => 'Error al enviar mensaje';

  @override
  String get startConversation =>
      '¡Comience la conversación enviando un mensaje!';

  @override
  String get startYourConversation => 'Comience su conversación';

  @override
  String get settings => 'Configuración';

  @override
  String get language => 'Idioma';

  @override
  String get selectLanguage => 'Seleccionar Idioma';

  @override
  String get mainConversationTitle => 'Conversación Principal';

  @override
  String get mainConversationTopic => 'Su viaje continuo juntos';

  @override
  String get aiCounsellor => 'Consejero IA';

  @override
  String get drSarahAiCounsellor => 'Coach Sarah (Coach IA)';

  @override
  String get startFirstConversationMessage =>
      'Comience su primera conversación con su pareja y reciba orientación de nuestro consejero IA.';

  @override
  String get partnerInvitationMessage =>
      'Una vez que su pareja acepte la invitación y cree su cuenta, ambos tendrán acceso a su hilo de conversación principal donde pueden comenzar a compartir y recibir orientación de nuestro consejero IA.';

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
