import '../../core/models/wallet_model.dart';
import '../../core/models/transaction_model.dart';
import '../../core/models/category_model.dart';
import '../../core/models/user_model.dart';

class DashboardModel {
  final double totalBalance;
  final double incomeThisMonth;
  final double expenseThisMonth;
  final List<CategorySummary> expenseByCategory;
  final List<CategorySummary> incomeByCategory;
  final List<TransactionModel> recentTransactions;
  final List<WalletModel> wallets;
  final UserModel? user;

  DashboardModel({
    required this.totalBalance,
    required this.incomeThisMonth,
    required this.expenseThisMonth,
    required this.expenseByCategory,
    required this.incomeByCategory,
    required this.recentTransactions,
    required this.wallets,
    this.user,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      totalBalance: double.tryParse(json['total_balance']?.toString() ?? '0') ?? 0.0,
      incomeThisMonth: double.tryParse(json['income_this_month']?.toString() ?? '0') ?? 0.0,
      expenseThisMonth: double.tryParse(json['expense_this_month']?.toString() ?? '0') ?? 0.0,
      expenseByCategory: (json['expense_by_category'] as List? ?? [])
          .map((item) => CategorySummary.fromJson(item))
          .toList(),
      incomeByCategory: (json['income_by_category'] as List? ?? [])
          .map((item) => CategorySummary.fromJson(item))
          .toList(),
      recentTransactions: (json['recent_transactions'] as List? ?? [])
          .map((item) => TransactionModel.fromJson(item))
          .toList(),
      wallets: (json['wallets'] as List? ?? [])
          .map((item) => WalletModel.fromJson(item))
          .toList(),
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}

class CategorySummary {
  final int categoryId;
  final double total;
  final CategoryModel category;

  CategorySummary({
    required this.categoryId,
    required this.total,
    required this.category,
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) {
    return CategorySummary(
      categoryId: int.tryParse(json['category_id']?.toString() ?? '0') ?? 0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      category: CategoryModel.fromJson(json['category']),
    );
  }
}
