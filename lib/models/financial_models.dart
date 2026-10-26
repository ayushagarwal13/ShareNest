class Expense {
  Expense({
    required this.title,
    required this.amountPaise,
    required this.paidBy,
    required this.participants,
    required this.date,
  });

  final String title;
  final int amountPaise;
  final String paidBy;
  final List<String> participants;
  final DateTime date;

  int get baseShare => amountPaise ~/ participants.length;

  int get remainder => amountPaise % participants.length;

  int shareFor(String member) {
    final index = participants.indexOf(member);
    if (index == -1) return 0;

    return baseShare + (index < remainder ? 1 : 0);
  }
}

class Settlement {
  Settlement({
    required this.from,
    required this.to,
    required this.amountPaise,
    required this.date,
  });

  final String from;
  final String to;
  final int amountPaise;
  final DateTime date;
}


class ExpenseGroup {
  ExpenseGroup({this.id, required this.name, required this.members});

  final String? id;
  final String name;
  final List<String> members;
  final List<Expense> expenses = [];
  final List<Settlement> settlements = [];

  int get totalPaise =>
      expenses.fold(0, (sum, expense) => sum + expense.amountPaise);
}


class Debt {
  const Debt({required this.from, required this.to, required this.amountPaise});

  final String from;
  final String to;
  final int amountPaise;
}

class ActivityEntry {
  ActivityEntry.expense(this.group, Expense e)
    : expense = e,
      settlement = null,
      date = e.date;

  ActivityEntry.settlement(this.group, Settlement s)
    : expense = null,
      settlement = s,
      date = s.date;

  final ExpenseGroup group;
  final Expense? expense;
  final Settlement? settlement;
  final DateTime date;
}
