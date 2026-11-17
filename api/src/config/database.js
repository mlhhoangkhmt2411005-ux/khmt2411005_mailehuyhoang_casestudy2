const mongoose = require('mongoose');

async function connectDatabase() {
  if (!process.env.MONGO_URI) {
    console.warn('Thiếu cấu hình MONGO_URI, chạy ở chế độ MemoryStore fallback.');
    return;
  }
  try {
    await mongoose.connect(process.env.MONGO_URI, { serverSelectionTimeoutMS: 2000 });
    console.log('Kết nối thành công đến MongoDB database');
  } catch (error) {
    console.warn('⚠️ Không thể kết nối MongoDB (chạy không cần MongoDB qua MemoryStore fallback):', error.message);
  }
}

module.exports = connectDatabase;
