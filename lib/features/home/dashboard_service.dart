import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/api_service.dart';
import '../../../core/models/dashboard_model.dart';

class DashboardService {
  static Future<DashboardModel> getDashboardSummary() async {
    final url = Uri.parse('${ApiService.baseUrl}/dashboard');
    
    try {
      final response = await http.get(
        url,
        headers: await ApiService.getHeaders(),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        return DashboardModel.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Gagal mengambil ringkasan dashboard');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan koneksi: $e');
    }
  }
}
