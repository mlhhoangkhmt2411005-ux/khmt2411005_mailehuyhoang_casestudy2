const Task = require('../models/Task');
const TaskActivity = require('../models/TaskActivity');

exports.getTasks = async (req, res) => {
  try {
    const { status, priority, search } = req.query;
    let query = {
      $or: [
        { createdBy: req.user.id },
        { assignees: req.user.id },
      ],
    };

    if (status) query.status = status;
    if (priority) query.priority = priority;
    if (search) {
      query.title = { $regex: search, $options: 'i' };
    }

    const tasks = await Task.find(query)
      .populate('createdBy', 'fullName email')
      .populate('assignees', 'fullName email')
      .populate('primaryAssignee', 'fullName email')
      .sort({ createdAt: -1 });

    res.json(tasks);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.createTask = async (req, res) => {
  try {
    const { title, description, startDate, dueDate, priority } = req.body;
    const task = await Task.create({
      title,
      description,
      startDate,
      dueDate,
      priority,
      createdBy: req.user.id,
      assignees: [req.user.id],
      primaryAssignee: req.user.id,
    });

    await TaskActivity.create({
      taskId: task._id,
      userId: req.user.id,
      action: 'Đã tạo công việc mới',
    });

    res.status(201).json(task);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getTaskById = async (req, res) => {
  try {
    const task = await Task.findById(req.params.id)
      .populate('createdBy', 'fullName email')
      .populate('assignees', 'fullName email')
      .populate('primaryAssignee', 'fullName email');

    if (!task) return res.status(404).json({ message: 'Không tìm thấy công việc' });
    res.json(task);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.updateTask = async (req, res) => {
  try {
    const { title, description, startDate, dueDate, priority } = req.body;
    const task = await Task.findByIdAndUpdate(
      req.params.id,
      { title, description, startDate, dueDate, priority },
      { new: true }
    );

    await TaskActivity.create({
      taskId: task._id,
      userId: req.user.id,
      action: 'Đã cập nhật thông tin công việc',
    });

    res.json(task);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.deleteTask = async (req, res) => {
  try {
    await Task.findByIdAndDelete(req.params.id);
    await TaskActivity.deleteMany({ taskId: req.params.id });
    res.json({ message: 'Đã xóa công việc thành công' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.updateStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const task = await Task.findByIdAndUpdate(req.params.id, { status }, { new: true });

    await TaskActivity.create({
      taskId: task._id,
      userId: req.user.id,
      action: `Đã thay đổi trạng thái thành: ${status}`,
    });

    res.json(task);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getTaskActivities = async (req, res) => {
  try {
    const activities = await TaskActivity.find({ taskId: req.params.id })
      .populate('userId', 'fullName email')
      .sort({ createdAt: -1 });
    res.json(activities);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.assignTask = async (req, res) => {
  try {
    const { assignees, primaryAssignee } = req.body;
    const task = await Task.findByIdAndUpdate(
      req.params.id,
      { assignees, primaryAssignee },
      { new: true }
    );

    await TaskActivity.create({
      taskId: task._id,
      userId: req.user.id,
      action: 'Đã cập nhật phân công công việc',
    });

    res.json(task);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
