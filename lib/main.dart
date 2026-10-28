import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'dart:convert';
import 'statistics_screen.dart';
import 'debt_screen.dart';
import 'firebase_service.dart';
import 'auth_service.dart';
import 'login_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/modern_button.dart';
import 'widgets/modern_card.dart';
import 'widgets/modern_text_field.dart';

const String expensesBoxName = 'expenses_box';
const String settingsBoxName = 'settings_box';
const String passwordBoxName = 'app_password_box';

String formatMoney(double amount) {
  final formatter = NumberFormat('#,###');
  return formatter.format(amount).replaceAll(',', '.');
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp();
  await Hive.initFlutter();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final box = await Hive.openBox(settingsBoxName);
    final String? savedTheme = box.get('theme_mode');
    setState(() {
      if (savedTheme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (savedTheme == 'light') {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.system;
      }
    });
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    final box = await Hive.openBox(settingsBoxName);
    String modeString = 'system';
    if (mode == ThemeMode.dark) modeString = 'dark';
    if (mode == ThemeMode.light) modeString = 'light';
    await box.put('theme_mode', modeString);
    setState(() {
      _themeMode = mode;
    });
  }

  void setThemeMode(ThemeMode mode) {
    _saveThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kunlik xarajatlar',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: LoginScreen(
        onThemeChanged: setThemeMode,
        currentTheme: _themeMode,
      ),
    );
  }
}

class Expense {
  String id;
  double amount;
  String category;
  String subCategory;
  String description;
  DateTime date;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    this.subCategory = '',
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'subCategory': subCategory,
      'description': description,
      'date': date.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      amount: map['amount'],
      category: map['category'],
      subCategory: map['subCategory'] ?? '',
      description: map['description'],
      date: DateTime.parse(map['date']),
    );
  }

  String get displayName {
    if (category == 'Yoqilg\'i' && subCategory.isNotEmpty) {
      return '$category ($subCategory)';
    }
    return category;
  }
}

class HomePage extends StatefulWidget {
  final void Function(ThemeMode) onThemeChanged;
  final ThemeMode currentTheme;

