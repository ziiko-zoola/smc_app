import 'package:flutter/material.dart';
import 'dart:ui';
import 'login_screen.dart';
import 'socket_service.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'api_service.dart';
import 'create_group_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

void main() {
  runApp(const SMCApplication());
}

class SMCApplication extends StatelessWidget {
  const SMCApplication({super.key});

  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMC Family Messenger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: FutureBuilder<bool>(
        future: _isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)));
          }
          if (snapshot.data == true) {
            return const MainScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  List<dynamic> _chats = [];
  Map<String, dynamic> _nicknames = {};
  bool _isLoading = true;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    SocketService.connectAndListen();
    _fetchChats();
    _loadUserIdAndNicknames();
    
    // Real-time updates for chat list
    SocketService.socket.on('status_updated', _onStatusUpdated);
    SocketService.socket.on('message_received', (_) {
       if (mounted) _fetchChats();
    });
    // Also refresh when I send a message (so my own chat list updates)
    SocketService.socket.on('message_sent_by_me', (_) {
       if (mounted) _fetchChats();
    });
  }

  void _onStatusUpdated(dynamic data) {
    if (mounted) {
       setState(() {
          for (var chat in _chats) {
             if (chat['_id'] == data['chatId'] && chat['latestMessage'] != null && chat['latestMessage']['_id'] == data['messageId']) {
                chat['latestMessage']['status'] = data['status'];
             }
          }
       });
    }
  }

  void _loadUserIdAndNicknames() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _myUserId = prefs.getString('userId');
        String nicknameStr = prefs.getString('nicknames') ?? '{}';
        _nicknames = jsonDecode(nicknameStr);
      });
    }
  }

  void _showEditProfileDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final nameCtrl = TextEditingController(text: prefs.getString('userName') ?? '');
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF192A45),
        title: const Text('Edit My Name', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'New Name', hintStyle: TextStyle(color: Colors.white54)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService.updateProfile(nameCtrl.text); 
                if (ctx.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name updated!')));
                   Navigator.pop(ctx);
                   _fetchChats(); 
                }
              } catch(e) {
                if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Update'),
          )
        ],
      )
    );
  }

  void _fetchChats() async {
    try {
      final chats = await ApiService.getChats();
      debugPrint('FETCH_CHATS: Received ${chats.length} chats');
      if (mounted) {
        setState(() {
          _chats = chats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('FETCH_CHATS_ERROR: $e');
      if (e.toString().contains('401')) {
         // Auto Logout if token failed/expired due to server restart
         final prefs = await SharedPreferences.getInstance();
         await prefs.clear();
         if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false
            );
         }
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold containing the content
    Widget content = Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      drawer: Drawer(
        backgroundColor: const Color(0xFF192A45),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF33205B)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('S.M.C FAMILY', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('Developed by Ziiko', style: TextStyle(color: Colors.cyanAccent.withValues(alpha: 0.9), fontStyle: FontStyle.italic)),
                ]
              ),
            ),
            ListTile(
              leading: const Icon(Icons.group_add, color: Colors.white),
              title: const Text('New Group', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.white),
              title: const Text('Profile Settings', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.cyanAccent),
              title: const Text('Change My Name', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showEditProfileDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                 final prefs = await SharedPreferences.getInstance();
                 await prefs.clear();
                 Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            // Logo Area
            _buildLogoArea(),
            const SizedBox(height: 30),
            // Chat/Group List Container (Glassmorphic)
            Expanded(
              child: _buildListContainer(
                title: _currentIndex == 0 ? 'CHATS' : 'GROUPS',
                child: _isLoading 
                    ? const Center(child: Text("SMC", style: TextStyle(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.bold))) 
                    : (_currentIndex == 0 ? _buildChatList() : _buildGroupList()),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF0C162D).withValues(alpha: 0.95),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.cyanAccent,
          unselectedItemColor: Colors.white54,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              activeIcon: Icon(Icons.group),
              label: 'Groups',
            ),
          ],
        ),
      ),
    );

    // Apply the gradient and constrain the width for desktop/web so it looks exactly like a Mobile App!
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF192A45),
        image: DecorationImage(
          image: AssetImage('assets/background.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xD933205B), // 85% opacity Deep purple
              Color(0xD9192A45), // 85% opacity Deep blue
              Color(0xD9135B6D), // 85% opacity Teal/Cyan bottom right
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: Container(
            width: 500, // Max width constraint to give a mobile feel on large screens
            margin: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
              border: Border.all(color: Colors.white12),
              borderRadius: BorderRadius.circular(40),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/background.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xD933205B),
                        Color(0xD9192A45),
                        Color(0xD9135B6D),
                      ],
                    ),
                  ),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoArea() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text(
              'S',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -2),
            ),
            const SizedBox(width: 2),
            Stack(
              alignment: Alignment.center,
              children: [
                const Text('M', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                Positioned(top: 0, right: -5, child: Icon(Icons.wifi, color: Colors.white.withValues(alpha: 0.8), size: 20)),
              ],
            ),
            const SizedBox(width: 2),
            const Text('C', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'S.M.C FAMILY',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 1.5),
        ),
        const SizedBox(height: 4),
        Text(
          'Developed by Ziiko',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
            color: Colors.cyanAccent.withValues(alpha: 0.9),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildListContainer({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0C162D).withValues(alpha: 0.4),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        border: Border(
           top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
           left: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
           right: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () {
                            _scaffoldKey.currentState?.openDrawer();
                          }, 
                          child: Icon(Icons.menu, color: Colors.white.withValues(alpha: 0.7))
                        ),
                        Text(
                          title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 1.0),
                        ),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
                              }, 
                              child: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7))
                            ),
                            const SizedBox(width: 15),
                            InkWell(
                              onTap: () {
                                 Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                              },
                              child: const CircleAvatar(
                                radius: 14,
                                backgroundColor: Color(0xFF135B6D),
                                child: Icon(Icons.person, color: Colors.white, size: 18),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  backgroundColor: const Color(0xFF135B6D),
                  onPressed: () => _showAddOptionsBottomSheet(context),
                  child: const Icon(Icons.add_comment, color: Colors.white),
                )
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showAddOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF192A45),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.person_add, color: Colors.cyanAccent),
                title: const Text('Add New Contact', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showAddContactDialog(context);
                }
              ),
              ListTile(
                leading: const Icon(Icons.group_add, color: Colors.cyanAccent),
                title: const Text('Create New Group', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
                },
              ),
            ],
          ),
        );
      }
    );
  }

  void _showAddContactDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF192A45),
          title: const Text('Add New Contact', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Full Name', hintStyle: TextStyle(color: Colors.white54)),
              ),
              TextField(
                controller: phoneCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Phone Number', hintStyle: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
          actions: [
            TextButton(child: const Text('Cancel', style: TextStyle(color: Colors.white54)), onPressed: () => Navigator.pop(ctx)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF135B6D)),
              child: const Text('Add Contact', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                 if (phoneCtrl.text.trim().isEmpty) return;
                 try {
                   final users = await ApiService.searchUsers(phoneCtrl.text.trim());
                   final exactMatch = users.where((u) => u['phone'] == phoneCtrl.text.trim()).toList();
                   if (exactMatch.isEmpty) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                           content: Text('Lambarkan kuma samaysna App-kan (This number is not registered)')
                        ));
                      }
                   } else {
                      final addedUser = exactMatch.first;
                      final chatInfo = await ApiService.accessChat(addedUser['_id']);
                      if (ctx.mounted) {
                         Navigator.pop(ctx);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(
                           name: nameCtrl.text.isNotEmpty ? nameCtrl.text : addedUser['name'], 
                           isOnline: true, 
                           chatId: chatInfo['_id'],
                           pic: addedUser['pic'],
                           onMessageSent: _fetchChats,
                         ))).then((_) => _fetchChats());
                      }
                   }
                 } catch(e) {
                   if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                 }
              }
            )
          ]
        );
      }
    );
  }

    String _formatDateTime(String? timestamp) {
      if (timestamp == null) return '';
      try {
        final dt = DateTime.parse(timestamp).toLocal();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));
        final dateToCheck = DateTime(dt.year, dt.month, dt.day);

        if (dateToCheck == today) {
          return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
        } else if (dateToCheck == yesterday) {
          return "Yesterday";
        } else {
          return "${dt.day}/${dt.month}/${dt.year}";
        }
      } catch (e) {
        return '';
      }
    }

  Widget _buildChatList() {
    debugPrint('BUILD_CHAT_LIST: _chats count = ${_chats.length}');
    final directChats = _chats.where((c) => c['isGroupChat'] == false).toList();
    
    // Manual sorting
    directChats.sort((a, b) {
      final aDate = DateTime.tryParse(a['updatedAt'] ?? '') ?? DateTime(0);
      final bDate = DateTime.tryParse(b['updatedAt'] ?? '') ?? DateTime(0);
      return bDate.compareTo(aDate);
    });

    return RefreshIndicator(
      onRefresh: () async => _fetchChats(),
      child: directChats.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 80, color: Colors.white24),
                      SizedBox(height: 20),
                      Text('No Chats Yet. Start searching to chat!', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: directChats.length,
              itemBuilder: (context, index) {
                 final chat = directChats[index];
                 final users = chat['users'] as List<dynamic>;
                 final otherUser = users.firstWhere((u) => u['_id'] != _myUserId, orElse: () => users[0]);
                 final otherUserId = otherUser['_id'];
                 final displayName = _nicknames[otherUserId] ?? otherUser['name'] ?? 'Unknown';
                 
                 return _buildItem(
                    name: displayName, 
                    message: chat['latestMessage'] != null ? chat['latestMessage']['content'] : 'No messages yet', 
                    time: _formatDateTime(chat['updatedAt']), 
                    chatId: chat['_id'],
                    pic: otherUser['pic'],
                    isOnline: true,
                    phoneNumber: otherUser['phone'],
                    userId: otherUserId,
                    unreadCount: chat['unreadCount'] ?? 0
                 );
              }
            ),
    );
  }

  Widget _buildGroupList() {
    final groups = _chats.where((c) => c['isGroupChat'] == true).toList();
    if (groups.isEmpty) {
      return const Center(child: Text('No Groups Yet.', style: TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: groups.length,
      itemBuilder: (context, index) {
         final chat = groups[index];
         return _buildItem(
            name: chat['chatName'] ?? 'Unnamed Group', 
            message: chat['latestMessage'] != null ? chat['latestMessage']['content'] : '...', 
            time: 'Now', 
            chatId: chat['_id'],
            pic: chat['pic'],
            isGroup: true
         );
      }
    );
  }



  Widget _buildItem({
    required String name,
    required String message,
    required String time,
    required String chatId,
    String? pic,
    String? phoneNumber,
    String? userId,
    int unreadCount = 0,
    bool isOnline = false,
    bool isGroup = false,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatDetailScreen(
            name: name, 
            isOnline: isOnline, 
            isGroup: isGroup, 
            chatId: chatId, 
            pic: pic,
            phoneNumber: phoneNumber,
            userId: userId,
            onMessageSent: _fetchChats,
          )),
        ).then((_) => _fetchChats());
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: isGroup ? const Color(0xFF33205B) : const Color(0xFF135B6D),
                  backgroundImage: pic != null && pic.startsWith('data:image') 
                      ? MemoryImage(base64Decode(pic.split(',')[1])) 
                      : null,
                  child: (pic == null || !pic.startsWith('data:image')) 
                      ? (isGroup 
                          ? const Icon(Icons.group, color: Colors.white)
                          : Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)))
                      : null,
                ),
                if (isOnline && !isGroup)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF192A45), width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontSize: 16, fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.w500, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(fontSize: 13, color: unreadCount > 0 ? Colors.white.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.5)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: unreadCount > 0 ? Colors.white.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 6),
                if (unreadCount > 0)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(color: Colors.yellowAccent, shape: BoxShape.circle),
                  )
                else
                   const SizedBox(height: 12),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class ChatDetailScreen extends StatefulWidget {
  final String name;
  final bool isOnline;
  final bool isGroup;
  final String? chatId; 
  final String? pic; 
  final String? phoneNumber;
  final String? userId;
  final VoidCallback? onMessageSent;

  const ChatDetailScreen({
    super.key,
    required this.name,
    required this.isOnline,
    this.isGroup = false,
    this.chatId,
    this.pic,
    this.phoneNumber,
    this.userId,
    this.onMessageSent,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgController = TextEditingController();
  List<dynamic> _messages = [];
  bool _isLoading = false;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    if (widget.chatId != null) {
      _fetchMessages();
      _markRead();
      SocketService.socket.emit('setup', {'_id': _myUserId});
      SocketService.socket.emit('join_chat', widget.chatId);
      SocketService.socket.on('message_received', _onMessageReceived);
      SocketService.socket.on('status_updated', _onStatusUpdated);
    }
  }

  void _markRead() async {
     if (widget.chatId != null) {
        try {
           await ApiService.markAsRead(widget.chatId!);
        } catch(e) {}
     }
  }

  void _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _myUserId = prefs.getString('userId'));
  }

  @override
  void dispose() {
    SocketService.socket.off('message_received', _onMessageReceived);
    super.dispose();
  }

  void _onMessageReceived(dynamic newMessage) {
    if (mounted && newMessage['chat']['_id'] == widget.chatId) {
       setState(() {
          _messages.add(newMessage);
       });
       // Emit read receipt when message is received while chat is open
       SocketService.socket.emit('message_read', {
          'messageId': newMessage['_id'],
          'senderId': newMessage['sender']['_id'],
          'chatId': widget.chatId
       });
    }
  }

  void _onStatusUpdated(dynamic data) {
    if (mounted) {
       setState(() {
          for (var m in _messages) {
             if (m['_id'] == data['messageId']) {
                m['status'] = data['status'];
             }
          }
       });
    }
  }

  void _fetchMessages() async {
    setState(() => _isLoading = true);
    try {
      final msgs = await ApiService.getMessages(widget.chatId!);
      if (mounted) {
        setState(() => _messages = msgs);
        // Identify unread messages from other user and emit read receipts
        for (var m in msgs) {
           if (m['sender'] != null && _myUserId != null && m['sender']['_id'] != _myUserId && m['status'] != 'read') {
              SocketService.socket.emit('message_read', {
                 'messageId': m['_id'],
                 'senderId': m['sender']['_id'],
                 'chatId': widget.chatId
              });
           }
        }
      }
    } catch(e) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _sendMessage() {
     _sendMessageWithContent(_msgController.text);
     _msgController.clear();
  }

  void _sendMessageWithContent(String contentText) async {
    if (contentText.trim().isEmpty || widget.chatId == null) return;
    try {
      final msg = await ApiService.sendMessage(widget.chatId!, contentText);
      SocketService.socket.emit('new_message', msg);
      if (mounted) setState(() => _messages.add(msg));
      // Refresh the main chat list immediately so this chat appears at top
      widget.onMessageSent?.call();
    } catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send')));
    }
  }

  void _pickAndSendFile() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
        final bytes = await image.readAsBytes();
        String base64String = base64Encode(bytes);
        String filePrefix = 'data:image/png;base64,';
        _sendMessageWithContent(filePrefix + base64String);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF192A45)), 
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: const Color(0xFF0C162D).withValues(alpha: 0.8),
              elevation: 0,
              titleSpacing: 0,
              title: InkWell(
                onTap: () {
                   if (!widget.isGroup && widget.userId != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ContactInfoScreen(
                        name: widget.name,
                        phone: widget.phoneNumber ?? '',
                        pic: widget.pic,
                        userId: widget.userId!,
                      )));
                   }
                },
                child: Row(
                  children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: widget.isGroup ? const Color(0xFF33205B) : const Color(0xFF135B6D),
                        backgroundImage: widget.pic != null && widget.pic!.startsWith('data:image') 
                            ? MemoryImage(base64Decode(widget.pic!.split(',')[1])) 
                            : null,
                        child: (widget.pic == null || !widget.pic!.startsWith('data:image')) 
                            ? (widget.isGroup 
                                ? const Icon(Icons.group, color: Colors.white, size: 18)
                                : Text(widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))
                            : null,
                      ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.name, style: const TextStyle(fontSize: 16)),
                        if (!widget.isGroup)
                          Text(
                            widget.isOnline ? 'Online' : 'Offline',
                            style: TextStyle(fontSize: 12, color: widget.isOnline ? Colors.greenAccent : Colors.grey),
                          )
                        else 
                          Text('Group', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [

                IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: _isLoading ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)) : 
                  _messages.isEmpty ? const Center(child: Text('Say Hi!', style: TextStyle(color: Colors.white54))) :
                  ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                        final m = _messages[i];
                        bool isMe = false; 
                        if (m['sender'] != null && _myUserId != null && m['sender']['_id'] == _myUserId) {
                           isMe = true;
                        }
                        return _buildMessageBubble(
                          m['content'], 
                          isMe, 
                          senderName: widget.isGroup ? m['sender']['name'] : null,
                          status: m['status'] ?? 'sent'
                        );
                    }
                  ),
                ),
                _buildMessageInput(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, {String? senderName, String status = 'sent'}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
           color: isMe ? const Color(0xFF135B6D) : const Color(0xFF33205B),
           borderRadius: BorderRadius.circular(18).copyWith(
             bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(18),
             bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(2),
           ),
           boxShadow: [
             BoxShadow(color: Colors.black26, blurRadius: 4, offset: isMe ? const Offset(2, 2) : const Offset(-2, 2))
           ]
        ),
        child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           mainAxisSize: MainAxisSize.min,
           children: [
             if (senderName != null && !isMe)
                Padding(
                   padding: const EdgeInsets.only(bottom: 4),
                   child: Text(senderName, style: TextStyle(color: Colors.cyanAccent.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
             text.startsWith('data:image')
                 ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(base64Decode(text.split(',')[1]), width: 220, fit: BoxFit.cover))
                 : Text(text, style: const TextStyle(color: Colors.white, fontSize: 14.5)),
             const SizedBox(height: 4),
             if (isMe)
               Align(
                 alignment: Alignment.bottomRight,
                 child: _buildTicks(status),
               ),
           ]
        )
      )
    );
  }

  Widget _buildTicks(String status) {
    if (status == 'read') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.done_all, color: Colors.yellowAccent, size: 14),
          SizedBox(width: 1),
          Icon(Icons.done, color: Colors.yellowAccent, size: 14, weight: 900),
        ],
      );
    } else if (status == 'delivered') {
      return const Icon(Icons.done_all, color: Colors.black, size: 14);
    } else {
      return const Icon(Icons.done, color: Colors.yellowAccent, size: 14);
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF0C162D).withValues(alpha: 0.8),
      child: SafeArea(
        child: Row(
          children: [
            InkWell(
              onTap: _pickAndSendFile, 
              child: Icon(Icons.add, color: Colors.white.withValues(alpha: 0.7))
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: _msgController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FloatingActionButton(
              mini: true,
              backgroundColor: const Color(0xFF135B6D),
              onPressed: _sendMessage,
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class ContactInfoScreen extends StatefulWidget {
  final String name;
  final String phone;
  final String? pic;
  final String userId;

  const ContactInfoScreen({
    super.key,
    required this.name,
    required this.phone,
    this.pic,
    required this.userId,
  });

  @override
  State<ContactInfoScreen> createState() => _ContactInfoScreenState();
}

class _ContactInfoScreenState extends State<ContactInfoScreen> {
  late TextEditingController _nameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
  }

  void _updateNickname() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.updateNickname(widget.userId, _nameController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name updated successfully!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF192A45)),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: const Color(0xFF0C162D).withValues(alpha: 0.8),
              title: const Text('Contact Info'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: const Color(0xFF135B6D),
                    backgroundImage: widget.pic != null && widget.pic!.startsWith('data:image') 
                        ? MemoryImage(base64Decode(widget.pic!.split(',')[1])) 
                        : null,
                    child: (widget.pic == null || !widget.pic!.startsWith('data:image')) 
                        ? Text(widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 40, color: Colors.white))
                        : null,
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: 'Display Name',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(widget.phone, style: const TextStyle(color: Colors.white54, fontSize: 16)),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text('Update Name', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF135B6D), padding: const EdgeInsets.symmetric(vertical: 15)),
                      onPressed: _isLoading ? null : _updateNickname,
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
