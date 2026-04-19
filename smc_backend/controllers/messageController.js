const Message = require('../models/Message');
const User = require('../models/User');
const Chat = require('../models/Chat');

const sendMessage = async (req, res) => {
  const { content, chatId } = req.body;
  if (!content || !chatId) return res.sendStatus(400);

  var newMessage = {
    sender: req.user._id,
    content: content,
    chat: chatId,
  };

  try {
    var message = await Message.create(newMessage);
    message = await message.populate('sender', 'name avatar');
    message = await message.populate('chat');
    message = await User.populate(message, { path: 'chat.users', select: 'name avatar phone' });

    await Chat.findByIdAndUpdate(req.body.chatId, { latestMessage: message });
    res.json(message);
  } catch (error) {
    res.status(400).send(error.message);
  }
};

const allMessages = async (req, res) => {
  try {
    // Exclude messages deleted for this specific user
    const messages = await Message.find({ 
      chat: req.params.chatId,
      deletedFor: { $ne: req.user._id } 
    })
      .populate('sender', 'name avatar phone')
      .populate('chat');
      
    res.json(messages);
  } catch (error) {
    res.status(400).send(error.message);
  }
};

const deleteMessage = async (req, res) => {
  const { messageId, type } = req.body; // type: 'forme' or 'foreveryone'
  
  try {
    const message = await Message.findById(messageId);
    if (!message) return res.status(404).send('Message not found');

    if (type === 'foreveryone') {
      if (message.sender.toString() !== req.user._id.toString()) {
        return res.status(403).send('You can only delete your own messages for everyone');
      }
      message.isDeletedForEveryone = true;
      message.content = "🚫 This message was deleted";
      await message.save();
    } else if (type === 'forme') {
      message.deletedFor.push(req.user._id);
      await message.save();
    }
    res.json({ success: true, message });
  } catch (error) {
    res.status(400).send(error.message);
  }
};

const markAsRead = async (req, res) => {
  const { chatId } = req.body;
  try {
    await Message.updateMany(
      { chat: chatId, sender: { $ne: req.user._id }, status: { $ne: 'read' } },
      { $set: { status: 'read' } }
    );
    res.json({ success: true });
  } catch (error) {
    res.status(400).send(error.message);
  }
};

module.exports = { allMessages, sendMessage, deleteMessage, markAsRead };
