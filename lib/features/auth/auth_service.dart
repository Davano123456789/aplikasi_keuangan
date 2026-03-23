import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/services/api_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('${ApiService.baseUrl}/login');
    
    try {
      final response = await http.post(
        url,
        headers: await ApiService.getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
          'device_name': 'flutter_web', // Sesuai kebutuhan API Laravel
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await ApiService.saveToken(data['token']);
        // Anda bisa simpan data user juga jika perlu
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false, 
          'message': data['message'] ?? 'Gagal login. Periksa kembali email dan password.'
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
