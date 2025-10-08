const AWS = require('aws-sdk');

// Configure SES
const ses = new AWS.SES({
  region: process.env.SES_REGION || 'us-east-1'
});

const sendInvitationEmail = async ({ to, inviterName, invitationId, message }) => {
  const invitationUrl = `${process.env.FRONTEND_URL}/invitation/${invitationId}`;
  
  const params = {
    Source: process.env.SES_FROM_EMAIL,
    Destination: {
      ToAddresses: [to]
    },
    Message: {
      Subject: {
        Data: `${inviterName} has invited you to join We Counsel`,
        Charset: 'UTF-8'
      },
      Body: {
        Html: {
          Data: `
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="utf-8">
              <title>We Counsel Invitation</title>
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
                  <h1>We Counsel</h1>
                  <h2>Couples Counselling App</h2>
                </div>
                <div class="content">
                  <h3>You've been invited!</h3>
                  <p><strong>${inviterName}</strong> has invited you to join them on We Counsel, a couples counselling app that helps strengthen relationships.</p>
                  ${message ? `<p><em>Personal message: "${message}"</em></p>` : ''}
                  <p>We Counsel provides:</p>
                  <ul>
                    <li>Private conversations between you and your partner</li>
                    <li>AI-powered counselling guidance</li>
                    <li>Safe space to communicate and grow together</li>
                  </ul>
                  <div style="text-align: center;">
                    <a href="${invitationUrl}" class="button">Accept Invitation</a>
                  </div>
                  <p><small>This invitation will expire in 7 days. If the button doesn't work, copy and paste this link: ${invitationUrl}</small></p>
                </div>
                <div class="footer">
                  <p>We Counsel - Strengthening relationships through guided communication</p>
                </div>
              </div>
            </body>
            </html>
          `,
          Charset: 'UTF-8'
        },
        Text: {
          Data: `
            We Counsel - Couples Counselling App

            You've been invited by ${inviterName} to join them on We Counsel!

            ${message ? `Personal message: "${message}"` : ''}

            We Counsel helps couples strengthen their relationships through:
            - Private conversations between partners
            - AI-powered counselling guidance  
            - Safe space to communicate and grow together

            Accept your invitation: ${invitationUrl}

            This invitation expires in 7 days.

            We Counsel - Strengthening relationships through guided communication
          `,
          Charset: 'UTF-8'
        }
      }
    }
  };

  try {
    const result = await ses.sendEmail(params).promise();
    console.log('Invitation email sent:', result.MessageId);
    return result;
  } catch (error) {
    console.error('Error sending invitation email:', error);
    throw error;
  }
};

const sendWelcomeEmail = async ({ to, firstName }) => {
  const params = {
    Source: process.env.SES_FROM_EMAIL,
    Destination: {
      ToAddresses: [to]
    },
    Message: {
      Subject: {
        Data: 'Welcome to We Counsel',
        Charset: 'UTF-8'
      },
      Body: {
        Html: {
          Data: `
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="utf-8">
              <title>Welcome to We Counsel</title>
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
                  <h1>Welcome to We Counsel</h1>
                </div>
                <div class="content">
                  <h3>Hi ${firstName}!</h3>
                  <p>Welcome to We Counsel! We're excited to help you and your partner strengthen your relationship.</p>
                  <p>Next steps:</p>
                  <ol>
                    <li>Invite your partner to join you on the app</li>
                    <li>Start your first conversation together</li>
                    <li>Let our AI counsellor guide you through meaningful discussions</li>
                  </ol>
                  <p>Remember, We Counsel is here to support you both on your journey together.</p>
                </div>
                <div class="footer">
                  <p>We Counsel - Strengthening relationships through guided communication</p>
                </div>
              </div>
            </body>
            </html>
          `,
          Charset: 'UTF-8'
        },
        Text: {
          Data: `
            Welcome to We Counsel!

            Hi ${firstName}!

            Welcome to We Counsel! We're excited to help you and your partner strengthen your relationship.

            Next steps:
            1. Invite your partner to join you on the app
            2. Start your first conversation together  
            3. Let our AI counsellor guide you through meaningful discussions

            Remember, We Counsel is here to support you both on your journey together.

            We Counsel - Strengthening relationships through guided communication
          `,
          Charset: 'UTF-8'
        }
      }
    }
  };

  try {
    const result = await ses.sendEmail(params).promise();
    console.log('Welcome email sent:', result.MessageId);
    return result;
  } catch (error) {
    console.error('Error sending welcome email:', error);
    throw error;
  }
};

module.exports = {
  sendInvitationEmail,
  sendWelcomeEmail
};
