/// Item Model - 商品模型
/// Corresponds to Section 5.2 of the Development Plan
class ItemModel {
  final String itemId;
  final String name;
  final String unit; // e.g., 'kg', '瓶', '碗'
  final double price;
  final double step; // Default step size for increment/decrement
  final String category; // 'weighing' (称重类) or 'counting' (计数类)
  final String? imagePath; // Optional path to item image (local file path)

  ItemModel({
    required this.itemId,
    required this.name,
    required this.unit,
    required this.price,
    required this.step,
    this.category = 'counting',
    this.imagePath,
  });

  /// Convert from Map (for SQLite)
  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      itemId: map['item_id'] as String,
      name: map['name'] as String,
      unit: map['unit'] as String,
      price: (map['price'] as num).toDouble(),
      step: (map['step'] as num).toDouble(),
      category: map['category'] as String? ?? 'counting',
      imagePath: map['image_path'] as String?,
    );
  }

  /// Convert to Map (for SQLite)
  Map<String, dynamic> toMap() {
    return {
      'item_id': itemId,
      'name': name,
      'unit': unit,
      'price': price,
      'step': step,
      'category': category,
      'image_path': imagePath,
    };
  }

  /// Create a copy with updated fields
  ItemModel copyWith({
    String? itemId,
    String? name,
    String? unit,
    double? price,
    double? step,
    String? category,
    String? imagePath,
  }) {
    return ItemModel(
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      step: step ?? this.step,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  /// Check if this is a weighing item (requires numeric keypad)
  bool get isWeighingItem => category == 'weighing';

  /// Check if this is a counting item (simple +/- buttons)
  bool get isCountingItem => category == 'counting';

  /// Check if item has an image
  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  /// Format price for display
  String get formattedPrice => price.toStringAsFixed(2);
}
