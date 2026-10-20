import 'package:flutter_test/flutter_test.dart';
import 'package:sharenest/main.dart';

void main() {
  group('Expense calculations', () {
    test('calculates balances for expenses with different participants', () {
      final group = ExpenseGroup(
        name: 'Weekend Trip',
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

      group.expenses.add(
        Expense(
          title: 'Cab',
          amountPaise: 30000,
          paidBy: 'Ayush',
          participants: ['Ayush', 'Sameer'],
          date: DateTime(2026, 10, 19),
        ),
      );

      expect(calculateBalances(group), {
        'Ayush': 45000,
        'Sameer': -25000,
        'Shreya': -10000,
        'Prerna': -10000,
      });

      expect(group.totalPaise, 70000);
    });

    test('distributes leftover paise deterministically', () {
      final expense = Expense(
        title: 'Shared Snack',
        amountPaise: 10000,
        paidBy: 'Ayush',
        participants: ['Ayush', 'Sameer', 'Shreya'],
        date: DateTime(2026, 10, 19),
      );

      expect(expense.shareFor('Ayush'), 3334);
      expect(expense.shareFor('Sameer'), 3333);
      expect(expense.shareFor('Shreya'), 3333);
      expect(expense.shareFor('Prerna'), 0);

      expect(
        expense.shareFor('Ayush') +
            expense.shareFor('Sameer') +
            expense.shareFor('Shreya'),
        10000,
      );
    });

    test('calculates simplified repayment suggestions', () {
      final group = ExpenseGroup(
        name: 'Weekend Trip',
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

      group.expenses.add(
        Expense(
          title: 'Cab',
          amountPaise: 30000,
          paidBy: 'Ayush',
          participants: ['Ayush', 'Sameer'],
          date: DateTime(2026, 10, 19),
        ),
      );

      final debts = calculateDebts(group);

      expect(debts, hasLength(3));
      expect(debts[0].from, 'Sameer');
      expect(debts[0].to, 'Ayush');
      expect(debts[0].amountPaise, 25000);
      expect(debts[1].from, 'Shreya');
      expect(debts[1].to, 'Ayush');
      expect(debts[1].amountPaise, 10000);
      expect(debts[2].from, 'Prerna');
      expect(debts[2].to, 'Ayush');
      expect(debts[2].amountPaise, 10000);
    });

    test('applies a recorded repayment to member balances', () {
      final group = ExpenseGroup(
        name: 'Weekend Trip',
        members: ['Ayush', 'Sameer'],
      );

      group.expenses.add(
        Expense(
          title: 'Dinner',
          amountPaise: 20000,
          paidBy: 'Ayush',
          participants: ['Ayush', 'Sameer'],
          date: DateTime(2026, 10, 19),
        ),
      );

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
  });

  group('Money input validation', () {
    test('parses valid rupee amounts into paise', () {
      expect(parsePaise('12'), 1200);
      expect(parsePaise('12.3'), 1230);
      expect(parsePaise('12.34'), 1234);
      expect(parsePaise('  50.00  '), 5000);
    });

    test('rejects invalid rupee amounts', () {
      expect(parsePaise(''), isNull);
      expect(parsePaise('-12'), isNull);
      expect(parsePaise('12.345'), isNull);
      expect(parsePaise('abc'), isNull);
      expect(parsePaise('1000000001'), isNull);
    });
  });
}
