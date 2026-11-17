const mongoose = require('mongoose');

const taskShareSchema = new mongoose.Schema({
  taskId: { type: mongoose.Schema.Types.ObjectId, ref: 'Task', required: true },
  sharedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  sharedWith: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  permission: { type: String, enum: ['viewer', 'editor'], default: 'viewer' },
}, { timestamps: true });

module.exports = mongoose.model('TaskShare', taskShareSchema);
