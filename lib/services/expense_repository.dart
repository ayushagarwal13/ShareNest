import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/financial_models.dart';

/// A saved group includes its Firestore document ID.
class SavedExpenseGroup {
  const SavedExpenseGroup({required this.id, required this.group});

  final String id;
  final ExpenseGroup group;
}

abstract interface class ExpenseRepositoryInterface {
  Future<SavedExpenseGroup> createGroup(ExpenseGroup group);

  Future<void> saveGroup(String groupId, ExpenseGroup group);

  Future<List<SavedExpenseGroup>> loadGroups();

  Future<void> deleteGroup(String groupId);

  Future<void> deleteAllGroups();
}

class ExpenseRepository implements ExpenseRepositoryInterface {
  ExpenseRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _userId {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('You must be signed in to access your expense groups.');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _groupsCollection {
    return _firestore.collection('users').doc(_userId).collection('groups');
  }

  /// Creates a group for the currently signed-in user.
  Future<SavedExpenseGroup> createGroup(ExpenseGroup group) async {
    final document = _groupsCollection.doc();

    await document.set(_groupToMap(group));

    final savedGroup =
        ExpenseGroup(
            id: document.id,
            name: group.name,
            members: List<String>.from(group.members),
          )
          ..expenses.addAll(group.expenses)
          ..settlements.addAll(group.settlements);

    return SavedExpenseGroup(id: document.id, group: savedGroup);
  }

  /// Saves changes to an existing group.
  Future<void> saveGroup(String groupId, ExpenseGroup group) async {
    await _groupsCollection.doc(groupId).set(_groupToMap(group));
  }

  /// Loads groups belonging to the currently signed-in user.
  Future<List<SavedExpenseGroup>> loadGroups() async {
    final snapshot = await _groupsCollection.get();

    return snapshot.docs.map((document) {
      final group = _groupFromMap(document.data(), documentId: document.id);

      return SavedExpenseGroup(id: document.id, group: group);
    }).toList();
  }

  /// Deletes a group belonging to the currently signed-in user.
  Future<void> deleteGroup(String groupId) async {
    await _groupsCollection.doc(groupId).delete();
  }

  /// Deletes all group documents belonging to the currently signed-in user.
  Future<void> deleteAllGroups() async {
    final snapshot = await _groupsCollection.get();

    // Firestore batches support at most 500 operations.
    for (var i = 0; i < snapshot.docs.length; i += 500) {
      final batch = _firestore.batch();
      final end = (i + 500 < snapshot.docs.length)
          ? i + 500
          : snapshot.docs.length;

      for (final document in snapshot.docs.sublist(i, end)) {
        batch.delete(document.reference);
      }

      await batch.commit();
    }
  }

  Map<String, dynamic> _groupToMap(ExpenseGroup group) {
    return {
      'name': group.name,
      'members': group.members,
      'expenses': group.expenses.map((expense) {
        return {
          'title': expense.title,
          'amountPaise': expense.amountPaise,
          'paidBy': expense.paidBy,
          'participants': expense.participants,
          'date': Timestamp.fromDate(expense.date),
        };
      }).toList(),
      'settlements': group.settlements.map((settlement) {
        return {
          'from': settlement.from,
          'to': settlement.to,
          'amountPaise': settlement.amountPaise,
          'date': Timestamp.fromDate(settlement.date),
        };
      }).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ExpenseGroup _groupFromMap(
    Map<String, dynamic> data, {
    required String documentId,
  }) {
    final group = ExpenseGroup(
      id: documentId,
      name: data['name'] as String,
      members: List<String>.from(data['members'] as List),
    );

    final expenses = data['expenses'] as List? ?? [];

    for (final item in expenses) {
      final expense = Map<String, dynamic>.from(item as Map);

      group.expenses.add(
        Expense(
          title: expense['title'] as String,
          amountPaise: (expense['amountPaise'] as num).toInt(),
          paidBy: expense['paidBy'] as String,
          participants: List<String>.from(expense['participants'] as List),
          date: (expense['date'] as Timestamp).toDate(),
        ),
      );
    }

    final settlements = data['settlements'] as List? ?? [];

    for (final item in settlements) {
      final settlement = Map<String, dynamic>.from(item as Map);

      group.settlements.add(
        Settlement(
          from: settlement['from'] as String,
          to: settlement['to'] as String,
          amountPaise: (settlement['amountPaise'] as num).toInt(),
          date: (settlement['date'] as Timestamp).toDate(),
        ),
      );
    }

    return group;
  }
}
