import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/user_account/screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://bqwvctzyijyfdefjrubj.supabase.co',
    publishableKey: 'sb_publishable_CabkXlDKHbbDH_rsTBL_nQ_JGsMugax',
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1687E8);
    const darkBlue = Color(0xFF123A63);
    const backgroundColour = Color(0xFFF5F7FA);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FuelWise MY',

      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundColour,

        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
          secondary: const Color(0xFF52B6F4),
          surface: Colors.white,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: darkBlue,
          elevation: 0,
          centerTitle: false,
        ),

        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            color: darkBlue,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: TextStyle(
            color: darkBlue,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            color: darkBlue,
            fontWeight: FontWeight.w600,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF61758A),
          ),
        ),
      ),

      home: const LoginScreen(),
    );
  }
}