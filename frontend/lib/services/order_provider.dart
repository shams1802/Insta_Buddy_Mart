import 'package:flutter/material.dart';
import '../models/order_model.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _allOrders = [];
  List<Order> get allOrders => List.unmodifiable(_allOrders);

  OrderProvider() {
    _initializeMockOrders();
  }

  void _initializeMockOrders() {
    final now = DateTime.now();
    _allOrders = [
      Order(
        id: 'PUB_GROCERY',
        requesterId: 'u_demo_1',
        requesterName: 'Neha Kulkarni',
        category: 'Grocery',
        items: ['Milk 2L', 'Bread', 'Eggs', 'Sugar 1kg'],
        description: 'Weekly grocery run — store nearby.',
        estimatedCost: 450,
        deliveryFee: 35,
        locality: 'Sector 18, Noida',
        status: 'OPEN',
        createdAt: now.subtract(const Duration(minutes: 8)),
        distanceKm: 0.9,
      ),
      Order(
        id: 'PUB_BOOKS',
        requesterId: 'u_demo_2',
        requesterName: 'Arjun Mehta',
        category: 'Books',
        items: ['NCERT set', 'Notebook bundle'],
        description: 'School books from stationery lane.',
        estimatedCost: 300,
        deliveryFee: 25,
        locality: 'Sector 62, Noida',
        status: 'OPEN',
        createdAt: now.subtract(const Duration(minutes: 18)),
        distanceKm: 1.4,
      ),
      Order(
        id: 'PUB_FOOD',
        requesterId: 'u_demo_3',
        requesterName: 'Sana Khan',
        category: 'Food',
        items: ['Biryani half', 'Raita', 'Sprite 600ml'],
        description: 'Hot food — quick pickup.',
        estimatedCost: 220,
        deliveryFee: 30,
        locality: 'Indirapuram, Ghaziabad',
        status: 'OPEN',
        createdAt: now.subtract(const Duration(minutes: 4)),
        distanceKm: 2.1,
      ),
      Order(
        id: 'PUB_MED',
        requesterId: 'u_demo_4',
        requesterName: 'Ravi Iyer',
        category: 'Medicine',
        items: ['Paracetamol strip', 'ORS', 'Bandages'],
        description: 'Pharmacy essentials.',
        estimatedCost: 560,
        deliveryFee: 40,
        locality: 'Vaishali, Ghaziabad',
        status: 'OPEN',
        createdAt: now.subtract(const Duration(minutes: 26)),
        distanceKm: 1.1,
      ),
      Order(
        id: 'PUB_WATCH',
        requesterId: 'u_demo_5',
        requesterName: 'Karan Malhotra',
        category: 'Watch',
        items: ['Strap + battery replacement kit'],
        description: 'Watch repair shop pickup.',
        estimatedCost: 899,
        deliveryFee: 50,
        locality: 'Connaught Place, Delhi',
        status: 'OPEN',
        createdAt: now.subtract(const Duration(minutes: 40)),
        distanceKm: 3.2,
      ),
    ];
    notifyListeners();
  }

  void createOrder(Order order) {
    _allOrders.insert(0, order);
    notifyListeners();
  }

  void acceptOrder(String orderId, String runnerId, String runnerName) {
    final i = _allOrders.indexWhere((o) => o.id == orderId);
    if (i == -1) return;
    final o = _allOrders[i];
    _allOrders[i] = Order(
      id: o.id,
      requesterId: o.requesterId,
      requesterName: o.requesterName,
      runnerId: runnerId,
      runnerName: runnerName,
      items: o.items,
      description: o.description,
      estimatedCost: o.estimatedCost,
      deliveryFee: o.deliveryFee,
      category: o.category,
      locality: o.locality,
      status: 'ACCEPTED',
      createdAt: o.createdAt,
      finalAmount: o.finalAmount,
      rating: o.rating,
      chatHistory: o.chatHistory,
      distanceKm: o.distanceKm,
    );
    notifyListeners();
  }

  void completeOrder(String orderId, double finalAmount, double rating) {
    final i = _allOrders.indexWhere((o) => o.id == orderId);
    if (i == -1) return;
    final o = _allOrders[i];
    _allOrders[i] = Order(
      id: o.id,
      requesterId: o.requesterId,
      requesterName: o.requesterName,
      runnerId: o.runnerId,
      runnerName: o.runnerName,
      items: o.items,
      description: o.description,
      estimatedCost: o.estimatedCost,
      deliveryFee: o.deliveryFee,
      category: o.category,
      locality: o.locality,
      status: 'COMPLETED',
      createdAt: o.createdAt,
      finalAmount: finalAmount,
      rating: rating,
      chatHistory: o.chatHistory,
      distanceKm: o.distanceKm,
    );
    notifyListeners();
  }

  List<Order> ordersForRequester(String requesterId) {
    return _allOrders.where((o) => o.requesterId == requesterId).toList();
  }

  List<Order> ordersForRunner(String runnerId) {
    return _allOrders.where((o) => o.runnerId == runnerId).toList();
  }

  List<Order> openOrdersExcluding(String requesterId) {
    return _allOrders.where((o) => o.status == 'OPEN' && o.requesterId != requesterId).toList();
  }

  List<Order> activeForRunner(String runnerId) {
    return _allOrders.where((o) => o.runnerId == runnerId && (o.status == 'ACCEPTED' || o.status == 'DELIVERED')).toList();
  }

  Order? _currentOrder;
  Order? get currentOrder => _currentOrder;

  void setCurrentOrder(Order? order) {
    _currentOrder = order;
    notifyListeners();
  }

  void markAsDelivered(String orderId) {
    final i = _allOrders.indexWhere((o) => o.id == orderId);
    if (i == -1) return;
    final o = _allOrders[i];
    _allOrders[i] = Order(
      id: o.id,
      requesterId: o.requesterId,
      requesterName: o.requesterName,
      runnerId: o.runnerId,
      runnerName: o.runnerName,
      items: o.items,
      description: o.description,
      estimatedCost: o.estimatedCost,
      deliveryFee: o.deliveryFee,
      category: o.category,
      locality: o.locality,
      status: 'DELIVERED',
      createdAt: o.createdAt,
      finalAmount: o.finalAmount,
      rating: o.rating,
      chatHistory: o.chatHistory,
      distanceKm: o.distanceKm,
    );
    notifyListeners();
  }
}
