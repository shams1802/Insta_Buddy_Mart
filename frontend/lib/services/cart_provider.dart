import 'package:flutter/material.dart';
import '../models/product_model.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  final double _deliveryFee = 30.0;
  final double _taxRate = 0.05;

  List<CartItem> get items => _items;
  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);
  bool get isEmpty => _items.isEmpty;

  double get subtotal => _items.fold(0, (sum, i) => sum + i.subtotal);
  double get tax => subtotal * _taxRate;
  double get deliveryFee => _items.isNotEmpty ? _deliveryFee : 0;
  double get total => subtotal + tax + deliveryFee;

  void addToCart(Product product, {int quantity = 1}) {
    final q = quantity < 1 ? 1 : quantity;
    final existing = _items.indexWhere((i) => i.product.id == product.id);
    if (existing != -1) {
      _items[existing].quantity += q;
    } else {
      _items.add(CartItem(product: product, quantity: q));
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _items.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    final idx = _items.indexWhere((i) => i.product.id == productId);
    if (idx != -1) {
      if (quantity <= 0) {
        _items.removeAt(idx);
      } else {
        _items[idx].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  void addProduct(Product product, int qty) {
    addToCart(product, quantity: qty);
  }

  void removeProduct(String productId) {
    removeFromCart(productId);
  }

  int getQuantity(String productId) {
    try {
      return _items.firstWhere((i) => i.product.id == productId).quantity;
    } catch (e) {
      return 0;
    }
  }
}
