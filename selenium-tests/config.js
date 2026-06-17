module.exports = {
  baseUrl: 'http://localhost:5173',
  browserName: 'chrome',
  headless: true, // Run headless by default for clean CLI output, change to false to view browser execution
  timeout: 15000, // Explicit wait timeout in milliseconds
  credentials: {
    email: 'demo@tradementor.com',
    password: 'password123'
  }
};
