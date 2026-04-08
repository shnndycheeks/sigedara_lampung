import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const GerCepMajuApp());
}

class GerCepMajuApp extends StatelessWidget {
  const GerCepMajuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GerCep Maju',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const SplashScreen(),
    );
  }
}
