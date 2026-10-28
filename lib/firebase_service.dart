import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String? get userId {
    return AuthService.getUserId();
  }

  static Future<void> saveExpenses(List<Map<String, dynamic>> expenses) async {
    final uid = userId;
    if (uid == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .doc('data')
          .set({
        'expenses': expenses,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Xarajatlar Firestore\'ga saqlandi');
    } catch (e) {
      print('Xarajatlarni saqlashda xatolik: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> loadExpenses() async {
    final uid = userId;
    if (uid == null) return [];

    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .doc('data')
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['expenses'] != null) {
          return List<Map<String, dynamic>>.from(data['expenses']);
        }
      }
      return [];
    } catch (e) {
      print('Xarajatlarni yuklashda xatolik: $e');
      return [];
    }
  }

  static Future<void> saveDebts(List<Map<String, dynamic>> debts) async {
    final uid = userId;
    if (uid == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('debts')
          .doc('data')
          .set({
        'debts': debts,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Qarzlar Firestore\'ga saqlandi');
    } catch (e) {
      print('Qarzlarlarni saqlashda xatolik: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> loadDebts() async {
    final uid = userId;
    if (uid == null) return [];

    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('debts')
          .doc('data')
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['debts'] != null) {
          return List<Map<String, dynamic>>.from(data['debts']);
        }
      }
      return [];
    } catch (e) {
      print('Qarzlarlarni yuklashda xatolik: $e');
      return [];
    }
  }
}