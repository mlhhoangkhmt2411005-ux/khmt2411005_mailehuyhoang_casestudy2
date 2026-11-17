const express = require('express');
const router = express.Router();
const { getTaskStats, getDeadlineStats } = require('../controllers/statisticsController');
const authMiddleware = require('../middleware/authMiddleware');

router.use(authMiddleware);

router.get('/tasks', getTaskStats);
router.get('/deadlines', getDeadlineStats);

module.exports = router;
