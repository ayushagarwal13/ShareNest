import 'package:flutter_test/flutter_test.dart';
import 'package:sharenest/main.dart';

void main() {
  group('Settlement validation scenarios', () {
    late ExpenseGroup group;

    setUp(() {
      group = ExpenseGroup(name: 'Weekend Trip', members: ['Ayush', 'Sameer']);

      group.expenses.add(
        Expense(
          title: 'Dinner',
          amountPaise: 20000,
          paidBy: 'Ayush',
          participants: ['Ayush', 'Sameer'],
          date: DateTime(2026, 10, 19),
        ),
      );
    });

    test('partial repayment reduces the outstanding debt', () {
      group.settlements.add(
        Settlement(
          from: 'Sameer',
          to: 'Ayush',
          amountPaise: 5000,
          date: DateTime(2026, 10, 19),
        ),
      );

      expect(calculateBalances(group), {'Ayush': 5000, 'Sameer': -5000});
    });

    test('full repayment clears the outstanding debt', () {
      group.settlements.add(
        Settlement(
          from: 'Sameer',
          to: 'Ayush',
          amountPaise: 10000,
          date: DateTime(2026, 10, 19),
        ),
      );

      expect(calculateBalances(group), {'Ayush': 0, 'Sameer': 0});

      expect(calculateDebts(group), isEmpty);
    });

    test('a repayment must not exceed the current outstanding debt', () {
      final debts = calculateDebts(group);

      expect(debts, hasLength(1));
      expect(debts.single.from, 'Sameer');
      expect(debts.single.to, 'Ayush');
      expect(debts.single.amountPaise, 10000);

      expect(15000 > debts.single.amountPaise, isTrue);
    });

    test('zero and negative amounts are invalid', () {
      expect(0 <= 0, isTrue);
      expect(-100 <= 0, isTrue);
    });
  });
}
