import 'package:flutter/material.dart';
import '../../core/models/transaction_model.dart';
import '../../core/themes/app_theme.dart';
import 'transaction_service.dart';
import 'add_transaction_screen.dart';
import 'transaction_detail_screen.dart';
import 'package:aplikasi_keuangan/core/utils/auth_helper.dart';
import 'package:intl/intl.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  String? _currentFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _fetchTransactions();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    
    setState(() {
      switch (_tabController.index) {
        case 0: _currentFilter = null; break;
        case 1: _currentFilter = 'IN'; break;
        case 2: _currentFilter = 'OUT'; break;
        case 3: _currentFilter = 'TRANS'; break;
      }
    });
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);
    try {
      final data = await TransactionService.getAll(type: _currentFilter);
      setState(() {
        _transactions = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          IconButton(onPressed: _fetchTransactions, icon: const Icon(Icons.refresh_rounded)),
          IconButton(
            onPressed: () => AuthHelper.showLogoutDialog(context),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Semua'),
                  Tab(text: 'Pemasukan'),
                  Tab(text: 'Pengeluaran'),
                  Tab(text: 'Pindah Saldo'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchTransactions,
              child: _transactions.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        return _buildTransactionItem(_transactions[index]);
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
          );
          if (result == true) {
            _fetchTransactions();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Icon(Icons.receipt_long_rounded, size: 80, color: Colors.grey),
        const SizedBox(height: 16),
        const Center(child: Text('Belum ada transaksi', style: TextStyle(color: Colors.grey, fontSize: 16))),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final bool isIncome = transaction.type == 'IN';
    final bool isTransfer = transaction.type == 'TRANS';
    final color = isIncome ? Colors.green : (isTransfer ? Colors.blue : Colors.red);
    final icon = isIncome 
        ? Icons.arrow_downward_rounded 
        : (isTransfer ? Icons.swap_horiz_rounded : Icons.arrow_upward_rounded);

    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          ListTile(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionDetailScreen(transactionId: transaction.id),
                ),
              );
              if (result == true) {
                _fetchTransactions();
              }
            },
            contentPadding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            title: Text(
              transaction.note ?? (transaction.category?.name ?? transaction.typeLabel),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(transaction.date),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                if (isTransfer) 
                  Text(
                    '${transaction.fromWallet?.name} ➔ ${transaction.toWallet?.name}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  )
                else
                  Text(
                    isIncome ? 'Ke: ${transaction.toWallet?.name}' : 'Dari: ${transaction.fromWallet?.name}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                if (transaction.user != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 10, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'Input oleh: ${transaction.user!.name}',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? "+" : "-"}${currencyFormat.format(transaction.amount)}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  transaction.typeLabel,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.edit_note_rounded, size: 28, color: AppTheme.primaryColor),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddTransactionScreen(transaction: transaction),
                  ),
                );
                if (result == true) {
                  _fetchTransactions();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
