import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/auth_helper.dart';
import 'user_service.dart';
import 'add_user_screen.dart';
import '../../../core/services/api_service.dart';

class UserDetailScreen extends StatefulWidget {
  final int userId;
  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  UserModel? _user;
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
    _fetchDetail();
  }

  void _checkRole() async {
    final role = await ApiService.getRole();
    if (mounted) {
      setState(() {
        _isAdmin = role == 'admin';
      });
    }
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    try {
      final user = await UserService.getById(widget.userId);
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleText = _user != null
        ? (_user!.email == 'admin' ? 'Administrator' : 'Pegawai')
        : '';
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Detail Pegawai'),
        actions: _user == null
            ? null
            : [
                if (_isAdmin)
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    tooltip: 'Edit Pegawai',
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddUserScreen(user: _user),
                        ),
                      );
                      if (result == true) {
                        _fetchDetail();
                      }
                    },
                  ),
                IconButton(
                  onPressed: () => AuthHelper.showLogoutDialog(context),
                  icon: const Icon(Icons.logout_rounded),
                ),
                const SizedBox(width: 8),
              ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('Data tidak ditemukan'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              child: const Icon(Icons.person_rounded, size: 50, color: AppTheme.primaryColor),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _user!.name,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              roleText,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'Informasi Akun',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailItem(Icons.badge_outlined, 'ID Pegawai', '#${_user!.id}'),
                      _buildDetailItem(Icons.person_outline_rounded, 'Username', _user!.name),
                      _buildDetailItem(Icons.security_outlined, 'Role / Peran', roleText),
                      if (_user!.email == 'user') ...[
                        const SizedBox(height: 32),
                        const Text(
                          'Hak Akses Dompet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _user!.wallets.isEmpty
                            ? const Text(
                                'Pegawai ini tidak memiliki akses ke dompet manapun.',
                                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _user!.wallets.length,
                                itemBuilder: (context, index) {
                                  final wallet = _user!.wallets[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.02),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                        child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primaryColor),
                                      ),
                                      title: Text(wallet.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      trailing: Text(
                                        'Rp ${wallet.balance.toStringAsFixed(0)}',
                                        style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
