import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/app_provider.dart';

void main() {
  runApp(const LegalAssistApp());
}

class LegalAssistApp extends StatelessWidget {
  const LegalAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: MaterialApp(
        title: 'Legal Assist',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // 公安蓝 + 科技感配色
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF003366),  // 深蓝（警徽色）
            brightness: Brightness.dark,
            primary: const Color(0xFF003366),
            secondary: const Color(0xFF00CED1),   // 科技青
            surface: const Color(0xFF0A1929),     // 深色背景
            tertiary: const Color(0xFFD4AF37),    // 金色点缀
          ),
          fontFamily: 'Simsun-ExtG',
          textTheme: Typography.material2021(platform: TargetPlatform.windows).white.apply(
            fontFamily: 'Simsun-ExtG',
            fontFamilyFallback: ['SimSun', 'Microsoft YaHei'],
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
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
        buttonTheme: const ButtonThemeData(
            buttonColor: Color(0xFF003366),
            textTheme: ButtonTextTheme.primary,
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF003366),
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
