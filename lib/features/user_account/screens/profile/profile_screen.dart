import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = "Loading...";
  String email = "Loading...";
  String phone = "Loading...";

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final supabase = Supabase.instance.client;

      // Get currently logged-in user
      final currentUser = supabase.auth.currentUser;

      if (currentUser == null) {
        return;
      }

      // Email comes from Supabase Authentication
      final userEmail = currentUser.email ?? "No email";

      // Get user's profile information
      final profile = await supabase
          .from('user')
          .select('full_name, phone_number')
          .eq('user_id', currentUser.id)
          .single();

      if (mounted) {
        setState(() {
          name = profile['full_name'] ?? "No name";
          email = userEmail;
          phone = profile['phone_number'] ?? "No phone";
        });
      }
    } catch (e) {
      print("PROFILE ERROR: $e");

      if (mounted) {
        setState(() {
          name = "Unable to load";
          email = "Unable to load";
          phone = "Unable to load";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            // Profile image
            const CircleAvatar(
              radius: 60,
              child: Icon(
                Icons.person,
                size: 60,
              ),
            ),

            const SizedBox(height: 20),

            // Full name
            Text(
              name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            // Full Name
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text("Full Name"),
                subtitle: Text(name),
              ),
            ),

            const SizedBox(height: 15),

            // Email
            Card(
              child: ListTile(
                leading: const Icon(Icons.email),
                title: const Text("Email"),
                subtitle: Text(email),
              ),
            ),

            const SizedBox(height: 15),

            // Phone
            Card(
              child: ListTile(
                leading: const Icon(Icons.phone),
                title: const Text("Phone Number"),
                subtitle: Text(phone),
              ),
            ),
          ],
        ),
      ),
    );
  }
}