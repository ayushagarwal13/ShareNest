import 'package:flutter/material.dart';

import 'models/financial_models.dart';
import 'utils/financial_calculations.dart';
import 'utils/settlement_validator.dart';

export 'models/financial_models.dart';
export 'utils/financial_calculations.dart';

void main() {
  runApp(const ShareNestApp());
}

const String currentUser = 'Ayush';

class NestColors {
  static const teal = Color(0xFF0F766E);
  static const tealDark = Color(0xFF0B4F4A);
  static const mint = Color(0xFFDDF5EC);
  static const canvas = Color(0xFFFAFAF7);
  static const ink = Color(0xFF14231F);
  static const muted = Color(0xFF5B6B66);
  static const line = Color(0xFFE3EAE6);
  static const owe = Color(0xFFB3382C);
  static const oweTint = Color(0xFFFBE9E6);
}



class ShareNestApp extends StatelessWidget {
  const ShareNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: NestColors.teal,
          brightness: Brightness.light,
        ).copyWith(
          primary: NestColors.teal,
          onPrimary: Colors.white,
          primaryContainer: NestColors.mint,
          onPrimaryContainer: NestColors.tealDark,
          surface: NestColors.canvas,
          onSurface: NestColors.ink,
          error: NestColors.owe,
        );

    return MaterialApp(
      title: 'ShareNest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: NestColors.canvas,
        appBarTheme: const AppBarTheme(
          backgroundColor: NestColors.canvas,
          surfaceTintColor: Colors.transparent,
          foregroundColor: NestColors.ink,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: NestColors.line),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: NestColors.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: NestColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: NestColors.teal, width: 2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 52),
            foregroundColor: NestColors.tealDark,
            side: const BorderSide(color: NestColors.line),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: NestColors.teal,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          indicatorColor: NestColors.mint,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: NestColors.canvas,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
        ),
        dividerTheme: const DividerThemeData(color: NestColors.line, space: 1),
      ),
      home: const ShareNestHome(),
    );
  }
}


