import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'auth_service.dart';
import 'main.dart';

const String passwordBoxName = 'app_password_box';

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
  bool _isLoading = true;
  bool _isFirstTime = true;
  String? _savedPassword;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _showPasswordSetup = false;

  @override
  void initState() {
    super.initState();
    _checkPassword();
    _trySilentSignIn();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkPassword() async {
    final box = await Hive.openBox(passwordBoxName);
    final password = box.get('app_password');
    setState(() {
      _savedPassword = password;
      _isFirstTime = password == null;
    });
  }

  Future<void> _trySilentSignIn() async {
    final userCredential = await AuthService.signInSilently();

    // Splash screen'ni o'chirish
    FlutterNativeSplash.remove();

    setState(() {
      _isLoading = false;
    });

    if (userCredential != null) {
      if (_isFirstTime) {
        setState(() {
          _showPasswordSetup = true;
        });
      } else {
        _showPasswordEntry();
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    final userCredential = await AuthService.signInWithGoogle();

    setState(() {
      _isLoading = false;
    });

    if (userCredential != null) {
      if (_isFirstTime) {
        setState(() {
          _showPasswordSetup = true;
        });
      } else {
        _showPasswordEntry();
      }
    }
  }

  void _showPasswordEntry() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.lock,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.indigo,
              ),
              const SizedBox(width: 10),
              Text(
                'Ilovaga kirish',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ],
          ),
          content: TextField(
            controller: _passwordController,
            obscureText: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8),
            decoration: const InputDecoration(
              hintText: '****',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 20),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Bekor qilish'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_passwordController.text == _savedPassword) {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomePage(
                        onThemeChanged: widget.onThemeChanged,
                        currentTheme: widget.currentTheme,
                      ),
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
              },
              child: const Text('Kirish'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _savePassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parol kamida 4 ta raqam bo\'lishi kerak!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parollar mos kelmadi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final box = await Hive.openBox(passwordBoxName);
    await box.put('app_password', password);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(
          onThemeChanged: widget.onThemeChanged,
          currentTheme: widget.currentTheme,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 30),
                    const Icon(Icons.account_circle, size: 70, color: Colors.white),
                    const SizedBox(height: 15),
                    const Text(
                      'Kunlik xarajatlar',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _showPasswordSetup
                          ? 'Ilova parolini o\'rnating'
                          : 'Davom etish uchun Google hisobingiz bilan kiring',
                      style: const TextStyle(fontSize: 15, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    if (_isLoading) ...[
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 20),
                      const Text(
                        'Tekshirilmoqda...',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ] else if (_showPasswordSetup) ...[
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          letterSpacing: 8,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Parol',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          letterSpacing: 8,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Parolni tasdiqlang',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _savePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.indigo,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'Parolni saqlash',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _signInWithGoogle,
                          icon: const Icon(Icons.login, color: Colors.indigo),
                          label: const Text(
                            'Google bilan kirish',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.indigo,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 15),
                    const Text(
                      'Ma\'lumotlaringiz xavfsiz saqlanadi',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}