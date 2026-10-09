import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const FlashcardApp());
}

class FlashcardApp extends StatelessWidget {
  const FlashcardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: "Flashcard Quiz",

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFAB47BC),
          brightness: Brightness.light,
        ),

        scaffoldBackgroundColor: const Color(0xFFFFF7FC),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE8D5F5),
          foregroundColor: Color(0xFF6A1B9A),
          centerTitle: true,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
          ),
        ),
      ),

      home: const HomeScreen(),
    );
  }
}