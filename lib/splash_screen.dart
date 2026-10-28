import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'auth_service.dart';
import 'login_screen.dart';
import 'main.dart';

const String passwordBoxName = 'app_password_box';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      // Foydalanuvchi kirgan - parolni tekshirish
      final box = await Hive.openBox(passwordBoxName);
      final password = box.get('app_password');
      
      if (password == null) {
        // Birinchi marta - parol o'rnatish
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        // Parol mavjud - parol kiritish ekrani
        _showPasswordEntry(password);
      }
    } else {
      // Foydalanuvchi kirmagan - login ekrani
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _showPasswordEntry(String savedPassword) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock, color: Colors.indigo),
              SizedBox(width: 10),
              Text('Ilovaga kirish'),
            ],
          ),
          content: TextField(
            controller: controller,
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
            ElevatedButton(
              onPressed: () {
                if (controller.text == savedPassword) {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomePage(
                        onThemeChanged: (mode) {},
                        currentTheme: ThemeMode.system,
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
                  controller.clear();
                }
              },
              child: const Text('Kirish'),
            ),
          ],
        );
      },
    );
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
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 100,
                color: Colors.white,
              ),
              SizedBox(height: 20),
              Text(
                'Kunlik xarajatlar',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 30),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}