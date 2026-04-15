import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/hive_service.dart';
import 'providers/timer_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive and open storage boxes
  await HiveService.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => TimerProvider()..loadFromStorage(),
      child: const SchedulerApp(),
    ),
  );
}

class SchedulerApp extends StatelessWidget {
  const SchedulerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Work Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          // Backgrounds
          surface: Color(0xFF1A2640),
          surfaceContainerHighest: Color(0xFF1E2D45),
          // Primary teal (buttons, active timer, icons)
          primary: Color(0xFF4DB896),
          onPrimary: Color(0xFF0F1A28),
          // Secondary teal (lighter variant)
          secondary: Color(0xFF6ECFAC),
          onSecondary: Color(0xFF0F1A28),
          // Tertiary (on-break state)
          tertiary: Color(0xFF8EDBBF),
          onTertiary: Color(0xFF0F1A28),
          // Outlines / dividers
          outline: Color(0xFF4A6080),
          outlineVariant: Color(0xFF2A3D55),
          // Text on surfaces
          onSurface: Color(0xFFE8DCC8),
          onSurfaceVariant: Color(0xFFAABBCC),
          // Error
          error: Color(0xFFFF6B6B),
          onError: Color(0xFF0F1A28),
        ),
        scaffoldBackgroundColor: const Color(0xFF131D2E),
        cardTheme: const CardThemeData(
          color: Color(0xFF1A2640),
          surfaceTintColor: Colors.transparent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF131D2E),
          foregroundColor: Color(0xFFE8DCC8),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
