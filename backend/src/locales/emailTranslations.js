// Email translations for multiple languages
const emailTranslations = {
  en: {
    invitation: {
      subject: (inviterName) => `${inviterName} has invited you to join We Counsel`,
      title: 'We Counsel',
      subtitle: 'Couples Counselling App',
      heading: "You've been invited!",
      body: (inviterName) => `<strong>${inviterName}</strong> has invited you to join them on We Counsel, a couples counselling app that helps strengthen relationships.`,
      personalMessage: 'Personal message:',
      features: 'We Counsel provides:',
      feature1: 'Private conversations between you and your partner',
      feature2: 'AI-powered counselling guidance',
      feature3: 'Safe space to communicate and grow together',
      button: 'Accept Invitation',
      expiry: 'This invitation will expire in 7 days.',
      linkInfo: "If the button doesn't work, copy and paste this link:",
      footer: 'We Counsel - Strengthening relationships through guided communication',
      // Plain text version
      plainBody: (inviterName) => `You've been invited by ${inviterName} to join them on We Counsel!`,
      plainFeatures: `We Counsel helps couples strengthen their relationships through:
- Private conversations between partners
- AI-powered counselling guidance  
- Safe space to communicate and grow together`,
      plainAccept: 'Accept your invitation:',
      plainExpiry: 'This invitation expires in 7 days.'
    },
    welcome: {
      subject: 'Welcome to We Counsel',
      heading: (firstName) => `Hi ${firstName}!`,
      body: "Welcome to We Counsel! We're excited to help you and your partner strengthen your relationship.",
      nextSteps: 'Next steps:',
      step1: 'Invite your partner to join you on the app',
      step2: 'Start your first conversation together',
      step3: 'Let our AI counsellor guide you through meaningful discussions',
      closing: 'Remember, We Counsel is here to support you both on your journey together.',
      footer: 'We Counsel - Strengthening relationships through guided communication',
      // Plain text version
      plainBody: (firstName) => `Hi ${firstName}!\n\nWelcome to We Counsel! We're excited to help you and your partner strengthen your relationship.`,
      plainSteps: `Next steps:
1. Invite your partner to join you on the app
2. Start your first conversation together  
3. Let our AI counsellor guide you through meaningful discussions`,
      plainClosing: 'Remember, We Counsel is here to support you both on your journey together.'
    },
    messageNotification: {
      subject: (senderName) => `${senderName} sent you a message on We Counsel`,
      heading: (senderName) => `New message from ${senderName}`,
      body: (senderName) => `${senderName} has sent you a message in your conversation.`,
      preview: 'Message preview:',
      button: 'View Message',
      footer: 'We Counsel - Strengthening relationships through guided communication',
      // Plain text version
      plainBody: (senderName) => `${senderName} has sent you a message on We Counsel.`,
      plainView: 'View your message:'
    }
  },
  fr: {
    invitation: {
      subject: (inviterName) => `${inviterName} vous a invité(e) à rejoindre We Counsel`,
      title: 'We Counsel',
      subtitle: 'Application de conseil de couple',
      heading: 'Vous avez été invité(e) !',
      body: (inviterName) => `<strong>${inviterName}</strong> vous a invité(e) à les rejoindre sur We Counsel, une application de conseil de couple qui aide à renforcer les relations.`,
      personalMessage: 'Message personnel :',
      features: 'We Counsel propose :',
      feature1: 'Conversations privées entre vous et votre partenaire',
      feature2: 'Conseils guidés par IA',
      feature3: 'Espace sûr pour communiquer et grandir ensemble',
      button: 'Accepter l\'invitation',
      expiry: 'Cette invitation expirera dans 7 jours.',
      linkInfo: 'Si le bouton ne fonctionne pas, copiez et collez ce lien :',
      footer: 'We Counsel - Renforcer les relations par une communication guidée',
      // Plain text version
      plainBody: (inviterName) => `Vous avez été invité(e) par ${inviterName} à les rejoindre sur We Counsel !`,
      plainFeatures: `We Counsel aide les couples à renforcer leurs relations grâce à :
- Conversations privées entre partenaires
- Conseils guidés par IA
- Espace sûr pour communiquer et grandir ensemble`,
      plainAccept: 'Acceptez votre invitation :',
      plainExpiry: 'Cette invitation expire dans 7 jours.'
    },
    welcome: {
      subject: 'Bienvenue sur We Counsel',
      heading: (firstName) => `Bonjour ${firstName} !`,
      body: 'Bienvenue sur We Counsel ! Nous sommes ravis de vous aider, vous et votre partenaire, à renforcer votre relation.',
      nextSteps: 'Prochaines étapes :',
      step1: 'Invitez votre partenaire à vous rejoindre sur l\'application',
      step2: 'Commencez votre première conversation ensemble',
      step3: 'Laissez notre conseiller IA vous guider dans des discussions significatives',
      closing: 'N\'oubliez pas, We Counsel est là pour vous soutenir tous les deux dans votre cheminement.',
      footer: 'We Counsel - Renforcer les relations par une communication guidée',
      // Plain text version
      plainBody: (firstName) => `Bonjour ${firstName} !\n\nBienvenue sur We Counsel ! Nous sommes ravis de vous aider, vous et votre partenaire, à renforcer votre relation.`,
      plainSteps: `Prochaines étapes :
1. Invitez votre partenaire à vous rejoindre sur l'application
2. Commencez votre première conversation ensemble
3. Laissez notre conseiller IA vous guider dans des discussions significatives`,
      plainClosing: 'N\'oubliez pas, We Counsel est là pour vous soutenir tous les deux dans votre cheminement.'
    },
    messageNotification: {
      subject: (senderName) => `${senderName} vous a envoyé un message sur We Counsel`,
      heading: (senderName) => `Nouveau message de ${senderName}`,
      body: (senderName) => `${senderName} vous a envoyé un message dans votre conversation.`,
      preview: 'Aperçu du message :',
      button: 'Voir le message',
      footer: 'We Counsel - Renforcer les relations par une communication guidée',
      // Plain text version
      plainBody: (senderName) => `${senderName} vous a envoyé un message sur We Counsel.`,
      plainView: 'Voir votre message :'
    }
  },
  es: {
    invitation: {
      subject: (inviterName) => `${inviterName} te ha invitado a unirte a We Counsel`,
      title: 'We Counsel',
      subtitle: 'Aplicación de consejería de parejas',
      heading: '¡Has sido invitado!',
      body: (inviterName) => `<strong>${inviterName}</strong> te ha invitado a unirte a We Counsel, una aplicación de consejería de parejas que ayuda a fortalecer las relaciones.`,
      personalMessage: 'Mensaje personal:',
      features: 'We Counsel ofrece:',
      feature1: 'Conversaciones privadas entre tú y tu pareja',
      feature2: 'Orientación de consejería impulsada por IA',
      feature3: 'Espacio seguro para comunicarse y crecer juntos',
      button: 'Aceptar invitación',
      expiry: 'Esta invitación expirará en 7 días.',
      linkInfo: 'Si el botón no funciona, copia y pega este enlace:',
      footer: 'We Counsel - Fortaleciendo relaciones a través de la comunicación guiada',
      // Plain text version
      plainBody: (inviterName) => `¡${inviterName} te ha invitado a unirte a We Counsel!`,
      plainFeatures: `We Counsel ayuda a las parejas a fortalecer sus relaciones a través de:
- Conversaciones privadas entre parejas
- Orientación de consejería impulsada por IA
- Espacio seguro para comunicarse y crecer juntos`,
      plainAccept: 'Acepta tu invitación:',
      plainExpiry: 'Esta invitación expira en 7 días.'
    },
    welcome: {
      subject: 'Bienvenido a We Counsel',
      heading: (firstName) => `¡Hola ${firstName}!`,
      body: '¡Bienvenido a We Counsel! Estamos emocionados de ayudarte a ti y a tu pareja a fortalecer su relación.',
      nextSteps: 'Próximos pasos:',
      step1: 'Invita a tu pareja a unirse a la aplicación',
      step2: 'Comienza tu primera conversación juntos',
      step3: 'Deja que nuestro consejero de IA te guíe en discusiones significativas',
      closing: 'Recuerda, We Counsel está aquí para apoyarlos a ambos en su camino juntos.',
      footer: 'We Counsel - Fortaleciendo relaciones a través de la comunicación guiada',
      // Plain text version
      plainBody: (firstName) => `¡Hola ${firstName}!\n\n¡Bienvenido a We Counsel! Estamos emocionados de ayudarte a ti y a tu pareja a fortalecer su relación.`,
      plainSteps: `Próximos pasos:
1. Invita a tu pareja a unirse a la aplicación
2. Comienza tu primera conversación juntos
3. Deja que nuestro consejero de IA te guíe en discusiones significativas`,
      plainClosing: 'Recuerda, We Counsel está aquí para apoyarlos a ambos en su camino juntos.'
    },
    messageNotification: {
      subject: (senderName) => `${senderName} te ha enviado un mensaje en We Counsel`,
      heading: (senderName) => `Nuevo mensaje de ${senderName}`,
      body: (senderName) => `${senderName} te ha enviado un mensaje en tu conversación.`,
      preview: 'Vista previa del mensaje:',
      button: 'Ver mensaje',
      footer: 'We Counsel - Fortaleciendo relaciones a través de la comunicación guiada',
      // Plain text version
      plainBody: (senderName) => `${senderName} te ha enviado un mensaje en We Counsel.`,
      plainView: 'Ver tu mensaje:'
    }
  }
};

module.exports = emailTranslations;
