import 'package:flutter_test/flutter_test.dart';
import 'package:sharenest/main.dart';
import 'package:sharenest/utils/settlement_validator.dart';

void main() {
  late ExpenseGroup group;

  setUp(() {
    group = ExpenseGroup(
      name: 'Trip',
      members: ['Ayush', 'Sameer', 'Shreya', 'Prerna'],
    );

    group.expenses.add(
      Expense(
        title: 'Dinner',
        amountPaise: 40000,
        paidBy: 'Ayush',
        participants: ['Ayush', 'Sameer', 'Shreya', 'Prerna'],
        date: DateTime(2026, 10, 19),
      ),
    );
  });

  test('accepts a valid partial repayment', () {
    final debt = calculateDebts(group)
        .firstWhere((item) => item.from == 'Sameer' && item.to == 'Ayush');

    expect(
      SettlementValidator.validate(group: group, debt: debt, amountPaise: 5000),
      isNull,
    );
  });

  test('rejects a zero repayment', () {
    final debt = calculateDebts(group).first;

    expect(
      SettlementValidator.validate(group: group, debt: debt, amountPaise: 0),
      'Repayment amount must be positive.',
    );
  });

  test('rejects a negative repayment', () {
    final debt = calculateDebts(group).first;

    expect(
      SettlementValidator.validate(group: group, debt: debt, amountPaise: -100),
      'Repayment amount must be positive.',
    );
  });

  test('rejects repayment exceeding the outstanding debt', () {
    final debt = calculateDebts(group)
        .firstWhere((item) => item.from == 'Sameer' && item.to == 'Ayush');

    expect(
      SettlementValidator.validate(
        group: group,
        debt: debt,
        amountPaise: 10001,
      ),
      'Repayment exceeds the outstanding debt.',
    );
  });

  test('rejects a debt that no longer exists', () {
    final debt = calculateDebts(group)
        .firstWhere((item) => item.from == 'Sameer' && item.to == 'Ayush');

    group.settlements.add(
      Settlement(
        from: 'Sameer',
        to: 'Ayush',
        amountPaise: 10000,
        date: DateTime(2026, 10, 19),
      ),
    );

    expect(
      SettlementValidator.validate(group: group, debt: debt, amountPaise: 1),
      'No outstanding debt exists for these members.',
    );
  });
}
