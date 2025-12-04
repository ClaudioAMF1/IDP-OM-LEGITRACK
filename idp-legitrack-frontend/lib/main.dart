import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const LegitrackApp());
}

class LegitrackApp extends StatelessWidget {
  const LegitrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LegiTrack',
      debugShowCheckedModeBanner: false, // Remove a faixa de "Debug" no canto
      theme: ThemeData(
        // Vamos definir a cor primária baseada no azul do seu design
        primarySwatch: Colors.blue,
        useMaterial3: true,
        // Definindo um fundo branco padrão para o app
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const LoginScreen(),
    );
  }
}