import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/api_service.dart';
import '../../../core/models/wallet_model.dart';

class WalletService {
  static Future<List<WalletModel>> getWallets() async {
    final url = Uri.parse('${ApiService.baseUrl}/wallets');
    
    try {
      final response = await http.get(
        url,
        headers: await ApiService.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        final List list = data['data'];
        return list.map((item) => WalletModel.fromJson(item)).toList();
      } else {
        throw Exception(data['message'] ?? 'Gagal mengambil data dompet');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan koneksi: $e');
    }
  }

  static Future<Map<String, dynamic>> store(String name, double balance) async {
    final url = Uri.parse('${ApiService.baseUrl}/wallets');
    
    try {
      final response = await http.post(
        url,
        headers: await ApiService.getHeaders(),
        body: jsonEncode({
          'name': name,
          'balance': balance,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['status'] == 'success') {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false, 
          'message': data['message'] ?? 'Gagal menambah dompet.'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }

  static Future<Map<String, dynamic>> destroy(int id) async {
    final url = Uri.parse('${ApiService.baseUrl}/wallets/$id');
    
    try {
      final response = await http.delete(
        url,
        headers: await ApiService.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false, 
          'message': data['message'] ?? 'Gagal menghapus dompet.'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }

  static Future<WalletModel> getById(int id) async {
    final url = Uri.parse('${ApiService.baseUrl}/wallets/$id');
    
    try {
      final response = await http.get(
        url,
        headers: await ApiService.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        return WalletModel.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Gagal mengambil detail dompet');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan koneksi: $e');
    }
  }
}
