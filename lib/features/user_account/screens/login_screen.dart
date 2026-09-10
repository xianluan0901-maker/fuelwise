import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/widgets/bottom_nav_bar.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'package:flutter/services.dart';

class MaxLengthInputFormatter extends TextInputFormatter {
  final int maxLength;
  final void Function(bool isExceeded) onExceeded;

  MaxLengthInputFormatter({
    required this.maxLength,
    required this.onExceeded,
  });

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (newValue.text.length > maxLength) {
      onExceeded(true);

      // Keep the old value, so the 21st character is NOT entered
      return oldValue;
    }

    onExceeded(false);
    return newValue;
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;
  String? passwordError;
  String? emailError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,

              inputFormatters: [
                MaxLengthInputFormatter(
                  maxLength: 100,
                  onExceeded: (isExceeded) {
                    setState(() {
                      emailError = isExceeded
                          ? 'Email cannot exceed 100 characters.'
                          : null;
                    });
                  },
                ),
              ],

              decoration: InputDecoration(
                labelText: "Email",
                border: const OutlineInputBorder(),
                errorText: emailError,
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: passwordController,
              obscureText: _obscurePassword,

              inputFormatters: [
                MaxLengthInputFormatter(
                  maxLength: 20,
                  onExceeded: (isExceeded) {
                    setState(() {
                      passwordError = isExceeded
                          ? 'Password cannot exceed 20 characters.'
                          : null;
                    });
                  },
                ),
              ],

              decoration: InputDecoration(
                labelText: "Password",
                border: const OutlineInputBorder(),
                errorText: passwordError,

                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : login,
                child: isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Text("Login"),
              ),
            ),

            const SizedBox(height: 15),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                      const ForgotPasswordScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Forgot Password?',
                ),
              ),
            ),

            const SizedBox(height: 5),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? "),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const SignupScreen(),
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

  Future<void> login() async {
    if (isLoading) return;

    print("LOGIN BUTTON CLICKED");

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email and password.'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response =
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print("LOGIN RESPONSE RECEIVED");
      print("USER: ${response.user}");
      print("SESSION: ${response.session}");

      if (response.user != null && response.session != null) {
        print("LOGIN SUCCESS");
        print("USER ID: ${response.user!.id}");
        print("EMAIL: ${response.user!.email}");
        print("NAVIGATING TO BOTTOM NAV");

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const BottomNavBar(),
          ),
              (route) => false,
        );
      }
    } on AuthException catch (e) {
      print("LOGIN FAILED: ${e.message}");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
        ),
      );
    } catch (e) {
      print("LOGIN ERROR: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}