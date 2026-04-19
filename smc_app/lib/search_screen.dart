import 'package:flutter/material.dart';
import 'api_service.dart';
import 'main.dart'; 
import 'dart:convert';
import 'dart:typed_data';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _users = [];
  bool _isLoading = false;

  void _search() async {
    setState(() => _isLoading = true);
    try {
      final results = await ApiService.searchUsers(_searchController.text);
      if (mounted) setState(() => _users = results);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startChat(String userId, String name, String? pic) async {
    try {
      final chatInfo = await ApiService.accessChat(userId);
      if (mounted) {
         Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(name: name, isOnline: true, chatId: chatInfo['_id'], pic: pic))).then((_) => _search());
      }
    } catch(e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF192A45)),
      child: Center(
        child: Container(
           width: 500,
           decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF33205B), Color(0xFF135B6D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: const Color(0xFF0C162D).withOpacity(0.8),
              title: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Search by name or number...', hintStyle: TextStyle(color: Colors.white54), border: InputBorder.none),
                onSubmitted: (_) => _search(),
              ),
              actions: [
                IconButton(icon: const Icon(Icons.search), onPressed: _search),
              ],
            ),
            body: _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : _users.isEmpty 
                    ? const Center(child: Text("No users found", style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF135B6D),
                              backgroundImage: user['pic'] != null && user['pic'].toString().startsWith('data:image') 
                                  ? MemoryImage(base64Decode(user['pic'].toString().split(',')[1])) 
                                  : null,
                              child: (user['pic'] == null || !user['pic'].toString().startsWith('data:image')) 
                                  ? Text(user['name'][0].toUpperCase(), style: const TextStyle(color: Colors.white))
                                  : null,
                            ),
                            title: Text(user['name'], style: const TextStyle(color: Colors.white)),
                            subtitle: Text(user['phone'] ?? ''),
                            onTap: () => _startChat(user['_id'], user['name'], user['pic']),
                          );
                        },
                      ),
          )
        )
      )
    );
  }
}
