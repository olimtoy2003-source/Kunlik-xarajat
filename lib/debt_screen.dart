import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'main.dart';
import 'firebase_service.dart';

const String debtsBoxName = 'debts_box';
const String passwordBoxName = 'app_password_box';

class Payment {
  double amount;
  DateTime date;
  String note;

  Payment({
    required this.amount,
    required this.date,
    required this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      note: map['note'] ?? '',
    );
  }
}

class Debt {
  String id;
  String personName;
  double amount;
  double paidAmount;
  String type;
  String description;
  DateTime date;
  DateTime? dueDate;
  bool isSettled;
  List<Payment> payments;

  Debt({
    required this.id,
    required this.personName,
    required this.amount,
    this.paidAmount = 0,
    required this.type,
    required this.description,
    required this.date,
    this.dueDate,
    this.isSettled = false,
    this.payments = const [],
  });

  double get remainingAmount => amount - paidAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personName': personName,
      'amount': amount,
      'paidAmount': paidAmount,
      'type': type,
      'description': description,
      'date': date.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'isSettled': isSettled,
      'payments': payments.map((p) => p.toMap()).toList(),
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'],
      personName: map['personName'],
      amount: map['amount'],
      paidAmount: map['paidAmount'] ?? 0,
      type: map['type'],
      description: map['description'] ?? '',
      date: DateTime.parse(map['date']),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      isSettled: map['isSettled'] ?? false,
      payments: map['payments'] != null
          ? List<Payment>.from(
              map['payments'].map((p) => Payment.fromMap(p)))
          : [],
    );
  }
}

class DebtScreen extends StatefulWidget {
  final void Function(ThemeMode) onThemeChanged;
  final ThemeMode currentTheme;

