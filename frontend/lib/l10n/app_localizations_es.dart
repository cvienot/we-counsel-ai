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
      'Este es su espacio principal de conversación donde usted y su pareja pueden compartir pensamientos, sentimientos y recibir orientación de Coach Sarah, su coach de IA.';

  @override
  String get shareThoughts =>
      'Comparte lo que tienes en mente. Coach Sarah está aquí para ayudar a guiar su conversación.';

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
  String get close => 'Cerrar';

  @override
  String get back => 'Volver';

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
    return 'Se ha enviado una invitación a $email. Recibirá un correo electrónico con instrucciones para unirse a ti.';
  }

  @override
  String get failedToSendInvitation => 'Error al enviar la invitación';

  @override
  String get invitationSteps =>
      '1. Tu pareja recibirá una invitación por correo electrónico\n2. Puede hacer clic en el enlace para crear su cuenta\n3. Una vez que la acepte, ambos estarán conectados\n4. Pueden comenzar a tener conversaciones con orientación de IA';

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
    return 'Paso $current/$total';
  }

  @override
  String get exerciseYourTurn => '¡Tu turno!';

  @override
  String exerciseWaitingFor(String partnerName) {
    return 'Esperando a $partnerName...';
  }

  @override
  String get exerciseJoin => 'Unirse';

  @override
  String get exerciseView => 'Ver';

  @override
  String get progressDashboard => 'Panel de Progreso';

  @override
  String get relationshipHealth => 'Salud de la Relación';

  @override
  String get healthGreat => 'Excelente';

  @override
  String get healthGood => 'Bien';

  @override
  String get healthGettingStarted => 'Comenzando';

  @override
  String get healthScoreDescription =>
      'Basado en sus conversaciones, ejercicios y participación';

  @override
  String get activityStreak => 'Racha de Actividad';

  @override
  String get days => 'días';

  @override
  String get best => 'Mejor';

  @override
  String get totalDaysActive => 'Total';

  @override
  String get weeklyActivity => 'Actividad Semanal';

  @override
  String get noActivityYet => 'Sin actividad esta semana aún';

  @override
  String get exerciseProgress => 'Progreso de Ejercicios';

  @override
  String get messages => 'Mensajes';

  @override
  String get exercisesCompleted => 'Ejercicios';

  @override
  String get aiSessions => 'Sesiones IA';

  @override
  String get completionRate => 'Tasa de Completación';

  @override
  String get completed => 'Completados';

  @override
  String get totalStarted => 'Iniciados';

  @override
  String get thisMonth => 'Este Mes';

  @override
  String get byCategory => 'Por Categoría';

  @override
  String get yourJourney => 'Tu Camino';

  @override
  String get viewProgress => 'Ver Progreso';

  @override
  String get trackYourJourney => 'Siga su viaje de relación y crecimiento';

  @override
  String welcomeBack(String name) {
    return '¡Bienvenido/a de nuevo, $name!';
  }

  @override
  String connectedWith(String name) {
    return 'Estás conectado/a con $name';
  }

  @override
  String get invitePartnerPrompt =>
      'Invita a tu pareja para comenzar su viaje de consejería juntos';

  @override
  String get pendingInvitationTitle => 'Invitación pendiente';

  @override
  String pendingInvitationMessage(String email) {
    return 'Has enviado una invitación a $email. Estamos esperando a que la acepte.';
  }

  @override
  String get resendInvitation => 'Reenviar invitación';

  @override
  String get sendInvitationSubtitle =>
      'Envía una invitación para empezar el coaching juntos';

  @override
  String get getStarted => 'Comenzar';

  @override
  String get mainThread => 'Hilo Principal';

  @override
  String get continueMainConversation =>
      'Continúa tu conversación principal con tu pareja';

  @override
  String get viewAllConversations => 'Ver todos tus hilos de conversación';

  @override
  String get profileSettings => 'Configuración del Perfil';

  @override
  String get manageAccountPreferences => 'Gestiona tu cuenta y preferencias';

  @override
  String get profileUpdatedSuccess => 'Perfil actualizado con éxito';

  @override
  String get failedToUpdateProfile => 'Error al actualizar el perfil';

  @override
  String get logoutConfirmation =>
      '¿Estás seguro/a de que quieres cerrar sesión?';

  @override
  String get personalInformation => 'Información Personal';

  @override
  String get pleaseEnterFirstName => 'Por favor, ingresa tu nombre';

  @override
  String get pleaseEnterLastName => 'Por favor, ingresa tu apellido';

  @override
  String get emailCannotBeChanged =>
      'El correo electrónico no se puede cambiar';

  @override
  String get relationshipStatus => 'Estado de la Relación';

  @override
  String get noPartnerConnected => 'Sin pareja conectada';

  @override
  String get exerciseHistory => 'Historial de Ejercicios';

  @override
  String get viewPastExercises => 'Ver ejercicios pasados y resúmenes';

  @override
  String get paymentPortal => 'Portal de Pago';

  @override
  String get manageSubscriptionBilling => 'Gestionar suscripción y facturación';

  @override
  String get billingHistory => 'Historial de Facturación';

  @override
  String get viewInvoicesPayments => 'Ver facturas y pagos';

  @override
  String get changePlan => 'Cambiar Plan';

  @override
  String get upgradeOrChangeSubscription => 'Mejorar o cambiar suscripción';

  @override
  String get welcomeToApp => 'Bienvenido a We Coach';

  @override
  String get strengthenRelationship => 'Fortalece tu relación juntos';

  @override
  String get pleaseEnterEmail => 'Por favor, ingresa tu correo electrónico';

  @override
  String get pleaseEnterPassword => 'Por favor, ingresa tu contraseña';

  @override
  String get signIn => 'Iniciar Sesión';

  @override
  String get noAccountSignUp => '¿No tienes cuenta? Regístrate';

  @override
  String get loginJoinedPartner => '¡Inicio de sesión exitoso y pareja unida!';

  @override
  String get loginFailed => 'Error de inicio de sesión';

  @override
  String get createAccount => 'Crear Cuenta';

  @override
  String get joinApp => 'Únete a We Coach';

  @override
  String get startJourneyBetterComm =>
      'Comienza tu viaje hacia una mejor comunicación';

  @override
  String get pleaseEnterAPassword => 'Por favor, ingresa una contraseña';

  @override
  String get passwordMinLength =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get pleaseConfirmPassword => 'Por favor, confirma tu contraseña';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get serviceDisclaimer =>
      'Este servicio proporciona únicamente apoyo a la comunicación relacional. NO es terapia ni un sustituto de los servicios de salud mental profesionales.';

  @override
  String get iAgreeToThe => 'Acepto los ';

  @override
  String get termsOfService => 'Términos de Servicio';

  @override
  String get mustAcceptTerms =>
      'Debes aceptar los Términos de Servicio para crear una cuenta';

  @override
  String get accountCreatedJoinedPartner =>
      '¡Cuenta creada y pareja unida con éxito!';

  @override
  String get registrationFailed => 'Error de registro';

  @override
  String get alreadyHaveAccountSignIn => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get joinYourPartner => 'Únete a tu Pareja';

  @override
  String get youveBeenInvited => '¡Has sido invitado/a!';

  @override
  String get partnerInvitedYou =>
      'Tu pareja te ha invitado a unirte a We Coach. Crea una cuenta o inicia sesión para comenzar tu viaje de coaching relacional juntos.';

  @override
  String get alreadySignedInAccept =>
      'Ya has iniciado sesión. Haz clic abajo para aceptar la invitación.';

  @override
  String get acceptInvitation => 'Aceptar Invitación';

  @override
  String get invitationInfoSteps =>
      '• Si ya tienes una cuenta, inicia sesión para conectarte con tu pareja\n• Si eres nuevo/a, crea una cuenta para comenzar\n• Una vez conectados, pueden iniciar conversaciones juntos';

  @override
  String get successfullyJoinedPartner => '¡Pareja unida con éxito!';

  @override
  String get failedToAcceptInvitation => 'Error al aceptar la invitación';

  @override
  String get failedToLoadTerms => 'Error al cargar los Términos de Servicio';

  @override
  String get conversationCreatedSuccess => 'Conversación creada con éxito';

  @override
  String get failedToCreateConversation => 'Error al crear la conversación';

  @override
  String messageCount(int count) {
    return '$count mensajes';
  }

  @override
  String get needToInvitePartner =>
      'Necesitas invitar y conectarte con tu pareja antes de poder iniciar conversaciones.';

  @override
  String get noConversationsYet => 'Sin Conversaciones Aún';

  @override
  String get newConversation => 'Nueva Conversación';

  @override
  String get conversationTitleHint => 'ej., Problemas de Comunicación';

  @override
  String get pleaseEnterTitle => 'Por favor, ingresa un título';

  @override
  String get conversationTopicHint => '¿De qué te gustaría hablar?';

  @override
  String get crisisResources => 'Recursos de Crisis';

  @override
  String get chooseYourPlan => 'Elige Tu Plan';

  @override
  String get startYourJourneyTogether => 'Comienza Tu Viaje Juntos';

  @override
  String get choosePlanDescription =>
      'Elige un plan que se adapte a tus necesidades. Puedes cambiar de plan en cualquier momento.';

  @override
  String get free => 'Gratis';

  @override
  String get forever => 'para siempre';

  @override
  String get tryAiCoach => 'Prueba el coach relacional de IA';

  @override
  String aiMessagesPerMonth(int count) {
    return '$count mensajes de IA al mes';
  }

  @override
  String get unlimitedPartnerMessaging => 'Mensajes ilimitados con la pareja';

  @override
  String get basicExercises => 'Ejercicios básicos';

  @override
  String get essential => 'Esencial';

  @override
  String get regularSupport => 'Apoyo regular para tu relación';

  @override
  String get allFreeFeatures => 'Todas las funciones gratuitas';

  @override
  String get guidedExercises => 'Ejercicios guiados';

  @override
  String get conversationSummaries => 'Resúmenes de conversación';

  @override
  String get premium => 'Premium';

  @override
  String get unlimitedAccess => 'Acceso ilimitado a todas las funciones';

  @override
  String get unlimitedAiMessages => 'Mensajes de IA ilimitados';

  @override
  String get allEssentialFeatures => 'Todas las funciones Esencial';

  @override
  String get prioritySupport => 'Soporte prioritario';

  @override
  String get advancedInsights => 'Análisis avanzados';

  @override
  String get popular => 'POPULAR';

  @override
  String get currentPlan => 'PLAN ACTUAL';

  @override
  String get monthly => 'Mensual';

  @override
  String get annual => 'Anual';

  @override
  String get save20 => 'Ahorra 20%';

  @override
  String get freeTrialInfo =>
      'Prueba gratuita de 7 días • Cancela en cualquier momento';

  @override
  String get currentPlanButton => 'Plan Actual';

  @override
  String get continueWithFree => 'Continuar Gratis';

  @override
  String get startFreeTrial => 'Comenzar Prueba Gratuita';

  @override
  String get perMonth => '/mes';

  @override
  String get perYear => '/año';

  @override
  String get manageSubscription => 'Gestionar Suscripción';

  @override
  String get upgradePlan => 'Mejorar Plan';

  @override
  String get aboutPaymentPortal => 'Acerca del Portal de Pago';

  @override
  String get paymentPortalDescription =>
      'Puedes gestionar tu suscripción, actualizar métodos de pago y ver el historial de facturación a través de nuestro portal de pago seguro impulsado por Stripe.';

  @override
  String get couldNotOpenPaymentPortal => 'No se pudo abrir el portal de pago';

  @override
  String get failedToOpenPortal => 'Error al abrir el portal';

  @override
  String get refresh => 'Actualizar';

  @override
  String get tryAgain => 'Intentar de Nuevo';

  @override
  String get noBillingHistoryYet => 'Sin historial de facturación';

  @override
  String get invoicesWillAppearHere =>
      'Tus facturas aparecerán aquí una vez que realices un pago.';

  @override
  String get viewInvoice => 'Ver Factura';

  @override
  String get paid => 'Pagado';

  @override
  String get pending => 'Pendiente';

  @override
  String get void_ => 'Anulado';

  @override
  String get failed => 'Fallido';

  @override
  String get subscription => 'Suscripción';

  @override
  String get invoiceUrlNotAvailable => 'URL de la factura no disponible';

  @override
  String get couldNotOpenInvoice => 'No se pudo abrir la factura';

  @override
  String get failedToLoadBillingHistory =>
      'Error al cargar el historial de facturación';

  @override
  String get paymentSuccessful => '¡Pago Exitoso!';

  @override
  String get subscriptionActivated =>
      'Tu suscripción ha sido activada.\n¡Disfruta de tu experiencia de coaching mejorada!';

  @override
  String get viewPaymentPortal => 'Ver Portal de Pago';

  @override
  String get guidedExercise => 'Ejercicio Guiado';

  @override
  String get exerciseComplete => 'Ejercicio Completado';

  @override
  String get exerciseCompleteTitle => '¡Ejercicio Completado! ✨';

  @override
  String greatWorkCompleting(String name) {
    return '¡Excelente trabajo completando \"$name\"!';
  }

  @override
  String get keyTakeaways => 'Puntos Clave';

  @override
  String get generatingSummary => 'Generando tu resumen...';

  @override
  String get returnToConversation => 'Volver a la Conversación';

  @override
  String get instruction => 'Instrucción';

  @override
  String get guidance => 'Orientación';

  @override
  String get conversationSoFar => 'Conversación Hasta Ahora';

  @override
  String get waitingForPartnerResponse =>
      'Esperando la respuesta de tu pareja...';

  @override
  String get typeYourResponseHere => 'Escribe tu respuesta aquí...';

  @override
  String get waitingForYourPartner => 'Esperando a tu pareja...';

  @override
  String get completeExercise => 'Completar Ejercicio';

  @override
  String get nextStep => 'Siguiente Paso';

  @override
  String get leaveExercise => '¿Salir del Ejercicio?';

  @override
  String get leaveExerciseConfirmation =>
      '¿Estás seguro/a de que quieres salir? Tu progreso será guardado.';

  @override
  String get stay => 'Quedarme';

  @override
  String get leave => 'Salir';

  @override
  String get pleaseEnterResponse => 'Por favor, ingresa una respuesta';

  @override
  String get noExercisesYet => 'Sin ejercicios aún';

  @override
  String get completeExercisePrompt =>
      'Completa un ejercicio con tu pareja\npara verlo aquí.';

  @override
  String get noSummaryAvailable => 'Sin resumen disponible.';

  @override
  String get failedToLoadHistory => 'Error al cargar el historial';

  @override
  String inProgressStatus(int current, int total) {
    return 'En curso ($current/$total)';
  }

  @override
  String get notAuthenticated => 'No autenticado';

  @override
  String get exerciseNotFound => 'Ejercicio no encontrado';

  @override
  String get goBack => 'Volver';

  @override
  String get categoryCommunication => 'Comunicación';

  @override
  String get categoryAppreciation => 'Apreciación';

  @override
  String get categoryConflict => 'Conflicto';

  @override
  String get categoryEmotional => 'Emocional';

  @override
  String get importantInformation => 'Información Importante';

  @override
  String get disclaimerText =>
      'Esta IA proporciona únicamente apoyo a la comunicación relacional. NO es terapia ni un sustituto de los servicios de salud mental profesionales. En caso de crisis, contacte los servicios de emergencia.';

  @override
  String get needImmediateHelp => '¿Necesitas Ayuda Inmediata?';

  @override
  String get crisisDialogText =>
      'Si tú o tu pareja están en crisis o experimentan una emergencia de salud mental, por favor contacten:';

  @override
  String get emergencyServices => 'Servicios de Emergencia';

  @override
  String get crisisHotlines => 'Líneas de Crisis 24/7';

  @override
  String get crisisHotlinesList =>
      '• Teléfono de la Esperanza: 717 003 717\n• Línea de Atención a la Conducta Suicida: 024\n• Emergencias: 112';

  @override
  String get appProvidesSupport =>
      'Esta aplicación proporciona únicamente apoyo a la comunicación. No es un sustituto de la ayuda profesional.';

  @override
  String get iUnderstand => 'Entiendo';

  @override
  String get guidedExerciseSuggestion => '🎯 Ejercicio Guiado';

  @override
  String get tapToStartExercise => 'Toca para iniciar el ejercicio guiado';

  @override
  String get continueExercise => 'Continuar Ejercicio';

  @override
  String get tryGuidedExercise => 'Probar un Ejercicio Guiado';

  @override
  String get exerciseInProgress => 'Tienes un ejercicio en curso';

  @override
  String get practiceSkillsTogether =>
      'Practica habilidades de comunicación juntos';

  @override
  String get chooseAnExercise => 'Elegir un Ejercicio';

  @override
  String get practiceSkillsWithExercises =>
      'Practica habilidades juntos con ejercicios guiados';

  @override
  String get noExercisesAvailable => 'No hay ejercicios disponibles';

  @override
  String userIsTyping(String name) {
    return '$name está escribiendo';
  }

  @override
  String get aiCoach => 'Coach IA';
}
