class ChatMessage {
  final String id;
  final String text;
  final String sender; // 'me', 'other', or 'system'
  final String type; // 'text', 'system', 'payment', 'status'
  final String? timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    this.type = 'text',
    this.timestamp,
  });

  String get displayTime {
    if (timestamp == null) return 'now';
    try {
      final dt = DateTime.parse(timestamp!);
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return 'now';
    }
  }
}

