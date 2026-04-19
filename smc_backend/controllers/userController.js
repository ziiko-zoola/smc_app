const User = require('../models/User');

const allUsers = async (req, res) => {
  const keyword = req.query.search ? {
    $or: [
      { name: { $regex: req.query.search, $options: "i" } },
      { phone: { $regex: req.query.search, $options: "i" } },
    ]
  } : {};

  const users = await User.find(keyword).select('-password');
  console.log(`🔍 Search for "${req.query.search}" returned ${users.length} results`);
  res.send(users);
};

const updateProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if(user) {
      user.name = req.body.name || user.name;
      user.avatar = req.body.avatar || user.avatar;
      
      const updatedUser = await user.save();
      res.json({
        _id: updatedUser._id,
        name: updatedUser.name,
        phone: updatedUser.phone,
        avatar: updatedUser.avatar,
      });
    } else {
      res.status(404).send('User not found');
    }
  } catch (error) {
     res.status(400).send(error.message);
  }
};

const updateNickname = async (req, res) => {
  try {
    const { contactId, nickname } = req.body;
    const user = await User.findById(req.user._id);
    if (!user.nicknames) user.nicknames = new Map();
    user.nicknames.set(contactId, nickname);
    await user.save();
    res.json({ message: 'Nickname updated successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const toggleBlock = async (req, res) => {
  try {
    const { contactId } = req.body;
    const user = await User.findById(req.user._id);
    const index = user.blockedUsers.indexOf(contactId);
    if (index > -1) {
      user.blockedUsers.splice(index, 1);
      res.json({ message: 'User unblocked', isBlocked: false });
    } else {
      user.blockedUsers.push(contactId);
      res.json({ message: 'User blocked', isBlocked: true });
    }
    await user.save();
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = { allUsers, updateProfile, updateNickname, toggleBlock };
