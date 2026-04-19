class Order {
  final String id;
  final String requesterId;
  final String requesterName;
  final String? runnerId;
  final String? runnerName;
  final List<String> items;
  final String description;
  final double estimatedCost;
  final double deliveryFee;
  final String category;
  final String locality;
  final String status; // OPEN, ACCEPTED, COMPLETED, CANCELLED
  final DateTime createdAt;
  final double? finalAmount;
  final double? rating;
  final String? chatHistory;
  final double distanceKm;

  Order({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    this.runnerId,
    this.runnerName,
    required this.items,
    required this.description,
    required this.estimatedCost,
    required this.deliveryFee,
    required this.category,
    required this.locality,
    required this.status,
    required this.createdAt,
    this.finalAmount,
    this.rating,
    this.chatHistory,
    this.distanceKm = 1.2,
  });

  double get totalAmount => estimatedCost + deliveryFee;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      requesterId: json['requesterId'] as String,
      requesterName: json['requesterName'] as String,
      runnerId: json['runnerId'] as String?,
      runnerName: json['runnerName'] as String?,
      items: List<String>.from(json['items'] as List? ?? []),
      description: json['description'] as String,
      estimatedCost: (json['estimatedCost'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 30,
      category: json['category'] as String,
      locality: json['locality'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      finalAmount: (json['finalAmount'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      chatHistory: json['chatHistory'] as String?,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 1.2,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'requesterId': requesterId,
    'requesterName': requesterName,
    'runnerId': runnerId,
    'runnerName': runnerName,
    'items': items,
    'description': description,
    'estimatedCost': estimatedCost,
    'deliveryFee': deliveryFee,
    'category': category,
    'locality': locality,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'finalAmount': finalAmount,
    'rating': rating,
    'chatHistory': chatHistory,
    'distanceKm': distanceKm,
  };
}
