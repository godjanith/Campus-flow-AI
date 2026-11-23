import 'package:socket_io_client/socket_io_client.dart' as sio;
import '../config/app_config.dart';
import '../models/ticket.dart';

class SocketService {
  static SocketService? _instance;
  late sio.Socket _socket;
  bool _isConnected = false;

  SocketService._internal() {
    _socket = sio.io(
      AppConfig.socketUrl,
      sio.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1000)
          .build(),
    );

    _socket.onConnect((_) {
      _isConnected = true;
    });

    _socket.onDisconnect((_) {
      _isConnected = false;
    });
  }

  factory SocketService() {
    _instance ??= SocketService._internal();
    return _instance!;
  }

  bool get isConnected => _isConnected;

  void joinStudentRoom(String regNo) {
    _socket.emit('join:student', regNo);
  }

  void onTicketCreated(void Function(Ticket) callback) {
    _socket.off('ticket:created');
    _socket.on('ticket:created', (data) {
      if (data is Map) {
        callback(Ticket.fromJson(Map<String, dynamic>.from(data)));
      }
    });
  }

  void onTicketUpdated(void Function(Ticket) callback) {
    _socket.off('ticket:updated');
    _socket.on('ticket:updated', (data) {
      if (data is Map) {
        callback(Ticket.fromJson(Map<String, dynamic>.from(data)));
      }
    });
  }

  void onTicketDeleted(void Function(String) callback) {
    _socket.off('ticket:deleted');
    _socket.on('ticket:deleted', (data) {
      callback(data.toString());
    });
  }

  void dispose() {
    _socket.dispose();
    _instance = null;
  }
}
