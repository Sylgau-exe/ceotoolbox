// lib/email.js - Email service using Resend (adapted from BizSimHub)
const RESEND_API_KEY = process.env.RESEND_API_KEY;
const FROM_EMAIL = process.env.FROM_EMAIL || 'CEO Toolbox <noreply@pandaprojet.com>';
const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'sgauthier@executiveproducer.ca';

export async function sendEmail({ to, subject, html, text, replyTo }) {
  if (!RESEND_API_KEY) {
    console.error('RESEND_API_KEY is not configured');
    throw new Error('Email service not configured');
  }

  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${RESEND_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: FROM_EMAIL,
      to: Array.isArray(to) ? to : [to],
      subject,
      html,
      text,
      reply_to: replyTo,
    }),
  });

  const data = await response.json();

  if (!response.ok) {
    console.error('Resend API error:', data);
    throw new Error(data.message || 'Failed to send email');
  }

  return data;
}

export async function sendPasswordResetEmail({ name, email, resetToken, resetUrl }) {
  const firstName = name ? name.split(' ')[0] : 'there';
  const fullResetUrl = resetUrl || `https://pmskillsassess.com?reset_token=${resetToken}`;
  
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; background: #f3f4f6; }
        .container { max-width: 600px; margin: 0 auto; padding: 40px 20px; }
        .card { background: white; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%); color: white; padding: 40px 30px; text-align: center; }
        .header h1 { margin: 0; font-size: 24px; }
        .content { padding: 40px 30px; }
        .cta { text-align: center; margin: 32px 0; }
        .cta a { display: inline-block; background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%); color: white; padding: 14px 32px; border-radius: 8px; text-decoration: none; font-weight: 600; }
        .warning { background: #fef3c7; border: 1px solid #f59e0b; border-radius: 8px; padding: 16px; margin: 24px 0; font-size: 14px; }
        .footer { text-align: center; padding: 24px; color: #6b7280; font-size: 14px; border-top: 1px solid #e5e7eb; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="card">
          <div class="header">
            <h1>🔑 Reset Your Password</h1>
          </div>
          <div class="content">
            <p>Hi ${firstName},</p>
            <p>We received a request to reset your CEO Toolbox password. Click the button below to create a new password:</p>
            
            <div class="cta">
              <a href="${fullResetUrl}">Reset Password</a>
            </div>
            
            <div class="warning">
              ⚠️ This link expires in 1 hour. If you didn't request this reset, you can safely ignore this email.
            </div>
            
            <p>If the button doesn't work, copy and paste this URL into your browser:</p>
            <p style="word-break: break-all; color: #6366f1;">${fullResetUrl}</p>
          </div>
          <div class="footer">
            <p>© 2026 CEO Toolbox by Panda Projet Inc.</p>
          </div>
        </div>
      </div>
    </body>
    </html>
  `;

  const text = `
Reset Your Password

Hi ${firstName},

We received a request to reset your CEO Toolbox password. Visit this link to create a new password:

${fullResetUrl}

This link expires in 1 hour. If you didn't request this reset, you can safely ignore this email.

- CEO Toolbox
  `;

  return sendEmail({
    to: email,
    subject: 'Reset your CEO Toolbox password',
    html,
    text,
  });
}

export async function sendWelcomeEmail({ name, email }) {
  const firstName = name ? name.split(' ')[0] : 'there';
  
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; background: #f3f4f6; }
        .container { max-width: 600px; margin: 0 auto; padding: 40px 20px; }
        .card { background: white; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%); color: white; padding: 40px 30px; text-align: center; }
        .header h1 { margin: 0 0 8px 0; font-size: 28px; }
        .content { padding: 40px 30px; }
        .features { background: #f9fafb; border-radius: 12px; padding: 24px; margin: 24px 0; }
        .cta { text-align: center; margin: 32px 0; }
        .cta a { display: inline-block; background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%); color: white; padding: 14px 32px; border-radius: 8px; text-decoration: none; font-weight: 600; }
        .footer { text-align: center; padding: 24px; color: #6b7280; font-size: 14px; border-top: 1px solid #e5e7eb; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="card">
          <div class="header">
            <h1>Welcome to CEO Toolbox!</h1>
            <p>Assess. Improve. Advance.</p>
          </div>
          <div class="content">
            <p>Hi ${firstName},</p>
            <p>Thanks for joining CEO Toolbox! You now have access to the GSM Decision Platform.</p>
            
            <div class="features">
              <p>📊 <strong>13 Skill Areas</strong> — Evaluate your PM competencies</p>
              <p>🗺️ <strong>Personalized Roadmap</strong> — Get a custom learning path</p>
              <p>📄 <strong>PDF Report</strong> — Download your detailed assessment</p>
            </div>
            
            <div class="cta">
              <a href="/">Open the platform →</a>
            </div>
            
            <p>See you on the platform.<br><strong>CEO Toolbox Team</strong></p>
          </div>
          <div class="footer">
            <p>© 2026 CEO Toolbox by Panda Projet Inc.</p>
          </div>
        </div>
      </div>
    </body>
    </html>
  `;

  return sendEmail({
    to: email,
    subject: `Welcome to CEO Toolbox, ${firstName}!`,
    html,
    text: `Welcome to CEO Toolbox, ${firstName}! Sign in to the GSM Decision Platform.`,
    replyTo: ADMIN_EMAIL,
  });
}
