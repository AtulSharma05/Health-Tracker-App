const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const emailService = require('../services/emailService');
const { generateVerificationToken, generateResetToken } = require('../utils/tokenGenerator');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'dev_secret_change_me';

function createToken(user) {
  return jwt.sign(
    { sub: user._id.toString(), email: user.email },
    JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
}

async function verifyEmailToken(token) {
  if (!token) {
    return { ok: false, status: 400, message: 'Verification token required' };
  }

  const user = await User.findOne({
    emailVerificationToken: token,
    emailVerificationExpiry: { $gt: new Date() },
  });

  if (!user) {
    return { ok: false, status: 400, message: 'Invalid or expired verification token' };
  }

  user.isEmailVerified = true;
  user.emailVerificationToken = null;
  user.emailVerificationExpiry = null;

  // Update auth methods
  if (user.authMethods) {
    user.authMethods = user.authMethods.map((m) =>
      m.type === 'email' ? { ...m, verified: true } : m
    );
  }

  await user.save();

  return {
    ok: true,
    status: 200,
    message: 'Email verified successfully',
    user,
  };
}

function renderVerificationPage({ title, message, isSuccess }) {
  const color = isSuccess ? '#1b5e20' : '#b71c1c';
  const bg = isSuccess ? '#e8f5e9' : '#ffebee';

  return `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>${title}</title>
    <style>
      body { font-family: Arial, sans-serif; margin: 0; background: #f7f9fc; }
      .wrap { max-width: 560px; margin: 10vh auto; padding: 24px; }
      .card { background: ${bg}; border: 1px solid ${color}; border-radius: 12px; padding: 20px; }
      h1 { margin: 0 0 10px; color: ${color}; font-size: 24px; }
      p { margin: 0; color: #1f2937; line-height: 1.5; }
      .hint { margin-top: 14px; color: #4b5563; font-size: 14px; }
    </style>
  </head>
  <body>
    <div class="wrap">
      <div class="card">
        <h1>${title}</h1>
        <p>${message}</p>
        <p class="hint">You can close this tab and return to the NutriPal app.</p>
      </div>
    </div>
  </body>
</html>`;
}

// =============== EMAIL/PASSWORD REGISTRATION & LOGIN ===============

router.post('/register', async (req, res) => {
  try {
    const { name, email, password } = req.body;

    if (!name || !email || !password || password.length < 6) {
      return res.status(400).json({ message: 'Invalid registration payload' });
    }

    const existing = await User.findOne({ email: email.toLowerCase() });
    if (existing) {
      return res.status(409).json({ message: 'Email already in use' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const verificationToken = generateVerificationToken();

    const user = await User.create({
      name,
      email: email.toLowerCase(),
      passwordHash,
      emailVerificationToken: verificationToken,
      emailVerificationExpiry: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours
      authMethods: [{ type: 'email', verified: false }],
    });

    // Send verification email (or provide dev token in non-production fallback)
    const emailResult = await emailService.sendVerificationEmail(
      user.email,
      verificationToken,
      user.name
    );

    const token = createToken(user);

    const responsePayload = {
      message: 'Registration successful. Please verify your email.',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        isEmailVerified: user.isEmailVerified,
      },
    };

    if (process.env.NODE_ENV !== 'production' && (emailResult.isDevelopment || !emailResult.success)) {
      responsePayload.devVerificationToken = verificationToken;
      responsePayload.message = emailResult.isDevelopment
        ? 'Registration successful. Development mode: use the provided verification token.'
        : 'Registration successful, but email delivery failed. Use the provided verification token.';
    }

    return res.status(201).json(responsePayload);
  } catch (error) {
    console.error('Registration error:', error);
    return res.status(500).json({ message: 'Registration failed' });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }

    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user || !user.passwordHash) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Check if account is locked (too many login attempts)
    if (user.lockUntil && user.lockUntil > new Date()) {
      return res.status(429).json({ message: 'Account locked. Try again later.' });
    }

    const isValid = await bcrypt.compare(password, user.passwordHash);
    if (!isValid) {
      // Increment login attempts
      user.loginAttempts = (user.loginAttempts || 0) + 1;
      if (user.loginAttempts >= 5) {
        user.lockUntil = new Date(Date.now() + 15 * 60 * 1000); // Lock for 15 minutes
      }
      await user.save();
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Reset login attempts on successful login
    user.loginAttempts = 0;
    user.lockUntil = null;
    user.lastLoginAt = new Date();
    await user.save();

    const token = createToken(user);
    return res.json({
      token,
      user: { 
        id: user._id, 
        name: user.name, 
        email: user.email,
        isEmailVerified: user.isEmailVerified,
      },
    });
  } catch (error) {
    console.error('Login error:', error);
    return res.status(500).json({ message: 'Login failed' });
  }
});

// =============== EMAIL VERIFICATION ===============

router.post('/verify-email', async (req, res) => {
  try {
    const { token } = req.body;
    const result = await verifyEmailToken(token);

    if (!result.ok) {
      return res.status(result.status).json({ message: result.message });
    }

    const user = result.user;

    return res.json({ 
      message: result.message,
      user: { 
        id: user._id, 
        name: user.name, 
        email: user.email,
        isEmailVerified: user.isEmailVerified,
      },
    });
  } catch (error) {
    console.error('Email verification error:', error);
    return res.status(500).json({ message: 'Verification failed' });
  }
});

router.get('/verify-email', async (req, res) => {
  try {
    const token = (req.query.token || '').toString();
    const result = await verifyEmailToken(token);

    if (!result.ok) {
      return res
        .status(result.status)
        .send(
          renderVerificationPage({
            title: 'Verification Failed',
            message: result.message,
            isSuccess: false,
          })
        );
    }

    return res
      .status(200)
      .send(
        renderVerificationPage({
          title: 'Email Verified',
          message: 'Your email has been verified successfully.',
          isSuccess: true,
        })
      );
  } catch (error) {
    console.error('Email verification link error:', error);
    return res
      .status(500)
      .send(
        renderVerificationPage({
          title: 'Verification Error',
          message: 'Something went wrong while verifying your email.',
          isSuccess: false,
        })
      );
  }
});

router.post('/resend-verification-email', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ message: 'Email required' });
    }

    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (user.isEmailVerified) {
      return res.status(400).json({ message: 'Email already verified' });
    }

    const verificationToken = generateVerificationToken();
    user.emailVerificationToken = verificationToken;
    user.emailVerificationExpiry = new Date(Date.now() + 24 * 60 * 60 * 1000);
    await user.save();

    const emailResult = await emailService.sendVerificationEmail(
      user.email,
      verificationToken,
      user.name
    );

    if (!emailResult.success && process.env.NODE_ENV === 'production') {
      return res.status(500).json({ message: 'Failed to send verification email' });
    }

    if (process.env.NODE_ENV !== 'production' && (emailResult.isDevelopment || !emailResult.success)) {
      return res.json({
        message: emailResult.isDevelopment
          ? 'Development mode: use the provided verification token.'
          : 'Email delivery failed. Use the provided verification token.',
        devVerificationToken: verificationToken,
      });
    }

    return res.json({ message: 'Verification email sent' });
  } catch (error) {
    console.error('Resend verification error:', error);
    return res.status(500).json({ message: 'Failed to send verification email' });
  }
});

