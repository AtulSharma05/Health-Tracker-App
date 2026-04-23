const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    passwordHash: { type: String, default: null }, // null for social logins
    
    // Email verification
    isEmailVerified: { type: Boolean, default: false },
    emailVerificationToken: { type: String, default: null },
    emailVerificationExpiry: { type: Date, default: null },
    
    // Google OAuth
    googleId: { type: String, trim: true },
    googleProfilePicture: { type: String, default: null },
    
    // Auth method tracking
    authMethods: [
      {
        type: { type: String, enum: ['email', 'google'], required: true },
        verified: { type: Boolean, default: false },
        connectedAt: { type: Date, default: Date.now },
      },
    ],
    
    // Password reset
    passwordResetToken: { type: String, default: null },
    passwordResetExpiry: { type: Date, default: null },
    
    // Last login tracking
    lastLoginAt: { type: Date, default: null },
    loginAttempts: { type: Number, default: 0 },
    lockUntil: { type: Date, default: null },
  },
  { timestamps: true }
);

// Index for email verification and password reset tokens
userSchema.index({ emailVerificationToken: 1 });
userSchema.index({ passwordResetToken: 1 });
// Only enforce uniqueness when googleId is an actual string value.
userSchema.index(
  { googleId: 1 },
  { unique: true, partialFilterExpression: { googleId: { $type: 'string' } } }
);

module.exports = mongoose.model('User', userSchema);
