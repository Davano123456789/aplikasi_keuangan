import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/api_service.dart';
import '../../../core/models/transaction_model.dart';

class TransactionService {
  static Future<List<TransactionModel>> getAll({String? type}) async {
    final queryParameters = type != null ? {'type': type} : null;
    final url = Uri.parse('${ApiService.baseUrl}/transactions').replace(queryParameters: queryParameters);
    
    try {
      final response = await http.get(
        url,
        headers: await ApiService.getHeaders(),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        final List transactionsJson = data['data']['data']; // Because of pagination: data.data
        return transactionsJson.map((json) => TransactionModel.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Gagal mengambil data transaksi');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan koneksi: $e');
    }
  }

  static Future<TransactionModel> getById(int id) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/transactions/$id'),
      headers: await ApiService.getHeaders(),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return TransactionModel.fromJson(jsonResponse['data']);
    } else {
      throw Exception('Gagal memuat detail transaksi: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> store({
    required String type,
    required double amount,
    required String date,
    int? categoryId,
    int? fromWalletId,
    int? toWalletId,
    String? note,
    String? imagePath,
  }) async {
    final url = Uri.parse('${ApiService.baseUrl}/transactions');
    
    try {
      final request = http.MultipartRequest('POST', url);
      final headers = await ApiService.getHeaders();
      request.headers.addAll(headers);

      request.fields['type'] = type;
      request.fields['amount'] = amount.toString();
      request.fields['date'] = date;
      if (categoryId != null) request.fields['category_id'] = categoryId.toString();
      if (fromWalletId != null) request.fields['from_wallet_id'] = fromWalletId.toString();
      if (toWalletId != null) request.fields['to_wallet_id'] = toWalletId.toString();
      if (note != null) request.fields['note'] = note;

      if (imagePath != null) {
        request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = json.decode(response.body);
      if (response.statusCode == 201 && data['status'] == 'success') {
        return {'success': true, 'message': data['message'], 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gagal mencatat transaksi'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }

  static Future<Map<String, dynamic>> update({
    required int id,
    required String type,
    required double amount,
    required String date,
    int? categoryId,
    int? fromWalletId,
    int? toWalletId,
    String? note,
  }) async {
    final url = Uri.parse('${ApiService.baseUrl}/transactions/$id');
    
    try {
      final response = await http.put(
        url,
        headers: await ApiService.getHeaders(),
        body: json.encode({
          'type': type,
          'amount': amount,
          'date': date,
          'category_id': categoryId,
          'from_wallet_id': fromWalletId,
          'to_wallet_id': toWalletId,
          'note': note,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'message': data['message'], 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gagal memperbarui transaksi'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }

  static Future<bool> delete(int id) async {
    final url = Uri.parse('${ApiService.baseUrl}/transactions/$id');
    try {
      final response = await http.delete(
        url,
        headers: await ApiService.getHeaders(),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}
