// Email translations for multiple languages
const emailTranslations = {
  en: {
    invitation: {
      subject: (inviterName) => `${inviterName} has invited you to join Entrelace`,
      title: 'Entrelace',
      subtitle: 'Couples Communication App',
      heading: "You've been invited!",
      body: (inviterName) => `<strong>${inviterName}</strong> has invited you to join them on Entrelace, a couples communication app that helps strengthen relationships.`,
      personalMessage: 'Personal message:',
      features: 'Entrelace provides:',
      feature1: 'Private conversations between you and your partner',
      feature2: 'AI-powered relationship communication guidance',
      feature3: 'Safe space to communicate and grow together',
      button: 'Accept Invitation',
      expiry: 'This invitation will expire in 7 days.',
      linkInfo: "If the button doesn't work, copy and paste this link:",
      footer: 'Entrelace - Strengthening relationships through guided communication',
      // Plain text version
      plainBody: (inviterName) => `You've been invited by ${inviterName} to join them on Entrelace!`,
      plainFeatures: `Entrelace helps couples strengthen their relationships through:
- Private conversations between partners
- AI-powered relationship communication guidance
- Safe space to communicate and grow together`,
      plainAccept: 'Accept your invitation:',
      plainExpiry: 'This invitation expires in 7 days.'
    },
    welcome: {
      subject: 'Welcome to Entrelace',
      heading: (firstName) => `Hi ${firstName}!`,
      body: "Welcome to Entrelace! We're excited to help you and your partner strengthen your relationship.",
      nextSteps: 'Next steps:',
      step1: 'Invite your partner to join you on the app',
      step2: 'Start your first conversation together',
      step3: 'Let our AI relationship coach guide you through meaningful discussions',
      closing: 'Remember, Entrelace is here to support you both on your journey together.',
      footer: 'Entrelace - Strengthening relationships through guided communication',
      // Plain text version
      plainBody: (firstName) => `Hi ${firstName}!\n\nWelcome to Entrelace! We're excited to help you and your partner strengthen your relationship.`,
      plainSteps: `Next steps:
1. Invite your partner to join you on the app
2. Start your first conversation together  
3. Let our AI relationship coach guide you through meaningful discussions`,
      plainClosing: 'Remember, Entrelace is here to support you both on your journey together.'
    },
    passwordReset: {
      subject: 'Reset your Entrelace password',
      heading: 'Password Reset Request',
      body: 'We received a request to reset your password. Click the button below to create a new password.',
      button: 'Reset Password',
      expiry: 'This link will expire in 1 hour.',
      ignore: "If you didn't request this, you can safely ignore this email.",
      footer: 'Entrelace - Strengthening relationships through guided communication',
      plainBody: 'We received a request to reset your Entrelace password.',
      plainLink: 'Reset your password:',
      plainExpiry: 'This link will expire in 1 hour.',
      plainIgnore: "If you didn't request this, you can safely ignore this email."
    },
    messageNotification: {
      subject: (senderName) => `${senderName} sent you a message on Entrelace`,
      heading: (senderName) => `New message from ${senderName}`,
      body: (senderName) => `${senderName} has sent you a message in your conversation.`,
      preview: 'Message preview:',
      button: 'View Message',
      footer: 'Entrelace - Strengthening relationships through guided communication',
      // Plain text version
      plainBody: (senderName) => `${senderName} has sent you a message on Entrelace.`,
      plainView: 'View your message:'
    }
  },
  fr: {
    invitation: {
      subject: (inviterName) => `${inviterName} vous a invité(e) à rejoindre Entrelace`,
      title: 'Entrelace',
      subtitle: 'Application de communication de couple',
      heading: 'Vous avez été invité(e) !',
      body: (inviterName) => `<strong>${inviterName}</strong> vous a invité(e) à les rejoindre sur Entrelace, une application de communication de couple qui aide à renforcer les relations.`,
      personalMessage: 'Message personnel :',
      features: 'Entrelace propose :',
      feature1: 'Conversations privées entre vous et votre partenaire',
      feature2: 'Guidance relationnelle assistée par IA',
      feature3: 'Espace sûr pour communiquer et grandir ensemble',
      button: 'Accepter l\'invitation',
      expiry: 'Cette invitation expirera dans 7 jours.',
      linkInfo: 'Si le bouton ne fonctionne pas, copiez et collez ce lien :',
      footer: 'Entrelace - Renforcer les relations par une communication guidée',
      // Plain text version
      plainBody: (inviterName) => `Vous avez été invité(e) par ${inviterName} à les rejoindre sur Entrelace !`,
      plainFeatures: `Entrelace aide les couples à renforcer leurs relations grâce à :
- Conversations privées entre partenaires
- Guidance relationnelle assistée par IA
- Espace sûr pour communiquer et grandir ensemble`,
      plainAccept: 'Acceptez votre invitation :',
      plainExpiry: 'Cette invitation expire dans 7 jours.'
    },
    welcome: {
      subject: 'Bienvenue sur Entrelace',
      heading: (firstName) => `Bonjour ${firstName} !`,
      body: 'Bienvenue sur Entrelace ! Nous sommes ravis de vous aider, vous et votre partenaire, à renforcer votre relation.',
      nextSteps: 'Prochaines étapes :',
      step1: 'Invitez votre partenaire à vous rejoindre sur l\'application',
      step2: 'Commencez votre première conversation ensemble',
      step3: 'Laissez notre coach relationnel IA vous guider dans des discussions significatives',
      closing: 'N\'oubliez pas, Entrelace est là pour vous soutenir tous les deux dans votre cheminement.',
      footer: 'Entrelace - Renforcer les relations par une communication guidée',
      // Plain text version
      plainBody: (firstName) => `Bonjour ${firstName} !\n\nBienvenue sur Entrelace ! Nous sommes ravis de vous aider, vous et votre partenaire, à renforcer votre relation.`,
      plainSteps: `Prochaines étapes :
1. Invitez votre partenaire à vous rejoindre sur l'application
2. Commencez votre première conversation ensemble
3. Laissez notre coach relationnel IA vous guider dans des discussions significatives`,
      plainClosing: 'N\'oubliez pas, Entrelace est là pour vous soutenir tous les deux dans votre cheminement.'
    },
    passwordReset: {
      subject: 'Réinitialisez votre mot de passe Entrelace',
      heading: 'Demande de réinitialisation de mot de passe',
      body: 'Nous avons reçu une demande de réinitialisation de votre mot de passe. Cliquez sur le bouton ci-dessous pour créer un nouveau mot de passe.',
      button: 'Réinitialiser le mot de passe',
      expiry: 'Ce lien expirera dans 1 heure.',
      ignore: 'Si vous n\'avez pas fait cette demande, vous pouvez ignorer cet e-mail en toute sécurité.',
      footer: 'Entrelace - Renforcer les relations par une communication guidée',
      plainBody: 'Nous avons reçu une demande de réinitialisation de votre mot de passe Entrelace.',
      plainLink: 'Réinitialisez votre mot de passe :',
      plainExpiry: 'Ce lien expirera dans 1 heure.',
      plainIgnore: 'Si vous n\'avez pas fait cette demande, vous pouvez ignorer cet e-mail en toute sécurité.'
    },
    messageNotification: {
      subject: (senderName) => `${senderName} vous a envoyé un message sur Entrelace`,
      heading: (senderName) => `Nouveau message de ${senderName}`,
      body: (senderName) => `${senderName} vous a envoyé un message dans votre conversation.`,
      preview: 'Aperçu du message :',
      button: 'Voir le message',
      footer: 'Entrelace - Renforcer les relations par une communication guidée',
      // Plain text version
      plainBody: (senderName) => `${senderName} vous a envoyé un message sur Entrelace.`,
      plainView: 'Voir votre message :'
    }
  },
  es: {
    invitation: {
      subject: (inviterName) => `${inviterName} te ha invitado a unirte a Entrelace`,
      title: 'Entrelace',
      subtitle: 'Aplicación de comunicación para parejas',
      heading: '¡Has sido invitado!',
      body: (inviterName) => `<strong>${inviterName}</strong> te ha invitado a unirte a Entrelace, una aplicación de comunicación para parejas que ayuda a fortalecer las relaciones.`,
      personalMessage: 'Mensaje personal:',
      features: 'Entrelace ofrece:',
      feature1: 'Conversaciones privadas entre tú y tu pareja',
      feature2: 'Orientación de comunicación relacional impulsada por IA',
      feature3: 'Espacio seguro para comunicarse y crecer juntos',
      button: 'Aceptar invitación',
      expiry: 'Esta invitación expirará en 7 días.',
      linkInfo: 'Si el botón no funciona, copia y pega este enlace:',
      footer: 'Entrelace - Fortaleciendo relaciones a través de la comunicación guiada',
      // Plain text version
      plainBody: (inviterName) => `¡${inviterName} te ha invitado a unirte a Entrelace!`,
      plainFeatures: `Entrelace ayuda a las parejas a fortalecer sus relaciones a través de:
- Conversaciones privadas entre parejas
- Orientación de comunicación relacional impulsada por IA
- Espacio seguro para comunicarse y crecer juntos`,
      plainAccept: 'Acepta tu invitación:',
      plainExpiry: 'Esta invitación expira en 7 días.'
    },
    welcome: {
      subject: 'Bienvenido a Entrelace',
      heading: (firstName) => `¡Hola ${firstName}!`,
      body: '¡Bienvenido a Entrelace! Estamos emocionados de ayudarte a ti y a tu pareja a fortalecer su relación.',
      nextSteps: 'Próximos pasos:',
      step1: 'Invita a tu pareja a unirse a la aplicación',
      step2: 'Comienza tu primera conversación juntos',
      step3: 'Deja que nuestro coach relacional de IA te guíe en conversaciones significativas',
      closing: 'Recuerda, Entrelace está aquí para apoyarlos a ambos en su camino juntos.',
      footer: 'Entrelace - Fortaleciendo relaciones a través de la comunicación guiada',
      // Plain text version
      plainBody: (firstName) => `¡Hola ${firstName}!\n\n¡Bienvenido a Entrelace! Estamos emocionados de ayudarte a ti y a tu pareja a fortalecer su relación.`,
      plainSteps: `Próximos pasos:
1. Invita a tu pareja a unirse a la aplicación
2. Comienza tu primera conversación juntos
3. Deja que nuestro coach relacional de IA te guíe en conversaciones significativas`,
      plainClosing: 'Recuerda, Entrelace está aquí para apoyarlos a ambos en su camino juntos.'
    },
    passwordReset: {
      subject: 'Restablece tu contraseña de Entrelace',
      heading: 'Solicitud de restablecimiento de contraseña',
      body: 'Recibimos una solicitud para restablecer tu contraseña. Haz clic en el botón de abajo para crear una nueva contraseña.',
      button: 'Restablecer contraseña',
      expiry: 'Este enlace expirará en 1 hora.',
      ignore: 'Si no solicitaste esto, puedes ignorar este correo de forma segura.',
      footer: 'Entrelace - Fortaleciendo relaciones a través de la comunicación guiada',
      plainBody: 'Recibimos una solicitud para restablecer tu contraseña de Entrelace.',
      plainLink: 'Restablece tu contraseña:',
      plainExpiry: 'Este enlace expirará en 1 hora.',
      plainIgnore: 'Si no solicitaste esto, puedes ignorar este correo de forma segura.'
    },
    messageNotification: {
      subject: (senderName) => `${senderName} te ha enviado un mensaje en Entrelace`,
      heading: (senderName) => `Nuevo mensaje de ${senderName}`,
      body: (senderName) => `${senderName} te ha enviado un mensaje en tu conversación.`,
      preview: 'Vista previa del mensaje:',
      button: 'Ver mensaje',
      footer: 'Entrelace - Fortaleciendo relaciones a través de la comunicación guiada',
      // Plain text version
      plainBody: (senderName) => `${senderName} te ha enviado un mensaje en Entrelace.`,
      plainView: 'Ver tu mensaje:'
    }
  }
};

module.exports = emailTranslations;
