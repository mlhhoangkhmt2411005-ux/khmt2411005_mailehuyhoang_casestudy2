const mongoose = require('mongoose');
const Task = require('../models/Task');
const MemoryStore = require('../models/MemoryStore');

function isMongoConnected() {
  return mongoose.connection.readyState === 1;
}

function canAccess(task, userId) {
  const creatorId = task.createdBy?._id?.toString() || task.createdBy?.toString();
  const assignees = (task.assigneeIds || []).map(a => a?._id?.toString() || a?.toString());
  return creatorId === userId || assignees.includes(userId);
}

exports.list = async (req, res) => {
  try {
    if (isMongoConnected()) {
      let filter = { $or: [{ createdBy: req.userId }, { assigneeIds: req.userId }] };
      if (req.query.scope === 'created') {
        filter = { createdBy: req.userId };
      } else if (req.query.scope === 'assigned') {
        filter = { assigneeIds: req.userId };
      }

      if (req.query.status) filter.status = req.query.status;
      if (req.query.priority) filter.priority = req.query.priority;
      if (req.query.q) filter.title = { $regex: String(req.query.q), $options: 'i' };

      const allowedSort = ['dueDate', 'priority', 'createdAt'];
      const sortBy = allowedSort.includes(req.query.sortBy) ? req.query.sortBy : 'createdAt';
      const order = req.query.order === 'asc' ? 1 : -1;

      const tasks = await Task.find(filter)
        .populate('createdBy', 'fullName email')
        .populate('assigneeIds', 'fullName email')
        .sort({ [sortBy]: order });

      return res.json({ tasks });
    } else {
      // MemoryStore fallback
      let list = MemoryStore.tasks.filter(t => canAccess(t, req.userId));
      if (req.query.scope === 'created') {
        list = list.filter(t => (t.createdBy?._id?.toString() || t.createdBy?.toString()) === req.userId);
      } else if (req.query.scope === 'assigned') {
        list = list.filter(t => (t.assigneeIds || []).some(a => (a?._id?.toString() || a?.toString()) === req.userId));
      }

      if (req.query.status) {
        list = list.filter(t => t.status === req.query.status);
      }
      if (req.query.priority) {
        list = list.filter(t => t.priority === req.query.priority);
      }
      if (req.query.q) {
        const q = String(req.query.q).toLowerCase();
        list = list.filter(t => t.title.toLowerCase().includes(q));
      }

      const sortBy = req.query.sortBy || 'createdAt';
      const order = req.query.order === 'asc' ? 1 : -1;
      list.sort((a, b) => {
        let va = a[sortBy] || 0;
        let vb = b[sortBy] || 0;
        if (va instanceof Date) va = va.getTime();
        if (vb instanceof Date) vb = vb.getTime();
        if (va < vb) return -1 * order;
        if (va > vb) return 1 * order;
        return 0;
      });

      // Populate createdBy
      const populated = list.map(t => {
        const creator = MemoryStore.users.find(u => u._id === (t.createdBy?._id || t.createdBy));
        return {
          ...t,
          createdBy: creator ? { _id: creator._id, fullName: creator.fullName, email: creator.email } : null,
        };
      });

      return res.json({ tasks: populated });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Lỗi server khi lấy danh sách công việc.' });
  }
};

exports.create = async (req, res) => {
  try {
    const { title, description, startDate, dueDate, priority, status } = req.body;

    if (!title || !title.trim()) {
      return res.status(400).json({ message: 'Tên công việc không được để trống.' });
    }

    if (startDate && dueDate && new Date(dueDate) < new Date(startDate)) {
      return res.status(400).json({ message: 'Hạn hoàn thành không được trước ngày bắt đầu.' });
    }

    if (isMongoConnected()) {
      const task = await Task.create({
        title: title.trim(),
        description: description || '',
        createdBy: req.userId,
        startDate: startDate ? new Date(startDate) : null,
        dueDate: dueDate ? new Date(dueDate) : null,
        priority: priority || 'medium',
        status: status || 'todo',
      });
      const populatedTask = await Task.findById(task._id).populate('createdBy', 'fullName email');
      return res.status(201).json({ message: 'Tạo công việc thành công.', task: populatedTask });
    } else {
      const newTask = {
        _id: 'task_' + Date.now(),
        title: title.trim(),
        description: description || '',
        createdBy: req.userId,
        assigneeIds: [req.userId],
        startDate: startDate ? new Date(startDate) : null,
        dueDate: dueDate ? new Date(dueDate) : null,
        priority: priority || 'medium',
        status: status || 'todo',
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      MemoryStore.tasks.push(newTask);
      const creator = MemoryStore.users.find(u => u._id === req.userId);
      const taskWithCreator = {
        ...newTask,
        createdBy: creator ? { _id: creator._id, fullName: creator.fullName, email: creator.email } : null,
      };
      return res.status(201).json({ message: 'Tạo công việc thành công.', task: taskWithCreator });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Lỗi server khi tạo công việc.' });
  }
};

exports.detail = async (req, res) => {
  try {
    const taskId = req.params.id;
    if (isMongoConnected()) {
      const task = await Task.findById(taskId)
        .populate('createdBy', 'fullName email')
        .populate('assigneeIds', 'fullName email');

      if (!task) {
        return res.status(404).json({ message: 'Không tìm thấy công việc.' });
      }
      if (!canAccess(task, req.userId)) {
        return res.status(403).json({ message: 'Bạn không có quyền truy cập công việc này.' });
      }
      return res.json({ task });
    } else {
      const task = MemoryStore.tasks.find(t => t._id === taskId);
      if (!task) {
        return res.status(404).json({ message: 'Không tìm thấy công việc.' });
      }
      if (!canAccess(task, req.userId)) {
        return res.status(403).json({ message: 'Bạn không có quyền truy cập công việc này.' });
      }
      const creator = MemoryStore.users.find(u => u._id === (task.createdBy?._id || task.createdBy));
      const populated = {
        ...task,
        createdBy: creator ? { _id: creator._id, fullName: creator.fullName, email: creator.email } : null,
      };
      return res.json({ task: populated });
    }
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server khi lấy chi tiết công việc.' });
  }
};

exports.update = async (req, res) => {
  try {
    const taskId = req.params.id;
    const { title, description, startDate, dueDate, priority, status } = req.body;

    if (isMongoConnected()) {
      const task = await Task.findById(taskId);
      if (!task) {
        return res.status(404).json({ message: 'Không tìm thấy công việc.' });
      }
      if (task.createdBy.toString() !== req.userId) {
        return res.status(403).json({ message: 'Chỉ người tạo mới có quyền chỉnh sửa công việc này.' });
      }

      if (title !== undefined) task.title = title.trim();
      if (description !== undefined) task.description = description;
      if (startDate !== undefined) task.startDate = startDate ? new Date(startDate) : null;
      if (dueDate !== undefined) task.dueDate = dueDate ? new Date(dueDate) : null;
      if (priority !== undefined) task.priority = priority;
      if (status !== undefined) task.status = status;

      if (!task.title || !task.title.trim()) {
        return res.status(400).json({ message: 'Tên công việc không được để trống.' });
      }
      if (task.startDate && task.dueDate && new Date(task.dueDate) < new Date(task.startDate)) {
        return res.status(400).json({ message: 'Hạn hoàn thành không được trước ngày bắt đầu.' });
      }

      await task.save();
      const updatedTask = await Task.findById(task._id).populate('createdBy', 'fullName email');
      return res.json({ message: 'Cập nhật công việc thành công.', task: updatedTask });
    } else {
      const task = MemoryStore.tasks.find(t => t._id === taskId);
      if (!task) {
        return res.status(404).json({ message: 'Không tìm thấy công việc.' });
      }
      const creatorId = task.createdBy?._id?.toString() || task.createdBy?.toString();
      if (creatorId !== req.userId) {
        return res.status(403).json({ message: 'Chỉ người tạo mới có quyền chỉnh sửa công việc này.' });
      }

      if (title !== undefined) task.title = title.trim();
      if (description !== undefined) task.description = description;
      if (startDate !== undefined) task.startDate = startDate ? new Date(startDate) : null;
      if (dueDate !== undefined) task.dueDate = dueDate ? new Date(dueDate) : null;
      if (priority !== undefined) task.priority = priority;
      if (status !== undefined) task.status = status;
      task.updatedAt = new Date();

      const creator = MemoryStore.users.find(u => u._id === creatorId);
      const populated = {
        ...task,
        createdBy: creator ? { _id: creator._id, fullName: creator.fullName, email: creator.email } : null,
      };
      return res.json({ message: 'Cập nhật công việc thành công.', task: populated });
    }
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server khi cập nhật công việc.' });
  }
};

exports.remove = async (req, res) => {
  try {
    const taskId = req.params.id;
    if (isMongoConnected()) {
      const task = await Task.findById(taskId);
      if (!task) {
        return res.status(404).json({ message: 'Không tìm thấy công việc.' });
      }
      if (task.createdBy.toString() !== req.userId) {
        return res.status(403).json({ message: 'Chỉ người tạo mới được quyền xóa công việc.' });
      }
      await task.deleteOne();
      return res.json({ message: 'Xóa công việc thành công.' });
    } else {
      const index = MemoryStore.tasks.findIndex(t => t._id === taskId);
      if (index === -1) {
        return res.status(404).json({ message: 'Không tìm thấy công việc.' });
      }
      const task = MemoryStore.tasks[index];
      const creatorId = task.createdBy?._id?.toString() || task.createdBy?.toString();
      if (creatorId !== req.userId) {
        return res.status(403).json({ message: 'Chỉ người tạo mới được quyền xóa công việc.' });
      }
      MemoryStore.tasks.splice(index, 1);
      return res.json({ message: 'Xóa công việc thành công.' });
    }
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server khi xóa công việc.' });
  }
};

exports.updateStatus = async (req, res) => {
  try {
    const taskId = req.params.id;
    const { status } = req.body;
    if (!['todo', 'in_progress', 'completed'].includes(status)) {
      return res.status(400).json({ message: 'Trạng thái công việc không hợp lệ.' });
    }

    if (isMongoConnected()) {
      const task = await Task.findById(taskId);
      if (!task) {
        return res.status(404).json({ message: 'Không tìm thấy công việc.' });
      }
      if (!canAccess(task, req.userId)) {
        return res.status(403).json({ message: 'Bạn không có quyền cập nhật công việc này.' });
      }
      task.status = status;
      await task.save();
      return res.json({ message: 'Cập nhật trạng thái thành công.', task });
    } else {
      const task = MemoryStore.tasks.find(t => t._id === taskId);
      if (!task) {
        return res.status(404).json({ message: 'Không tìm thấy công việc.' });
      }
      if (!canAccess(task, req.userId)) {
        return res.status(403).json({ message: 'Bạn không có quyền cập nhật công việc này.' });
      }
      task.status = status;
      task.updatedAt = new Date();
      return res.json({ message: 'Cập nhật trạng thái thành công.', task });
    }
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server khi cập nhật trạng thái.' });
  }
};
