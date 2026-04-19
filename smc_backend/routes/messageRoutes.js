const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const { sendMessage, allMessages, deleteMessage, markAsRead } = require('../controllers/messageController');

const router = express.Router();

router.route('/').post(protect, sendMessage);
router.route('/:chatId').get(protect, allMessages);
router.route('/delete').post(protect, deleteMessage);
router.route('/markAsRead').post(protect, markAsRead);

module.exports = router;
