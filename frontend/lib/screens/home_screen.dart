import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_provider.dart';
import '../services/cart_provider.dart';
import '../models/product_model.dart';
import '../data/demo_data.dart';
import '../widgets/custom_cards.dart';
import 'create_custom_order_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedCatId;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    var list = allProducts;
    if (_selectedCatId != null) {
      list = list.where((p) => p.category == _selectedCatId).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) {
        final disp = categoryDisplayName(p.category).toLowerCase();
        return p.name.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            disp.contains(q);
      }).toList();
    }
    return list;
  }

  void _openNotifications() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.local_offer, color: AppTheme.primaryColor),
              title: const Text('Weekend delivery promo', style: TextStyle(color: AppTheme.textPrimary)),
              subtitle: Text('Extra ₹20 off on first order', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.9))),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delivery_dining, color: AppTheme.successColor),
              title: const Text('Runner nearby', style: TextStyle(color: AppTheme.textPrimary)),
              subtitle: Text('Avg pickup time ~18 min', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.9))),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final firstName = auth.userName.split(' ').first;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppTheme.primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(gradient: AppTheme.primaryGradientReverse),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hello, $firstName 👋',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 14, color: Colors.white70),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            auth.userLocation,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _openNotifications,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Stack(
                                      children: [
                                        const Center(child: Icon(Icons.notifications_outlined, color: Colors.white, size: 22)),
                                        Positioned(
                                          right: 6,
                                          top: 6,
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration: const BoxDecoration(color: AppTheme.errorColor, shape: BoxShape.circle),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _searchQuery = v),
                            decoration: InputDecoration(
                              hintText: 'Search milk, books, medicine…',
                              hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                              prefixIcon: const Icon(Icons.search, color: Colors.white30, size: 18),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                      icon: const Icon(Icons.close, color: Colors.white30, size: 18),
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            style: const TextStyle(fontSize: 13, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Categories', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _catChip('All', null),
                            ...categoriesData.map((c) => _catChip(c['name'] as String, c['id'] as String)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
                sliver: _filteredProducts.isEmpty
                    ? SliverToBoxAdapter(
                        child: SizedBox(
                          height: 220,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 50, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                                const SizedBox(height: 10),
                                const Text(
                                  'No products found',
                                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedCatId = null;
                                      _searchCtrl.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                  child: const Text('Clear filters'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.58,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 14,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, idx) {
                            final prod = _filteredProducts[idx];
                            final qty = cart.getQuantity(prod.id);
                            return ProductCard(
                              image: prod.image,
                              name: prod.name,
                              price: prod.price,
                              category: categoryDisplayName(prod.category),
                              quantity: qty,
                              onQuantityChange: (newQty) {
                                if (newQty <= 0) {
                                  cart.removeProduct(prod.id);
                                } else {
                                  cart.updateQuantity(prod.id, newQty);
                                }
                                setState(() {});
                              },
                              onAddCart: () {
                                cart.addProduct(prod, 1);
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${prod.name} added to cart'),
                                    backgroundColor: AppTheme.successColor,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            );
                          },
                          childCount: _filteredProducts.length,
                        ),
                      ),
              ),
            ],
          ),
          if (cart.items.isNotEmpty)
            Positioned(
              right: 18,
              bottom: 22,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${cart.itemCount} item${cart.itemCount > 1 ? 's' : ''}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const CreateCustomOrderScreen())),
        backgroundColor: AppTheme.primaryColor,
        elevation: 8,
        child: Icon(cart.items.isEmpty ? Icons.add : Icons.shopping_cart, size: 30, color: Colors.white),
      ),
    );
  }

  Widget _catChip(String label, String? id) {
    final selected = id == null ? _selectedCatId == null : _selectedCatId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedCatId = id),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: selected ? AppTheme.primaryGradient : null,
              color: selected ? null : AppTheme.surfaceLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: selected ? null : Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
