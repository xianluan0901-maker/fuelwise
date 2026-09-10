import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  bool nameTooLong = false;
  bool emailTooLong = false;
  bool phoneTooLong = false;

  bool isSaving = false;
  File? selectedImage;
  String? currentImageUrl;

  Future<void> pickProfileImage() async {
    try {
      final picker = ImagePicker();

      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() {
        selectedImage = File(image.path);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select image: $e'),
          ),
        );
      }
    }
  }
  Future<String?> uploadProfileImage(String userId) async {
    if (selectedImage == null) {
      return currentImageUrl;
    }

    try {
      final supabase = Supabase.instance.client;

      final filePath = '$userId/profile.jpg';

      await supabase.storage
          .from('profile-images')
          .upload(
        filePath,
        selectedImage!,
        fileOptions: const FileOptions(
          upsert: true,
        ),
      );

      final imageUrl = supabase.storage
          .from('profile-images')
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();

    nameController.addListener(() {
      if (nameController.text.length >= 50) {
        setState(() {
          nameTooLong = true;
        });
      } else {
        setState(() {
          nameTooLong = false;
        });
      }
    });

    emailController.addListener(() {
      if (emailController.text.length >= 100) {
        setState(() {
          emailTooLong = true;
        });
      } else {
        setState(() {
          emailTooLong = false;
        });
      }
    });

    phoneController.addListener(() {
      if (phoneController.text.length >= 11) {
        setState(() {
          phoneTooLong = true;
        });
      } else {
        setState(() {
          phoneTooLong = false;
        });
      }
    });

    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) return;

      final profile = await supabase
          .from('user')
          .select('full_name, phone_number, profile_image_url')
          .eq('user_id', user.id)
          .single();

      if (mounted) {
        setState(() {
          nameController.text =
              profile['full_name']?.toString() ?? '';

          phoneController.text =
              profile['phone_number']?.toString() ?? '';

          emailController.text =
              user.email ?? '';
          currentImageUrl =
              profile['profile_image_url']?.toString();
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('No logged-in user found.');
      }

      // Update name, phone and profile image
      final imageUrl = await uploadProfileImage(user.id);

      await supabase
          .from('user')
          .update({
        'full_name': nameController.text.trim(),
        'phone_number': phoneController.text.trim(),
        'profile_image_url': imageUrl,
      })
          .eq('user_id', user.id);
      // Update email without email verification
      final newEmail = emailController.text.trim();

      if (newEmail != (user.email ?? '')) {
        final response = await supabase.functions.invoke(
          'update-email',
          body: {
            'email': newEmail,
          },
        );

        debugPrint('EMAIL FUNCTION RESPONSE: ${response.data}');

        if (response.data == null ||
            response.data['success'] != true) {
          throw Exception(
            response.data?['error'] ?? 'Failed to update email.',
          );
        }

        debugPrint('UPDATED EMAIL: ${response.data['email']}');

        // Refresh the current session/user
        await supabase.auth.refreshSession();
      }

      // No email change
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
          ),
        );

        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      debugPrint('EMAIL UPDATE ERROR');
      debugPrint('Message: ${e.message}');
      debugPrint('Code: ${e.code}');
      debugPrint('Status: ${e.statusCode}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to update your email: ${e.message}',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('SAVE PROFILE ERROR: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
          ),
        );
      }
    } finally {
      if (mounted && isSaving) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              const SizedBox(height: 10),

              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: selectedImage != null
                          ? FileImage(selectedImage!)
                          : (currentImageUrl != null &&
                          currentImageUrl!.isNotEmpty
                          ? NetworkImage(
                        '${currentImageUrl!}?t=${DateTime.now().millisecondsSinceEpoch}',
                      )
                          : const AssetImage(
                        'assets/images/default_image.jpg',
                      )) as ImageProvider,
                    ),

                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: pickProfileImage,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1687E8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_a_photo,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Full Name
              TextFormField(
                controller: nameController,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(50),
                ],
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person),
                  border: const OutlineInputBorder(),
                  errorText: nameTooLong
                      ? 'Name cannot exceed 50 characters.'
                      : null,
                ),
                validator: (value) {
                  final name = value?.trim() ?? '';

                  if (name.isEmpty) {
                    return 'Please enter your full name.';
                  }

                  if (name.length < 2) {
                    return 'Name must contain at least 2 characters.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Email
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(100),
                ],
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: const OutlineInputBorder(),
                  errorText: emailTooLong
                      ? 'Email cannot exceed 100 characters.'
                      : null,
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';

                  if (email.isEmpty) {
                    return 'Please enter your email address.';
                  }

                  final emailRegex = RegExp(
                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                  );

                  if (!emailRegex.hasMatch(email)) {
                    return 'Please enter a valid email address.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Phone Number
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone),
                  hintText: 'e.g. 0123456789',
                  border: const OutlineInputBorder(),
                  errorText: phoneTooLong
                      ? 'Phone number cannot exceed 11 digits.'
                      : null,
                ),
                validator: (value) {
                  final phone = value?.trim() ?? '';

                  if (phone.isEmpty) {
                    return 'Please enter your phone number.';
                  }

                  final phoneRegex = RegExp(r'^01\d{8,9}$');

                  if (!phoneRegex.hasMatch(phone)) {
                    return 'Please enter a valid Malaysian phone number.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 30),

              // Save Changes
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: isSaving ? null : saveProfile,
                  child: isSaving
                      ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text('Saving...'),
                    ],
                  )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}