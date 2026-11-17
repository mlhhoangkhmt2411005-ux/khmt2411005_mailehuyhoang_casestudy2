const User = require('../models/User');

exports.searchUsers = async (req, res) => {
  try {
    const q = req.query.q || '';
    const users = await User.find({
      $or: [
        { fullName: { $regex: q, $options: 'i' } },
        { email: { $regex: q, $options: 'i' } },
      ],
    }).select('-password').limit(10);
    res.json(users);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
