import 'package:flutter/material.dart';
import 'api_service.dart';
import 'login_screen.dart';

void main() {
  // Ensure Flutter bindings are initialized
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
      theme: ThemeData.dark(),
      home: const LoginScreen(),
    );
  }
}