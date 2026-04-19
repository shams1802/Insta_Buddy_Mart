import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/order_model.dart';
import '../services/auth_provider.dart';
import '../services/order_provider.dart';
import '../services/chat_provider.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  Future<void> _accept(BuildContext context, Order o) async {
    final auth = context.read<AuthProvider>();
    final orderProv = context.read<OrderProvider>();
    final chatProv = context.read<ChatProvider>();
    
    // Check if user is a runner
    if (!auth.isRunner) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only runners can accept orders. Please complete KYC to become a runner.'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Check if KYC is completed
    if (!auth.kycCompleted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KYC verification is required to accept orders.'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final runnerId = auth.userProfile?['id'] as String? ?? 'u_self';
    final runnerName = auth.userName;

    orderProv.acceptOrder(o.id, runnerId, runnerName);
    chatProv.addDemoConversation(
      orderId: o.id,
      requesterId: o.requesterId,
      requesterName: o.requesterName,
      runnerId: runnerId,
      runnerName: runnerName,
      items: o.items,
      totalAmount: o.totalAmount,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You accepted order ${o.id}. Open the Chat tab to message.'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orders = context.watch<OrderProvider>();
    final myId = auth.userProfile?['id'] as String? ?? 'u_${auth.userEmail.hashCode.abs()}';

    final myOrders = orders.ordersForRequester(myId);
    final nearby = orders.openOrdersExcluding(myId);
    final active = orders.activeForRunner(myId);

    // Tabs configuration based on user role
    final isRunner = auth.isRunner;
    final tabCount = isRunner ? 3 : 1;
    final tabs = isRunner
        ? const [
            Tab(text: 'My Orders'),
            Tab(text: 'Nearby'),
            Tab(text: 'Active'),
          ]
        : const [
            Tab(text: 'My Orders'),
          ];

    return DefaultTabController(
      length: tabCount,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          title: const Text('Orders'),
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: tabs,
          ),
        ),
        body: isRunner
            ? TabBarView(
                children: [
                  _OrderList(orders: myOrders, mode: _OrderListMode.my),
                  _OrderList(orders: nearby, mode: _OrderListMode.nearby, onAccept: (o) => _accept(context, o)),
                  _OrderList(orders: active, mode: _OrderListMode.active),
                ],
              )
            : _OrderList(orders: myOrders, mode: _OrderListMode.my),
      ),
    );
  }
}

enum _OrderListMode { my, nearby, active }

class _OrderList extends StatelessWidget {
  final List<Order> orders;
  final _OrderListMode mode;
  final void Function(Order)? onAccept;

  const _OrderList({required this.orders, required this.mode, this.onAccept});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            mode == _OrderListMode.my
                ? 'No orders yet.\nCheckout from Home to post a public order for runners.'
                : mode == _OrderListMode.nearby
                    ? 'No nearby public orders right now.'
                    : 'No active deliveries.\nAccept a nearby order to see it here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65), height: 1.4),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final o = orders[i];
        return _OrderTile(
          order: o,
          showAccept: mode == _OrderListMode.nearby,
          onAccept: onAccept == null ? null : () => onAccept!(o),
        );
      },
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Order order;
  final bool showAccept;
  final VoidCallback? onAccept;

  const _OrderTile({required this.order, required this.showAccept, this.onAccept});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppTheme.surfaceCard : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);
    final onCard = scheme.onSurface;

    Color statusColor;
    switch (order.status) {
      case 'OPEN':
        statusColor = AppTheme.warningColor;
        break;
      case 'ACCEPTED':
      case 'DELIVERED':
        statusColor = AppTheme.primaryColor;
        break;
      case 'COMPLETED':
        statusColor = AppTheme.successColor;
        break;
      default:
        statusColor = scheme.onSurface.withValues(alpha: 0.5);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '#${order.id}',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: onCard),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(order.requesterName, style: TextStyle(fontWeight: FontWeight.w600, color: onCard)),
          const SizedBox(height: 4),
          Text(
            '${order.distanceKm.toStringAsFixed(1)} km · ${order.locality}',
            style: TextStyle(fontSize: 12, color: onCard.withValues(alpha: 0.55)),
          ),
          const SizedBox(height: 10),
          ...order.items.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: onCard.withValues(alpha: 0.45), fontSize: 12)),
                  Expanded(child: Text(line, style: TextStyle(fontSize: 13, color: onCard))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '₹${order.estimatedCost.toStringAsFixed(0)} + ₹${order.deliveryFee.toStringAsFixed(0)} delivery',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.successColor),
              ),
              const Spacer(),
              Text(
                'Total ₹${order.totalAmount.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: onCard),
              ),
            ],
          ),
          if (showAccept && onAccept != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onAccept,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Accept order'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
