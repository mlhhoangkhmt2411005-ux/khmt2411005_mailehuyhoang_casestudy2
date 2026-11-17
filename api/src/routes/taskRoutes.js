const router = require('express').Router();
const auth = require('../middleware/auth');
const controller = require('../controllers/taskController');

router.use(auth);
router.get('/', controller.list);
router.post('/', controller.create);
router.get('/:id', controller.detail);
router.put('/:id', controller.update);
router.delete('/:id', controller.remove);
router.patch('/:id/status', controller.updateStatus);

module.exports = router;
