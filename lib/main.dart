import 'package:flutter/material.dart';
import 'package:fuelwisee/shared/widgets/bottom_nav_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/user_account/screens/login_screen.dart';
import 'features/fuel_price/screens/home_screen.dart';
import 'features/user_account/screens/reset_password_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://bqwvctzyijyfdefjrubj.supabase.co',
    publishableKey: 'sb_publishable_CabkXlDKHbbDH_rsTBL_nQ_JGsMugax',

  );

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}


class _MainAppState extends State<MainApp> {
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
          backgroundColor: Color(0xFFE1F2FF),
          foregroundColor: Color(0xFF153B60),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          toolbarHeight: 56,
          titleTextStyle: TextStyle(
            color: Color(0xFF153B60),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(
            color: Color(0xFF153B60),
          ),
          actionsIconTheme: IconThemeData(
            color: Color(0xFF153B60),
          ),
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

      home: const AuthGate(),
    );
  }
}
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool isPasswordRecovery = false;
  bool recoveryNavigationDone = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // ---------------------------------------------------------
        // Password recovery
        // ---------------------------------------------------------
        if (snapshot.hasData) {
          final authState = snapshot.data!;
          final event = authState.event;

          debugPrint('AUTH EVENT: $event');
          debugPrint(
            'SESSION EXISTS: ${authState.session != null}',
          );

          if (event == AuthChangeEvent.passwordRecovery) {
            debugPrint('PASSWORD RECOVERY DETECTED');
            debugPrint('RECOVERY EVENT SESSION: ${authState.session}');
            debugPrint(
              'CURRENT SESSION: ${Supabase.instance.client.auth.currentSession}',
            );

            isPasswordRecovery = true;

            if (!recoveryNavigationDone) {
              recoveryNavigationDone = true;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const ResetPasswordScreen(),
                  ),
                      (route) => false,
                );
              });
            }
          }

          // ---------------------------------------------------------
          // User signed out
          // ---------------------------------------------------------
          if (event == AuthChangeEvent.signedOut) {
            debugPrint('USER SIGNED OUT');

            isPasswordRecovery = false;
            recoveryNavigationDone = false;
          }
        }

        // ---------------------------------------------------------
        // Password recovery screen
        // ---------------------------------------------------------
        if (isPasswordRecovery) {
          return const ResetPasswordScreen();
        }

        // ---------------------------------------------------------
        // Check current Supabase session
        // ---------------------------------------------------------
        final session =
            Supabase.instance.client.auth.currentSession;

        if (session != null) {
          debugPrint('SHOWING BOTTOM NAV');
          return const BottomNavBar();
        }

        // ---------------------------------------------------------
        // No session = Login
        // ---------------------------------------------------------
        debugPrint('SHOWING LOGIN');
        return const LoginScreen();
      },
    );
  }
}