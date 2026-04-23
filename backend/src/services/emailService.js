const nodemailer = require('nodemailer');

class EmailService {
  constructor() {
    const hasSmtpCreds = Boolean(process.env.EMAIL_USER && process.env.EMAIL_PASSWORD);

    // Configure email transporter
    // For development: use ethereal email (free testing), or real SMTP
    this.transporter = nodemailer.createTransport({
      service: process.env.EMAIL_SERVICE || 'gmail',
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASSWORD,
      },
    });

    // Fallback for development (no real email sending)
    this.isDevelopment = process.env.NODE_ENV !== 'production' && !hasSmtpCreds;
  }

  async sendVerificationEmail(email, verificationToken, name) {
    const backendBaseUrl =
      process.env.BACKEND_PUBLIC_URL || `http://localhost:${process.env.PORT || 4000}`;
    const verificationBaseUrl =
      process.env.VERIFICATION_LINK_BASE_URL || `${backendBaseUrl}/api/v1/auth/verify-email`;
    const verificationLink = `${verificationBaseUrl}?token=${encodeURIComponent(verificationToken)}`;

    const htmlContent = `
      <h2>Welcome to NutriPal, ${name}!</h2>
      <p>Please verify your email address to complete your registration.</p>
      <p>
        <a href="${verificationLink}" style="display: inline-block; padding: 10px 20px; background-color: #007AFF; color: white; text-decoration: none; border-radius: 5px;">
          Verify Email
        </a>
      </p>
      <p>Or copy this link: ${verificationLink}</p>
      <p>This link expires in 24 hours.</p>
      <hr>
      <p>If you didn't create this account, please ignore this email.</p>
    `;

    try {
      if (this.isDevelopment) {
        console.log(`[DEV] Verification email would be sent to: ${email}`);
        console.log(`[DEV] Verification link: ${verificationLink}`);
        return { success: true, isDevelopment: true };
      }

      await this.transporter.sendMail({
        from: process.env.EMAIL_USER,
        to: email,
        subject: 'Verify Your NutriPal Email',
        html: htmlContent,
      });

      return { success: true };
    } catch (error) {
      console.error('Email service error:', error);
      return { success: false, error: error.message };
    }
  }

  async sendPasswordResetEmail(email, resetToken, name) {
    const resetLink = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/reset-password?token=${resetToken}`;

    const htmlContent = `
      <h2>Password Reset Request</h2>
      <p>Hi ${name},</p>
      <p>We received a request to reset your password. Click the link below to create a new password.</p>
      <p>
        <a href="${resetLink}" style="display: inline-block; padding: 10px 20px; background-color: #007AFF; color: white; text-decoration: none; border-radius: 5px;">
          Reset Password
        </a>
      </p>
      <p>Or copy this link: ${resetLink}</p>
      <p>This link expires in 1 hour.</p>
      <hr>
      <p>If you didn't request a password reset, please ignore this email.</p>
    `;

    try {
      if (this.isDevelopment) {
        console.log(`[DEV] Reset email would be sent to: ${email}`);
        console.log(`[DEV] Reset link: ${resetLink}`);
        return { success: true, isDevelopment: true };
      }

      await this.transporter.sendMail({
        from: process.env.EMAIL_USER,
        to: email,
        subject: 'Reset Your NutriPal Password',
        html: htmlContent,
      });

      return { success: true };
    } catch (error) {
      console.error('Email service error:', error);
      return { success: false, error: error.message };
    }
  }
}

module.exports = new EmailService();
