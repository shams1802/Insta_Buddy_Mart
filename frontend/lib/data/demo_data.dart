import 'package:flutter/material.dart';
import '../models/product_model.dart';

// ═══════════════════════════════════════════════════════════════════
//  Categories
// ═══════════════════════════════════════════════════════════════════
class CategoryItem {
  final String id;
  final String name;
  final IconData? iconData;
  final String emoji;
  final int colorValue;

  const CategoryItem({
    required this.id,
    required this.name,
    this.iconData,
    required this.emoji,
    required this.colorValue,
  });
}

// We use simple data lists here (no flutter import needed for the list itself)
String categoryDisplayName(String categoryId) {
  for (final c in categoriesData) {
    if (c['id'] == categoryId) return c['name'] as String;
  }
  if (categoryId.isEmpty) return categoryId;
  return '${categoryId[0].toUpperCase()}${categoryId.substring(1)}';
}

final List<Map<String, dynamic>> categoriesData = [
  {'id': 'grocery', 'name': 'Grocery', 'emoji': '🛒', 'color': 0xFF10B981},
  {'id': 'food', 'name': 'Food', 'emoji': '🍕', 'color': 0xFFEF4444},
  {'id': 'books', 'name': 'Books', 'emoji': '📚', 'color': 0xFF7C3AED},
  {'id': 'watch', 'name': 'Watch', 'emoji': '⌚', 'color': 0xFFF59E0B},
  {'id': 'bags', 'name': 'Bags', 'emoji': '👜', 'color': 0xFF06B6D4},
  {'id': 'purse', 'name': 'Purse', 'emoji': '👛', 'color': 0xFFA855F7},
  {'id': 'medicine', 'name': 'Medicine', 'emoji': '💊', 'color': 0xFF0EA5E9},
  {'id': 'electronics', 'name': 'Electronics', 'emoji': '📱', 'color': 0xFFFF6B35},
  {'id': 'clothes', 'name': 'Clothes', 'emoji': '👕', 'color': 0xFF8B5CF6},
];

// ═══════════════════════════════════════════════════════════════════
//  Products
// ═══════════════════════════════════════════════════════════════════
final List<Product> allProducts = [
  Product(id: 'p1', name: 'Fresh Organic Milk', price: 65, category: 'grocery', image: 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=300', rating: 4.5),
  Product(id: 'p2', name: 'Brown Bread Loaf', price: 45, category: 'grocery', image: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=300', rating: 4.3),
  Product(id: 'p3', name: 'Basmati Rice 5kg', price: 350, category: 'grocery', image: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=300', rating: 4.7),
  Product(id: 'p4', name: 'Farm Fresh Eggs', price: 90, category: 'grocery', image: 'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=300', rating: 4.4),
  Product(id: 'p5', name: 'Extra Virgin Olive Oil', price: 420, category: 'grocery', image: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=300', rating: 4.8),
  Product(id: 'p6', name: 'Margherita Pizza', price: 299, category: 'food', image: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=300', rating: 4.6),
  Product(id: 'p7', name: 'Chicken Biryani', price: 220, category: 'food', image: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=300', rating: 4.8),
  Product(id: 'p8', name: 'Veg Burger Combo', price: 180, category: 'food', image: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=300', rating: 4.2),
  Product(id: 'p9', name: 'Butter Naan Set', price: 120, category: 'food', image: 'https://images.unsplash.com/photo-1596560548464-f010549b84d7?w=300', rating: 4.5),
  Product(id: 'p10', name: 'Atomic Habits', price: 350, category: 'books', image: 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=300', rating: 4.9),
  Product(id: 'p11', name: 'Rich Dad Poor Dad', price: 280, category: 'books', image: 'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=300', rating: 4.7),
  Product(id: 'p12', name: 'The Alchemist', price: 199, category: 'books', image: 'https://images.unsplash.com/photo-1543002588-bfa74002ed7e?w=300', rating: 4.8),
  Product(id: 'p13', name: 'Classic Analog Watch', price: 1499, category: 'watch', image: 'https://images.unsplash.com/photo-1524592094714-0f0654e20314?w=300', rating: 4.4),
  Product(id: 'p14', name: 'Smart Fitness Band', price: 2499, category: 'watch', image: 'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?w=300', rating: 4.6),
  Product(id: 'p15', name: 'Leather Laptop Bag', price: 1899, category: 'bags', image: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=300', rating: 4.5),
  Product(id: 'p16', name: 'Travel Backpack', price: 1299, category: 'bags', image: 'https://images.unsplash.com/photo-1622560480605-d83c853bc5c3?w=300', rating: 4.3),
  Product(id: 'p17', name: 'Designer Clutch', price: 799, category: 'purse', image: 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=300', rating: 4.2),
  Product(id: 'p18', name: 'Leather Wallet', price: 599, category: 'purse', image: 'https://images.unsplash.com/photo-1627123424574-724758594e93?w=300', rating: 4.6),
  Product(id: 'p19', name: 'Vitamin C Tablets', price: 180, category: 'medicine', image: 'https://images.unsplash.com/photo-1584308666544-f26428f04a2d?w=300', rating: 4.7),
  Product(id: 'p20', name: 'First Aid Kit', price: 560, category: 'medicine', image: 'https://images.unsplash.com/photo-1603398938378-e54eab446dde?w=300', rating: 4.8),
  Product(id: 'p21', name: 'Wireless Earbuds', price: 1999, category: 'electronics', image: 'https://images.unsplash.com/photo-1590658268037-6bf12f032f55?w=300', rating: 4.5),
  Product(id: 'p22', name: 'Phone Charger 65W', price: 899, category: 'electronics', image: 'https://images.unsplash.com/photo-1583863788434-e58a36330cf0?w=300', rating: 4.3),
  Product(id: 'p23', name: 'Cotton T-Shirt', price: 499, category: 'clothes', image: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=300', rating: 4.4),
  Product(id: 'p24', name: 'Denim Jeans Slim', price: 1299, category: 'clothes', image: 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=300', rating: 4.6),
];

// ═══════════════════════════════════════════════════════════════════
//  Demo Users
// ═══════════════════════════════════════════════════════════════════
final List<DemoUser> demoUsers = [
  DemoUser(id: 'u1', name: 'Priya Sharma', avatar: '👩', phone: '+91 98765 43210', email: 'priya@example.com', location: 'Sector 15, Noida', rating: 4.8, isRunner: true, kycCompleted: true),
  DemoUser(id: 'u2', name: 'Rahul Verma', avatar: '👨', phone: '+91 87654 32109', email: 'rahul@example.com', location: 'Connaught Place, Delhi', rating: 4.5, isRunner: true, kycCompleted: true),
  DemoUser(id: 'u3', name: 'Anita Desai', avatar: '👩‍🦱', phone: '+91 76543 21098', email: 'anita@example.com', location: 'MG Road, Gurugram', rating: 4.9),
  DemoUser(id: 'u4', name: 'Vikram Singh', avatar: '🧔', phone: '+91 65432 10987', email: 'vikram@example.com', location: 'Sector 62, Noida', rating: 4.3, isRunner: true, kycCompleted: true),
  DemoUser(id: 'u5', name: 'Meera Patel', avatar: '👩‍🔬', phone: '+91 54321 09876', email: 'meera@example.com', location: 'Dwarka, Delhi', rating: 4.7),
];
