const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/authRoutes');
const taskRoutes = require('./routes/taskRoutes');

const app = express();

app.use(cors());
app.use(express.json());

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Task Manager API is running' });
});

app.use('/api/auth', authRoutes);
app.use('/api/tasks', taskRoutes);

app.use((req, res) => {
  res.status(404).json({ message: 'API endpoint không tồn tại.' });
});

app.use((err, req, res, next) => {
  console.error(err);
  if (err.code === 11000) {
    return res.status(409).json({ message: 'Email đã được sử dụng.' });
  }
  res.status(500).json({ message: 'Lỗi máy chủ. Vui lòng thử lại sau.' });
});

module.exports = app;
