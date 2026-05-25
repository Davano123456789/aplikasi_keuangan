import 'package:flutter/material.dart';
import 'user_service.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/wallet_model.dart';
import '../wallet/wallet_service.dart';

class AddUserScreen extends StatefulWidget {
  final UserModel? user;
  const AddUserScreen({super.key, this.user});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'user';
  List<WalletModel> _allWallets = [];
  List<int> _selectedWalletIds = [];
  bool _isSaving = false;
  bool _isLoadingWallets = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _nameController.text = widget.user!.name;
      _selectedRole = widget.user!.email; // email is role
      _selectedWalletIds = widget.user!.wallets.map((w) => w.id).toList();
    }
    _fetchWallets();
  }

  void _fetchWallets() async {
    setState(() => _isLoadingWallets = true);
    try {
      final wallets = await WalletService.getWallets();
      setState(() {
        _allWallets = wallets;
        _isLoadingWallets = false;
      });
    } catch (e) {
      setState(() => _isLoadingWallets = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data dompet: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _saveUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      
      try {
        final Map<String, dynamic> result;
        if (widget.user == null) {
          result = await UserService.store(
            name: _nameController.text,
            email: _selectedRole,
            password: _passwordController.text,
            walletIds: _selectedRole == 'user' ? _selectedWalletIds : [],
          );
        } else {
          result = await UserService.update(
            id: widget.user!.id,
            name: _nameController.text,
            email: _selectedRole,
            password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
            walletIds: _selectedRole == 'user' ? _selectedWalletIds : [],
          );
        }

        setState(() => _isSaving = false);

        if (result['success']) {
          if (mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Pegawai' : 'Tambah Pegawai'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Username',
                icon: Icons.person_outline_rounded,
                validator: (v) => (v == null || v.isEmpty) ? 'Masukkan username' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: _getInputDecoration('Role / Peran', Icons.badge_outlined),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('User / Pegawai')),
                  DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedRole = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: _getInputDecoration(
                  isEdit ? 'Password Baru (Kosongkan jika tidak diubah)' : 'Password',
                  Icons.lock_outline_rounded,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (isEdit && (v == null || v.isEmpty)) {
                    return null;
                  }
                  if (v == null || v.length < 8) {
                    return 'Password minimal 8 karakter';
                  }
                  return null;
                },
              ),
              if (_selectedRole == 'user') ...[
                const SizedBox(height: 28),
                const Text(
                  'Hak Akses Dompet',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pilih dompet mana saja yang boleh diakses/dikelola oleh pegawai ini.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 12),
                _isLoadingWallets
                    ? const Center(child: CircularProgressIndicator())
                    : _allWallets.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Belum ada data dompet', style: TextStyle(color: Colors.grey)),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _allWallets.length,
                              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                              itemBuilder: (context, index) {
                                final wallet = _allWallets[index];
                                final isChecked = _selectedWalletIds.contains(wallet.id);
                                return CheckboxListTile(
                                  activeColor: AppTheme.primaryColor,
                                  title: Text(wallet.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                  value: isChecked,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedWalletIds.add(wallet.id);
                                      } else {
                                        _selectedWalletIds.remove(wallet.id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
              ],
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(isEdit ? 'Simpan Perubahan' : 'Simpan Pegawai', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _getInputDecoration(label, icon),
      validator: validator,
    );
  }

  InputDecoration _getInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    );
  }
}
