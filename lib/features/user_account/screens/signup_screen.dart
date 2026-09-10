import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

      return oldValue;
    }

    onExceeded(false);

    return newValue;
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneNumController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  String? nameError;
  String? emailError;
  String? phoneError;
  String? passwordError;
  String? confirmPasswordError;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneNumController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Icon(
                Icons.local_gas_station,
                size: 80,
              ),

              const SizedBox(height: 20),

              TextField(
                controller: nameController,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r"[a-zA-Z\s]"),
                  ),
                  MaxLengthInputFormatter(
                    maxLength: 50,
                    onExceeded: (isExceeded) {
                      setState(() {
                        nameError = isExceeded
                            ? 'Name cannot exceed 50 characters.'
                            : null;
                      });
                    },
                  ),
                ],
                decoration: InputDecoration(
                  labelText: "Full Name",
                  border: const OutlineInputBorder(),
                  errorText: nameError,
                ),
              ),

              const SizedBox(height: 15),

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
                controller: phoneNumController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  MaxLengthInputFormatter(
                    maxLength: 11,
                    onExceeded: (isExceeded) {
                      setState(() {
                        phoneError = isExceeded
                            ? 'Phone number cannot exceed 11 digits.'
                            : null;
                      });
                    },
                  ),
                ],
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  border: const OutlineInputBorder(),
                  errorText: phoneError,
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: passwordController,
                obscureText: true,
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
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                inputFormatters: [
                  MaxLengthInputFormatter(
                    maxLength: 20,
                    onExceeded: (isExceeded) {
                      setState(() {
                        confirmPasswordError = isExceeded
                            ? 'Confirm password cannot exceed 20 characters.'
                            : null;
                      });
                    },
                  ),
                ],
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  border: const OutlineInputBorder(),
                  errorText: confirmPasswordError,
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: signup,
                  child: const Text("Sign Up"),
                ),
              ),

              const SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Login",
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
      ),
    );
  }

  Future<void> signup() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneNumController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    // Check empty fields
    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields.'),
        ),
      );
      return;
    }

    // Validate email
    final emailRegex = RegExp(
      r'^[\w\.-]+@[\w\.-]+\.\w+$',
    );

    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid email address (e.g. name@example.com).',
          ),
        ),
      );
      return;
    }

    // Validate Malaysian phone number
    final phoneRegex = RegExp(r'^01\d{8,9}$');

    if (!phoneRegex.hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid Malaysian phone number (e.g. 0123456789).',
          ),
        ),
      );
      return;
    }

    // Check password match
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The passwords do not match. Please check and try again.',
          ),
        ),
      );
      return;
    }


    try {
      final supabase = Supabase.instance.client;

      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'phone_number': phone,
        },
      );

      // Check whether account was created
      if (response.user != null) {
        // Sign out immediately so the newly registered user
        // must login manually.
        await supabase.auth.signOut();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account created! Please login."),
            ),
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
                (route) => false,
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Something went wrong."),
          ),
        );
      }
    }
  }
}