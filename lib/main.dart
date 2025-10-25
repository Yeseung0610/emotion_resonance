import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'screens/camera_screen.dart';
import 'features/dashboard/dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emotion Resonance',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF000000),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00FF88),
          secondary: const Color(0xFF00CCFF),
          surface: const Color(0xFF1A1A1A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF000000),
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF1A1A1A),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      // Show Dashboard on Web, Camera on Mobile
      home: kIsWeb
          ? const DashboardScreen(
              serverUrl: 'http://localhost:8080',
            )
          : const CameraScreen(),
    );
  }
}