List<ActivityEntry> buildActivityEntries(List<ExpenseGroup> groups) {
  final entries = <ActivityEntry>[];

  for (final group in groups) {
    for (final expense in group.expenses) {
      entries.add(ActivityEntry.expense(group, expense));
    }

    for (final settlement in group.settlements) {
      entries.add(ActivityEntry.settlement(group, settlement));
    }
  }

  entries.sort((a, b) => b.date.compareTo(a.date));
  return entries;
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

int currentUserBalance(ExpenseGroup group) =>
    calculateBalances(group)[currentUser] ?? 0;



const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String dateLabel(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;

  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return '${d.day} ${_months[d.month - 1]} ${d.year}';
}

String displayName(String member) =>
    member == currentUser ? '$member (you)' : member;



class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, required this.name, this.radius = 20});

  final String name;
  final double radius;

  static const _palette = [
    [Color(0xFFDDF5EC), Color(0xFF0B4F4A)],
    [Color(0xFFFDE8CF), Color(0xFF7A4210)],
    [Color(0xFFE3E8FB), Color(0xFF2F3E8C)],
    [Color(0xFFF9E1EA), Color(0xFF8A2650)],
    [Color(0xFFEAF2D3), Color(0xFF465C12)],
    [Color(0xFFE4DDF6), Color(0xFF4B3290)],
  ];

  @override
  Widget build(BuildContext context) {
    final seed = name.codeUnits.fold<int>(0, (a, b) => a + b);
    final colors = _palette[seed % _palette.length];

    return CircleAvatar(
      radius: radius,
      backgroundColor: colors[0],
      child: Text(
        name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
        style: TextStyle(
          color: colors[1],
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}


class BalanceChip extends StatelessWidget {
  const BalanceChip({super.key, required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final String text;
    final Color fg;
    final Color bg;

    if (balance > 0) {
      icon = Icons.south_west_rounded;
      text = 'You get ${money(balance)}';
      fg = NestColors.tealDark;
      bg = NestColors.mint;
    } else if (balance < 0) {
      icon = Icons.north_east_rounded;
      text = 'You owe ${money(balance.abs())}';
      fg = NestColors.owe;
      bg = NestColors.oweTint;
    } else {
      icon = Icons.check_rounded;
      text = 'Settled';
      fg = NestColors.muted;
      bg = const Color(0xFFEFF2F0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.2),
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: NestColors.mint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: NestColors.teal),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: NestColors.muted, height: 1.4),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 18),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.group, required this.onTap});

  final ExpenseGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: NestColors.mint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.groups_rounded, color: NestColors.teal),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${group.members.length} members · '
                      '${group.expenses.length} expenses',
                      style: const TextStyle(
                        color: NestColors.muted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    BalanceChip(balance: currentUserBalance(group)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: NestColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({
    super.key,
    required this.expense,
    this.groupName,
    this.onTap,
  });

  final Expense expense;
  final String? groupName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final people = expense.participants.length;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: NestColors.mint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: NestColors.teal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (groupName != null) groupName!,
                        'Paid by ${expense.paidBy}',
                        '$people ${people == 1 ? 'person' : 'people'}',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: NestColors.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    money(expense.amountPaise),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel(expense.date),
                    style: const TextStyle(
                      color: NestColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettlementTile extends StatelessWidget {
  const SettlementTile({super.key, required this.settlement, this.groupName});

  final Settlement settlement;
  final String? groupName;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF1F8F5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: NestColors.teal,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.handshake_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${settlement.from} paid ${settlement.to}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (groupName != null) groupName!,
                      'Repayment recorded',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: NestColors.muted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  money(settlement.amountPaise),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: NestColors.tealDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateLabel(settlement.date),
                  style: const TextStyle(color: NestColors.muted, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- BOTTOM SHEET HELPERS ----------

Future<T?> showNestSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: child,
    ),
  );
}

class SheetFrame extends StatelessWidget {
  const SheetFrame({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: const TextStyle(color: NestColors.muted)),
          ],
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class ErrorLine extends StatelessWidget {
  const ErrorLine(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: NestColors.oweTint,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: NestColors.owe, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: NestColors.owe,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----- Create group sheet -----

Future<ExpenseGroup?> showCreateGroupSheet(BuildContext context) =>
    showNestSheet<ExpenseGroup>(context, const _CreateGroupSheet());

class _CreateGroupSheet extends StatefulWidget {
  const _CreateGroupSheet();

  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  final _nameC = TextEditingController();
  final _membersC = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nameC.dispose();
    _membersC.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameC.text.trim();
    final members = _membersC.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Remove duplicate names, ignoring case.
    final uniqueMembers = <String>[];
    final seen = <String>{};

    for (final member in members) {
      if (seen.add(member.toLowerCase())) {
        uniqueMembers.add(member);
      }
    }

    // The current user is always part of their own group.
    if (!seen.contains(currentUser.toLowerCase())) {
      uniqueMembers.insert(0, currentUser);
    }

    if (name.isEmpty || uniqueMembers.length < 2) {
      setState(() => _error = 'Enter a group name and at least one friend.');
      return;
    }

    Navigator.pop(context, ExpenseGroup(name: name, members: uniqueMembers));
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      title: 'Create a group',
      subtitle: 'You are added automatically. Add your friends below.',
      children: [
        TextField(
          controller: _nameC,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Group name',
            hintText: 'Goa Trip',
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _membersC,
          maxLines: 3,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Friends',
            hintText: 'Sameer, Shreya, Prerna',
            helperText: 'Separate names with commas',
          ),
        ),
        if (_error != null) ErrorLine(_error!),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _submit,
            child: const Text('Create group'),
          ),
        ),
      ],
    );
  }
}

// ----- Group picker (used from Home when adding an expense) -----

Future<ExpenseGroup?> showGroupPicker(
  BuildContext context,
  List<ExpenseGroup> groups,
) {
  return showNestSheet<ExpenseGroup>(
    context,
    SheetFrame(
      title: 'Add expense to…',
      subtitle: 'Choose a group',
      children: [
        for (final g in groups)
          Card(
            child: ListTile(
              leading: const Icon(Icons.groups_rounded, color: NestColors.teal),
              title: Text(
                g.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('${g.members.length} members'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context, g),
            ),
          ),
      ],
    ),
  );
}

// ----- Add expense sheet -----

Future<Expense?> showAddExpenseSheet(
  BuildContext context,
  ExpenseGroup group,
) => showNestSheet<Expense>(context, _AddExpenseSheet(group: group));

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet({required this.group});

  final ExpenseGroup group;

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _titleC = TextEditingController();
  final _amountC = TextEditingController();
  late String _payer;
  late final Set<String> _selected;
  String? _error;

  ExpenseGroup get group => widget.group;

  @override
  void initState() {
    super.initState();
    _payer = group.members.contains(currentUser)
        ? currentUser
        : group.members.first;
    _selected = {...group.members};
  }

  @override
  void dispose() {
    _titleC.dispose();
    _amountC.dispose();
    super.dispose();
  }

  Expense? _preview() {
    final amount = parsePaise(_amountC.text);
    if (amount == null || amount <= 0 || _selected.isEmpty) return null;

    return Expense(
      title: '',
      amountPaise: amount,
      paidBy: _payer,
      participants: group.members.where(_selected.contains).toList(),
      date: DateTime.now(),
    );
  }

  void _submit() {
    final title = _titleC.text.trim();
    final amount = parsePaise(_amountC.text);

    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid positive amount.');
      return;
    }
    if (title.isEmpty) {
      setState(() => _error = 'Enter an expense description.');
      return;
    }
    if (_selected.isEmpty) {
      setState(() => _error = 'Select at least one participant.');
      return;
    }

    Navigator.pop(
      context,
      Expense(
        title: title,
        amountPaise: amount,
        paidBy: _payer,
        participants: group.members.where(_selected.contains).toList(),
        date: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview();

    String summary;
    if (preview == null) {
      summary = 'Enter an amount and choose who shares it.';
    } else {
      final n = preview.participants.length;
      summary =
          'Split equally between $n ${n == 1 ? 'person' : 'people'}'
          ' · ${money(preview.baseShare)} each'
          '${preview.remainder > 0 ? ' (leftover paise shared out)' : ''}';
    }

    return SheetFrame(
      title: 'Add expense',
      subtitle: group.name,
      children: [
        TextField(
          controller: _amountC,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: '₹ ',
            hintText: '0.00',
          ),
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _titleC,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'What was it for?',
            hintText: 'Dinner, taxi, groceries…',
          ),
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: 20),
        const Text('Paid by', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final member in group.members)
              ChoiceChip(
                label: Text(member == currentUser ? 'You' : member),
                selected: _payer == member,
                selectedColor: NestColors.mint,
                showCheckmark: true,
                onSelected: (_) => setState(() => _payer = member),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Split between',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _selected.addAll(group.members)),
              child: const Text('Select all'),
            ),
            TextButton(
              onPressed: () => setState(_selected.clear),
              child: const Text('Clear'),
            ),
          ],
        ),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < group.members.length; i++) ...[
                if (i > 0) const Divider(),
                CheckboxListTile(
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(displayName(group.members[i])),
                  secondary: Text(
                    preview != null && _selected.contains(group.members[i])
                        ? money(preview.shareFor(group.members[i]))
                        : '—',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  value: _selected.contains(group.members[i]),
                  onChanged: (checked) {
                    setState(() {
                      _error = null;
                      if (checked == true) {
                        _selected.add(group.members[i]);
                      } else {
                        _selected.remove(group.members[i]);
                      }
                    });
                  },
                ),
              ],
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: NestColors.mint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.pie_chart_outline_rounded,
                color: NestColors.tealDark,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  summary,
                  style: const TextStyle(
                    color: NestColors.tealDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_error != null) ErrorLine(_error!),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _submit,
            child: const Text('Save expense'),
          ),
        ),
      ],
    );
  }
}

