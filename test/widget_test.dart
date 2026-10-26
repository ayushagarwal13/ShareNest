import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharenest/main.dart';
import 'package:sharenest/services/expense_repository.dart';

class FakeExpenseRepository implements ExpenseRepositoryInterface {
  @override
  Future<List<SavedExpenseGroup>> loadGroups() async => [];

  @override
  Future<SavedExpenseGroup> createGroup(ExpenseGroup group) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveGroup(String groupId, ExpenseGroup group) async {}

  @override
  Future<void> deleteGroup(String groupId) async {}

    @override
  Future<void> deleteAllGroups() async {}
}

void main() {
  testWidgets('ShareNest home screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ShareNestHome(expenseRepository: FakeExpenseRepository()),
      ),
    );

    // Allow the asynchronous group-loading operation to complete.
    await tester.pumpAndSettle();

    expect(find.text('Hello, Ayush'), findsOneWidget);
    expect(find.textContaining('Shared money,'), findsOneWidget);
    expect(find.text('Groups'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
  });
}
