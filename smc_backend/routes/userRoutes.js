const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const { allUsers, updateProfile, updateNickname, toggleBlock } = require('../controllers/userController');

const router = express.Router();
router.route('/').get(protect, allUsers);
router.route('/profile').put(protect, updateProfile);
router.route('/nickname').put(protect, updateNickname);
router.route('/block').put(protect, toggleBlock);

module.exports = router;
