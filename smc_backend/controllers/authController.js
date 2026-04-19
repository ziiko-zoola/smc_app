const User = require('../models/User');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET || 'smc_super_secret', { expiresIn: '30d' });
};

const requestOTP = async (req, res) => {
  try {
    const { phone } = req.body;
    if (!phone) return res.status(400).json({ error: 'Phone is required' });

    let user = await User.findOne({ phone });
    if (!user) {
      user = await User.create({ phone });
    }

    // SIMULATED OTP: Always 1234 for testing purposes as per implementation plan
    const otp = '1234'; 
    user.otp = otp;
    user.otpExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 mins
    await user.save();

    console.log(`📱 OTP for ${phone}: ${otp}`);
    res.json({ message: 'OTP sent successfully', otp: otp }); // Returning OTP for simulation
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const verifyOTP = async (req, res) => {
  try {
    const { phone, otp, name } = req.body;
    if (!phone || !otp) return res.status(400).json({ error: 'Phone and OTP are required' });

    const user = await User.findOne({ phone, otp });

    if (!user || user.otpExpires < new Date()) {
      return res.status(400).json({ error: 'Invalid or expired OTP' });
    }

    // Clean up OTP
    user.otp = undefined;
    user.otpExpires = undefined;
    
    // If name is provided (for new users), save it
    if (name) user.name = name;
    await user.save();

    res.json({
      _id: user._id,
      name: user.name,
      phone: user.phone,
      pic: user.pic,
      nicknames: user.nicknames || {},
      token: generateToken(user._id)
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = { requestOTP, verifyOTP };
