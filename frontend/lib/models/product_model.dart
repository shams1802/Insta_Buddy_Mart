class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final String image;
  final double rating;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.image,
    required this.rating,
  });
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.price * quantity;
}

class DemoUser {
  final String id;
  final String name;
  final String avatar;
  final String phone;
  final String email;
  final String location;
  final double rating;
  final bool isRunner;
  final bool kycCompleted;

  DemoUser({
    required this.id,
    required this.name,
    required this.avatar,
    required this.phone,
    required this.email,
    required this.location,
    required this.rating,
    this.isRunner = false,
    this.kycCompleted = false,
  });
}
