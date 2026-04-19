import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_provider.dart';
import '../services/order_provider.dart';
import '../services/cart_provider.dart';
import '../models/order_model.dart';

class CreateCustomOrderScreen extends StatefulWidget {
  const CreateCustomOrderScreen({super.key});

  @override
  State<CreateCustomOrderScreen> createState() => _CreateCustomOrderScreenState();
}

class _CreateCustomOrderScreenState extends State<CreateCustomOrderScreen> {
  final _storeName = TextEditingController();
  final _entries = <Map<String, String>>[];
  final _itemCtrl = TextEditingController();
  final _itemDescCtrl = TextEditingController();
  final _estimatedCostCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _seededFromCart = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seededFromCart) return;
    final cart = context.read<CartProvider>();
    if (cart.items.isNotEmpty) {
      _entries.addAll(
        cart.items
            .map(
              (c) => {
                'item': '${c.product.name} x${c.quantity}',
                'description': 'From cart',
              },
            )
            .toList(),
      );
      if (_estimatedCostCtrl.text.trim().isEmpty) {
        _estimatedCostCtrl.text = cart.subtotal.toStringAsFixed(0);
      }
    }
    _seededFromCart = true;
  }

  @override
  void dispose() {
    _storeName.dispose();
    _itemCtrl.dispose();
    _itemDescCtrl.dispose();
    _estimatedCostCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _addItem() {
    if (_itemCtrl.text.trim().isNotEmpty) {
      setState(() {
        _entries.add({
          'item': _itemCtrl.text.trim(),
          'description': _itemDescCtrl.text.trim(),
        });
        _itemCtrl.clear();
        _itemDescCtrl.clear();
      });
    }
  }

  void _removeItem(int index) {
    setState(() => _entries.removeAt(index));
  }

  void _submitOrder() {
    // Validation
    if (_entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_estimatedCostCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter estimated cost'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Create order
    final auth = context.read<AuthProvider>();
    final orders = context.read<OrderProvider>();
    final cart = context.read<CartProvider>();
    final manualEstimate = double.tryParse(_estimatedCostCtrl.text) ?? 0;
    final estimatedCost = manualEstimate > 0 ? manualEstimate : cart.subtotal;
    if (estimatedCost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter estimated cost or add items to cart'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final items = _entries.map((e) => e['item'] ?? '').where((e) => e.isNotEmpty).toList();
    final pairDescriptions = _entries
      .where((e) => (e['description'] ?? '').isNotEmpty)
      .map((e) => '${e['item']}: ${e['description']}')
      .join('\n');
    
    // Calculate delivery fee (minimum ₹30, ₹2 per km, but we'll use a demo flat fee)
    const deliveryFee = 50.0;
    final requesterId = auth.userProfile?['id'] as String? ?? 'u_${auth.userEmail.hashCode.abs()}';

    final newOrder = Order(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      requesterId: requesterId,
      requesterName: auth.userName,
      runnerId: null,
      runnerName: null,
      items: items,
      description: [pairDescriptions, _notesCtrl.text.trim()].where((e) => e.isNotEmpty).join('\n\n'),
      estimatedCost: estimatedCost,
      deliveryFee: deliveryFee,
      category: 'custom',
      locality: _storeName.text.trim().isEmpty ? 'Not specified' : _storeName.text.trim(),
      status: 'OPEN',
      createdAt: DateTime.now(),
      finalAmount: null,
      rating: null,
      chatHistory: null,
      distanceKm: 2.5, // Demo distance
    );

    orders.createOrder(newOrder);
    cart.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order created! Total: ₹${(estimatedCost * 1.15 + deliveryFee).toStringAsFixed(2)}'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Create Custom Order'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Items
            Text('Items to Buy', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Column(
              children: [
                TextField(
                  controller: _itemCtrl,
                  decoration: InputDecoration(
                    hintText: 'Item (e.g., Milk 1L, Bread)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _itemDescCtrl,
                        minLines: 3,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Description (brand, qty, notes)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _addItem,
                      style: FilledButton.styleFrom(padding: const EdgeInsets.all(12)),
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // List of items
            if (_entries.isNotEmpty) ...[
              ...List.generate(_entries.length, (idx) {
                final entry = _entries[idx];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? AppTheme.surfaceCard : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.shopping_cart, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry['item'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                              if ((entry['description'] ?? '').isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(entry['description']!, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => _removeItem(idx),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],

            // Estimated Cost
            Text('Estimated Cost (₹)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _estimatedCostCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'e.g., 500',
                prefixIcon: const Icon(Icons.currency_rupee),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // Notes
            Text('Additional Notes (Optional)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              minLines: 4,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'E.g., Brand preference, specific requirements',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // Store/Location Name (optional, at end)
            Text('Store or Location (Optional)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _storeName,
              decoration: InputDecoration(
                hintText: 'e.g., Reliance Smart, Local Medical Store',
                prefixIcon: const Icon(Icons.store),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),

            // Delivery Fee Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Delivery fee of ₹50 will be added to estimated cost',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitOrder,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Create Order'),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _entries.isEmpty ? _addItem : _submitOrder,
        backgroundColor: AppTheme.primaryColor,
        child: Icon(_entries.isEmpty ? Icons.add : Icons.shopping_cart_checkout, color: Colors.white),
      ),
    );
  }
}
