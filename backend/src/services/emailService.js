const { SESClient, SendEmailCommand } = require('@aws-sdk/client-ses');
const emailTranslations = require('../locales/emailTranslations');

// Configure SES
const sesClient = new SESClient({
  region: process.env.AWS_REGION || 'eu-west-3'
});

const sendInvitationEmail = async ({ to, inviterName, invitationId, message, language = 'en' }) => {
  const invitationUrl = `${process.env.FRONTEND_URL}/invitation/${invitationId}`;
  
  // Get translations for the specified language, fallback to English
  const lang = emailTranslations[language] || emailTranslations.en;
  const t = lang.invitation;
  
  const params = {
    Source: process.env.EMAIL_FROM,
    Destination: {
      ToAddresses: [to]
    },
    Message: {
      Subject: {
        Data: t.subject(inviterName),
        Charset: 'UTF-8'
      },
      Body: {
        Html: {
          Data: `
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="utf-8">
              <title>${t.title}</title>
              <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { text-align: center; padding: 20px 0; }
                .content { padding: 20px; background: #f9f9f9; border-radius: 8px; }
                .button { 
                  display: inline-block; 
                  background: #007bff; 
                  color: white; 
                  padding: 12px 24px; 
                  text-decoration: none; 
                  border-radius: 4px; 
                  margin: 20px 0; 
                }
                .footer { text-align: center; padding: 20px 0; font-size: 12px; color: #666; }
              </style>
            </head>
            <body>
              <div class="container">
                <div class="header">
                  <h1>${t.title}</h1>
                  <h2>${t.subtitle}</h2>
                </div>
                <div class="content">
                  <h3>${t.heading}</h3>
                  <p>${t.body(inviterName)}</p>
                  ${message ? `<p><em>${t.personalMessage} "${message}"</em></p>` : ''}
                  <p>${t.features}</p>
                  <ul>
                    <li>${t.feature1}</li>
                    <li>${t.feature2}</li>
                    <li>${t.feature3}</li>
                  </ul>
                  <div style="text-align: center;">
                    <a href="${invitationUrl}" class="button">${t.button}</a>
                  </div>
                  <p><small>${t.expiry} ${t.linkInfo} ${invitationUrl}</small></p>
                </div>
                <div class="footer">
                  <p>${t.footer}</p>
                </div>
              </div>
            </body>
            </html>
          `,
          Charset: 'UTF-8'
        },
        Text: {
          Data: `
            ${t.title} - ${t.subtitle}

            ${t.plainBody(inviterName)}

            ${message ? `${t.personalMessage} "${message}"` : ''}

            ${t.plainFeatures}

            ${t.plainAccept} ${invitationUrl}

            ${t.plainExpiry}

            ${t.footer}
          `,
          Charset: 'UTF-8'
        }
      }
    }
  };

  try {
    const command = new SendEmailCommand(params);
    const result = await sesClient.send(command);
    console.log('Invitation email sent:', result.MessageId);
    return result;
  } catch (error) {
    console.error('Error sending invitation email:', error);
    throw error;
  }
};

