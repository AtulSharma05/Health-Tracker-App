const mongoose = require('mongoose');

async function connectDB(uri) {
  await mongoose.connect(uri);

  // Repair legacy googleId unique index that blocks email/password signups.
  const users = mongoose.connection.collection('users');
  try {
    const indexes = await users.indexes();
    const googleIdIndex = indexes.find((idx) => idx.name === 'googleId_1');
    const hasPartialFilter = Boolean(googleIdIndex?.partialFilterExpression);

    if (googleIdIndex && !hasPartialFilter) {
      await users.updateMany(
        { googleId: null },
        { $unset: { googleId: '' } }
      );
      await users.dropIndex('googleId_1');
      await users.createIndex(
        { googleId: 1 },
        { unique: true, partialFilterExpression: { googleId: { $type: 'string' } } }
      );
      console.log('Repaired users.googleId_1 index for OAuth/email signup compatibility');
    }
  } catch (error) {
    console.warn('Skipped googleId index repair:', error.message);
  }

  console.log('MongoDB connected');
}

module.exports = connectDB;
