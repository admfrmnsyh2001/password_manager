import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/master_password_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Disable online fetching for google_fonts to ensure 100% offline capability
  GoogleFonts.config.allowRuntimeFetching = false;
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Password Manager',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F12),
      ),
      home: const MasterPasswordScreen(),
    );
  }
}
