import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Color(0xFF0B375E),
    scaffoldBackgroundColor: Color(0xFF0B375E),
    colorScheme: ColorScheme.dark(
      primary: Colors.blueGrey,
      secondary: Colors.tealAccent,
      surface: Colors.grey[800]!,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Color.fromARGB(255, 8, 39, 66),
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