  const DebtScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentTheme,
  });

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> {
  List<Debt> debts = [];
  late Box _debtsBox;
  String filterType = 'Barchasi';
  String? _appPassword;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadPassword();
  }

  Future<void> _loadData() async {
    _debtsBox = await Hive.openBox(debtsBoxName);
    
    final firebaseDebts = await FirebaseService.loadDebts();
    
    if (firebaseDebts.isNotEmpty) {
      setState(() {
        debts = firebaseDebts.map((e) => Debt.fromMap(e)).toList();
      });
      final String encodedData = jsonEncode(firebaseDebts);
      await _debtsBox.put('debts_list', encodedData);
    } else {
      final String? savedData = _debtsBox.get('debts_list');
      if (savedData != null) {
        final List<dynamic> decodedData = jsonDecode(savedData);
        setState(() {
          debts = decodedData.map((e) => Debt.fromMap(e)).toList();
        });
      }
    }
  }

  Future<void> _loadPassword() async {
    final box = await Hive.openBox(passwordBoxName);
    setState(() {
      _appPassword = box.get('app_password');
    });
  }

  Future<void> _saveData() async {
    final String encodedData = jsonEncode(debts.map((e) => e.toMap()).toList());
    await _debtsBox.put('debts_list', encodedData);
    
    final List<Map<String, dynamic>> debtsMaps = debts.map((e) => e.toMap()).toList();
    await FirebaseService.saveDebts(debtsMaps);
  }

  void addDebt(Debt debt) {
    setState(() {
      debts.add(debt);
    });
    _saveData();
  }

  void updateDebt(String id, Debt updated) {
    setState(() {
      final index = debts.indexWhere((e) => e.id == id);
      if (index != -1) {
        debts[index] = updated;
      }
    });
    _saveData();
  }

  void deleteDebt(String id) {
    setState(() {
      debts.removeWhere((e) => e.id == id);
    });
    _saveData();
  }

  void addPayment(String debtId, double paymentAmount, String note) {
    setState(() {
      final index = debts.indexWhere((e) => e.id == debtId);
      if (index != -1) {
        final debt = debts[index];
        final newPaidAmount = debt.paidAmount + paymentAmount;
        final newPayments = List<Payment>.from(debt.payments)
          ..add(Payment(
            amount: paymentAmount,
            date: DateTime.now(),
            note: note,
          ));

        debts[index] = Debt(
          id: debt.id,
          personName: debt.personName,
          amount: debt.amount,
          paidAmount: newPaidAmount,
          type: debt.type,
          description: debt.description,
          date: debt.date,
          dueDate: debt.dueDate,
          isSettled: newPaidAmount >= debt.amount,
          payments: newPayments,
        );
      }
    });
    _saveData();
  }

  List<Debt> get filteredDebts {
    if (filterType == 'Barchasi') {
      return debts.where((d) => !d.isSettled).toList();
    }
    return debts.where((d) => d.type == filterType && !d.isSettled).toList();
  }

  double get totalOwedToMe {
    return debts
        .where((d) => d.type == 'owed_to_me' && !d.isSettled)
        .fold(0.0, (sum, d) => sum + d.remainingAmount);
  }

  double get totalOwedByMe {
    return debts
        .where((d) => d.type == 'owed_by_me' && !d.isSettled)
        .fold(0.0, (sum, d) => sum + d.remainingAmount);
  }

  @override
  void dispose() {
    _debtsBox.close();
    super.dispose();
  }

  Future<bool> askPassword() async {
    final controller = TextEditingController();
    bool result = false;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.lock,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.indigo),
              const SizedBox(width: 10),
              Text(
                'Parolni kiriting',
                style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black),
              ),
            ],
          ),
          content: TextField(
            controller: controller,
            obscureText: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, letterSpacing: 5),
            decoration: const InputDecoration(
              hintText: '****',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 15),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Bekor qilish'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text == _appPassword) {
                  result = true;
                  Navigator.pop(context);
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Parol noto\'g\'ri!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Tasdiqlash'),
            ),
          ],
        );
      },
    );
    return result;
  }

  void _showAddPaymentDialog(BuildContext context, Debt debt) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Qisman to\'lov qo\'shish'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Qolgan summa: ${formatMoney(debt.remainingAmount)} so\'m',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: debt.type == 'owed_to_me' ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'To\'lov summasi (so\'m)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Izoh (ixtiyoriy)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Bekor qilish'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (amountController.text.isNotEmpty) {
                  final paymentAmount = double.parse(amountController.text);
                  if (paymentAmount > debt.remainingAmount) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('To\'lov summasi qolgan qarzdan oshib ketdi!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final ok = await askPassword();
                  if (ok) {
                    addPayment(debt.id, paymentAmount, noteController.text);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('To\'lov qo\'shildi!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: const Text('Qo\'shish'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Qarz daftari', style: TextStyle(color: Colors.white)),
        backgroundColor: isDark ? const Color(0xFF1a1a2e) : const Color(0xFF667eea),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)]
                : [const Color(0xFF667eea), const Color(0xFF764ba2)],
          ),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.green.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Menga berishi kerak',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text('${formatMoney(totalOwedToMe)} so\'m',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Men berishim kerak',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text('${formatMoney(totalOwedByMe)} so\'m',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  _buildFilterChip('Barchasi', isDark),
                  const SizedBox(width: 10),
                  _buildFilterChip('owed_to_me', isDark, label: 'Menga'),
                  const SizedBox(width: 10),
                  _buildFilterChip('owed_by_me', isDark, label: 'Berishim'),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
                child: filteredDebts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_balance_wallet,
                                size: 64, color: isDark ? Colors.grey[700] : Colors.grey),
                            const SizedBox(height: 16),
                            Text('Hali qarzlar yo\'q',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: isDark ? Colors.grey[500] : Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(15),
                        itemCount: filteredDebts.length,
                        itemBuilder: (context, index) {
                          final debt = filteredDebts[index];
                          final isOwedToMe = debt.type == 'owed_to_me';
                          final progress = debt.amount > 0 ? debt.paidAmount / debt.amount : 0;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            elevation: 2,
                            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: (isOwedToMe ? Colors.green : Colors.red)
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          isOwedToMe
                                              ? Icons.arrow_downward
                                              : Icons.arrow_upward,
                                          color: isOwedToMe ? Colors.green : Colors.red,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(debt.personName,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: isDark
                                                        ? Colors.white
                                                        : Colors.black87)),
                                            const SizedBox(height: 4),
                                            if (debt.description.isNotEmpty)
                                              Text(debt.description,
                                                  style: TextStyle(
                                                      color: isDark
                                                          ? Colors.grey[400]
                                                          : Colors.grey[600],
                                                      fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('${formatMoney(debt.amount)} so\'m',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: isOwedToMe
                                                      ? Colors.green
                                                      : Colors.red)),
                                          if (debt.paidAmount > 0) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'To\'langan: ${formatMoney(debt.paidAmount)} so\'m',
                                              style: TextStyle(
                                                  color: Colors.blue,
                                                  fontSize: 12),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (debt.paidAmount > 0) ...[
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: progress.toDouble(),
                                        backgroundColor: Colors.grey[300],
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          isOwedToMe ? Colors.green : Colors.red,
                                        ),
                                        minHeight: 8,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Qolgan: ${formatMoney(debt.remainingAmount)} so\'m',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          '${(progress * 100).toStringAsFixed(0)}%',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isOwedToMe ? Colors.green : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Sana: ${DateFormat('dd.MM.yyyy HH:mm').format(debt.date)}',
                                        style: TextStyle(
                                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                                            fontSize: 11),
                                      ),
                                      if (debt.dueDate != null) ...[
                                        const SizedBox(width: 12),
                                        Icon(Icons.access_time, size: 14, color: Colors.orange),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Muddati: ${DateFormat('dd.MM.yyyy').format(debt.dueDate!)}',
                                          style: TextStyle(
                                              color: Colors.orange,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (debt.payments.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.grey[800] : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'To\'lovlar tarixi:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ...debt.payments.map((payment) => Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 2),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.check_circle,
                                                        size: 14, color: Colors.blue),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        '${formatMoney(payment.amount)} so\'m - ${DateFormat('dd.MM.yyyy HH:mm').format(payment.date)}',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: isDark
                                                              ? Colors.grey[300]
                                                              : Colors.grey[700],
                                                        ),
                                                      ),
                                                    ),
                                                    if (payment.note.isNotEmpty)
                                                      Text(
                                                        payment.note,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: isDark
                                                              ? Colors.grey[400]
                                                              : Colors.grey[500],
                                                          fontStyle: FontStyle.italic,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              )),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (!debt.isSettled) ...[
                                        IconButton(
                                          icon: const Icon(Icons.payment,
                                              size: 22, color: Colors.blue),
                                          onPressed: () =>
                                              _showAddPaymentDialog(context, debt),
                                          tooltip: 'Qisman to\'lov qo\'shish',
                                        ),
                                      ],
                                      IconButton(
                                        icon: Icon(
                                          debt.isSettled
                                              ? Icons.check_circle
                                              : Icons.check_circle_outline,
                                          size: 22,
                                          color: debt.isSettled ? Colors.green : Colors.blue,
                                        ),
                                        onPressed: () async {
                                          final ok = await askPassword();
                                          if (ok) {
                                            updateDebt(
                                                debt.id,
                                                Debt(
                                                  id: debt.id,
                                                  personName: debt.personName,
                                                  amount: debt.amount,
                                                  paidAmount: debt.amount,
                                                  type: debt.type,
                                                  description: debt.description,
                                                  date: debt.date,
                                                  dueDate: debt.dueDate,
                                                  isSettled: true,
                                                  payments: debt.payments,
                                                ));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Qarz yopildi!'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        },
                                        tooltip: debt.isSettled
                                            ? 'Yopildi'
                                            : 'To\'liq yopildi deb belgilash',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            size: 22, color: Colors.red),
                                        onPressed: () async {
                                          final ok = await askPassword();
                                          if (ok) {
                                            deleteDebt(debt.id);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('O\'chirildi'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDebtDialog(context),
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.indigo, size: 30),
      ),
    );
  }

  Widget _buildFilterChip(String value, bool isDark, {String? label}) {
    final isSelected = filterType == value;
    return GestureDetector(
      onTap: () => setState(() => filterType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? Colors.white : Colors.white54, width: 1.5),
        ),
        child: Text(
          label ?? value,
          style: TextStyle(
            color: isSelected ? Colors.indigo : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _showAddDebtDialog(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String type = 'owed_to_me';
    DateTime? selectedDueDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Yangi qarz qo\'shish'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                            labelText: 'Ism / Familiya',
                            border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(
                          labelText: 'Qarz turi', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(
                            value: 'owed_to_me',
                            child: Text('Menga berishi kerak (Yashil)')),
                        DropdownMenuItem(
                            value: 'owed_by_me',
                            child: Text('Men berishim kerak (Qizil)')),
                      ],
                      onChanged: (val) => setState(() => type = val!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                        controller: amountController,
                        decoration: const InputDecoration(
                            labelText: 'Summa (so\'m)',
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    TextField(
                        controller: descController,
                        decoration: const InputDecoration(
                            labelText: 'Izoh (ixtiyoriy)',
                            border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(selectedDueDate == null
                          ? 'Muddat tanlanmagan'
                          : DateFormat('dd.MM.yyyy').format(selectedDueDate!)),
                      trailing: const Icon(Icons.arrow_drop_down),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate:
                              DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (picked != null) {
                          setState(() => selectedDueDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Bekor qilish')),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty &&
                        amountController.text.isNotEmpty) {
                      addDebt(Debt(
                        id: DateTime.now().toString(),
                        personName: nameController.text,
                        amount: double.parse(amountController.text),
                        type: type,
                        description: descController.text,
                        date: DateTime.now(),
                        dueDate: selectedDueDate,
                      ));
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Saqlash'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}