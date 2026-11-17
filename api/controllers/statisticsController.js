const Task = require('../models/Task');

exports.getTaskStats = async (req, res) => {
  try {
    const userId = req.user.id;
    const total = await Task.countDocuments({ $or: [{ createdBy: userId }, { assignees: userId }] });
    const todo = await Task.countDocuments({ $or: [{ createdBy: userId }, { assignees: userId }], status: 'todo' });
    const in_progress = await Task.countDocuments({ $or: [{ createdBy: userId }, { assignees: userId }], status: 'in_progress' });
    const completed = await Task.countDocuments({ $or: [{ createdBy: userId }, { assignees: userId }], status: 'completed' });

    res.json({ total, todo, in_progress, completed });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getDeadlineStats = async (req, res) => {
  try {
    const userId = req.user.id;
    const now = new Date();
    const upcoming = await Task.countDocuments({
      $or: [{ createdBy: userId }, { assignees: userId }],
      dueDate: { $gte: now },
      status: { $ne: 'completed' },
    });
    const overdue = await Task.countDocuments({
      $or: [{ createdBy: userId }, { assignees: userId }],
      dueDate: { $lt: now },
      status: { $ne: 'completed' },
    });

    res.json({ upcoming, overdue });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
