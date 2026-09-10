import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = "Loading...";
  String email = "Loading...";
  String phone = "Loading...";
  String? profileImageUrl;
  bool isMalaysian = true;
  String? icNumber;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final supabase = Supabase.instance.client;

      final currentUser = supabase.auth.currentUser;

      if (currentUser == null) {
        return;
      }

      final profile = await supabase
          .from('user')
          .select('full_name, phone_number, profile_image_url, is_malaysian, ic_number',)
          .eq('user_id', currentUser.id)
          .single();

      if (mounted) {
        setState(() {
          name = profile['full_name'] ?? "No name";
          email = currentUser.email ?? "No email";
          phone = profile['phone_number'] ?? "No phone";
          profileImageUrl = profile['profile_image_url'];
          isMalaysian = profile['is_malaysian'] ?? true;
          icNumber = profile['ic_number'];
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              ).then((_) {
                loadProfile();
              });
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            // Profile image
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: profileImageUrl != null &&
                  profileImageUrl!.isNotEmpty
                  ? NetworkImage(
                '${profileImageUrl!}?t=${DateTime.now().millisecondsSinceEpoch}',
              )
                  : const AssetImage(
                'assets/images/default_image.jpg',
              ) as ImageProvider,
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
            const SizedBox(height: 15),



          ],
        ),
      ),
    );
  }
}