import '../models/category_model.dart';
import '../models/wallet_model.dart';
import '../models/user_model.dart';

class TransactionModel {
  final int id;
  final String type; // 'IN', 'OUT', 'TRANS'
  final double amount;
  final String? note;
  final DateTime date;
  final int? categoryId;
  final int? fromWalletId;
  final int? toWalletId;
  final CategoryModel? category;
  final WalletModel? fromWallet;
  final WalletModel? toWallet;
  final UserModel? user;
  final String? image;

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    this.note,
    required this.date,
    this.categoryId,
    this.fromWalletId,
    this.toWalletId,
    this.category,
    this.fromWallet,
    this.toWallet,
    this.user,
    this.image,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      type: json['type'],
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      note: json['note'],
      date: DateTime.parse(json['date']),
      categoryId: json['category_id'],
      fromWalletId: json['from_wallet_id'],
      toWalletId: json['to_wallet_id'],
      category: json['category'] != null ? CategoryModel.fromJson(json['category']) : null,
      fromWallet: json['from_wallet'] != null ? WalletModel.fromJson(json['from_wallet']) : null,
      toWallet: json['to_wallet'] != null ? WalletModel.fromJson(json['to_wallet']) : null,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'note': note,
      'date': date.toIso8601String(),
      'category_id': categoryId,
      'from_wallet_id': fromWalletId,
      'to_wallet_id': toWalletId,
    };
  }

  String get typeLabel {
    switch (type) {
      case 'IN':
        return 'Pemasukan';
      case 'OUT':
        return 'Pengeluaran';
      case 'TRANS':
        return 'Pindah Saldo';
      default:
        return 'Transaksi';
    }
  }
}
