import '../models/financial_models.dart';

String _indianGrouping(int n) {
  final s = n.toString();
  if (s.length <= 3) return s;

  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];

  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);

  return '${parts.join(',')},$last3';
}

String money(int paise) {
  final abs = paise.abs();
  final rupees = abs ~/ 100;
  final cents = (abs % 100).toString().padLeft(2, '0');

  return '${paise < 0 ? '-' : ''}₹${_indianGrouping(rupees)}.$cents';
}

String paiseToInput(int paise) {
  final rupees = paise ~/ 100;
  final rest = paise % 100;
  return rest == 0 ? '$rupees' : '$rupees.${rest.toString().padLeft(2, '0')}';
}

int? parsePaise(String input) {
  final value = input.trim();

  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value)) {
    return null;
  }

  final parts = value.split('.');
  final rupees = int.tryParse(parts[0]);
  final paise = int.tryParse(
    parts.length == 2 ? parts[1].padRight(2, '0') : '00',
  );

  if (rupees == null || paise == null) return null;

  if (rupees > 1000000000) return null;

  return rupees * 100 + paise;
}

Map<String, int> calculateBalances(ExpenseGroup group) {
  final balances = <String, int>{for (final member in group.members) member: 0};

  for (final expense in group.expenses) {
    balances[expense.paidBy] = balances[expense.paidBy]! + expense.amountPaise;

    for (final member in expense.participants) {
      balances[member] = balances[member]! - expense.shareFor(member);
    }
  }

  for (final settlement in group.settlements) {
    balances[settlement.from] =
        balances[settlement.from]! + settlement.amountPaise;
    balances[settlement.to] = balances[settlement.to]! - settlement.amountPaise;
  }

  return balances;
}

List<Debt> calculateDebts(ExpenseGroup group) {
  final balances = calculateBalances(group);

  final creditors = <MapEntry<String, int>>[];
  final debtors = <MapEntry<String, int>>[];

  for (final member in group.members) {
    final balance = balances[member]!;
    if (balance > 0) {
      creditors.add(MapEntry(member, balance));
    } else if (balance < 0) {
      debtors.add(MapEntry(member, -balance));
    }
  }

  final debts = <Debt>[];
  var i = 0;
  var j = 0;

  while (i < debtors.length && j < creditors.length) {
    final amount = debtors[i].value < creditors[j].value
        ? debtors[i].value
        : creditors[j].value;

    if (amount > 0) {
      debts.add(
        Debt(from: debtors[i].key, to: creditors[j].key, amountPaise: amount),
      );
    }

    final remainingDebt = debtors[i].value - amount;
    final remainingCredit = creditors[j].value - amount;

    debtors[i] = MapEntry(debtors[i].key, remainingDebt);
    creditors[j] = MapEntry(creditors[j].key, remainingCredit);

    if (remainingDebt == 0) i++;
    if (remainingCredit == 0) j++;
  }

  return debts;
}
