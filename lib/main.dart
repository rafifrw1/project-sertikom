import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/login_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set default credentials if not yet saved
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getString('username') == null) {
    await prefs.setString('username', 'user');
    await prefs.setString('password', 'user');
  }

  runApp(const AgendaNusantaraApp());
}

class AgendaNusantaraApp extends StatelessWidget {
  const AgendaNusantaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agenda Nusantara',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE91E63)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE91E63),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const LoginPages(),
    );
  }
}