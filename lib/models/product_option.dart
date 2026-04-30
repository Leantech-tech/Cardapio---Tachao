class ProductOption {
  final String id;
  final String name;
  final double priceModifier;

  ProductOption({
    required this.id,
    required this.name,
    this.priceModifier = 0.0,
  });

  factory ProductOption.fromJson(Map<String, dynamic> json) {
    return ProductOption(
      id: json['id'].toString(),
      name: json['name'] as String,
      priceModifier: (json['price_modifier'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ProductOptionGroup {
  final String id;
  final String name;
  final List<ProductOption> options;

  ProductOptionGroup({
    required this.id,
    required this.name,
    required this.options,
  });

  factory ProductOptionGroup.fromJson(Map<String, dynamic> json) {
    final optionsList = (json['options'] as List<dynamic>? ?? [])
        .map((o) => ProductOption.fromJson(o as Map<String, dynamic>))
        .toList();
    return ProductOptionGroup(
      id: json['id'].toString(),
      name: json['name'] as String,
      options: optionsList,
    );
  }
}
