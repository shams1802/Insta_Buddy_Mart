import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import '../models/chat_message_model.dart';

class Conversation {
  final String orderId;
  final String requesterId;
  final String requesterName;
  final String runnerId;
  final String runnerName;
  final List<String> orderItems;
  final double totalAmount;
  final List<ChatMessage> messages;
  String deliveryStatus; // accepted, shopping, on_the_way, delivered
  bool paymentSent;
  int rating;

  Conversation({
    required this.orderId,
    required this.requesterId,
    required this.requesterName,
    required this.runnerId,
    required this.runnerName,
    required this.orderItems,
    required this.totalAmount,
    List<ChatMessage>? messages,
    this.deliveryStatus = 'accepted',
    this.paymentSent = false,
    this.rating = 0,
  }) : messages = messages ?? [
          ChatMessage(
            id: 'sys_1',
            text: 'Order accepted! You can coordinate pickup and delivery here.',
            sender: 'system',
            type: 'system',
            timestamp: DateTime.now().toIso8601String(),
          ),
        ];

  String titleFor(String myUserId) {
    if (myUserId == requesterId) {
      return runnerName.isNotEmpty ? runnerName : 'Runner';
    }
    return requesterName;
  }
}

class ChatProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  IO.Socket? _socket;

  final Map<String, Conversation> _conversations = {};

  List<dynamic> _rooms = [];
  List<dynamic> _apiMessages = [];
  String? _activeRoomId;

  Map<String, Conversation> get conversations => _conversations;
  List<Conversation> get conversationList => _conversations.values.toList();
  List<dynamic> get rooms => _rooms;
  List<dynamic> get apiMessages => _apiMessages;
  String? get activeRoomId => _activeRoomId;

  void addDemoConversation({
    required String orderId,
    required String requesterId,
    required String requesterName,
    required String runnerId,
    required String runnerName,
    required List<String> items,
    required double totalAmount,
  }) {
    if (_conversations.containsKey(orderId)) return;
    _conversations[orderId] = Conversation(
      orderId: orderId,
      requesterId: requesterId,
      requesterName: requesterName,
      runnerId: runnerId,
      runnerName: runnerName,
      orderItems: items,
      totalAmount: totalAmount,
    );
    notifyListeners();
  }

  void sendChatMessage(String orderId, String text, String sender) {
    final conv = _conversations[orderId];
    if (conv != null && text.trim().isNotEmpty) {
      conv.messages.add(ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: text.trim(),
        sender: sender,
        timestamp: DateTime.now().toIso8601String(),
      ));
      notifyListeners();
    }
  }

  void updateDeliveryStatus(String orderId, String status) {
    final conv = _conversations[orderId];
    if (conv != null) {
      conv.deliveryStatus = status;
      conv.messages.add(ChatMessage(
        id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
        text: 'Delivery update: $status',
        sender: 'system',
        type: 'system',
        timestamp: DateTime.now().toIso8601String(),
      ));
      notifyListeners();
    }
  }

  void markPaymentSent(String orderId) {
    final conv = _conversations[orderId];
    if (conv != null && !conv.paymentSent) {
      conv.paymentSent = true;
      conv.messages.add(ChatMessage(
        id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
        text: 'Payment marked as sent.',
        sender: 'system',
        type: 'payment',
        timestamp: DateTime.now().toIso8601String(),
      ));
      notifyListeners();
    }
  }

  void markDeliveryCompleted(String orderId) {
    updateDeliveryStatus(orderId, 'delivered');
  }

  void setRating(String orderId, int rating) {
    final conv = _conversations[orderId];
    if (conv != null) {
      conv.rating = rating;
      conv.messages.add(ChatMessage(
        id: 'rate_${DateTime.now().millisecondsSinceEpoch}',
        text: 'Thanks! You rated this delivery $rating★',
        sender: 'system',
        type: 'system',
        timestamp: DateTime.now().toIso8601String(),
      ));
      notifyListeners();
    }
  }

  void addImagePlaceholder(String orderId, String sender) {
    final conv = _conversations[orderId];
    if (conv == null) return;
    conv.messages.add(ChatMessage(
      id: 'img_${DateTime.now().millisecondsSinceEpoch}',
      text: '📷 Shared an image (demo)',
      sender: sender,
      type: 'image',
      timestamp: DateTime.now().toIso8601String(),
    ));
    notifyListeners();
  }

  void connectSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token == 'demo_token') return;

    _socket = IO.io('http://10.0.2.2:3001', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token},
    });

    _socket!.connect();
    _socket!.onConnect((_) => debugPrint('Connected to chat socket'));
    _socket!.on('new_message', (data) {
      if (_activeRoomId != null && data['room_id'] == _activeRoomId) {
        _apiMessages.insert(0, data);
        notifyListeners();
      }
      fetchRooms();
    });
    _socket!.onDisconnect((_) => debugPrint('Disconnected from chat socket'));
  }

  void disconnectSocket() {
    _socket?.disconnect();
    _socket = null;
  }

  Future<void> fetchRooms() async {
    try {
      final res = await _apiClient.getRequest('/chat/rooms');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _rooms = data['data'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching rooms: $e');
    }
  }

  Future<void> openRoom(String roomId) async {
    _activeRoomId = roomId;
    _apiMessages = [];
    notifyListeners();
    _socket?.emit('join_room', {'roomId': roomId});
    try {
      final res = await _apiClient.getRequest('/chat/rooms/$roomId/messages');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _apiMessages = data['data']['messages'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    }
  }

  void closeRoom() {
    _activeRoomId = null;
    _apiMessages = [];
    notifyListeners();
  }

  void sendSocketMessage(String content) {
    if (_activeRoomId == null || _socket == null) return;
    if (content.trim().isEmpty) return;
    _socket!.emit('send_message', {
      'roomId': _activeRoomId,
      'content': content.trim(),
      'type': 'text',
    });
  }

  void addMessage(String orderId, String text) {
    sendChatMessage(orderId, text, 'me');
  }

  Conversation? getConversation(String id) {
    return _conversations[id];
  }
}
