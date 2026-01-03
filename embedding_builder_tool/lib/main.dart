import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/app_provider.dart';

void main() {
  runApp(const EmbeddingBuilderApp());
}

class EmbeddingBuilderApp extends StatelessWidget {
  const EmbeddingBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: MaterialApp(
        title: 'Embedding Builder Tool',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E3A5F),
            brightness: Brightness.dark,
          ),
          fontFamily: 'Simsun-ExtG',
          useMaterial3: true,
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
          ),
        filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF1E3A5F),
              disabledBackgroundColor: Colors.grey.shade800,
              disabledForegroundColor: Colors.grey.shade500,
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