  const HomePage({
    super.key,
    required this.onThemeChanged,
    required this.currentTheme,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Expense> expenses = [];
  String selectedCategory = 'Barchasi';
  String selectedDateFilter = 'Barchasi';
  late Box _expensesBox;
  DateTime? _startDate;
  int _daysCount = 0;
  late ThemeMode _currentTheme;

  final Map<String, IconData> categoryIcons = {
    'Yo\'l': Icons.commute,
    'Yoqilg\'i': Icons.local_gas_station,
    'Oziq-ovqat': Icons.restaurant,
    'Kiyim-kechak': Icons.checkroom,
    'Kommunal': Icons.home,
    'Ko\'ngilochar': Icons.movie,
    'Sog\'liq': Icons.local_hospital,
    'Boshqa': Icons.category,
  };

  final Map<String, Color> categoryColors = {
    'Yo\'l': AppTheme.infoColor,
    'Yoqilg\'i': AppTheme.warningColor,
    'Oziq-ovqat': AppTheme.primaryColor,
    'Kiyim-kechak': AppTheme.accentColor,
    'Kommunal': AppTheme.successColor,
    'Ko\'ngilochar': const Color(0xFFf472b6),
    'Sog\'liq': const Color(0xFFfb7185),
    'Boshqa': Colors.grey,
  };

  final List<String> categories = [
    'Barchasi',
    'Yo\'l',
    'Yoqilg\'i',
    'Oziq-ovqat',
    'Kiyim-kechak',
    'Kommunal',
    'Ko\'ngilochar',
    'Sog\'liq',
    'Boshqa'
  ];

  final List<String> dateFilters = ['Barchasi', 'Bugun', 'Kecha', 'Shu hafta', 'Shu oy'];
  final List<String> fuelTypes = ['Benzin', 'Metan'];

  @override
  void initState() {
    super.initState();
    _currentTheme = widget.currentTheme;
    _loadData();
    _loadStartDate();
  }

  Future<void> _loadData() async {
    _expensesBox = await Hive.openBox(expensesBoxName);

    final firebaseExpenses = await FirebaseService.loadExpenses();

    if (firebaseExpenses.isNotEmpty) {
      setState(() {
        expenses = firebaseExpenses.map((e) => Expense.fromMap(e)).toList();
      });
      final String encodedData = jsonEncode(firebaseExpenses);
      await _expensesBox.put('expenses_list', encodedData);
    } else {
      final String? savedData = _expensesBox.get('expenses_list');
      if (savedData != null) {
        final List<dynamic> decodedData = jsonDecode(savedData);
        setState(() {
          expenses = decodedData.map((e) => Expense.fromMap(e)).toList();
        });
      }
    }
  }

  Future<void> _loadStartDate() async {
    final box = await Hive.openBox(settingsBoxName);
    final String? savedDate = box.get('start_date');

    if (savedDate != null) {
      setState(() {
        _startDate = DateTime.parse(savedDate);
        _daysCount = DateTime.now().difference(_startDate!).inDays + 1;
      });
    } else {
      final today = DateTime.now();
      await box.put('start_date', today.toIso8601String());
      setState(() {
        _startDate = today;
        _daysCount = 1;
      });
    }
  }

  Future<void> _saveData() async {
    final String encodedData = jsonEncode(expenses.map((e) => e.toMap()).toList());
    await _expensesBox.put('expenses_list', encodedData);

    final List<Map<String, dynamic>> expensesMaps = expenses.map((e) => e.toMap()).toList();
    await FirebaseService.saveExpenses(expensesMaps);
  }

  @override
  void dispose() {
    _expensesBox.close();
    super.dispose();
  }

  void addExpense(Expense expense) {
    setState(() {
      expenses.add(expense);
    });
    _saveData();
  }

  void updateExpense(String id, Expense updated) {
    setState(() {
      final index = expenses.indexWhere((e) => e.id == id);
      if (index != -1) {
        expenses[index] = updated;
      }
    });
    _saveData();
  }

  void deleteExpense(String id) {
    setState(() {
      expenses.removeWhere((e) => e.id == id);
    });
    _saveData();
  }

  List<Expense> get filteredExpenses {
    List<Expense> result = expenses;

    if (selectedCategory != 'Barchasi') {
      result = result.where((e) => e.category == selectedCategory).toList();
    }

    final now = DateTime.now();

    if (selectedDateFilter == 'Bugun') {
      result = result.where((e) =>
          e.date.year == now.year && e.date.month == now.month && e.date.day == now.day).toList();
    } else if (selectedDateFilter == 'Kecha') {
      final yesterday = now.subtract(const Duration(days: 1));
      result = result.where((e) =>
          e.date.year == yesterday.year &&
          e.date.month == yesterday.month &&
          e.date.day == yesterday.day).toList();
    } else if (selectedDateFilter == 'Shu hafta') {
      final mondayOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfMonday = DateTime(
          mondayOfThisWeek.year, mondayOfThisWeek.month, mondayOfThisWeek.day);
      result = result
          .where((e) =>
              e.date.isAfter(startOfMonday) ||
              e.date.isAtSameMomentAs(startOfMonday))
          .toList();
    } else if (selectedDateFilter == 'Shu oy') {
      result = result
          .where((e) => e.date.year == now.year && e.date.month == now.month)
          .toList();
    }

    return result;
  }

  double get totalExpenses {
    return filteredExpenses.fold(0, (sum, item) => sum + item.amount);
  }

  Future<bool> askPassword() async {
    final box = await Hive.openBox(passwordBoxName);
    final savedPassword = box.get('app_password');

    final controller = TextEditingController();
    bool result = false;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Parolni kiriting'),
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
                if (controller.text == savedPassword) {
                  result = true;
                  Navigator.pop(context);
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Parol noto\'g\'ri!'),
                      backgroundColor: AppTheme.errorColor,
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

  Future<void> _changePassword() async {
    final box = await Hive.openBox(passwordBoxName);
    final savedPassword = box.get('app_password');

    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Parolni o\'zgartirish'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModernTextField(
                controller: currentController,
                hintText: 'Joriy parol',
                labelText: 'Joriy parol',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              ModernTextField(
                controller: newController,
                hintText: 'Yangi parol',
                labelText: 'Yangi parol',
                prefixIcon: Icons.lock,
                obscureText: true,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              ModernTextField(
                controller: confirmController,
                hintText: 'Yangi parolni tasdiqlang',
                labelText: 'Tasdiqlash',
                prefixIcon: Icons.lock_clock,
                obscureText: true,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Bekor qilish'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (currentController.text != savedPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Joriy parol noto\'g\'ri!'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }
                if (newController.text.length < 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Yangi parol kamida 4 ta raqam bo\'lishi kerak!'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }
                if (newController.text != confirmController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Yangi parollar mos kelmadi!'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }

                await box.put('app_password', newController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Parol muvaffaqiyatli o\'zgartirildi!'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
              child: const Text('Saqlash'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut() async {
    try {
      final box = await Hive.openBox(passwordBoxName);
      await box.clear();

      await AuthService.signOut();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            onThemeChanged: widget.onThemeChanged,
            currentTheme: _currentTheme,
          ),
        ),
      );
    } catch (e) {
      print('Chiqishda xatolik: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xatolik: $e')),
      );
    }
  }

  void _showSettingsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1B2E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.settings, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Sozlamalar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SettingsTile(
              icon: Icons.lock,
              iconColor: AppTheme.primaryColor,
              title: 'Parolni o\'zgartirish',
              onTap: () {
                Navigator.pop(context);
                _changePassword();
              },
            ),
            _SettingsTile(
              icon: _currentTheme == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
              iconColor: AppTheme.infoColor,
              title: 'Qorong\'u rejim',
              subtitle: _currentTheme == ThemeMode.dark ? 'Yoqilgan' : 'O\'chirilgan',
              trailing: Switch(
                value: _currentTheme == ThemeMode.dark,
                activeColor: AppTheme.primaryColor,
                onChanged: (value) {
                  final newMode = value ? ThemeMode.dark : ThemeMode.light;
                  setState(() {
                    _currentTheme = newMode;
                  });
                  widget.onThemeChanged(newMode);
                },
              ),
            ),
            _SettingsTile(
              icon: Icons.info,
              iconColor: AppTheme.infoColor,
              title: 'Ilova $_daysCount kundan beri ishlayapti',
              subtitle: _startDate != null
                  ? 'Boshlangan sana: ${DateFormat('dd.MM.yyyy').format(_startDate!)}'
                  : null,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.logout,
              iconColor: AppTheme.errorColor,
              title: 'Chiqish',
              titleColor: AppTheme.errorColor,
              onTap: () {
                Navigator.pop(context);
                _signOut();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1020) : const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text(
          'Kunlik xarajatlar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: 'Qarz daftari',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DebtScreen(
                    onThemeChanged: widget.onThemeChanged,
                    currentTheme: _currentTheme,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
              setState(() {
                _currentTheme = newMode;
              });
              widget.onThemeChanged(newMode);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gradient Card - Jami xarajat
            GradientCard(
              title: 'Jami xarajat',
              value: '${formatMoney(totalExpenses)} so\'m',
              icon: Icons.account_balance_wallet,
              gradient: AppTheme.primaryGradient,
            ),
            const SizedBox(height: 12),

            // Kunlar soni
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1B2E) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    '${_daysCount} kundan beri nazoratda',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Kategoriya filtrlari
            const Text(
              'Kategoriyalar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectedCategory = category;
                          });
                        },
                        borderRadius: BorderRadius.circular(22),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            gradient: isSelected ? AppTheme.primaryGradient : null,
                            color: isSelected ? null : (isDark ? const Color(0xFF1A1B2E) : Colors.white),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
                              width: 1.5,
                            ),
                            boxShadow: isSelected ? AppTheme.softShadow : [],
                          ),
                          child: Center(
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Sana filtrlari
            const Text(
              'Sana bo\'yicha',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: dateFilters.length,
                itemBuilder: (context, index) {
                  final filter = dateFilters[index];
                  final isSelected = selectedDateFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectedDateFilter = filter;
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: isSelected ? AppTheme.accentGradient : null,
                            color: isSelected ? null : (isDark ? const Color(0xFF1A1B2E) : Colors.white),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              filter,
                              style: TextStyle(
                                color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Xarajatlar ro'yxati
            if (filteredExpenses.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1B2E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 64,
                      color: Colors.grey.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Hali xarajat qo\'shilmagan',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredExpenses.length,
                itemBuilder: (context, index) {
                  final expense = filteredExpenses[index];
                  final icon = categoryIcons[expense.category] ?? Icons.category;
                  final color = categoryColors[expense.category] ?? AppTheme.primaryColor;

                  return ExpenseCard(
                    title: expense.displayName,
                    subtitle: expense.description,
                    amount: '${formatMoney(expense.amount)} so\'m',
                    date: DateFormat('dd.MM.yyyy HH:mm').format(expense.date),
                    icon: icon,
                    iconColor: color,
                    onEdit: () async {
                      final ok = await askPassword();
                      if (ok) _showEditDialog(context, expense);
                    },
                    onDelete: () async {
                      final ok = await askPassword();
                      if (ok) {
                        deleteExpense(expense.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('O\'chirildi'),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StatisticsScreen(
                    expenses: filteredExpenses,
                    startDate: _startDate,
                  ),
                ),
              );
            },
            backgroundColor: AppTheme.secondaryColor,
            child: const Icon(Icons.pie_chart, size: 28),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            onPressed: () => _showAddExpenseDialog(context),
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.add, size: 28),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCat = 'Yo\'l';
    String selectedFuel = 'Benzin';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 10),
                  const Text('Yangi xarajat'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ModernTextField(
                      hintText: 'Summani kiriting',
                      labelText: 'Summa (so\'m)',
                      prefixIcon: Icons.attach_money,
                      controller: amountController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedCat,
                        decoration: const InputDecoration(
                          labelText: 'Kategoriya',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: categories
                            .where((c) => c != 'Barchasi')
                            .map((category) => DropdownMenuItem(
                                  value: category,
                                  child: Row(
                                    children: [
                                      Icon(categoryIcons[category], size: 20),
                                      const SizedBox(width: 10),
                                      Text(category),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCat = value!;
                          });
                        },
                      ),
                    ),
                    if (selectedCat == 'Yoqilg\'i') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedFuel,
                          decoration: const InputDecoration(
                            labelText: 'Yoqilg\'i turi',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: fuelTypes
                              .map((fuel) => DropdownMenuItem(
                                    value: fuel,
                                    child: Text(fuel),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedFuel = value!;
                            });
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ModernTextField(
                      hintText: 'Izoh yozing...',
                      labelText: 'Izoh (ixtiyoriy)',
                      prefixIcon: Icons.description,
                      controller: descriptionController,
                      maxLines: 3,
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
                  onPressed: () {
                    if (amountController.text.isNotEmpty) {
                      final expense = Expense(
                        id: DateTime.now().toString(),
                        amount: double.parse(amountController.text),
                        category: selectedCat,
                        subCategory: selectedCat == 'Yoqilg\'i' ? selectedFuel : '',
                        description: descriptionController.text,
                        date: DateTime.now(),
                      );
                      addExpense(expense);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Xarajat qo\'shildi!'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  },
                  child: const Text('Qo\'shish'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, Expense expense) {
    final amountController = TextEditingController(text: expense.amount.toString());
    final descriptionController = TextEditingController(text: expense.description);
    String selectedCat = expense.category;
    String selectedFuel = expense.subCategory.isEmpty ? 'Benzin' : expense.subCategory;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit, color: AppTheme.warningColor),
                  ),
                  const SizedBox(width: 10),
                  const Text('Tahrirlash'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ModernTextField(
                      hintText: 'Summani kiriting',
                      labelText: 'Summa (so\'m)',
                      prefixIcon: Icons.attach_money,
                      controller: amountController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedCat,
                        decoration: const InputDecoration(
                          labelText: 'Kategoriya',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: categories
                            .where((c) => c != 'Barchasi')
                            .map((category) => DropdownMenuItem(
                                  value: category,
                                  child: Row(
                                    children: [
                                      Icon(categoryIcons[category], size: 20),
                                      const SizedBox(width: 10),
                                      Text(category),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCat = value!;
                          });
                        },
                      ),
                    ),
                    if (selectedCat == 'Yoqilg\'i') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedFuel,
                          decoration: const InputDecoration(
                            labelText: 'Yoqilg\'i turi',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: fuelTypes
                              .map((fuel) => DropdownMenuItem(
                                    value: fuel,
                                    child: Text(fuel),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedFuel = value!;
                            });
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ModernTextField(
                      hintText: 'Izoh yozing...',
                      labelText: 'Izoh (ixtiyoriy)',
                      prefixIcon: Icons.description,
                      controller: descriptionController,
                      maxLines: 3,
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
                  onPressed: () {
                    if (amountController.text.isNotEmpty) {
                      final updated = Expense(
                        id: expense.id,
                        amount: double.parse(amountController.text),
                        category: selectedCat,
                        subCategory: selectedCat == 'Yoqilg\'i' ? selectedFuel : '',
                        description: descriptionController.text,
                        date: expense.date,
                      );
                      updateExpense(expense.id, updated);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tahrirlandi!'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
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

// ============================================
// Helper Widget: Settings Tile
// ============================================
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (trailing == null && onTap != null)
                Icon(Icons.chevron_right, color: isDark ? Colors.grey[600] : Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}