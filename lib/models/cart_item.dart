class CartItem {
  final String id;
  final String productId;
  final String name;
  final String imagePath;
  final double basePrice;
  int quantity;
  String? observation;
  final Map<String, String> selectedOptions;
  final double optionsPrice;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.imagePath,
    required this.basePrice,
    this.quantity = 1,
    this.observation,
    this.selectedOptions = const {},
    this.optionsPrice = 0.0,
  });

  double get total => (basePrice + optionsPrice) * quantity;

  double get unitPrice => basePrice + optionsPrice;
}
