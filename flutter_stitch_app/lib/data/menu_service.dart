import 'mock_data.dart';
import 'firestore_service.dart';

class MenuService {
  final FirestoreService _firestoreService = FirestoreService();

  /// Fetches today's menu from Cloud Firestore via REST API.
  /// Falls back to [MockData.dailyItems] if nothing is published yet
  /// or if the network is unavailable.
  Future<List<MenuItem>> fetchMenuItems() async {
    try {
      final items = await _firestoreService.getTodayMenu();
      if (items.isNotEmpty) return items;
    } catch (_) {
      // Firestore unreachable — fall through to mock data
    }
    return MockData.dailyItems;
  }
}
