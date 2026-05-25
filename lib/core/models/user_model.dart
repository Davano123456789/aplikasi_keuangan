import 'wallet_model.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final DateTime? createdAt;
  final List<WalletModel> wallets;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.createdAt,
    this.wallets = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['username'] ?? json['name'] ?? '',
      email: json['role'] ?? json['email'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      wallets: json['wallets'] != null
          ? (json['wallets'] as List).map((w) => WalletModel.fromJson(w)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': name,
      'role': email,
      'wallets': wallets.map((w) => w.toJson()).toList(),
    };
  }
}
