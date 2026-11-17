require('dotenv').config();
const app = require('./app');
const connectDatabase = require('./config/database');

const PORT = process.env.PORT || 3000;

connectDatabase()
  .then(() => {
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`API running at http://localhost:${PORT}`);
    });
  })
  .catch((error) => {
    console.error('Không thể kết nối MongoDB:', error.message);
    process.exit(1);
  });