// =============== GOOGLE OAUTH ===============

router.post('/google', async (req, res) => {
  try {
    const { googleId, email, name, profilePictureUrl } = req.body;

    if (!googleId || !email) {
      return res.status(400).json({ message: 'Google ID and email required' });
    }

    let user = await User.findOne({ email: email.toLowerCase() });

    if (user) {
      // User exists - link Google account if not already linked
      if (!user.googleId) {
        user.googleId = googleId;
        if (!user.googleProfilePicture) {
          user.googleProfilePicture = profilePictureUrl;
        }
        
        // Add Google to auth methods if not present
        const hasGoogle = user.authMethods?.some(m => m.type === 'google');
        if (!hasGoogle) {
          user.authMethods.push({ type: 'google', verified: true });
        }
      }
      user.lastLoginAt = new Date();
      await user.save();
    } else {
      // Create new user with Google auth
      user = await User.create({
        name,
        email: email.toLowerCase(),
        googleId,
        googleProfilePicture: profilePictureUrl,
        isEmailVerified: true, // Auto-verify Google emails (Google verifies them)
        authMethods: [{ type: 'google', verified: true }],
        lastLoginAt: new Date(),
      });
    }

    const token = createToken(user);
    return res.json({
      token,
      user: { 
        id: user._id, 
        name: user.name, 
        email: user.email,
        isEmailVerified: user.isEmailVerified,
        profilePictureUrl: user.googleProfilePicture,
      },
    });
  } catch (error) {
    console.error('Google auth error:', error);
    return res.status(500).json({ message: 'Google authentication failed' });
  }
});

// =============== PASSWORD RESET ===============

router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ message: 'Email required' });
    }

    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      // Don't reveal if user exists (security)
      return res.json({ message: 'If account exists, reset email has been sent' });
    }

    if (!user.passwordHash) {
      return res.status(400).json({ message: 'Account uses social login. Cannot reset password.' });
    }

    const resetToken = generateResetToken();
    user.passwordResetToken = resetToken;
    user.passwordResetExpiry = new Date(Date.now() + 60 * 60 * 1000); // 1 hour
    await user.save();

    await emailService.sendPasswordResetEmail(user.email, resetToken, user.name);

    return res.json({ message: 'If account exists, reset email has been sent' });
  } catch (error) {
    console.error('Forgot password error:', error);
    return res.status(500).json({ message: 'Failed to process password reset' });
  }
});

router.post('/reset-password', async (req, res) => {
  try {
    const { token, newPassword } = req.body;

    if (!token || !newPassword || newPassword.length < 6) {
      return res.status(400).json({ message: 'Invalid reset token or password' });
    }

    const user = await User.findOne({
      passwordResetToken: token,
      passwordResetExpiry: { $gt: new Date() },
    });

    if (!user) {
      return res.status(400).json({ message: 'Invalid or expired reset token' });
    }

    const passwordHash = await bcrypt.hash(newPassword, 10);
    user.passwordHash = passwordHash;
    user.passwordResetToken = null;
    user.passwordResetExpiry = null;
    await user.save();

    return res.json({ message: 'Password reset successfully' });
  } catch (error) {
    console.error('Reset password error:', error);
    return res.status(500).json({ message: 'Password reset failed' });
  }
});

// =============== USER INFO ===============

router.get('/me', requireAuth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select(
      '_id name email isEmailVerified googleProfilePicture authMethods'
    );
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    return res.json({ 
      user: { 
        id: user._id, 
        name: user.name, 
        email: user.email,
        isEmailVerified: user.isEmailVerified,
        profilePictureUrl: user.googleProfilePicture,
        authMethods: user.authMethods,
      },
    });
  } catch (error) {
    console.error('Get user error:', error);
    return res.status(500).json({ message: 'Failed to fetch user' });
  }
});

module.exports = router;
