import '../models/financial_models.dart';
import 'financial_calculations.dart';

class SettlementValidator {
  static String? validate({
    required ExpenseGroup group,
    required Debt debt,
    required int amountPaise,
  }) {
    if (amountPaise <= 0) {
      return 'Repayment amount must be positive.';
    }

    final currentDebt = calculateDebts(group)
        .where((item) => item.from == debt.from && item.to == debt.to);

    if (currentDebt.isEmpty) {
      return 'No outstanding debt exists for these members.';
    }

    if (amountPaise > currentDebt.first.amountPaise) {
      return 'Repayment exceeds the outstanding debt.';
    }

    return null;
  }
}
