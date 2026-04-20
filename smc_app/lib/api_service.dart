import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static String get baseUrl {
    // For Flutter Web, Uri.base.origin gets the current domain (e.g., cloudflare link)
    // This removes the need to update the code whenever the tunnel link changes.
    String url = Uri.base.origin;
    if (url == 'null' || url.isEmpty || url.contains('localhost') || url.contains('127.0.0.1')) {
      // Fallback for local development
      return 'http://192.168.100.134:5000/api'; 
    }
    return '$url/api';
  }

  
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> requestOTP(String phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/request-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(jsonDecode(response.body)['error'] ?? 'OTP Request failed');
  }

  static Future<dynamic> verifyOTP(String phone, String otp, {String? name}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'otp': otp, 'name': name}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('userId', data['_id']);
      await prefs.setString('userName', data['name'] ?? '');
      await prefs.setString('userPhone', data['phone']);
      await prefs.setString('userPic', data['pic'] ?? '');
      await prefs.setString('nicknames', jsonEncode(data['nicknames'] ?? {}));
      return data;
    }
    throw Exception(jsonDecode(response.body)['error'] ?? 'Verification failed');
  }

  static Future<List<dynamic>> searchUsers(String search) async {
    final response = await http.get(Uri.parse('$baseUrl/user?search=$search'), headers: await _getHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error ${response.statusCode}: ${jsonDecode(response.body)['error'] ?? 'Search failed'}');
  }

  static Future<dynamic> updateProfilePic(String base64Image) async {
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString('userId') ?? '';
    final response = await http.put(
      Uri.parse('$baseUrl/user/profilepic'),
      headers: await _getHeaders(),
      body: jsonEncode({'userId': userId, 'pic': 'data:image/jpeg;base64,' + base64Image}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error ${response.statusCode}: Failed to update picture');
  }

  static Future<dynamic> accessChat(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: await _getHeaders(),
      body: jsonEncode({'userId': userId}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error ${response.statusCode}: Failed to access chat');
  }

  static Future<dynamic> createGroupChat(String name, List<String> userIds) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/group'),
      headers: await _getHeaders(),
      body: jsonEncode({'name': name, 'users': jsonEncode(userIds)}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error ${response.statusCode}: Failed to create group');
  }

  static Future<List<dynamic>> getChats() async {
    final response = await http.get(Uri.parse('$baseUrl/chat'), headers: await _getHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error ${response.statusCode}: Failed to load chats');
  }

  static Future<List<dynamic>> getMessages(String chatId) async {
    final response = await http.get(Uri.parse('$baseUrl/message/$chatId'), headers: await _getHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error ${response.statusCode}: Failed to get messages');
  }

  static Future<dynamic> sendMessage(String chatId, String content) async {
    final response = await http.post(
      Uri.parse('$baseUrl/message'),
      headers: await _getHeaders(),
      body: jsonEncode({'chatId': chatId, 'content': content}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error ${response.statusCode}: Failed to send message');
  }

  static Future<dynamic> updateProfile(String name) async {
    final response = await http.put(
      Uri.parse('$baseUrl/user/profile'),
      headers: await _getHeaders(),
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', data['name'] ?? name);
      return data;
    }
    throw Exception('Error ${response.statusCode}: Failed to update profile');
  }

  static Future<dynamic> updateNickname(String contactId, String nickname) async {
    final response = await http.put(
      Uri.parse('$baseUrl/user/nickname'),
      headers: await _getHeaders(),
      body: jsonEncode({'contactId': contactId, 'nickname': nickname}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error ${response.statusCode}: Failed to update nickname');
  }

  static Future<dynamic> toggleBlock(String contactId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/user/block'),
      headers: await _getHeaders(),
      body: jsonEncode({'contactId': contactId}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error ${response.statusCode}: Failed to toggle block');
  }

  static Future<void> markAsRead(String chatId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/message/markAsRead'),
      headers: await _getHeaders(),
      body: jsonEncode({'chatId': chatId}),
    );
    if (response.statusCode != 200) throw Exception('Error ${response.statusCode}: Failed to mark as read');
  }
}
