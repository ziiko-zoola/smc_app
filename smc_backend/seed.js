const mongoose = require('mongoose');
const User = require('./models/User');
const bcrypt = require('bcrypt');
const dotenv = require('dotenv');
dotenv.config();

async function seedUser() {
    try {
        const password = await bcrypt.hash('123456', 10);
        const phone = '611318633';
        
        const existing = await User.findOne({ phone });
        if (existing) {
            console.log('User already exists');
        } else {
            await User.create({
                name: 'Test Partner',
                phone: phone,
                password: password,
                pic: ''
            });
            console.log('User 611318633 created successfully');
        }
    } catch (e) {
        console.error('Seeding error:', e);
    }
}

module.exports = seedUser;