// ----- Settle sheet -----

Future<int?> showSettleSheet(BuildContext context, Debt debt) =>
    showNestSheet<int>(context, _SettleSheet(debt: debt));

class _SettleSheet extends StatefulWidget {
  const _SettleSheet({required this.debt});

  final Debt debt;

  @override
  State<_SettleSheet> createState() => _SettleSheetState();
}

class _SettleSheetState extends State<_SettleSheet> {
  late final TextEditingController _amountC;
  String? _error;

  Debt get debt => widget.debt;

  @override
  void initState() {
    super.initState();
    _amountC = TextEditingController(text: paiseToInput(debt.amountPaise));
  }

  @override
  void dispose() {
    _amountC.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = parsePaise(_amountC.text);

    if (parsed == null || parsed <= 0) {
      setState(() => _error = 'Enter a valid positive amount.');
      return;
    }
    if (parsed > debt.amountPaise) {
      setState(() => _error = 'Amount exceeds the outstanding balance.');
      return;
    }

    Navigator.pop(context, parsed);
  }

  @override
  Widget build(BuildContext context) {
    final parsed = parsePaise(_amountC.text);
    final validPartial =
        parsed != null && parsed > 0 && parsed <= debt.amountPaise;

    return SheetFrame(
      title: 'Settle up',
      subtitle: 'Record a full or partial repayment',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        MemberAvatar(name: debt.from, radius: 24),
                        const SizedBox(height: 6),
                        Text(
                          debt.from,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const Column(
                      children: [
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: NestColors.teal,
                        ),
                        Text(
                          'pays',
                          style: TextStyle(
                            color: NestColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        MemberAvatar(name: debt.to, radius: 24),
                        const SizedBox(height: 6),
                        Text(
                          debt.to,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Outstanding',
                      style: TextStyle(color: NestColors.muted),
                    ),
                    Text(
                      money(debt.amountPaise),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _amountC,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          decoration: const InputDecoration(
            labelText: 'Amount paid',
            prefixText: '₹ ',
          ),
          onChanged: (_) => setState(() => _error = null),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() {
              _amountC.text = paiseToInput(debt.amountPaise);
              _error = null;
            }),
            child: const Text('Pay full amount'),
          ),
        ),
        if (validPartial)
          Text(
            parsed == debt.amountPaise
                ? 'This will fully settle the balance.'
                : 'Remaining after this: '
                      '${money(debt.amountPaise - parsed)}',
            style: const TextStyle(
              color: NestColors.tealDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (_error != null) ErrorLine(_error!),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF2F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 20, color: NestColors.muted),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This only records a repayment in ShareNest. '
                  'No money is transferred.',
                  style: TextStyle(color: NestColors.muted, height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _submit,
            child: const Text('Record repayment'),
          ),
        ),
      ],
    );
  }
}

// ----- Debt picker (when a group has several suggested repayments) -----

Future<Debt?> showDebtPicker(BuildContext context, List<Debt> debts) {
  return showNestSheet<Debt>(
    context,
    SheetFrame(
      title: 'Who is paying?',
      subtitle: 'Choose a suggested repayment',
      children: [
        for (final d in debts)
          Card(
            child: ListTile(
              leading: MemberAvatar(name: d.from),
              title: Text(
                '${d.from} → ${d.to}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(money(d.amountPaise)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context, d),
            ),
          ),
      ],
    ),
  );
}

// ----- Expense details sheet -----

void showExpenseDetailsSheet(
  BuildContext context,
  ExpenseGroup group,
  Expense expense,
) {
  showNestSheet<void>(
    context,
    SheetFrame(
      title: expense.title,
      subtitle: '${group.name} · ${dateLabel(expense.date)}',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(color: NestColors.muted),
                    ),
                    Text(
                      money(expense.amountPaise),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Paid by',
                      style: TextStyle(color: NestColors.muted),
                    ),
                    Text(
                      displayName(expense.paidBy),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SectionHeader('Each person\'s share'),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < expense.participants.length; i++) ...[
                if (i > 0) const Divider(),
                ListTile(
                  leading: MemberAvatar(name: expense.participants[i]),
                  title: Text(displayName(expense.participants[i])),
                  trailing: Text(
                    money(expense.shareFor(expense.participants[i])),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

// ---------- HOME AND NAVIGATION ----------

class ShareNestHome extends StatefulWidget {
  const ShareNestHome({super.key});

  @override
  State<ShareNestHome> createState() => _ShareNestHomeState();
}

class _ShareNestHomeState extends State<ShareNestHome> {
  final List<ExpenseGroup> groups = [];
  int selectedTab = 0;

  Future<void> createGroup() async {
    final group = await showCreateGroupSheet(context);
    if (!mounted || group == null) return;

    setState(() {
      groups.add(group);
      selectedTab = 1;
    });
  }

  Future<void> addExpenseFromHome() async {
    if (groups.isEmpty) return;

    final ExpenseGroup? chosen = groups.length == 1
        ? groups.first
        : await showGroupPicker(context, groups);
    if (!mounted || chosen == null) return;

    final expense = await showAddExpenseSheet(context, chosen);
    if (!mounted || expense == null) return;

    setState(() => chosen.expenses.add(expense));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${money(expense.amountPaise)} to ${chosen.name}.'),
      ),
    );
  }

  void openGroup(ExpenseGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GroupDetailsPage(group: group)),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  int get totalOwedPaise {
    var total = 0;
    for (final group in groups) {
      final b = currentUserBalance(group);
      if (b < 0) total += -b;
    }
    return total;
  }

  int get totalToReceivePaise {
    var total = 0;
    for (final group in groups) {
      final b = currentUserBalance(group);
      if (b > 0) total += b;
    }
    return total;
  }

  Widget? _buildFab() {
    if (selectedTab == 0) {
      return groups.isEmpty
          ? FloatingActionButton.extended(
              onPressed: createGroup,
              icon: const Icon(Icons.group_add_rounded),
              label: const Text('Create group'),
            )
          : FloatingActionButton.extended(
              onPressed: addExpenseFromHome,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add expense'),
            );
    }
    if (selectedTab == 1) {
      return FloatingActionButton.extended(
        onPressed: createGroup,
        icon: const Icon(Icons.group_add_rounded),
        label: const Text('Create group'),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 18,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: NestColors.teal,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.egg_alt_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'ShareNest',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: selectedTab,
        children: [buildHome(), buildGroups(), buildActivity(), buildAccount()],
      ),
      floatingActionButton: _buildFab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (index) => setState(() => selectedTab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  // ----- Home tab -----

  Widget buildHome() {
    final recent = buildActivityEntries(groups).take(5).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
      children: [
        Text(
          'Hello, $currentUser',
          style: const TextStyle(color: NestColors.muted, fontSize: 15),
        ),
        const SizedBox(height: 2),
        Text(
          'Shared money,\nmade simple.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 20),
        heroCard(),
        const SizedBox(height: 22),
        SectionHeader(
          'Your groups',
          actionLabel: groups.length > 3 ? 'See all' : null,
          onAction: () => setState(() => selectedTab = 1),
        ),
        if (groups.isEmpty)
          Card(
            child: EmptyState(
              icon: Icons.groups_outlined,
              title: 'Start with a group',
              subtitle:
                  'Create a group for a trip, flat or dinner, then add '
                  'expenses and see who owes whom.',
              actionLabel: 'Create group',
              onAction: createGroup,
            ),
          )
        else
          ...groups
              .take(3)
              .map((g) => GroupCard(group: g, onTap: () => openGroup(g))),
        const SizedBox(height: 16),
        SectionHeader(
          'Recent activity',
          actionLabel: recent.isNotEmpty ? 'View all' : null,
          onAction: () => setState(() => selectedTab = 2),
        ),
        if (recent.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Expenses and repayments will show up here.',
              style: TextStyle(color: NestColors.muted),
            ),
          )
        else
          ...recent.map(activityTile),
      ],
    );
  }

  Widget heroCard() {
    final owe = totalOwedPaise;
    final owed = totalToReceivePaise;
    final net = owed - owe;

    final String headline;
    if (net > 0) {
      headline = 'Overall, you are owed';
    } else if (net < 0) {
      headline = 'Overall, you owe';
    } else {
      headline = groups.isEmpty ? 'No balances yet' : 'You are all settled up';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NestColors.tealDark,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: const TextStyle(color: Color(0xFFBFE6DC), fontSize: 14),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              money(net.abs()),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: heroStat('You owe', owe, Icons.north_east_rounded),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: heroStat('You are owed', owed, Icons.south_west_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget heroStat(String label, int paise, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFFBFE6DC)),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFBFE6DC),
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              money(paise),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----- Groups tab -----

  Widget buildGroups() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
      children: [
        Text(
          'Your groups',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        const SizedBox(height: 4),
        const Text(
          'Trips, flats, meals and everyday shared costs.',
          style: TextStyle(color: NestColors.muted),
        ),
        const SizedBox(height: 18),
        if (groups.isEmpty)
          Card(
            child: EmptyState(
              icon: Icons.group_add_outlined,
              title: 'Create your first group',
              subtitle: 'Add your friends and start tracking shared costs.',
              actionLabel: 'Create group',
              onAction: createGroup,
            ),
          )
        else
          ...groups.map((g) => GroupCard(group: g, onTap: () => openGroup(g))),
      ],
    );
  }

  // ----- Activity tab -----

  Widget activityTile(ActivityEntry entry) {
    if (entry.expense != null) {
      return ExpenseTile(
        expense: entry.expense!,
        groupName: entry.group.name,
        onTap: () =>
            showExpenseDetailsSheet(context, entry.group, entry.expense!),
      );
    }
    return SettlementTile(
      settlement: entry.settlement!,
      groupName: entry.group.name,
    );
  }

  Widget buildActivity() {
    final entries = buildActivityEntries(groups);
    final children = <Widget>[];
    String? lastLabel;

    for (final entry in entries) {
      final label = dateLabel(entry.date);
      if (label != lastLabel) {
        children.add(SectionHeader(label));
        lastLabel = label;
      }
      children.add(activityTile(entry));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
      children: [
        Text(
          'Activity',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        const SizedBox(height: 4),
        const Text(
          'Every expense and repayment, newest first.',
          style: TextStyle(color: NestColors.muted),
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          const Card(
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Nothing here yet',
              subtitle: 'Expenses and settlements will appear here.',
            ),
          )
        else
          ...children,
      ],
    );
  }

  // ----- Account tab -----

  Widget buildAccount() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
      children: [
        const SizedBox(height: 12),
        const Center(child: MemberAvatar(name: currentUser, radius: 44)),
        const SizedBox(height: 14),
        Text(
          currentUser,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Prototype profile',
          textAlign: TextAlign.center,
          style: TextStyle(color: NestColors.muted),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.cloud_off_outlined, color: NestColors.muted),
                    SizedBox(width: 10),
                    Text(
                      'Not signed in',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign-in and cloud sync are planned for a later version. '
                  'For now your data stays in memory on this device.',
                  style: TextStyle(color: NestColors.muted, height: 1.4),
                ),
                const SizedBox(height: 14),
                const SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: null,
                    child: Text('Sign in (coming soon)'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.lock_outline),
                title: Text('Privacy and security'),
                subtitle: Text('Settings will be added with accounts.'),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('About ShareNest'),
                subtitle: Text('Shared expenses. Clear balances.'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------- GROUP DETAILS ----------

class GroupDetailsPage extends StatefulWidget {
  const GroupDetailsPage({super.key, required this.group});

  final ExpenseGroup group;

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  ExpenseGroup get group => widget.group;

  /// 0 = Balances, 1 = Expenses, 2 = History
  int section = 0;

  Future<void> addExpense() async {
    final expense = await showAddExpenseSheet(context, group);
    if (!mounted || expense == null) return;

    setState(() => group.expenses.add(expense));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Expense of ${money(expense.amountPaise)} saved.'),
      ),
    );
  }


Future<void> settleUp(Debt debt) async {
    final amount = await showSettleSheet(context, debt);
    if (!mounted || amount == null) return;

    final error = SettlementValidator.validate(
      group: group,
      debt: debt,
      amountPaise: amount,
    );

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() {
      group.settlements.add(
        Settlement(
          from: debt.from,
          to: debt.to,
          amountPaise: amount,
          date: DateTime.now(),
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Repayment of ${money(amount)} recorded.')),
    );
  }


  Future<void> settleFlow(List<Debt> debts) async {
    if (debts.isEmpty) return;
    if (debts.length == 1) {
      await settleUp(debts.first);
      return;
    }
    final chosen = await showDebtPicker(context, debts);
    if (!mounted || chosen == null) return;
    await settleUp(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final balances = calculateBalances(group);
    final debts = calculateDebts(group);
    final mine = balances[currentUser] ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(group.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total group expenses',
                    style: TextStyle(color: NestColors.muted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    money(group.totalPaise),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      BalanceChip(balance: mine),
                      const SizedBox(width: 10),
                      Text(
                        '${group.members.length} members',
                        style: const TextStyle(color: NestColors.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: debts.isEmpty ? null : () => settleFlow(debts),
                      icon: const Icon(Icons.handshake_outlined),
                      label: const Text('Settle up'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: 0,
                  icon: Icon(Icons.balance_rounded),
                  label: Text('Balances'),
                ),
                ButtonSegment(
                  value: 1,
                  icon: Icon(Icons.receipt_long_rounded),
                  label: Text('Expenses'),
                ),
                ButtonSegment(
                  value: 2,
                  icon: Icon(Icons.history_rounded),
                  label: Text('History'),
                ),
              ],
              selected: {section},
              onSelectionChanged: (s) => setState(() => section = s.first),
            ),
          ),
          const SizedBox(height: 14),
          if (section == 0) ..._balancesSection(balances, debts),
          if (section == 1) ..._expensesSection(),
          if (section == 2) ..._historySection(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addExpense,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add expense'),
      ),
    );
  }

  List<Widget> _balancesSection(Map<String, int> balances, List<Debt> debts) {
    return [
      const SectionHeader('Suggested repayments'),
      if (debts.isEmpty)
        const Card(
          child: ListTile(
            leading: Icon(Icons.check_circle_outline, color: NestColors.teal),
            title: Text('Everyone is settled up!'),
            subtitle: Text('No outstanding balances.'),
          ),
        )
      else
        ...debts.map(
          (debt) => Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  MemberAvatar(name: debt.from),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${debt.from} owes ${debt.to}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          money(debt.amountPaise),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 44),
                    ),
                    onPressed: () => settleUp(debt),
                    child: const Text('Settle'),
                  ),
                ],
              ),
            ),
          ),
        ),
      const SizedBox(height: 10),
      const SectionHeader('Member balances'),
      Card(
        child: Column(
          children: [
            for (var i = 0; i < group.members.length; i++) ...[
              if (i > 0) const Divider(),
              _memberRow(group.members[i], balances[group.members[i]] ?? 0),
            ],
          ],
        ),
      ),
    ];
  }

  Widget _memberRow(String member, int balance) {
    final String label;
    final IconData icon;
    final Color color;

    if (balance > 0) {
      label = 'Gets back ${money(balance)}';
      icon = Icons.south_west_rounded;
      color = NestColors.tealDark;
    } else if (balance < 0) {
      label = 'Owes ${money(balance.abs())}';
      icon = Icons.north_east_rounded;
      color = NestColors.owe;
    } else {
      label = 'Settled up';
      icon = Icons.check_rounded;
      color = NestColors.muted;
    }

    return ListTile(
      leading: MemberAvatar(name: member),
      title: Text(
        displayName(member),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  List<Widget> _expensesSection() {
    if (group.expenses.isEmpty) {
      return [
        Card(
          child: EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No expenses yet',
            subtitle: 'Add the first expense to start splitting costs.',
            actionLabel: 'Add expense',
            onAction: addExpense,
          ),
        ),
      ];
    }

    return [
      ...group.expenses.reversed.map(
        (expense) => ExpenseTile(
          expense: expense,
          onTap: () => showExpenseDetailsSheet(context, group, expense),
        ),
      ),
    ];
  }

  List<Widget> _historySection() {
    if (group.settlements.isEmpty) {
      return const [
        Card(
          child: EmptyState(
            icon: Icons.handshake_outlined,
            title: 'No repayments yet',
            subtitle: 'Recorded repayments will appear here.',
          ),
        ),
      ];
    }

    return [
      ...group.settlements.reversed.map((s) => SettlementTile(settlement: s)),
    ];
  }
}
