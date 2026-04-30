import 'product_option.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imagePath;
  final String categoryId;
  final List<String> ingredients;
  final bool isActive;
  final String? badge;
  final double rating;
  final int prepTimeMinutes;
  final int reviewCount;
  final List<ProductOptionGroup> optionGroups;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imagePath,
    required this.categoryId,
    this.ingredients = const [],
    this.isActive = true,
    this.badge,
    this.rating = 4.5,
    this.prepTimeMinutes = 15,
    this.reviewCount = 0,
    this.optionGroups = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['nome'] as String? ?? 'Sem nome',
      description: json['inf_adicionais'] as String? ?? '',
      price: (json['vr_venda'] as num?)?.toDouble() ?? 0.0,
      imagePath: (json['foto_url'] as String? ?? '').isNotEmpty
          ? json['foto_url'] as String
          : json['image_url'] as String? ?? '',
      categoryId: json['categoria_id'].toString(),
      ingredients: const [],
      isActive: json['is_ativo'] as bool? ?? true,
      badge: null,
      rating: 4.5,
      prepTimeMinutes: 15,
      reviewCount: 0,
      optionGroups: const [],
    );
  }
}
