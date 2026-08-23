import 'package:flutter/material.dart';

import '../models/fuel_station_model.dart';
import '../services/fuel_station_service.dart';

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

      if (!mounted) return;

      // DEBUG: Print the complete Google Place Details response
      print('PLACE DETAILS: $result');

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
    // ----------------------------------------------------------
    // Station Name
    // ----------------------------------------------------------

    final name =
        details?['displayName']?['text']
            ?.toString() ??
            widget.station.stationName;

    // ----------------------------------------------------------
    // Address
    // ----------------------------------------------------------

    final address =
        details?['formattedAddress']
            ?.toString() ??
            widget.station.stationAddress;

    // ----------------------------------------------------------
    // Phone Number
    // ----------------------------------------------------------

    final phone =
        details?['nationalPhoneNumber']
            ?.toString() ??
            details?['internationalPhoneNumber']
                ?.toString();

    // ----------------------------------------------------------
    // Opening Hours
    // ----------------------------------------------------------

    final openingHours =
    details?['regularOpeningHours']
    ?['weekdayDescriptions'];

    // ----------------------------------------------------------
    // Photos
    // ----------------------------------------------------------

    final photos =
    details?['photos'] as List<dynamic>?;

    // ==========================================================
    // SCREEN
    // ==========================================================

    return Scaffold(
      // ========================================================
      // APP BAR
      // ========================================================

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
              setState(() {
                isFavourite = !isFavourite;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFavourite
                        ? 'Saved to favourites'
                        : 'Removed from favourites',
                  ),
                ),
              );
            },
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

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
            // GOOGLE PHOTO
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
                  // ==================================================
                  // NAME
                  // ==================================================

                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // ADDRESS
                  // ==================================================

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

                  // ==================================================
                  // PHONE NUMBER
                  // ==================================================

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
                            style: const TextStyle(
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
                  // FAVOURITE
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
                      onPressed: () {
                        setState(() {
                          isFavourite =
                          !isFavourite;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ==================================================
                  // PAYMENT
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
                      ),
                      onPressed: () {
                        // TODO:
                        // Connect your existing
                        // PaymentScreen here.

                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Payment page can be connected here.',
                            ),
                          ),
                        );
                      },
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