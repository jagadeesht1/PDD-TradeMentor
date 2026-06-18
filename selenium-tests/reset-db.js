// Try to load mongoose from various possible locations
let mongoose;
try {
  mongoose = require('mongoose');
} catch (e) {
  try {
    mongoose = require('../backend/node_modules/mongoose');
  } catch (e2) {
    console.warn('Warning: mongoose not found, skipping DB reset. Tests will run without a clean slate.');
    process.exit(0); // Exit cleanly so test-runner.js continues
  }
}

async function reset() {
  console.log('Connecting to MongoDB for pre-test reset...');
  try {
    await mongoose.connect('mongodb://127.0.0.1:27017/tradementor', { serverSelectionTimeoutMS: 5000 });
  } catch (connErr) {
    console.warn('Warning: Could not connect to MongoDB for reset:', connErr.message);
    console.warn('Skipping DB reset - tests will continue.');
    process.exit(0);
  }

  console.log('Resetting default user wallet balance...');
  await mongoose.connection.db.collection('users').updateOne(
    { email: 'demo@tradementor.com' },
    { $set: { walletBalance: 100000.00 } }
  );

  console.log('Resetting portfolio holdings...');
  await mongoose.connection.db.collection('portfolios').updateOne(
    { userId: 'default' },
    { $set: { holdings: [] } }
  );

  console.log('Deleting trade history...');
  await mongoose.connection.db.collection('trades').deleteMany({ userId: 'default' });

  console.log('Database reset completed successfully.');
  await mongoose.disconnect();
}

reset().catch(err => {
  console.warn('DB reset encountered an error (non-fatal):', err.message);
  process.exit(0); // Exit cleanly so test-runner.js continues
});
