import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/services/api_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('${ApiService.baseUrl}/login');
    
    try {
      final response = await http.post(
        url,
        headers: await ApiService.getHeaders(),
        body: jsonEncode({
          'username': username,
          'password': password,
          'device_name': 'flutter_app', // Sesuai kebutuhan API Laravel
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await ApiService.saveToken(data['token']);
        final userJson = data['user'];
        if (userJson != null && userJson['role'] != null) {
          await ApiService.saveRole(userJson['role']);
        }
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false, 
          'message': data['message'] ?? 'Gagal login. Periksa kembali username dan password.'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    final url = Uri.parse('${ApiService.baseUrl}/logout');
    
    try {
      final response = await http.post(
        url,
        headers: await ApiService.getHeaders(),
      );

      await ApiService.clearAuth();

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'message': 'Gagal logout di server, tapi sesi lokal dihapus.'};
      }
    } catch (e) {
      await ApiService.clearAuth();
      return {'success': false, 'message': 'Koneksi gagal saat logout: $e'};
    }
  }
}
