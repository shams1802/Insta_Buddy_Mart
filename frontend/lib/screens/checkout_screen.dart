import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/cart_provider.dart';
import '../services/order_provider.dart';
import '../services/auth_provider.dart';
import '../models/order_model.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'upi';
  bool _paid = false;

  final _payMethods = [
    {'id': 'upi', 'label': 'UPI / GPay', 'icon': Icons.phone_android},
    {'id': 'card', 'label': 'Credit / Debit Card', 'icon': Icons.credit_card},
    {'id': 'wallet', 'label': 'Wallet Balance', 'icon': Icons.account_balance_wallet},
    {'id': 'cod', 'label': 'Cash on Delivery', 'icon': Icons.money},
  ];

  void _handlePay(CartProvider cart) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('₹${cart.total.round()} paid successfully!'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    setState(() => _paid = true);
  }

  void _handleSendOrder(CartProvider cart) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final orderProv = Provider.of<OrderProvider>(context, listen: false);

    final newOrder = Order(
      id: 'ORD_${DateTime.now().millisecondsSinceEpoch}',
      requesterId: auth.userProfile?['id'] ?? 'u_self',
      requesterName: auth.userName,
      category: cart.items.first.product.category,
      items: cart.items.map((i) => '${i.product.name} × ${i.quantity}').toList(),
      description: 'Order from ${auth.userName}',
      estimatedCost: cart.subtotal,
      deliveryFee: cart.deliveryFee,
      locality: auth.userLocation,
      status: 'OPEN',
      createdAt: DateTime.now(),
    );

    orderProv.createOrder(newOrder);
    cart.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Order posted! Nearby runners can see it now.'),
        backgroundColor: AppTheme.successColor,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    if (cart.isEmpty && !_paid) {
      return Scaffold(
        backgroundColor: AppTheme.surfaceDark,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🛒', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              const Text('Cart is Empty', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              const Text('Add some products to get started', style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Start Shopping', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          // ── Items ──
          _sectionCard('Selected Items', [
            ...cart.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(item.product.image, width: 48, height: 48, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(width: 48, height: 48, color: AppTheme.surfaceLight, child: const Icon(Icons.image, size: 20, color: AppTheme.textSecondary))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                        Text('₹${item.product.price.toInt()}', style: const TextStyle(fontSize: 12, color: AppTheme.successColor, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  // Quantity controls
                  Container(
                    decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        _qtyBtn(Icons.remove, () => cart.updateQuantity(item.product.id, item.quantity - 1)),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('${item.quantity}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700))),
                        _qtyBtn(Icons.add, () => cart.updateQuantity(item.product.id, item.quantity + 1)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => cart.removeFromCart(item.product.id),
                    child: const Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 20),
                  ),
                ],
              ),
            )),
          ]),
          const SizedBox(height: 12),

          // ── Price Details ──
          _sectionCard('Price Details', [
            _priceRow('Subtotal', '₹${cart.subtotal.round()}'),
            _priceRow('Delivery Fee', '₹${cart.deliveryFee.round()}'),
            _priceRow('Taxes (5%)', '₹${cart.tax.round()}'),
            const Divider(color: AppTheme.surfaceLight, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                Text('₹${cart.total.round()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.successColor)),
              ],
            ),
          ]),
          const SizedBox(height: 12),

          // ── Payment Method ──
          _sectionCard('Payment Method', [
            ..._payMethods.map((pm) {
              final active = _paymentMethod == pm['id'];
              return GestureDetector(
                onTap: () => setState(() => _paymentMethod = pm['id'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: active ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                    border: Border.all(color: active ? AppTheme.primaryColor : Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      Icon(pm['icon'] as IconData, color: active ? AppTheme.primaryColor : AppTheme.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(pm['label'] as String, style: TextStyle(color: AppTheme.textPrimary, fontWeight: active ? FontWeight.w600 : FontWeight.w400, fontSize: 14))),
                      Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: active ? AppTheme.primaryColor : AppTheme.textSecondary, width: 2),
                        ),
                        child: active ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryColor))) : null,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ]),
          const SizedBox(height: 18),

          // ── Action ──
          if (!_paid)
            _actionButton('💰 Pay ₹${cart.total.round()}', AppTheme.primaryGradient, () => _handlePay(cart))
          else
            _actionButton('📦 Send Order to Runners', AppTheme.successGradient, () => _handleSendOrder(cart)),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: AppTheme.primaryColor, size: 16),
      ),
    );
  }

  Widget _actionButton(String label, LinearGradient gradient, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: gradient.colors.first.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
