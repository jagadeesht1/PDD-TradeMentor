const mongoose = require('../backend/node_modules/mongoose');

async function reset() {
  console.log('Connecting to MongoDB...');
  await mongoose.connect('mongodb://127.0.0.1:27017/tradementor');
  
  console.log('Resetting default user...');
  await mongoose.connection.db.collection('users').updateOne(
    { email: 'demo@tradementor.com' },
    { $set: { walletBalance: 100000.00 } }
  );

  console.log('Resetting portfolios...');
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
  console.error('Reset failed:', err);
  process.exit(1);
});
