// features/fuel_station/screens/station_detail_screen.dart

import 'package:flutter/material.dart';
import '../models/fuel_station_model.dart';
import '../services/fuel_station_service.dart';
import '../../payment/screens/payment_page.dart';
import 'favourite_list_screen.dart';
import '../models/favourite_model.dart';
import '../services/favourite_service.dart';

class StationDetailScreen extends StatefulWidget {
  final FuelStation station;
  final FuelStationService service;

  const StationDetailScreen({
    super.key,
    required this.station,
    required this.service,
  });

  @override
  State<StationDetailScreen> createState() =>
      _StationDetailScreenState();
}

class _StationDetailScreenState
    extends State<StationDetailScreen> {
  Map<String, dynamic>? details;

  bool isLoading = true;

  bool isFavourite = false;
  final FavoriteService _favService = FavoriteService();

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  // ============================================================
  // LOAD GOOGLE PLACE DETAILS
  // ============================================================

  Future<void> _loadDetails() async {
    try {
      final result =
      await widget.service.getStationDetails(
        widget.station.placeId,
      );

      final photos = result['photos'] as List<dynamic>?;

      if (photos != null && photos.isNotEmpty) {
        final photoName = photos.first['name'].toString();
        final fullUrl = widget.service.getPhotoUrl(photoName);

        print('🖼️ COMPLETE PHOTO URL: $fullUrl');
      } else {
        print('❌ NO PHOTO FOUND');
      }

      setState(() {
        details = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load station details: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final name =
        details?['displayName']?['text']
            ?.toString() ??
            widget.station.stationName;

    final address =
        details?['formattedAddress']
            ?.toString() ??
            widget.station.stationAddress;

    final phone =
        details?['nationalPhoneNumber']
            ?.toString() ??
            details?['internationalPhoneNumber']
                ?.toString();

    final openingHours =
    details?['regularOpeningHours']
    ?['weekdayDescriptions'];

    final photos =
    details?['photos'] as List<dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Station Details',
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFavourite
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: isFavourite
                  ? Colors.red
                  : null,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FavoriteListScreen(
                    service: widget.service,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // ==================================================
            // STATION PHOTO
            // ==================================================

            if (photos != null &&
                photos.isNotEmpty)
              SizedBox(
                height: 230,
                width: double.infinity,
                child: Image.network(
                  widget.service.getPhotoUrl(
                    photos.first['name'].toString(),
                  ),
                  fit: BoxFit.cover,
                  loadingBuilder:
                      (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }

                    return Center(
                      child:
                      CircularProgressIndicator(
                        value: loadingProgress
                            .expectedTotalBytes !=
                            null
                            ? loadingProgress
                            .cumulativeBytesLoaded /
                            loadingProgress
                                .expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder:
                      (context, error, stackTrace) {
                    return _buildPhotoFallback();
                  },
                ),
              )
            else
              _buildPhotoFallback(),

            // ==================================================
            // STATION INFORMATION
            // ==================================================

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          address,
                          style: const TextStyle(
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (phone != null &&
                      phone.isNotEmpty) ...[
                    const SizedBox(height: 18),

                    Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.phone,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            phone,
                            style:
                            const TextStyle(
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ==================================================
                  // OPENING HOURS
                  // ==================================================

                  const Text(
                    'Opening Hours',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (openingHours is List)
                    ...openingHours.map(
                          (hour) => Padding(
                        padding:
                        const EdgeInsets.only(
                          bottom: 6,
                        ),
                        child: Text(
                          hour.toString(),
                        ),
                      ),
                    )
                  else
                    const Text(
                      'Opening hours unavailable',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),

                  const SizedBox(height: 30),

                  // ==================================================
                  // FAVOURITE BUTTON
                  // ==================================================

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: Icon(
                        isFavourite
                            ? Icons.favorite
                            : Icons.favorite_border,
                      ),
                      label: Text(
                        isFavourite
                            ? 'Saved'
                            : 'Save Favourite',
                      ),
                      onPressed: () async {
                        try {
                          final alreadyFavorite =
                          await _favService
                              .isFavorite(
                            widget.station.placeId,
                          );

                          if (alreadyFavorite) {
                            if (!mounted) return;

                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Already in favourites',
                                ),
                              ),
                            );

                            return;
                          }

                          final favorite =
                          Favorite.fromStation(
                            widget.station,
                          );

                          await _favService
                              .addFavorite(
                            favorite,
                          );

                          if (!mounted) return;

                          setState(() {
                            isFavourite = true;
                          });

                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Saved to favourites',
                              ),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;

                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to save favourite: $e',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ==================================================
                  // PAYMENT BUTTON
                  // ==================================================

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.local_gas_station,
                      ),
                      label: const Text(
                        'Proceed to Payment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PaymentPage(
                                  placeId:
                                  widget.station.placeId,
                                  stationName: name,
                                  stationAddress:
                                  address,
                                ),
                          ),
                        );
                      },
                      style:
                      ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color(0xFF1687E8),
                        foregroundColor:
                        Colors.white,
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PHOTO FALLBACK
  // ============================================================

  Widget _buildPhotoFallback() {
    return Container(
      height: 230,
      width: double.infinity,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.local_gas_station,
          size: 70,
          color: Colors.grey,
        ),
      ),
    );
  }
}