import 'package:flutter/material.dart';
import 'package:aplikasi_keuangan/core/models/transaction_model.dart';
import 'package:aplikasi_keuangan/core/themes/app_theme.dart';
import 'package:aplikasi_keuangan/features/transactions/transaction_service.dart';
import 'package:aplikasi_keuangan/features/transactions/add_transaction_screen.dart';
import 'package:aplikasi_keuangan/core/services/api_service.dart';
import 'package:intl/intl.dart';

class TransactionDetailScreen extends StatefulWidget {
  final int transactionId;
  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  TransactionModel? _transaction;
  bool _isLoading = true;
  String? _errorMessage;
  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final transaction = await TransactionService.getById(widget.transactionId);
      setState(() {
        _transaction = transaction;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        elevation: 0,
        actions: _transaction != null ? [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryColor),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTransactionScreen(transaction: _transaction),
                ),
              );
              if (result == true) {
                _fetchDetail();
              }
            },
          ),
          const SizedBox(width: 8),
        ] : null,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _fetchDetail, child: const Text('Coba Lagi')),
                  ],
                ))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final t = _transaction!;
    final isIncome = t.type == 'IN';
    final isTransfer = t.type == 'TRANS';
    final color = isIncome ? Colors.green : (isTransfer ? Colors.blue : Colors.redAccent);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroSection(t, color, isIncome),
          const SizedBox(height: 24),
          if (t.image != null) _buildImageSection(t.image!),
          const SizedBox(height: 24),
          _buildInfoSection(t),
        ],
      ),
    );
  }

  Widget _buildHeroSection(TransactionModel t, Color color, bool isIncome) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              t.type == 'IN' ? Icons.arrow_downward_rounded : 
              (t.type == 'TRANS' ? Icons.swap_horiz_rounded : Icons.arrow_upward_rounded),
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            t.typeLabel,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            '${t.type == 'OUT' ? '-' : (t.type == 'IN' ? '+' : '')}${currencyFormat.format(t.amount)}',
            style: TextStyle(
              color: color,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (t.note != null && t.note!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              t.note!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection(TransactionModel t) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          if (t.type != 'TRANS') 
            _buildDetailRow('Kategori', t.category?.name ?? '-', Icons.category_outlined),
          
          if (t.type == 'OUT' || t.type == 'TRANS')
            _buildDetailRow('Dari Dompet', t.fromWallet?.name ?? '-', Icons.wallet_outlined),
            
          if (t.type == 'IN' || t.type == 'TRANS')
            _buildDetailRow('Asal/Tujuan', t.toWallet?.name ?? '-', Icons.account_balance_wallet_outlined),
          
          _buildDetailRow('Tanggal', DateFormat('EEEE, dd MMMM yyyy').format(t.date), Icons.calendar_today_outlined),
          _buildDetailRow('Waktu', DateFormat('HH:mm').format(t.date), Icons.access_time_rounded),
          
          if (t.user != null)
            _buildDetailRow('Input Oleh', t.user!.name, Icons.person_outline_rounded),
        ],
      ),
    );
  }

  Widget _buildImageSection(String imagePath) {
    // Construct full URL. Laravel usually stores in storage/
    // Assuming ApiService.baseUrl is .../api, we might need to go up one level
    final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
    final imageUrl = imagePath.startsWith('http') ? imagePath : '$baseUrl/storage/$imagePath';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.image_outlined, size: 18, color: Colors.grey),
              SizedBox(width: 8),
              Text('Bukti Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 100,
                width: double.infinity,
                color: Colors.grey.shade100,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_outlined, color: Colors.grey),
                    SizedBox(height: 4),
                    Text('Gagal memuat gambar', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
