import 'package:flutter/material.dart';
import '../../core/models/category_model.dart';
import '../../core/models/wallet_model.dart';
import '../../core/models/transaction_model.dart';
import '../master/category/category_service.dart';
import '../master/wallet/wallet_service.dart';
import 'transaction_service.dart';
import '../../core/themes/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;
  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  
  String _selectedType = 'OUT'; // 'IN', 'OUT', 'TRANS'
  int? _selectedCategoryId;
  int? _fromWalletId;
  int? _toWalletId;
  String? _imagePath;

  bool get _isEditMode => widget.transaction != null;

  List<CategoryModel> _categories = [];
  List<WalletModel> _wallets = [];
  bool _isLoadingData = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      final wallets = await WalletService.getWallets();
      final categories = await CategoryService.getAll();
      setState(() {
        _wallets = wallets;
        _categories = categories;
        _isLoadingData = false;

        if (_isEditMode) {
          final t = widget.transaction!;
          _selectedType = t.type;
          _amountController.text = t.amount.toStringAsFixed(0);
          _noteController.text = t.note ?? '';
          _selectedDate = t.date;
          _selectedCategoryId = t.categoryId;
          _fromWalletId = t.fromWalletId;
          _toWalletId = t.toWalletId;
        } else {
          // Pick defaults if available for NEW mode
          if (_wallets.isNotEmpty) {
            if (_selectedType == 'OUT') _fromWalletId = _wallets.first.id;
            if (_selectedType == 'IN') _toWalletId = _wallets.first.id;
            if (_selectedType == 'TRANS') {
              _fromWalletId = _wallets.first.id;
              _toWalletId = _wallets.length > 1 ? _wallets[1].id : _wallets.first.id;
            }
          }
        }
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
      }
    }
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      
      try {
        final Map<String, dynamic> result;
        if (_isEditMode) {
          result = await TransactionService.update(
            id: widget.transaction!.id,
            type: _selectedType,
            amount: double.parse(_amountController.text),
            date: _selectedDate.toIso8601String(),
            categoryId: _selectedCategoryId,
            fromWalletId: _fromWalletId,
            toWalletId: _toWalletId,
            note: _noteController.text,
          );
        } else {
          result = await TransactionService.store(
            type: _selectedType,
            amount: double.parse(_amountController.text),
            date: _selectedDate.toIso8601String(),
            categoryId: _selectedCategoryId,
            fromWalletId: _fromWalletId,
            toWalletId: _toWalletId,
            note: _noteController.text,
            imagePath: _imagePath,
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
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Transaksi' : 'Tambah Transaksi'),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTypeSelector(),
                    const SizedBox(height: 32),
                    _buildAmountField(),
                    const SizedBox(height: 24),
                    if (_selectedType != 'TRANS') _buildCategoryDropdown(),
                    if (_selectedType != 'IN') _buildWalletDropdown(label: 'Dari Dompet', value: _fromWalletId, onChanged: (v) => setState(() => _fromWalletId = v)),
                    if (_selectedType != 'OUT') _buildWalletDropdown(label: 'Ke Dompet', value: _toWalletId, onChanged: (v) => setState(() => _toWalletId = v)),
                    const SizedBox(height: 16),
                    _buildDateField(),
                    const SizedBox(height: 16),
                    _buildNoteField(),
                    const SizedBox(height: 24),
                    _buildImagePicker(),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveTransaction,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_isEditMode ? 'Update Transaksi' : 'Simpan Transaksi', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTypeTab('OUT', 'Pengeluaran', Colors.red),
          _buildTypeTab('IN', 'Pemasukan', Colors.green),
          _buildTypeTab('TRANS', 'Pindah Saldo', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildTypeTab(String type, String label, Color color) {
    bool isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: _isEditMode ? null : () => setState(() {
          _selectedType = type;
          _selectedCategoryId = null; // Reset category when switching
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? color : (_isEditMode ? Colors.grey.shade300 : Colors.grey.shade600),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      readOnly: _isEditMode,
      keyboardType: TextInputType.number,
      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _isEditMode ? Colors.grey : Colors.black),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: '0',
        prefixText: 'Rp ',
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        filled: true,
        fillColor: _isEditMode ? Colors.grey.shade100 : Colors.white,
      ),
      validator: (value) => (value == null || value.isEmpty) ? 'Masukkan nominal' : null,
    );
  }

  Widget _buildCategoryDropdown() {
    final filteredCategories = _categories.where((c) => c.type == _selectedType).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<int>(
        value: _selectedCategoryId,
        decoration: _getInputDecoration('Kategori', Icons.category_rounded),
        items: filteredCategories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
        onChanged: (v) => setState(() => _selectedCategoryId = v),
        validator: (v) => v == null ? 'Pilih kategori' : null,
      ),
    );
  }

  Widget _buildWalletDropdown({required String label, required int? value, required Function(int?) onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<int>(
        value: value,
        onChanged: _isEditMode ? null : onChanged,
        decoration: _getInputDecoration(label, Icons.account_balance_wallet_rounded),
        items: _wallets.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
        validator: (v) => v == null ? 'Pilih dompet' : null,
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _isEditMode ? null : () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) setState(() => _selectedDate = date);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _isEditMode ? Colors.grey.shade100 : Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: _isEditMode ? Colors.grey.shade400 : Colors.grey, size: 20),
            const SizedBox(width: 12),
            Text(
              DateFormat('dd MMMM yyyy').format(_selectedDate),
              style: TextStyle(color: _isEditMode ? Colors.grey : Colors.black87),
            ),
            const Spacer(),
            if (!_isEditMode) const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      maxLines: 2,
      decoration: _getInputDecoration('Catatan (Opsional)', Icons.notes_rounded),
    );
  }

  Widget _buildImagePicker() {
    if (_isEditMode) return const SizedBox.shrink(); // Hide image picker in edit mode for now

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Foto Bukti (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showImageSourceSheet,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.none),
            ),
            child: _imagePath != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(File(_imagePath!), width: double.infinity, height: 150, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: GestureDetector(
                          onTap: () => setState(() => _imagePath = null),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('Tambah Foto', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _showImageSourceSheet() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih Sumber Foto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Kamera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildSourceOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeri',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source, imageQuality: 70);
    
    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  InputDecoration _getInputDecoration(String label, IconData icon) {
    bool isFieldDisabled = _isEditMode && label != 'Kategori' && label != 'Catatan (Opsional)';
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: isFieldDisabled ? Colors.grey.shade400 : null),
      labelStyle: TextStyle(color: isFieldDisabled ? Colors.grey : null),
      filled: true,
      fillColor: isFieldDisabled ? Colors.grey.shade100 : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    );
  }
}

