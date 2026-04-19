import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/chat_provider.dart';
import '../services/auth_provider.dart';
import '../services/order_provider.dart';
import '../models/chat_message_model.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  String _selectedOrderId = '';

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  void _sendMessage(ChatProvider chat) {
    if (_msgCtrl.text.trim().isEmpty) return;
    chat.addMessage(_selectedOrderId, _msgCtrl.text.trim());
    _msgCtrl.clear();
  }

  Future<void> _rateAndComplete(BuildContext context, Conversation c, String myId) async {
    final chat = context.read<ChatProvider>();
    final orders = context.read<OrderProvider>();
    int stars = 5;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Rate this delivery'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('How was your experience with ${c.titleFor(myId)}?'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final idx = i + 1;
                      return IconButton(
                        onPressed: () => setLocal(() => stars = idx),
                        icon: Icon(idx <= stars ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 32),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Later')),
                FilledButton(
                  onPressed: () {
                    chat.setRating(c.orderId, stars);
                    orders.completeOrder(c.orderId, c.totalAmount, stars.toDouble());
                    Navigator.pop(ctx);
                    setState(() => _selectedOrderId = '');
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProv = context.watch<ChatProvider>();
    final auth = context.watch<AuthProvider>();
    final myId = auth.userProfile?['id'] as String? ?? 'u_${auth.userEmail.hashCode.abs()}';

    if (chatProv.conversations.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Chat')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 60, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25)),
                const SizedBox(height: 16),
                Text(
                  'No active chats',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Accept an order from the Nearby tab to open a runner ↔ requester chat.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55), height: 1.4),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_selectedOrderId.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Messages')),
        body: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          itemCount: chatProv.conversationList.length,
          itemBuilder: (context, idx) {
            final convo = chatProv.conversationList[idx];
            return _ConversationCard(
              conversation: convo,
              title: convo.titleFor(myId),
              onTap: () => setState(() => _selectedOrderId = convo.orderId),
            );
          },
        ),
      );
    }

    final convo = chatProv.getConversation(_selectedOrderId);
    if (convo == null) {
      return Scaffold(
        appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => setState(() => _selectedOrderId = ''))),
        body: const Center(child: Text('Conversation not found')),
      );
    }

    final itemsPreview = convo.orderItems.length > 2
        ? '${convo.orderItems.take(2).join(', ')} +${convo.orderItems.length - 2} more'
        : convo.orderItems.join(', ');
    final isRequester = myId == convo.requesterId;
    final isRunner = myId == convo.runnerId;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leadingWidth: 48,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => setState(() => _selectedOrderId = ''),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(convo.titleFor(myId), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(
              '$itemsPreview · ₹${convo.totalAmount.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (convo.paymentSent)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Chip(label: Text('Paid'), avatar: Icon(Icons.check_circle, size: 18)),
            ),
        ],
      ),
      body: Column(
        children: [
          _StatusStrip(
            status: convo.deliveryStatus,
            paymentSent: convo.paymentSent,
            isRequester: isRequester,
            isRunner: isRunner,
            onShopping: () => chatProv.updateDeliveryStatus(convo.orderId, 'shopping'),
            onWay: () => chatProv.updateDeliveryStatus(convo.orderId, 'on_the_way'),
            onDelivered: () {
              chatProv.markDeliveryCompleted(convo.orderId);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as delivered')));
            },
            onPay: () {
              chatProv.markPaymentSent(convo.orderId);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment marked as sent')));
            },
            onRate: () => _rateAndComplete(context, convo, myId),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: convo.messages.length,
              itemBuilder: (context, idx) {
                final msg = convo.messages[idx];
                return _MessageBubble(message: msg);
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.surfaceCard : Colors.white,
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.25))),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => chatProv.addImagePlaceholder(convo.orderId, 'me'),
                  icon: const Icon(Icons.image_outlined),
                  color: AppTheme.primaryColor,
                ),
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: const InputDecoration(
                      hintText: 'Type a message…',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(chatProv),
                  ),
                ),
                IconButton.filled(
                  onPressed: () => _sendMessage(chatProv),
                  icon: const Icon(Icons.send_rounded, size: 20),
                  style: IconButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  final String status;
  final bool paymentSent;
  final bool isRequester;
  final bool isRunner;
  final VoidCallback onShopping;
  final VoidCallback onWay;
  final VoidCallback onDelivered;
  final VoidCallback onPay;
  final VoidCallback onRate;

  const _StatusStrip({
    required this.status,
    required this.paymentSent,
    required this.isRequester,
    required this.isRunner,
    required this.onShopping,
    required this.onWay,
    required this.onDelivered,
    required this.onPay,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          if (isRequester && !paymentSent)
            ActionChip(label: const Text('Mark payment sent'), onPressed: onPay, avatar: const Icon(Icons.payments_outlined, size: 18)),
          if (isRunner)
            ActionChip(label: const Text('Shopping'), onPressed: onShopping, avatar: const Icon(Icons.shopping_bag_outlined, size: 18)),
          if (isRunner)
            ActionChip(label: const Text('On the way'), onPressed: onWay, avatar: const Icon(Icons.delivery_dining, size: 18)),
          if (isRunner)
            ActionChip(label: const Text('Delivered'), onPressed: onDelivered, avatar: const Icon(Icons.flag, size: 18)),
          if (isRequester && status == 'delivered')
            ActionChip(label: const Text('Rate & close'), onPressed: onRate, avatar: const Icon(Icons.star_outline, size: 18)),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isSystem = message.sender == 'system' || message.type != 'text';
    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75)),
            ),
          ),
        ),
      );
    }

    final isOwn = message.sender == 'me';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: isOwn ? AppTheme.primaryGradient : null,
            color: isOwn ? null : Theme.of(context).brightness == Brightness.dark ? AppTheme.surfaceCard : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: isOwn ? null : Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: TextStyle(fontSize: 14, color: isOwn ? Colors.white : Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                message.displayTime,
                style: TextStyle(fontSize: 11, color: isOwn ? Colors.white70 : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final Conversation conversation;
  final String title;
  final VoidCallback onTap;

  const _ConversationCard({required this.conversation, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceCard : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: Text(
                    title.isNotEmpty ? title[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      'Order #${conversation.orderId}',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${conversation.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
