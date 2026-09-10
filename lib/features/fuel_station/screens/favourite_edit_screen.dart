import 'package:flutter/material.dart';
import '../models/favourite_model.dart';

class FavoriteEditScreen extends StatefulWidget {
  final Favorite favorite;

  const FavoriteEditScreen({
    super.key,
    required this.favorite,
  });

  @override
  State<FavoriteEditScreen> createState() =>
      _FavoriteEditScreenState();
}

class _FavoriteEditScreenState
    extends State<FavoriteEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.favorite.customName,
    );

    _noteController = TextEditingController(
      text: widget.favorite.note,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveFavorite() {
    final updated = widget.favorite.copyWith(
      customName: _nameController.text.trim(),
      note: _noteController.text.trim(),
    );

    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Favorite',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          TextButton(
            onPressed: _saveFavorite,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFF1687E8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [

              const Text(
                'Original Name',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                widget.favorite.stationName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Divider(height: 30),

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Custom Name',
                  hintText:
                  'Give this station a memorable name',
                  border: OutlineInputBorder(),
                  contentPadding:
                  EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Personal Note',
                  hintText:
                  'e.g., Cheap diesel, car wash...',
                  border: OutlineInputBorder(),
                  contentPadding:
                  EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveFavorite,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF1687E8),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}