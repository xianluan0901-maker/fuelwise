import 'package:flutter/material.dart';
import 'package:fuelwisee/shared/widgets/main_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/user_account/screens/signup_screen.dart';
import 'features/user_account/screens/login_screen.dart';
import 'features/fuel_price/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://bqwvctzyijyfdefjrubj.supabase.co',
    publishableKey: 'sb_publishable_CabkXlDKHbbDH_rsTBL_nQ_JGsMugax',
  );

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Debug: Print all stored data
  Set<String> keys = prefs.getKeys();
  print("All stored keys: $keys");

  for (String key in keys) {
    print("$key: ${prefs.get(key)}");
  }

  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(
    MainApp(
      isLoggedIn: isLoggedIn,
    ),
  );
}

class MainApp extends StatelessWidget {
  final bool isLoggedIn;

  const MainApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? const MainNavigation() : const LoginScreen(),
    );
  }
}