// features/fuel_station/screens/favorite_list_screen.dart

import 'package:flutter/material.dart';
import '../models/favourite_model.dart';
import '../models/fuel_station_model.dart';
import '../services/favourite_service.dart';
import '../services/fuel_station_service.dart';
import 'station_detail_screen.dart';
import 'favourite_edit_screen.dart';

class FavoriteListScreen extends StatefulWidget {
  final FuelStationService service;

  const FavoriteListScreen({super.key, required this.service});

  @override
  State<FavoriteListScreen> createState() => _FavoriteListScreenState();
}

class _FavoriteListScreenState extends State<FavoriteListScreen> {
  final FavoriteService _favService = FavoriteService();
  List<Favorite> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final list = await _favService.getFavorites();
    setState(() {
      _favorites = list;
      _isLoading = false;
    });
  }

  Future<void> _deleteFavorite(String placeId, String name) async {
    await _favService.removeFavorite(placeId);
    setState(() {
      _favorites.removeWhere((f) => f.placeId == placeId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed «$name»')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Favorites', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(onPressed: _loadFavorites, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No favorites yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('Go to a station and tap ❤️ to add', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final fav = _favorites[index];
          final displayName = fav.customName.isNotEmpty ? fav.customName : fav.stationName;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1687E8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_gas_station, color: Color(0xFF1687E8)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        if (fav.customName.isNotEmpty)
                          Text(fav.stationName, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        Text(fav.stationAddress, style: TextStyle(fontSize: 13, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (fav.note.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('📝 ${fav.note}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Color(0xFF1687E8), size: 22),
                        onPressed: () {
                          final station = FuelStation(
                            placeId: fav.placeId,
                            stationName: fav.stationName,
                            stationAddress: fav.stationAddress,
                            brand: 'Other',
                            latitude: fav.latitude,
                            longitude: fav.longitude,
                          );
                          Navigator.push(context, MaterialPageRoute(builder: (_) => StationDetailScreen(station: station, service: widget.service)))
                              .then((_) => _loadFavorites());
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange, size: 22),
                        onPressed: () async {
                          final result = await Navigator.push<Favorite>(
                            context,
                            MaterialPageRoute(builder: (_) => FavoriteEditScreen(favorite: fav)),
                          );
                          if (result != null) {
                            await _favService.updateFavorite(result);
                            await _loadFavorites();
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Favorite updated')));
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 22),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Remove Favorite'),
                              content: Text('Are you sure you want to remove «$displayName»?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _deleteFavorite(fav.placeId, displayName);
                                  },
                                  child: const Text('Remove', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}