const mongoose = require('mongoose');
const Chat = require('../models/Chat');
const Message = require('../models/Message');

const accessChat = async (req, res) => {
  const { userId } = req.body;
  if (!userId) return res.status(400).send('UserId param not sent in request');
  if (!req.user) return res.status(401).send('Not authorized');

  const myId = new mongoose.Types.ObjectId(req.user._id);
  const otherId = new mongoose.Types.ObjectId(userId);

  let isChat = await Chat.find({
    isGroupChat: false,
    users: { $all: [myId, otherId] }
  }).populate('users', '-password').populate('latestMessage');

  if (isChat.length > 0) {
    res.send(isChat[0]);
  } else {
    var chatData = {
      chatName: 'sender',
      isGroupChat: false,
      users: [req.user._id, userId],
    };

    try {
      const createdChat = await Chat.create(chatData);
      const FullChat = await Chat.findOne({ _id: createdChat._id }).populate('users', '-password');
      res.status(200).json(FullChat);
    } catch (error) {
      res.status(400).send(error.message);
    }
  }
};

const fetchChats = async (req, res) => {
  if (!req.user) return res.status(401).send('Not authorized');
  try {
    console.log('FETCH_CHATS: Finding chats for user:', req.user._id);
    const results = await Chat.find({ users: req.user._id })
      .populate('users', '-password')
      .populate('groupAdmin', '-password')
      .populate({
        path: 'latestMessage',
        populate: {
          path: 'sender',
          select: 'name pic phone',
        }
      })
    const resultsWithUnread = await Promise.all(results.map(async (chat) => {
      const unreadCount = await Message.countDocuments({
        chat: chat._id,
        sender: { $ne: req.user._id },
        status: { $ne: 'read' },
      });
      return { ...chat._doc, unreadCount };
    }));

    res.status(200).send(resultsWithUnread);
  } catch (error) {
    console.error('FETCH_CHATS_ERROR:', error.message);
    res.status(400).send(error.message);
  }
};

const createGroupChat = async (req, res) => {
  if (!req.body.users || !req.body.name) {
    return res.status(400).send({ message: 'Please Fill all the fields' });
  }

  var users = JSON.parse(req.body.users);
  if (users.length < 2) {
    return res.status(400).send('More than 2 users are required to form a group chat');
  }

  users.push(req.user);

  try {
    const groupChat = await Chat.create({
      chatName: req.body.name,
      users: users,
      isGroupChat: true,
      groupAdmin: req.user,
    });

    const fullGroupChat = await Chat.findOne({ _id: groupChat._id })
      .populate('users', '-password')
      .populate('groupAdmin', '-password');

    res.status(200).json(fullGroupChat);
  } catch (error) {
    res.status(400).send(error.message);
  }
};

module.exports = { accessChat, fetchChats, createGroupChat };
