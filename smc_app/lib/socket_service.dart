import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class SocketService {
  static late IO.Socket socket;

  static String get serverUrl {
    String url = Uri.base.origin;
    if (url == 'null' || url.isEmpty || url.contains('localhost') || url.contains('127.0.0.1')) {
      return 'http://192.168.100.134:5000';
    }
    return url;
  }

  static Future<void> connectAndListen() async {
    socket = IO.io(serverUrl, IO.OptionBuilder()
      .setTransports(['polling', 'websocket']) // Must have polling for web browser
      .disableAutoConnect()
      .setReconnectionAttempts(5)
      .setReconnectionDelay(2000)
      .build());

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
      
    socket.connect();
    
    socket.onConnect((_) {
      // Immediately register this user with the server so messages can reach them
      if (userId.isNotEmpty) {
        socket.emit('setup', {'_id': userId});
      }
    });

    socket.onDisconnect((_) {
      // Auto re-register on reconnect
      socket.onConnect((_) {
        if (userId.isNotEmpty) {
          socket.emit('setup', {'_id': userId});
        }
      });
    });
  }

  static void setupUser(String userId) {
    if (userId.isNotEmpty && socket.connected) {
      socket.emit('setup', {'_id': userId});
    }
  }

  static void dispose() {
    socket.disconnect();
  }
}
