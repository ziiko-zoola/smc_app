import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';
import 'dart:convert';
import 'dart:typed_data';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _phone = '';
  String? _base64Pic;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('userName') ?? 'No Name';
      _phone = prefs.getString('userPhone') ?? 'No Phone';
      _base64Pic = prefs.getString('userPic');
    });
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF192A45),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.cyanAccent),
                title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                }
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.cyanAccent),
                title: const Text('Take a Photo', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      }
    );
  }

  void _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      final bytes = await image.readAsBytes();
      String base64Image = base64Encode(bytes);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userPic', base64Image);
      setState(() {
         _base64Pic = base64Image;
      });
      try {
        await ApiService.updateProfilePic(base64Image);
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Photo Updated Everywhere!')));
      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved locally, but failed to sync globally: $e')));
      }
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
              title: const Text('My Profile'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   CircleAvatar(
                     radius: 60,
                     backgroundColor: Colors.cyanAccent,
                     backgroundImage: _base64Pic != null && _base64Pic!.isNotEmpty
                         ? MemoryImage(base64Decode(_base64Pic!.contains(',') ? _base64Pic!.split(',')[1] : _base64Pic!))
                         : null,
                     child: (_base64Pic == null || _base64Pic!.isEmpty) 
                         ? Text(_name.isNotEmpty ? _name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 40, color: Color(0xFF192A45), fontWeight: FontWeight.bold))
                         : null,
                   ),
                   const SizedBox(height: 20),
                   const Text('Name', style: TextStyle(color: Colors.white54, fontSize: 14)),
                   Text(_name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 20),
                   const Text('Phone Number', style: TextStyle(color: Colors.white54, fontSize: 14)),
                   Text(_phone, style: const TextStyle(color: Colors.white, fontSize: 18)),
                   const SizedBox(height: 40),
                   ElevatedButton.icon(
                     style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF135B6D)),
                     onPressed: _showImagePickerOptions,
                     icon: const Icon(Icons.image, color: Colors.white),
                     label: const Text('Set New Avatar', style: TextStyle(color: Colors.white)),
                   )
                ]
              )
            )
          )
        )
      )
    );
  }
}
