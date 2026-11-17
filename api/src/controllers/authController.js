const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const MemoryStore = require('../models/MemoryStore');

function isMongoConnected() {
  return mongoose.connection.readyState === 1;
}

function createToken(userId) {
  return jwt.sign({ userId }, process.env.JWT_SECRET || 'secret', {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });
}

function publicUser(user) {
  return {
    id: user._id?.toString() || user.id,
    fullName: user.fullName,
    email: user.email,
    avatarUrl: user.avatarUrl || '',
  };
}

exports.register = async (req, res) => {
  try {
    const { fullName, email, password } = req.body;
    if (!fullName || !email || !password) {
      return res.status(400).json({ message: 'Vui lòng nhập đầy đủ họ tên, email và mật khẩu.' });
    }
    if (password.length < 6) {
      return res.status(400).json({ message: 'Mật khẩu phải có ít nhất 6 ký tự.' });
    }

    const normalizedEmail = String(email).trim().toLowerCase();

    if (isMongoConnected()) {
      const existingUser = await User.findOne({ email: normalizedEmail });
      if (existingUser) {
        return res.status(409).json({ message: 'Email này đã được sử dụng.' });
      }
      const passwordHash = await bcrypt.hash(password, 12);
      const user = await User.create({
        fullName: fullName.trim(),
        email: normalizedEmail,
        passwordHash,
      });
      return res.status(201).json({
        message: 'Đăng ký tài khoản thành công.',
        token: createToken(user._id),
        user: publicUser(user),
      });
    } else {
      // MemoryStore fallback
      let existing = MemoryStore.users.find(u => u.email === normalizedEmail);
      if (existing) {
        return res.status(409).json({ message: 'Email này đã được sử dụng.' });
      }
      const passwordHash = await bcrypt.hash(password, 12);
      const newUser = {
        _id: 'user_' + Date.now(),
        fullName: fullName.trim(),
        email: normalizedEmail,
        passwordHash,
        avatarUrl: '',
        createdAt: new Date(),
      };
      MemoryStore.users.push(newUser);
      return res.status(201).json({
        message: 'Đăng ký tài khoản thành công.',
        token: createToken(newUser._id),
        user: publicUser(newUser),
      });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Lỗi server khi đăng ký.' });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ message: 'Vui lòng nhập email và mật khẩu.' });
    }

    const normalizedEmail = String(email).trim().toLowerCase();

    if (isMongoConnected()) {
      const user = await User.findOne({ email: normalizedEmail });
      if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
        return res.status(401).json({ message: 'Email hoặc mật khẩu không chính xác.' });
      }
      return res.json({
        message: 'Đăng nhập thành công.',
        token: createToken(user._id),
        user: publicUser(user),
      });
    } else {
      // MemoryStore fallback
      const user = MemoryStore.users.find(u => u.email === normalizedEmail);
      if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
        return res.status(401).json({ message: 'Email hoặc mật khẩu không chính xác.' });
      }
      return res.json({
        message: 'Đăng nhập thành công.',
        token: createToken(user._id),
        user: publicUser(user),
      });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Lỗi server khi đăng nhập.' });
  }
};

exports.me = async (req, res) => {
  try {
    if (isMongoConnected()) {
      const user = await User.findById(req.userId);
      if (!user) {
        return res.status(404).json({ message: 'Không tìm thấy thông tin người dùng.' });
      }
      res.json({ user: publicUser(user) });
    } else {
      const user = MemoryStore.users.find(u => u._id === req.userId);
      if (!user) {
        return res.status(404).json({ message: 'Không tìm thấy thông tin người dùng.' });
      }
      res.json({ user: publicUser(user) });
    }
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server.' });
  }
};

exports.updateMe = async (req, res) => {
  try {
    const { fullName, avatarUrl } = req.body;
    if (isMongoConnected()) {
      const updates = {};
      if (typeof fullName === 'string' && fullName.trim()) updates.fullName = fullName.trim();
      if (typeof avatarUrl === 'string') updates.avatarUrl = avatarUrl.trim();
      const user = await User.findByIdAndUpdate(req.userId, updates, { new: true });
      if (!user) return res.status(404).json({ message: 'Không tìm thấy người dùng.' });
      res.json({ message: 'Cập nhật hồ sơ thành công.', user: publicUser(user) });
    } else {
      const user = MemoryStore.users.find(u => u._id === req.userId);
      if (!user) return res.status(404).json({ message: 'Không tìm thấy người dùng.' });
      if (typeof fullName === 'string' && fullName.trim()) user.fullName = fullName.trim();
      if (typeof avatarUrl === 'string') user.avatarUrl = avatarUrl.trim();
      res.json({ message: 'Cập nhật hồ sơ thành công.', user: publicUser(user) });
    }
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server.' });
  }
};

exports.changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    if (!currentPassword || !newPassword || newPassword.length < 6) {
      return res.status(400).json({ message: 'Vui lòng nhập mật khẩu hiện tại và mật khẩu mới (tối thiểu 6 ký tự).' });
    }

    if (isMongoConnected()) {
      const user = await User.findById(req.userId);
      if (!user || !(await bcrypt.compare(currentPassword, user.passwordHash))) {
        return res.status(400).json({ message: 'Mật khẩu hiện tại không đúng.' });
      }
      user.passwordHash = await bcrypt.hash(newPassword, 12);
      await user.save();
    } else {
      const user = MemoryStore.users.find(u => u._id === req.userId);
      if (!user || !(await bcrypt.compare(currentPassword, user.passwordHash))) {
        return res.status(400).json({ message: 'Mật khẩu hiện tại không đúng.' });
      }
      user.passwordHash = await bcrypt.hash(newPassword, 12);
    }
    res.json({ message: 'Đổi mật khẩu thành công. Vui lòng đăng nhập lại.' });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server.' });
  }
};
