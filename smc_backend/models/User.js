const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: { type: String, default: '' },
  phone: { type: String, required: true, unique: true },
  password: { type: String },
  pic: { type: String, default: '' },
  otp: { type: String },
  otpExpires: { type: Date },
  isOnline: { type: Boolean, default: false },
  blockedUsers: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  nicknames: { type: Map, of: String, default: {} }
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
