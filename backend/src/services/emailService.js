const { SESClient, SendEmailCommand } = require('@aws-sdk/client-ses');
const emailTranslations = require('../locales/emailTranslations');

// Configure SES
const sesClient = new SESClient({
  region: process.env.AWS_REGION || 'eu-west-3'
});

const escapeHtml = (value) => String(value ?? '').replace(/[&<>"']/g, (char) => ({
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&#39;'
}[char]));

const formatOptionalText = (label, value) => {
  if (value === undefined || value === null || value === '') return '';
  return `${label}: ${value}\n`;
};

const formatOptionalHtmlRow = (label, value) => {
  if (value === undefined || value === null || value === '') return '';
  return `<tr><td><strong>${escapeHtml(label)}</strong></td><td>${escapeHtml(value)}</td></tr>`;
};

const formatObjectText = (label, value) => {
  if (!value || typeof value !== 'object' || Array.isArray(value) || Object.keys(value).length === 0) return '';
  return `${label}: ${JSON.stringify(value)}\n`;
};

const formatObjectHtmlRow = (label, value) => {
  if (!value || typeof value !== 'object' || Array.isArray(value) || Object.keys(value).length === 0) return '';
  return `<tr><td><strong>${escapeHtml(label)}</strong></td><td><code>${escapeHtml(JSON.stringify(value))}</code></td></tr>`;
};

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

const sendSignupNotificationEmail = async ({ to, user }) => {
  const appUrl = process.env.FRONTEND_URL || 'https://app.we-connect-app.com';
  const subject = 'Nouvelle inscription We Connect';
  const fullName = `${user.firstName || ''} ${user.lastName || ''}`.trim();

  const htmlRows = [
    formatOptionalHtmlRow('Nom', fullName),
    formatOptionalHtmlRow('Email', user.email),
    formatOptionalHtmlRow('Langue', user.language),
    formatOptionalHtmlRow('Plan choisi', user.selectedPlan || 'free'),
    formatOptionalHtmlRow('Date inscription', user.createdAt),
    formatOptionalHtmlRow('Landing page', user.landingPage),
    formatOptionalHtmlRow('Referrer', user.referrer),
    formatObjectHtmlRow('First touch UTM', user.firstTouchUtm),
    formatObjectHtmlRow('Last touch UTM', user.lastTouchUtm),
    formatObjectHtmlRow('First touch ads', user.firstTouchAdParams),
    formatObjectHtmlRow('Last touch ads', user.lastTouchAdParams)
  ].join('');

  const textBody = [
    'Nouvelle inscription We Connect',
    '',
    formatOptionalText('Nom', fullName),
    formatOptionalText('Email', user.email),
    formatOptionalText('Langue', user.language),
    formatOptionalText('Plan choisi', user.selectedPlan || 'free'),
    formatOptionalText('Date inscription', user.createdAt),
    formatOptionalText('Landing page', user.landingPage),
    formatOptionalText('Referrer', user.referrer),
    formatObjectText('First touch UTM', user.firstTouchUtm),
    formatObjectText('Last touch UTM', user.lastTouchUtm),
    formatObjectText('First touch ads', user.firstTouchAdParams),
    formatObjectText('Last touch ads', user.lastTouchAdParams),
    `App: ${appUrl}`
  ].join('\n').replace(/\n{3,}/g, '\n\n');

  const params = {
    Source: process.env.EMAIL_FROM,
    Destination: {
      ToAddresses: [to]
    },
    Message: {
      Subject: {
        Data: subject,
        Charset: 'UTF-8'
      },
      Body: {
        Html: {
          Data: `
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="utf-8">
              <title>${subject}</title>
              <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { max-width: 640px; margin: 0 auto; padding: 20px; }
                .content { padding: 20px; background: #f9f9f9; border-radius: 8px; }
                table { width: 100%; border-collapse: collapse; }
                td { padding: 8px 0; border-bottom: 1px solid #e5e5e5; vertical-align: top; }
                td:first-child { width: 160px; color: #555; }
                code { white-space: pre-wrap; word-break: break-word; }
                .footer { padding-top: 16px; font-size: 12px; color: #666; }
              </style>
            </head>
            <body>
              <div class="container">
                <h1>${subject}</h1>
                <div class="content">
                  <table>${htmlRows}</table>
                  <p class="footer"><a href="${escapeHtml(appUrl)}">Ouvrir l'app We Connect</a></p>
                </div>
              </div>
            </body>
            </html>
          `,
          Charset: 'UTF-8'
        },
        Text: {
          Data: textBody,
          Charset: 'UTF-8'
        }
      }
    }
  };

  try {
    const command = new SendEmailCommand(params);
    const result = await sesClient.send(command);
    console.log('Signup notification email sent:', result.MessageId);
    return result;
  } catch (error) {
    console.error('Error sending signup notification email:', error);
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
                  <h1>We Connect</h1>
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

const sendPasswordResetEmail = async ({ to, resetToken, language = 'en' }) => {
  const resetUrl = `${process.env.FRONTEND_URL}/reset-password/${resetToken}`;
  
  const lang = emailTranslations[language] || emailTranslations.en;
  const t = lang.passwordReset;
  
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
                  <h1>We Connect</h1>
                </div>
                <div class="content">
                  <h2>${t.heading}</h2>
                  <p>${t.body}</p>
                  <div style="text-align: center;">
                    <a href="${resetUrl}" class="button">${t.button}</a>
                  </div>
                  <p><small>${t.expiry}</small></p>
                  <p><small>${t.ignore}</small></p>
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

            ${t.plainBody}

            ${t.plainLink} ${resetUrl}

            ${t.plainExpiry}

            ${t.plainIgnore}

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
    console.log('Password reset email sent:', result.MessageId);
    return result;
  } catch (error) {
    console.error('Error sending password reset email:', error);
    throw error;
  }
};

module.exports = {
  sendInvitationEmail,
  sendWelcomeEmail,
  sendSignupNotificationEmail,
  sendMessageNotification,
  sendPasswordResetEmail
};