const sendWelcomeEmail = async ({ to, firstName, language = 'en' }) => {
  // Get translations for the specified language, fallback to English
  const lang = emailTranslations[language] || emailTranslations.en;
  const t = lang.welcome;
  
  const params = {
    Source: process.env.EMAIL_FROM,
    Destination: {
      ToAddresses: [to]
    },
    Message: {
      Subject: {
        Data: t.subject,
        Charset: 'UTF-8'
      },
      Body: {
        Html: {
          Data: `
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="utf-8">
              <title>${t.subject}</title>
              <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { text-align: center; padding: 20px 0; }
                .content { padding: 20px; background: #f9f9f9; border-radius: 8px; }
                .footer { text-align: center; padding: 20px 0; font-size: 12px; color: #666; }
              </style>
            </head>
            <body>
              <div class="container">
                <div class="header">
                  <h1>${t.subject}</h1>
                </div>
                <div class="content">
                  <h3>${t.heading(firstName)}</h3>
                  <p>${t.body}</p>
                  <p>${t.nextSteps}</p>
                  <ol>
                    <li>${t.step1}</li>
                    <li>${t.step2}</li>
                    <li>${t.step3}</li>
                  </ol>
                  <p>${t.closing}</p>
                </div>
                <div class="footer">
                  <p>${t.footer}</p>
                </div>
              </div>
            </body>
            </html>
          `,
          Charset: 'UTF-8'
        },
        Text: {
          Data: `
            ${t.subject}

            ${t.plainBody(firstName)}

            ${t.plainSteps}

            ${t.plainClosing}

            ${t.footer}
          `,
          Charset: 'UTF-8'
        }
      }
    }
  };

  try {
    const command = new SendEmailCommand(params);
    const result = await sesClient.send(command);
    console.log('Welcome email sent:', result.MessageId);
    return result;
  } catch (error) {
    console.error('Error sending welcome email:', error);
    throw error;
  }
};

const sendMessageNotification = async ({ to, recipientName, senderName, messagePreview, conversationId, language = 'en' }) => {
  const conversationUrl = `${process.env.FRONTEND_URL}/conversations`;
  
  // Get translations for the specified language, fallback to English
  const lang = emailTranslations[language] || emailTranslations.en;
  const t = lang.messageNotification;
  
  // Truncate message preview to 150 characters
  const preview = messagePreview.length > 150 
    ? messagePreview.substring(0, 150) + '...' 
    : messagePreview;
  
  const params = {
    Source: process.env.EMAIL_FROM,
    Destination: {
      ToAddresses: [to]
    },
    Message: {
      Subject: {
        Data: t.subject(senderName),
        Charset: 'UTF-8'
      },
      Body: {
        Html: {
          Data: `
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="utf-8">
              <title>${t.subject(senderName)}</title>
              <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { text-align: center; padding: 20px 0; }
                .content { padding: 20px; background: #f9f9f9; border-radius: 8px; }
                .message-preview { 
                  background: white; 
                  padding: 15px; 
                  border-left: 4px solid #007bff; 
                  margin: 20px 0;
                  font-style: italic;
                }
                .button { 
                  display: inline-block; 
                  background: #007bff; 
                  color: white; 
                  padding: 12px 24px; 
                  text-decoration: none; 
                  border-radius: 4px; 
                  margin: 20px 0; 
                }
                .footer { text-align: center; padding: 20px 0; font-size: 12px; color: #666; }
              </style>
            </head>
            <body>
              <div class="container">
                <div class="header">
                  <h1>We Coach</h1>
                </div>
                <div class="content">
                  <h2>${t.heading(senderName)}</h2>
                  <p>${t.body(senderName)}</p>
                  <p><strong>${t.preview}</strong></p>
                  <div class="message-preview">
                    "${preview}"
                  </div>
                  <a href="${conversationUrl}" class="button">${t.button}</a>
                </div>
                <div class="footer">
                  <p>${t.footer}</p>
                </div>
              </div>
            </body>
            </html>
          `,
          Charset: 'UTF-8'
        },
        Text: {
          Data: `
            ${t.subject(senderName)}

            ${t.plainBody(senderName)}

            ${t.preview}
            "${preview}"

            ${t.plainView}
            ${conversationUrl}

            ${t.footer}
          `,
          Charset: 'UTF-8'
        }
      }
    }
  };

  try {
    const command = new SendEmailCommand(params);
    const result = await sesClient.send(command);
    console.log('Message notification email sent:', result.MessageId);
    return result;
  } catch (error) {
    console.error('Error sending message notification email:', error);
    throw error;
  }
};

module.exports = {
  sendInvitationEmail,
  sendWelcomeEmail,
  sendMessageNotification
};
