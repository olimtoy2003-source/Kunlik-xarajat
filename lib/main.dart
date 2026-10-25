import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'statistics_screen.dart';

const String expensesBoxName = 'expenses_box';
const String passwordBoxName = 'password_box';
const String settingsBoxName = 'settings_box';

String formatMoney(double amount) {
  final formatter = NumberFormat('#,###');
  return formatter.format(amount).replaceAll(',', '.');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      themeMode: _themeMode,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF667eea),
          secondary: Color(0xFF764ba2),
          surface: Color(0xFF1E1E1E),
        ),
      ),
      home: LoginScreen(onThemeChanged: setThemeMode, currentTheme: _themeMode),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final void Function(ThemeMode) onThemeChanged;
  final ThemeMode currentTheme;

  const LoginScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentTheme,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool isFirstTime = true;
  String? savedPassword;

  @override
  void initState() {
    super.initState();
    _checkPassword();
  }

  Future<void> _checkPassword() async {
    final box = await Hive.openBox(passwordBoxName);
    final password = box.get('app_password');
    if (password != null) {
      setState(() {
        savedPassword = password;
        isFirstTime = false;
      });
    }
  }

  Future<void> _savePassword(String password) async {
    final box = await Hive.openBox(passwordBoxName);
    await box.put('app_password', password);
  }

  Future<void> _resetPassword() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 10),
            Text('Diqqat!'),
          ],
        ),
        content: const Text(
          'Parolni tiklash uchun barcha ma\'lumotlar (xarajatlar va parol) o\'chiriladi. Davom etasizmi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ha, o\'chirish'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final expensesBox = await Hive.openBox(expensesBoxName);
      final passwordBox = await Hive.openBox(passwordBoxName);
      final settingsBox = await Hive.openBox(settingsBoxName);
      
      await expensesBox.clear();
      await passwordBox.clear();
      await settingsBox.clear();
      
      await expensesBox.close();
      await passwordBox.close();
      await settingsBox.close();

      setState(() {
        savedPassword = null;
        isFirstTime = true;
        _passwordController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Barcha ma\'lumotlar o\'chirildi. Yangi parol o\'rnating.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 80, color: Colors.white),
                const SizedBox(height: 20),
                Text(
                  isFirstTime ? 'Parol o\'rnating' : 'Ilovaga kirish',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isFirstTime
                      ? 'Ilovani himoyalash uchun parol yarating'
                      : 'Davom etish uchun parolni kiriting',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    hintText: '****',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      final password = _passwordController.text.trim();
                      if (password.length < 4) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Parol kamida 4 ta raqam bo\'lishi kerak!'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (isFirstTime) {
                        _savePassword(password).then((_) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HomePage(onThemeChanged: widget.onThemeChanged, currentTheme: widget.currentTheme),
                            ),
                          );
                        });
                      } else {
                        if (password == savedPassword) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HomePage(onThemeChanged: widget.onThemeChanged, currentTheme: widget.currentTheme),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Parol noto\'g\'ri!'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          _passwordController.clear();
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.indigo,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      isFirstTime ? 'Parolni saqlash' : 'Kirish',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (!isFirstTime) ...[
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _resetPassword,
                    child: const Text(
                      'Parolni unutdingizmi?',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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
  String? _appPassword;
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
    _loadPassword();
    _loadStartDate();
  }

  Future<void> _loadData() async {
    _expensesBox = await Hive.openBox(expensesBoxName);
    final String? savedData = _expensesBox.get('expenses_list');
    
    if (savedData != null) {
      final List<dynamic> decodedData = jsonDecode(savedData);
      setState(() {
        expenses = decodedData.map((e) => Expense.fromMap(e)).toList();
      });
    }
  }

  Future<void> _loadPassword() async {
    final box = await Hive.openBox(passwordBoxName);
    setState(() {
      _appPassword = box.get('app_password');
    });
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
  }

  Future<void> _savePassword(String password) async {
    final box = await Hive.openBox(passwordBoxName);
    await box.put('app_password', password);
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
        e.date.year == now.year && e.date.month == now.month && e.date.day == now.day
      ).toList();
    } 
    else if (selectedDateFilter == 'Kecha') {
      final yesterday = now.subtract(const Duration(days: 1));
      result = result.where((e) =>
        e.date.year == yesterday.year && e.date.month == yesterday.month && e.date.day == yesterday.day
      ).toList();
    } 
    else if (selectedDateFilter == 'Shu hafta') {
      final mondayOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfMonday = DateTime(mondayOfThisWeek.year, mondayOfThisWeek.month, mondayOfThisWeek.day);
      result = result.where((e) => 
        e.date.isAfter(startOfMonday) || e.date.isAtSameMomentAs(startOfMonday)
      ).toList();
    } 
    else if (selectedDateFilter == 'Shu oy') {
      result = result.where((e) =>
        e.date.year == now.year && e.date.month == now.month
      ).toList();
    }

    return result;
  }

  double get totalExpenses {
    return filteredExpenses.fold(0, (sum, item) => sum + item.amount);
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
              Icon(Icons.lock, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.indigo),
              const SizedBox(width: 10),
              Text('Parolni kiriting', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)),
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

  Future<void> _changePassword() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Parolni o\'zgartirish'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Joriy parol',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Yangi parol',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Yangi parolni tasdiqlang',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Bekor qilish'),
            ),
            ElevatedButton(
              onPressed: () {
                if (currentController.text != _appPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Joriy parol noto\'g\'ri!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (newController.text.length < 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Yangi parol kamida 4 ta raqam bo\'lishi kerak!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (newController.text != confirmController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Yangi parollar mos kelmadi!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                _savePassword(newController.text).then((_) {
                  setState(() {
                    _appPassword = newController.text;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Parol muvaffaqiyatli o\'zgartirildi!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                });
              },
              child: const Text('Saqlash'),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sozlamalar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.lock, color: Colors.indigo),
              title: Text('Parolni o\'zgartirish', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              onTap: () {
                Navigator.pop(context);
                _changePassword();
              },
            ),
            ListTile(
              leading: Icon(
                _currentTheme == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                color: Colors.indigo,
              ),
              title: Text('Qorong\'u rejim', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              subtitle: Text(
                _currentTheme == ThemeMode.dark ? 'Yoqilgan' : 'O\'chirilgan',
                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              trailing: Switch(
                value: _currentTheme == ThemeMode.dark,
                onChanged: (value) {
                  final newMode = value ? ThemeMode.dark : ThemeMode.light;
                  setState(() {
                    _currentTheme = newMode;
                  });
                  widget.onThemeChanged(newMode);
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.blue),
              title: Text('Ilova $_daysCount kundan beri ishlayapti', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              subtitle: _startDate != null
                  ? Text('Boshlangan sana: ${DateFormat('dd.MM.yyyy').format(_startDate!)}', 
                      style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]))
                  : null,
              onTap: () => Navigator.pop(context),
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
      appBar: AppBar(
        title: const Text('Kunlik xarajatlar', style: TextStyle(color: Colors.white)),
        backgroundColor: isDark ? const Color(0xFF1a1a2e) : const Color(0xFF667eea),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
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
        ],
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                children: [
                  const Text(
                    'Jami xarajat',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${formatMoney(totalExpenses)} so\'m',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          '${_daysCount} kundan beri nazoratda',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Container(
              height: 55,
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.white54,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            category,
                            style: TextStyle(
                              color: isSelected ? Colors.indigo : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Container(
              height: 45,
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: dateFilters.length,
                itemBuilder: (context, index) {
                  final filter = dateFilters[index];
                  final isSelected = selectedDateFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDateFilter = filter;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.white54,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected ? Colors.indigo : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(0),
                    bottomRight: Radius.circular(0),
                  ),
                ),
                child: filteredExpenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: isDark ? Colors.grey[700] : Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'Hali xarajat qo\'shilmagan',
                              style: TextStyle(fontSize: 16, color: isDark ? Colors.grey[500] : Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: filteredExpenses.length,
                        itemBuilder: (context, index) {
                          final expense = filteredExpenses[index];
                          final icon = categoryIcons[expense.category] ?? Icons.category;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            elevation: 3,
                            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(icon, color: Colors.indigo, size: 28),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          expense.displayName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          expense.description,
                                          style: TextStyle(
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('dd.MM.yyyy HH:mm').format(expense.date),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${formatMoney(expense.amount)} so\'m',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.indigo,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 20, color: Colors.orange),
                                            onPressed: () async {
                                              final ok = await askPassword();
                                              if (ok) _showEditDialog(context, expense);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                            onPressed: () async {
                                              final ok = await askPassword();
                                              if (ok) {
                                                deleteExpense(expense.id);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('O\'chirildi')),
                                                );
                                              }
                                            },
                                          ),
                                        ],
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
            backgroundColor: Colors.white,
            child: const Icon(Icons.pie_chart, color: Colors.indigo, size: 30),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            onPressed: () => _showAddExpenseDialog(context),
            backgroundColor: Colors.white,
            child: const Icon(Icons.add, color: Colors.indigo, size: 30),
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
              title: const Text('Yangi xarajat qo\'shish'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCat,
                      decoration: const InputDecoration(labelText: 'Kategoriya', border: OutlineInputBorder()),
                      items: categories.where((c) => c != 'Barchasi').map((category) => DropdownMenuItem(
                            value: category,
                            child: Row(children: [Icon(categoryIcons[category], size: 20), const SizedBox(width: 10), Text(category)]),
                          )).toList(),
                      onChanged: (value) {
                        setState(() { selectedCat = value!; });
                      },
                    ),
                    if (selectedCat == 'Yoqilg\'i') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedFuel,
                        decoration: const InputDecoration(labelText: 'Yoqilg\'i turi', border: OutlineInputBorder()),
                        items: fuelTypes.map((fuel) => DropdownMenuItem(value: fuel, child: Text(fuel))).toList(),
                        onChanged: (value) {
                          setState(() { selectedFuel = value!; });
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Summa (so\'m)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Izoh (ixtiyoriy)', border: OutlineInputBorder())),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
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
              title: const Text('Xarajatni tahrirlash'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCat,
                      decoration: const InputDecoration(labelText: 'Kategoriya', border: OutlineInputBorder()),
                      items: categories.where((c) => c != 'Barchasi').map((category) => DropdownMenuItem(
                            value: category,
                            child: Row(children: [Icon(categoryIcons[category], size: 20), const SizedBox(width: 10), Text(category)]),
                          )).toList(),
                      onChanged: (value) {
                        setState(() { selectedCat = value!; });
                      },
                    ),
                    if (selectedCat == 'Yoqilg\'i') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedFuel,
                        decoration: const InputDecoration(labelText: 'Yoqilg\'i turi', border: OutlineInputBorder()),
                        items: fuelTypes.map((fuel) => DropdownMenuItem(value: fuel, child: Text(fuel))).toList(),
                        onChanged: (value) {
                          setState(() { selectedFuel = value!; });
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Summa (so\'m)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Izoh (ixtiyoriy)', border: OutlineInputBorder())),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
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
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tahrirlandi')));
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