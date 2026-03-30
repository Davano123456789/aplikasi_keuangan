import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../auth/auth_service.dart';
import '../../core/themes/app_theme.dart';
import '../../core/models/wallet_model.dart';
import '../master/wallet/wallet_service.dart';
import '../../core/models/transaction_model.dart';
import '../transactions/transaction_service.dart';
import 'package:aplikasi_keuangan/features/transactions/transaction_detail_screen.dart';
import 'package:aplikasi_keuangan/core/utils/auth_helper.dart';
import 'package:aplikasi_keuangan/features/home/dashboard_service.dart';
import 'package:aplikasi_keuangan/core/models/dashboard_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onViewAll;
  const DashboardScreen({super.key, this.onViewAll});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardModel? _dashboardData;
  bool _isLoading = true;
  bool _isBalanceVisible = true;
  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final dashboardData = await DashboardService.getDashboardSummary();
      setState(() {
        _isBalanceVisible = prefs.getBool('is_balance_visible') ?? true;
        _dashboardData = dashboardData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data dashboard: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => AuthHelper.showLogoutDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildChartsSection(),
                    const SizedBox(height: 32),
                    _buildRecentTransactionsSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(
                      'Halo, Selamat Datang',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _dashboardData?.user?.name ?? 'Pengguna Keuangan',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                ],
              ),
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(Icons.person_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Saldo Anda', style: TextStyle(color: Colors.white70, fontSize: 14)),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  _isBalanceVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: _toggleBalanceVisibility,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _isBalanceVisible ? currencyFormat.format(_dashboardData?.totalBalance ?? 0) : 'Rp ••••••••',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildMiniSummary('Pemasukan', _isBalanceVisible ? currencyFormat.format(_dashboardData?.incomeThisMonth ?? 0) : 'Rp ••••', Icons.arrow_downward_rounded, Colors.greenAccent),
              const SizedBox(width: 24),
              _buildMiniSummary('Pengeluaran', _isBalanceVisible ? currencyFormat.format(_dashboardData?.expenseThisMonth ?? 0) : 'Rp ••••', Icons.arrow_upward_rounded, Colors.orangeAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniSummary(String label, String amount, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
            Text(amount, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Transaksi Terakhir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
              TextButton(
                onPressed: widget.onViewAll, 
                child: const Text('Lihat Semua', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600))
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_dashboardData == null || _dashboardData!.recentTransactions.isEmpty) 
            const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Belum ada transaksi', style: TextStyle(color: Colors.grey))))
          else 
            ..._dashboardData!.recentTransactions.map((t) => _buildTransactionItem(t)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final bool isIncome = transaction.type == 'IN';
    final bool isTransfer = transaction.type == 'TRANS';
    final color = isIncome ? Colors.green : (isTransfer ? Colors.blue : Colors.redAccent);
    final icon = isIncome ? Icons.arrow_downward_rounded : (isTransfer ? Icons.swap_horiz_rounded : Icons.arrow_upward_rounded);

    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailScreen(transactionId: transaction.id),
          ),
        );
        if (result == true) {
          _fetchData();
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction.note ?? (transaction.category?.name ?? transaction.typeLabel), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(DateFormat('dd MMM').format(transaction.date), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
            Text(
              _isBalanceVisible 
                  ? '${isIncome ? "+" : "-"}${currencyFormat.format(transaction.amount)}'
                  : 'Rp •••',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    if (_dashboardData == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Analisis Bulan Ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textColor)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPieChartCard(
                  title: 'Pengeluaran',
                  data: _dashboardData!.expenseByCategory,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPieChartCard(
                  title: 'Pemasukan',
                  data: _dashboardData!.incomeByCategory,
                  color: Colors.greenAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  final List<Color> _chartColors = [
    Colors.blueAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.tealAccent,
    Colors.pinkAccent,
    Colors.indigoAccent,
    Colors.amberAccent,
    Colors.cyanAccent,
  ];

  Widget _buildPieChartCard({
    required String title,
    required List<CategorySummary> data,
    required Color color, // Base color for empty state or fallback
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: data.isEmpty 
              ? const Center(child: Text('Kosong', style: TextStyle(fontSize: 10, color: Colors.grey)))
              : _buildPieChart(data),
          ),
          const SizedBox(height: 12),
          // Legend (Simplified)
          ...data.take(3).map((item) {
            final index = data.indexOf(item);
            final itemColor = _chartColors[index % _chartColors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: itemColor, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(item.category.name, style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis)),
                ],
              ),
            );
          }),
          if (data.length > 3) 
             Text('+${data.length - 3} lainnya', style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<CategorySummary> data) {
    final double totalSum = data.fold(0, (sum, item) => sum + item.total);
    
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 30,
        sections: data.map((item) {
          final index = data.indexOf(item);
          final itemColor = _chartColors[index % _chartColors.length];
          final percentage = totalSum > 0 ? (item.total / totalSum * 100) : 0;
          
          return PieChartSectionData(
            color: itemColor,
            value: item.total,
            title: percentage >= 8 ? '${percentage.toStringAsFixed(0)}%' : '', 
            radius: 20,
            titleStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _toggleBalanceVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBalanceVisible = !_isBalanceVisible;
      prefs.setBool('is_balance_visible', _isBalanceVisible);
    });
  }
}
