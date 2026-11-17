const router = require('express').Router();
const auth = require('../middleware/auth');
const controller = require('../controllers/authController');

router.post('/register', controller.register);
router.post('/login', controller.login);
router.get('/me', auth, controller.me);
router.put('/me', auth, controller.updateMe);
router.put('/change-password', auth, controller.changePassword);

module.exports = router;
