import 'package:flutter/material.dart';
import 'api_service.dart';
import 'login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ApiService.init(); 
  runApp(const SyncinemaApp());
}

class SyncinemaApp extends StatelessWidget {
  const SyncinemaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Syncinema',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.black,
        cardColor: Colors.black,
        dividerColor: Colors.white.withOpacity(0.15),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          surface: Colors.black,
          background: Colors.black,
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}