import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Ganti sesuai dengan IP/alamat Laravel lokal Anda
  // Jika di Chrome/Web: http://localhost:8000/api
  // Jika di Emulator Android: http://10.0.2.2:8000/api
  static const String baseUrl = 'https://keuangan-production-25fe.up.railway.app/api';

  static Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    // Consider using jsonEncode if storing complex objects
    // for now just simple storage
  }
}
