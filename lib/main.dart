import 'package:flutter/material.dart';
import 'core/themes/app_theme.dart';
import 'presentation/pages/home/home_page.dart';

void main() {
  runApp(RadioApp());
}

class RadioApp extends StatelessWidget {
  const RadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'El Contraste App',
      theme: AppTheme.darkTheme,
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
