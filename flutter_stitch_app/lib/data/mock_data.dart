/// Strongly-typed model for a menu item.
class MenuItem {
  final String name;
  final String description;

  /// Local asset path, e.g. 'assets/images/pav_bhaji.png'
  final String image;

  /// Remote Firebase Storage download URL (nullable).
  /// When set, this takes priority over [image] for display.
  final String? imageUrl;

  final String price;

  const MenuItem({
    required this.name,
    required this.description,
    required this.image,
    required this.price,
    this.imageUrl,
  });

  /// Returns the best available image source:
  /// Firebase Storage URL if available, otherwise the local asset path.
  String get displayImage => imageUrl ?? image;

  /// True if the image should be loaded from the network (Firebase Storage).
  bool get isNetworkImage => imageUrl != null && imageUrl!.isNotEmpty;

  factory MenuItem.fromFirestore(Map<String, dynamic> data) {
    return MenuItem(
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      // 'imageUrl' is the Firebase Storage download URL stored in Firestore
      imageUrl: data['imageUrl'] as String?,
      // 'image' is the fallback local asset path
      image: data['image'] ?? 'assets/images/pav_bhaji.png',
      price: data['price'] ?? r'$0.00',
    );
  }

  factory MenuItem.fromJson(Map<String, dynamic> data) =>
      MenuItem.fromFirestore(data);
}

class MockData {
  static const String appTitle = '4 to 8';
  static const String heroHeadline = 'The Golden Hour Flavors';
  static const String heroSubtext =
      'An exclusive fine dining experience available only from 4 PM to 8 PM. Featuring four artisan street delicacies daily.';

  static const List<MenuItem> dailyItems = [
    MenuItem(
      name: 'Pav Bhaaji',
      description:
          'Hand-crafted spiced vegetable reduction served with artisanal buttered brioche.',
      image: 'assets/images/pav_bhaji.png',
      price: r'$9.99',
    ),
    MenuItem(
      name: 'Bajji',
      description:
          'Crispy heirloom vegetable tempura served with a vibrant cooling mint emulsion.',
      image: 'assets/images/bujji.png',
      price: r'$6.99',
    ),
    MenuItem(
      name: 'Kozhukattai',
      description:
          'Delicate steamed rice pearls with a velvet coconut and dark jaggery infusion.',
      image: 'assets/images/kozhukattai.png',
      price: r'$9.99',
    ),
    MenuItem(
      name: 'Samosa',
      description:
          'Ultra-crispy golden pyramids filled with spiced emerald peas and potatoes.',
      image: 'assets/images/samosa.png',
      price: r'$6.49',
    ),
  ];

  static bool isShopOpen() {
    final now = DateTime.now();
    return now.hour >= 16 && now.hour < 20;
  }

  static String getTimeStatus() {
    if (isShopOpen()) {
      return 'EXPERIENCE OPEN';
    } else {
      return 'RESERVATIONS AT 3 PM';
    }
  }
}
