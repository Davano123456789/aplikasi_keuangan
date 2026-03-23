import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/api_service.dart';
import '../../../core/models/user_model.dart';

class UserService {
  static Future<List<UserModel>> getAll() async {
    final url = Uri.parse('${ApiService.baseUrl}/users');
    
    try {
      final response = await http.get(
        url,
        headers: await ApiService.getHeaders(),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        final List usersJson = data['data'];
        return usersJson.map((json) => UserModel.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Gagal mengambil data pegawai');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan koneksi: $e');
    }
  }

  static Future<UserModel> getById(int id) async {
    final url = Uri.parse('${ApiService.baseUrl}/users/$id');
    
    try {
      final response = await http.get(
        url,
        headers: await ApiService.getHeaders(),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        return UserModel.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Gagal mengambil detail pegawai');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan koneksi: $e');
    }
  }

  static Future<Map<String, dynamic>> store({
    required String name,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${ApiService.baseUrl}/users');
    
    try {
      final response = await http.post(
        url,
        headers: await ApiService.getHeaders(),
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 201 && data['status'] == 'success') {
        return {'success': true, 'message': data['message'], 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gagal menambahkan akun pegawai'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }

  static Future<Map<String, dynamic>> delete(int id) async {
    final url = Uri.parse('${ApiService.baseUrl}/users/$id');
    
    try {
      final response = await http.delete(
        url,
        headers: await ApiService.getHeaders(),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gagal menghapus akun pegawai'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }
}
