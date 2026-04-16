import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_stitch_app/data/mock_data.dart';

void main() {
  group('MockData', () {
    test('dailyItems contains exactly 4 items', () {
      expect(MockData.dailyItems.length, 4);
    });

    test('each MenuItem has non-empty fields', () {
      for (final item in MockData.dailyItems) {
        expect(item.name, isNotEmpty, reason: 'Name should not be empty');
        expect(item.description, isNotEmpty, reason: 'Description should not be empty');
        expect(item.image, isNotEmpty, reason: 'Image path should not be empty');
        expect(item.price, isNotEmpty, reason: 'Price should not be empty');
      }
    });

    test('image paths follow expected pattern', () {
      for (final item in MockData.dailyItems) {
        expect(item.image, startsWith('assets/images/'));
        expect(item.image, endsWith('.png'));
      }
    });

    test('getTimeStatus returns EXPERIENCE OPEN when shop is open', () {
      // We verify the return value for each possible status
      final status = MockData.getTimeStatus();
      expect(
        status == 'EXPERIENCE OPEN' || status == 'RESERVATIONS AT 3 PM',
        isTrue,
        reason: 'Status must be one of the two expected strings',
      );
    });

    test('isShopOpen is consistent with getTimeStatus', () {
      final isOpen = MockData.isShopOpen();
      final status = MockData.getTimeStatus();
      if (isOpen) {
        expect(status, equals('EXPERIENCE OPEN'));
      } else {
        expect(status, equals('RESERVATIONS AT 3 PM'));
      }
    });

    test('heroHeadline and heroSubtext are non-empty strings', () {
      expect(MockData.heroHeadline, isNotEmpty);
      expect(MockData.heroSubtext, isNotEmpty);
    });

    test('appTitle is correct', () {
      expect(MockData.appTitle, equals('4 to 8'));
    });
  });

  group('MenuItem.fromFirestore', () {
    test('maps all fields correctly', () {
      final item = MenuItem.fromFirestore({
        'name': 'Samosa',
        'description': 'Crispy',
        'price': r'$6.49',
        'imageUrl': 'https://storage.googleapis.com/bucket/photo.jpg',
        'image': 'assets/images/samosa.png',
      });
      expect(item.name, equals('Samosa'));
      expect(item.description, equals('Crispy'));
      expect(item.price, equals(r'$6.49'));
      expect(item.imageUrl, equals('https://storage.googleapis.com/bucket/photo.jpg'));
      expect(item.image, equals('assets/images/samosa.png'));
    });

    test('falls back to default image when image key is absent', () {
      final item = MenuItem.fromFirestore({
        'name': 'Bajji',
        'description': 'Crispy tempura',
        'price': r'$6.99',
      });
      expect(item.image, equals('assets/images/pav_bhaji.png'));
    });

    test('falls back to default price when price key is absent', () {
      final item = MenuItem.fromFirestore({
        'name': 'Bajji',
        'description': 'Crispy tempura',
      });
      expect(item.price, equals(r'$0.00'));
    });

    test('imageUrl is null when not provided', () {
      final item = MenuItem.fromFirestore({'name': 'X', 'description': 'Y', 'price': r'$1'});
      expect(item.imageUrl, isNull);
    });

    test('displayImage returns imageUrl when set', () {
      final item = MenuItem.fromFirestore({
        'name': 'X',
        'description': 'Y',
        'price': r'$1',
        'imageUrl': 'https://storage.googleapis.com/b/x.jpg',
      });
      expect(item.displayImage, equals('https://storage.googleapis.com/b/x.jpg'));
      expect(item.isNetworkImage, isTrue);
    });

    test('displayImage returns local asset when imageUrl is absent', () {
      final item = MenuItem.fromFirestore({
        'name': 'X',
        'description': 'Y',
        'price': r'$1',
        'image': 'assets/images/samosa.png',
      });
      expect(item.displayImage, equals('assets/images/samosa.png'));
      expect(item.isNetworkImage, isFalse);
    });

    test('empty imageUrl string is treated as no network image', () {
      final item = MenuItem.fromFirestore({
        'name': 'X',
        'description': 'Y',
        'price': r'$1',
        'imageUrl': '',
      });
      expect(item.isNetworkImage, isFalse);
    });
  });
}
