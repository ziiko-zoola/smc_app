const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const seedUser = require('./seed');

dotenv.config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
  }
});

// Middleware
app.use(cors());
app.use(express.json({limit: '50mb'}));
app.use(express.urlencoded({limit: '50mb', extended: true}));

async function connectDB() {
  const mongoUri = process.env.MONGODB_URI;
  
  try {
    console.log('⏳ Attempting to connect to Local MongoDB...');
    // Connect with a short timeout to detect if service is down
    await mongoose.connect(mongoUri, { 
      serverSelectionTimeoutMS: 3000,
      connectTimeoutMS: 3000
    });
    console.log(`✅ Connected to External MongoDB: ${mongoUri}`);
  } catch (error) {
    console.log('⚠️ Local MongoDB Service not found. Starting Internal Database fallback...');
    try {
      const { MongoMemoryServer } = require('mongodb-memory-server');
      const mongoServer = await MongoMemoryServer.create({
        instance: {
          dbPath: './db_data',
          storageEngine: 'wiredTiger',
          port: 27017,
        }
      });
      const fallbackUri = mongoServer.getUri();
      await mongoose.connect(fallbackUri);
      console.log('✅ Connected to Internal Persistent Database (db_data)');
    } catch (fallbackError) {
      console.error('❌ Critical: Failed to start both Local and Internal Database:', fallbackError);
      process.exit(1);
    }
  }

  // Start Server regardless of which DB connected
  try {
    await seedUser(); 
    const PORT = process.env.PORT || 5000;
    server.listen(PORT, '0.0.0.0', () => {
      console.log(`🚀 SMC Backend running on port ${PORT}`);
    });
  } catch (err) {
    console.error('❌ Server startup error:', err);
  }
}
connectDB();

// Routes
const authRoutes = require('./routes/authRoutes');
const chatRoutes = require('./routes/chatRoutes');
const messageRoutes = require('./routes/messageRoutes');
const userRoutes = require('./routes/userRoutes');

app.use('/api/auth', authRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/message', messageRoutes);
app.use('/api/user', userRoutes);

const User = require('./models/User');
const Message = require('./models/Message');
app.put('/api/user/profilepic', async (req, res) => {
   try {
      const { userId, pic } = req.body;
      const updatedUser = await User.findByIdAndUpdate(userId, { pic }, { new: true });
      res.json(updatedUser);
   } catch(e) {
      res.status(400).json({error: e.message});
   }
});

app.get('/', (req, res) => {
  res.send('SMC Family Backend is running');
});

const onlineUsers = new Map();

// Socket.io for Real-time chat & WebRTC signaling
io.on('connection', (socket) => {
  console.log('A user connected:', socket.id);

  socket.on('setup', (userData) => {
    socket.join(userData._id);
    onlineUsers.set(userData._id, socket.id);
    socket.emit('connected');
  });

  socket.on('join_chat', (room) => {
    socket.join(room);
    console.log(`User joined room: ${room}`);
  });

  socket.on('new_message', async (newMessageReceived) => {
    var chat = newMessageReceived.chat;
    if (!chat.users) return console.log('Chat users not defined');

    for (const user of chat.users) {
      if (user._id == newMessageReceived.sender._id) continue;
      
      // Mark as delivered if user is online
      if (onlineUsers.has(user._id)) {
        await Message.findByIdAndUpdate(newMessageReceived._id, { status: 'delivered' });
        newMessageReceived.status = 'delivered';
        // Notify the sender that the message was delivered
        io.to(newMessageReceived.sender._id).emit('status_updated', { 
           messageId: newMessageReceived._id, 
           status: 'delivered', 
           chatId: chat._id 
        });
      }
      
      io.to(user._id).emit('message_received', newMessageReceived);
    }
  });

  socket.on('message_read', async (data) => {
     // data: { messageId, senderId, chatId }
     try {
        await Message.findByIdAndUpdate(data.messageId, { status: 'read' });
        // Notify the sender that the message was read
        io.to(data.senderId).emit('status_updated', { 
           messageId: data.messageId, 
           status: 'read', 
           chatId: data.chatId 
        });
     } catch (e) {
        console.error('Error on message_read:', e);
     }
  });

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
    // Remove from onlineUsers
    for (let [userId, socketId] of onlineUsers.entries()) {
      if (socketId === socket.id) {
        onlineUsers.delete(userId);
        break;
      }
    }
  });
});

// Process is managed by auto-DB startup
