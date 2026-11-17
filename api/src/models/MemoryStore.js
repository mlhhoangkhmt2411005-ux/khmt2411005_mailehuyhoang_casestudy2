const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// In-memory fallback store when MongoDB is not running
const users = [];
const tasks = [];

// Seed default user for testing
async function initMemoryStore() {
  if (users.length === 0) {
    const hash = await bcrypt.hash('123456', 12);
    users.push({
      _id: 'user_default_1',
      fullName: 'Mai Lê Huy Hoàng',
      email: 'huyhoang0106@gmail.com',
      passwordHash: hash,
      avatarUrl: '',
      createdAt: new Date(),
    });
    // Seed sample task
    tasks.push({
      _id: 'task_1',
      title: 'Hoàn thành Case Study 2 - Phần B',
      description: 'Phát triển ứng dụng Quản lý công việc Flutter & Node.js API',
      createdBy: 'user_default_1',
      assigneeIds: ['user_default_1'],
      startDate: new Date(),
      dueDate: new Date(Date.now() + 86400000 * 3),
      priority: 'high',
      status: 'in_progress',
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  }
}

initMemoryStore();

function createToken(userId) {
  return jwt.sign({ userId }, process.env.JWT_SECRET || 'secret', { expiresIn: '7d' });
}

module.exports = {
  users,
  tasks,
  createToken,
};
