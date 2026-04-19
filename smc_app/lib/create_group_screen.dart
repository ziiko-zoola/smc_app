import 'package:flutter/material.dart';
import 'api_service.dart';
import 'main.dart'; 

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  List<dynamic> _users = [];
  final List<String> _selectedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void _fetchUsers() async {
    try {
      final results = await ApiService.searchUsers(''); 
      if(mounted) {
        setState(() {
          _users = results;
          _isLoading = false;
        });
      }
    } catch(e) {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  void _createGroup() async {
    if (_groupNameController.text.isEmpty || _selectedUsers.length < 2) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter group name and select at least 2 users!')));
       return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiService.createGroupChat(_groupNameController.text, _selectedUsers);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group Created Successfully!')));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
      }
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF192A45)),
      child: Center(
        child: SizedBox(
          width: 500,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: const Color(0xFF0C162D).withOpacity(0.8),
              title: const Text('Create New Group'),
              actions: [
                 IconButton(icon: const Icon(Icons.check), onPressed: _createGroup)
              ]
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    controller: _groupNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Type Group Name...',
                      hintStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    ),
                  )
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Align(alignment: Alignment.centerLeft, child: Text('Select Members to Add', style: TextStyle(color: Colors.cyanAccent.withOpacity(0.9), fontWeight: FontWeight.bold))),
                ),
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator()) 
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          final isSelected = _selectedUsers.contains(user['_id']);
                          return ListTile(
                            leading: CircleAvatar(
                               backgroundColor: const Color(0xFF135B6D),
                               child: Text(user['name'][0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                            ),
                            title: Text(user['name'], style: const TextStyle(color: Colors.white)),
                            subtitle: Text(user['phone'] ?? '', style: const TextStyle(color: Colors.white54)),
                            trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.cyanAccent) : const Icon(Icons.circle_outlined, color: Colors.white54),
                            onTap: () {
                               if (mounted) {
                                 setState(() {
                                    if (isSelected) {
                                        _selectedUsers.remove(user['_id']);
                                    } else {
                                        _selectedUsers.add(user['_id']);
                                    }
                                 });
                               }
                            }
                          );
                        }
                    )
                )
              ]
            )
          )
        )
      )
    );
  }
}
