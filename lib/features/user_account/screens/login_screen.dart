import 'package:flutter/material.dart';
import 'package:fuelwisee/shared/widgets/main_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../fuel_price/screens/home_screen.dart';
import 'signup_screen.dart';
import '../../../shared/widgets/main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: login,
                child: const Text("Login"),
              ),
            ),
            const SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                const Text(
                  "Don't have an account? ",
                ),

                GestureDetector(

                  onTap: () {

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignupScreen(),
                      ),
                    );

                  },

                  child: const Text(
                    "Sign Up",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void login() async {
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    // Check empty input
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    String savedEmail = prefs.getString('email') ?.trim() ?? '';
    String savedPassword = prefs.getString('password')?.trim() ?? '';


    // 👇 ADD HERE
    print("INPUT EMAIL: '$email'");
    print("INPUT PASSWORD: '$password'");

    print("SAVED EMAIL: '$savedEmail'");
    print("SAVED PASSWORD: '$savedPassword'");


    if (email == savedEmail && password == savedPassword) {

      await prefs.setBool('isLoggedIn', true);

      bool loggedIn = prefs.getBool('isLoggedIn') ?? false;
      print("isLoggedIn set to: $loggedIn");

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainNavigation(),
          ),
        );
      }

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid email or password")),
      );

    }
  }
}