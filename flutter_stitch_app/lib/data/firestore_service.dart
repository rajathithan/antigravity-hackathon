import 'dart:convert';
import 'package:http/http.dart' as http;
import 'mock_data.dart';
import '../config.dart';

class FirestoreService {
  /// Returns a date string like "2026-04-15" for a given [date].
  static String dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Fetches today's menu via the backend API.
  /// The backend reads from Firestore using the Cloud Run service account.
  Future<List<MenuItem>> getTodayMenu() async {
    final response = await http.get(Uri.parse(AppConfig.apiMenu));
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final dishes = data['dishes'] as List<dynamic>? ?? [];
    return dishes
        .map((d) => MenuItem.fromFirestore(d as Map<String, dynamic>))
        .toList();
  }
}
