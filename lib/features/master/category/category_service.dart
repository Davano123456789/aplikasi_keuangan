import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/api_service.dart';
import '../../../core/models/category_model.dart';
import 'dart:io';

class CategoryService {
  static Future<List<CategoryModel>> getAll() async {
    final url = Uri.parse('${ApiService.baseUrl}/categories');
    
    try {
      final response = await http.get(
        url,
        headers: await ApiService.getHeaders(),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        final List categoriesJson = data['data'];
        return categoriesJson.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Gagal mengambil data kategori');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan koneksi: $e');
    }
  }

  static Future<Map<String, dynamic>> store(String name, String type) async {
    final url = Uri.parse('${ApiService.baseUrl}/categories');
    
    try {
      final response = await http.post(
        url,
        headers: await ApiService.getHeaders(),
        body: json.encode({
          'name': name,
          'type': type,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 201 && data['status'] == 'success') {
        return {'success': true, 'message': data['message'], 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gagal menambahkan kategori'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }

  static Future<Map<String, dynamic>> delete(int id) async {
    final url = Uri.parse('${ApiService.baseUrl}/categories/$id');
    
    try {
      final response = await http.delete(
        url,
        headers: await ApiService.getHeaders(),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gagal menghapus kategori'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }

  static Future<Map<String, dynamic>> update(int id, String name, String type) async {
    final url = Uri.parse('${ApiService.baseUrl}/categories/$id');
    
    try {
      final response = await http.put(
        url,
        headers: await ApiService.getHeaders(),
        body: json.encode({
          'name': name,
          'type': type,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'message': data['message'], 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gagal memperbarui kategori'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }

  static Future<CategoryModel> getById(int id) async {
    final url = Uri.parse('${ApiService.baseUrl}/categories/$id');
    
    try {
      final response = await http.get(
        url,
        headers: await ApiService.getHeaders(),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        return CategoryModel.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Gagal mengambil detail kategori');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan koneksi: $e');
    }
  }
}
