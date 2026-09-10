import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../models/fuel_station_model.dart';
import '../services/fuel_station_service.dart';
import 'station_detail_screen.dart';

class StationListScreen extends StatefulWidget {
  final bool selectionMode;

  const StationListScreen({
    super.key,
    this.selectionMode = false,
  });

  @override
  State<StationListScreen> createState() =>
      _StationListScreenState();
}

class _StationListScreenState extends State<StationListScreen> {
  late final WebViewController _webViewController;

  // ============================================================
  // SERVICES
  // ============================================================

  final FuelStationService _stationService =
  FuelStationService();

  // ============================================================
  // LOCATION
  // ============================================================

  Position? currentPosition;

  // ============================================================
  // DATA
  // ============================================================

  List<FuelStation> _allStations = [];
  List<FuelStation> _displayedStations = [];

  // ============================================================
  // UI STATE
  // ============================================================

  bool isLoading = true;

  String? errorMessage;

  String? _selectedBrand;

  String _searchKeyword = '';

  Timer? _searchDebounce;

  // ============================================================
  // CONSTANT
  // ============================================================

  static const double _nearbyRadius = 10000;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _initWebView();

    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();

    super.dispose();
  }

  // ============================================================
  // WEBVIEW
  // ============================================================

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(
        JavaScriptMode.unrestricted,
      )
      ..setBackgroundColor(
        const Color(0x00000000),
      )

    // ========================================================
    // IMPORTANT
    //
    // JavaScript marker click
    //        ↓
    // StationChannel
    //        ↓
    // Flutter
    //        ↓
    // StationDetailScreen
    // ========================================================

      ..addJavaScriptChannel(
        'StationChannel',
        onMessageReceived: (JavaScriptMessage message) {
          final placeId = message.message.trim();

          if (placeId.isEmpty) {
            return;
          }

          _openStationDetail(placeId);
        },
      )

      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            debugPrint(
              'Google Maps loaded',
            );
          },

          onWebResourceError:
              (WebResourceError error) {
            debugPrint(
              'WebView error: '
                  '${error.errorCode} '
                  '${error.description}',
            );
          },
        ),
      );
  }

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // --------------------------------------------------------
      // Check location service
      // --------------------------------------------------------

      final serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Location service is disabled. '
              'Please enable GPS.',
        );
      }

      // --------------------------------------------------------
      // Check permission
      // --------------------------------------------------------

      LocationPermission permission =
      await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
        await Geolocator.requestPermission();
      }

      if (permission ==
          LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is required '
              'to find nearby fuel stations.',
        );
      }

      // --------------------------------------------------------
      // Get REAL GPS location
      // --------------------------------------------------------

      final position =
      await Geolocator.getCurrentPosition(
        locationSettings:
        const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      currentPosition = position;

      debugPrint(
        'CURRENT LOCATION: '
            '${position.latitude}, '
            '${position.longitude}',
      );

      // --------------------------------------------------------
      // Load real nearby stations
      // --------------------------------------------------------

      await _loadNearbyStations();
    } catch (e) {
      debugPrint(
        'Location error: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // LOAD REAL NEARBY STATIONS
  //
  // Google Places API
  // Radius = 10 km
  // ============================================================

  Future<void> _loadNearbyStations() async {
    if (currentPosition == null) {
      return;
    }

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final stations =
      await _stationService.getNearbyStations(
        latitude:
        currentPosition!.latitude,
        longitude:
        currentPosition!.longitude,
        radius: _nearbyRadius,
      );

      if (!mounted) return;

      setState(() {
        _allStations = stations;

        _displayedStations =
            _applyBrandFilter(stations);

        isLoading = false;
      });

      _updateMap();

      debugPrint(
        'REAL nearby stations: '
            '${stations.length}',
      );
    } catch (e) {
      debugPrint(
        'Nearby station error: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            e.toString();
      });
    }
  }

  // ============================================================
  // SEARCH
  //
  // Google Places Text Search
  // Real station name / address
  // ============================================================

  void _searchStations(String keyword) {
    _searchKeyword = keyword;

    _searchDebounce?.cancel();

    // ----------------------------------------------------------
    // User deleted search keyword
    //
    // Return to:
    // REAL current location
    // +
    // nearby 10 km stations
    // ----------------------------------------------------------

    if (keyword.trim().isEmpty) {
      _selectedBrand = null;

      setState(() {
        _displayedStations =
            _allStations;
      });

      _loadNearbyStations();

      return;
    }

    // ----------------------------------------------------------
    // Small debounce
    // Avoid calling Google API for every single keystroke
    // ----------------------------------------------------------

    _searchDebounce = Timer(
      const Duration(
        milliseconds: 500,
      ),
          () async {
        await _performSearch(
          keyword.trim(),
        );
      },
    );
  }

  Future<void> _performSearch(
      String query,
      ) async {
    if (currentPosition == null) {
      return;
    }

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final results =
      await _stationService.searchStations(
        query: query,
        latitude:
        currentPosition!.latitude,
        longitude:
        currentPosition!.longitude,
      );

      if (!mounted) return;

      // --------------------------------------------------------
      // Apply selected brand filter if user already selected one
      // --------------------------------------------------------

      final filtered =
      _applyBrandFilter(results);

      setState(() {
        _allStations = results;

        _displayedStations =
            filtered;

        isLoading = false;
      });

      _updateMap();

      debugPrint(
        'REAL search results: '
            '${results.length} '
            'for "$query"',
      );
    } catch (e) {
      debugPrint(
        'Search error: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            e.toString();
      });
    }
  }

  // ============================================================
  // BRAND FILTER
  //
  // Filter REAL Google Places results
  // ============================================================

  void _filterByBrand(
      String? brand,
      ) {
    setState(() {
      _selectedBrand = brand;

      _displayedStations =
          _applyBrandFilter(
            _allStations,
          );
    });

    _updateMap();

    debugPrint(
      'Brand filter: '
          '${brand ?? "All"} '
          '- '
          '${_displayedStations.length} stations',
    );
  }

  List<FuelStation> _applyBrandFilter(
      List<FuelStation> stations,
      ) {
    if (_selectedBrand == null) {
      return List<FuelStation>.from(
        stations,
      );
    }

    final selected =
    _selectedBrand!.toLowerCase();

    return stations.where((station) {
      return station.brand
          .toLowerCase() ==
          selected;
    }).toList();
  }

  // ============================================================
  // CLEAR SEARCH / FILTER
  // ============================================================

  void _clearFilters() {
    _searchDebounce?.cancel();

    setState(() {
      _searchKeyword = '';

      _selectedBrand = null;

      _displayedStations =
          _allStations;
    });

    // ----------------------------------------------------------
    // Reload real nearby stations
    // based on current GPS location
    // ----------------------------------------------------------

    _loadNearbyStations();
  }

  // ============================================================
  // OPEN STATION DETAIL
  // ============================================================

  void _openStationDetail(
      String placeId,
      ) {
    FuelStation? selectedStation;

    try {
      selectedStation =
          _allStations.firstWhere(
                (station) =>
            station.placeId ==
                placeId,
          );
    } catch (_) {
      selectedStation = null;
    }

    if (selectedStation == null) {
      try {
        selectedStation =
            _displayedStations
                .firstWhere(
                  (station) =>
              station.placeId ==
                  placeId,
            );
      } catch (_) {
        selectedStation = null;
      }
    }

    if (selectedStation == null) {
      debugPrint(
        'Station not found: $placeId',
      );

      return;
    }

    if (widget.selectionMode) {
      Navigator.pop<FuelStation>(context, selectedStation);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            StationDetailScreen(
              station: selectedStation!,
              service: _stationService,
            ),
      ),
    );
  }

  // ============================================================
  // GENERATE GOOGLE MAP HTML
  // ============================================================

  String _generateMapHtml() {
    if (currentPosition == null) {
      return '''
        <html>
          <body></body>
        </html>
      ''';
    }

    final lat =
        currentPosition!.latitude;

    final lng =
        currentPosition!.longitude;

    // ----------------------------------------------------------
    // IMPORTANT
    //
    // jsonEncode safely converts Dart data
    // into valid JavaScript values.
    //
    // This prevents:
    //
    // Uncaught SyntaxError:
    // Invalid or unexpected token
    // ----------------------------------------------------------

    final searchKeywordJs =
    jsonEncode(
      _searchKeyword,
    );

    // ----------------------------------------------------------
    // Convert REAL Google Places data
    // into JavaScript
    // ----------------------------------------------------------

    final stationsJson =
    _displayedStations.map(
          (station) {
        return {
          'id': station.placeId,
          'name': station.stationName,
          'address':
          station.stationAddress,
          'brand': station.brand,
          'lat': station.latitude,
          'lng': station.longitude,
        };
      },
    ).toList();

    final stationsJs =
    jsonEncode(
      stationsJson,
    );

    // ----------------------------------------------------------
    // Google Maps Demo Key
    //
    // Stored in FuelStationService
    // ----------------------------------------------------------

    final apiKey =
        FuelStationService.apiKey;

    return '''
<!DOCTYPE html>

<html>

<head>

<meta
  name="viewport"
  content="width=device-width,
           initial-scale=1.0,
           maximum-scale=1.0,
           user-scalable=no">

<style>

html,
body,
#map {

  height: 100%;
  width: 100%;

  margin: 0;
  padding: 0;

}

</style>

</head>

<body>

<div id="map"></div>

<script>

let map;

function initMap() {

  // ==========================================================
  // CURRENT LOCATION
  // ==========================================================

  const currentLocation = {
    lat: $lat,
    lng: $lng
  };


  // ==========================================================
  // CREATE MAP
  // ==========================================================

  map = new google.maps.Map(
    document.getElementById('map'),
    {
      center: currentLocation,

      zoom: 13,

      mapTypeControl: false,

      fullscreenControl: false,

      streetViewControl: false,

      zoomControl: true
    }
  );


  // ==========================================================
  // CURRENT LOCATION MARKER
  // ==========================================================

  const currentLocationIcon = {

    path:
      google.maps.SymbolPath.CIRCLE,

    scale: 9,

    fillColor: '#4285F4',

    fillOpacity: 1,

    strokeColor: '#FFFFFF',

    strokeWeight: 3

  };


  new google.maps.Marker({

    position:
      currentLocation,

    map: map,

    title:
      'Your current location',

    icon:
      currentLocationIcon,

    zIndex: 1000

  });


  // ==========================================================
  // REAL GOOGLE PLACES STATIONS
  // ==========================================================

  const stations =
      $stationsJs;


  stations.forEach(
    function(station) {

      // ------------------------------------------------------
      // Make sure coordinate is valid
      // ------------------------------------------------------

      if (
        !station.lat ||
        !station.lng
      ) {
        return;
      }


      // ------------------------------------------------------
      // Station marker
      // ------------------------------------------------------

      const marker =
        new google.maps.Marker({

          position: {

            lat:
              Number(station.lat),

            lng:
              Number(station.lng)

          },

          map: map,

          title:
            station.name

        });


      // ------------------------------------------------------
      // Marker click
      //
      // JavaScript
      //       ↓
      // StationChannel
      //       ↓
      // Flutter
      //       ↓
      // StationDetailScreen
      // ------------------------------------------------------

      marker.addListener(
        'click',
        function() {

          if (
            window.StationChannel &&
            window.StationChannel.postMessage
          ) {

            window.StationChannel.postMessage(
              String(station.id)
            );

          }

        }
      );

    }
  );


  // ==========================================================
  // SEARCH RESULT MAP MOVEMENT
  // ==========================================================

  const searchKeyword =
      $searchKeywordJs;


  if (
    searchKeyword.length > 0 &&
    stations.length > 0
  ) {

    // --------------------------------------------------------
    // ONE SEARCH RESULT
    // Move directly to station
    // --------------------------------------------------------

    if (
      stations.length === 1
    ) {

      map.panTo({

        lat:
          Number(
            stations[0].lat
          ),

        lng:
          Number(
            stations[0].lng
          )

      });

      map.setZoom(16);

    }

    // --------------------------------------------------------
    // MULTIPLE SEARCH RESULTS
    // Show all results
    // --------------------------------------------------------

    else {

      const bounds =
          new google.maps.LatLngBounds();


      stations.forEach(
        function(station) {

          bounds.extend({

            lat:
              Number(
                station.lat
              ),

            lng:
              Number(
                station.lng
              )

          });

        }
      );


      map.fitBounds(
        bounds
      );

    }

  }


  console.log(
    'Map initialized. Real stations: ' +
    stations.length
  );

}

</script>


<!-- ========================================================
     GOOGLE MAPS JAVASCRIPT API
     ======================================================== -->

<script
  src="https://maps.googleapis.com/maps/api/js?key=$apiKey&loading=async&callback=initMap"
  async
  defer>
</script>


</body>

</html>
''';
  }

  // ============================================================
  // UPDATE MAP
  // ============================================================

  void _updateMap() {
    if (currentPosition == null) {
      return;
    }

    final html =
    _generateMapHtml();

    _webViewController
        .loadHtmlString(html);
  }

  // ============================================================
  // BUILD UI
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(

      backgroundColor:
      const Color(0xFFF5F7FA),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(

        backgroundColor:
        const Color(0xFFE1F2FF),

        elevation: 0,

        centerTitle: true,

        title: Text(
          widget.selectionMode ? 'Choose a station' : 'Fuel Stations',
          style: const TextStyle(
            color: Color(0xFF153B60),
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [

          IconButton(

            icon: const Icon(
              Icons.favorite,
              color:
              Color(0xFF1687E8),
            ),

            onPressed: () {

              ScaffoldMessenger
                  .of(context)
                  .showSnackBar(
                const SnackBar(
                  content: Text(
                    'Favorites coming soon!',
                  ),
                  duration:
                  Duration(
                    seconds: 1,
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

      body: Stack(

        children: [

          // ====================================================
          // GOOGLE MAP
          // ====================================================

          WebViewWidget(
            controller:
            _webViewController,
          ),


          // ====================================================
          // SEARCH + BRAND FILTER
          // ====================================================

          Positioned(

            top: 0,

            left: 0,

            right: 0,

            child: Padding(

              padding:
              const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
              ),

              child: Row(

                children: [

                  // ==================================================
                  // SEARCH BAR
                  // ==================================================

                  Expanded(

                    child: Container(

                      height: 50,

                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 6,
                      ),

                      decoration:
                      BoxDecoration(

                        color:
                        Colors.white,

                        borderRadius:
                        BorderRadius
                            .circular(
                          25,
                        ),

                        boxShadow: [

                          BoxShadow(

                            color:
                            Colors.black
                                .withAlpha(
                              26,
                            ),

                            blurRadius: 10,

                            offset:
                            const Offset(
                              0,
                              4,
                            ),

                          ),

                        ],

                      ),

                      child: TextField(

                        decoration:
                        InputDecoration(

                          prefixIcon:
                          const Icon(
                            Icons.search,
                            color:
                            Colors.grey,
                          ),

                          hintText:
                          'Find a station',

                          hintStyle:
                          const TextStyle(
                            color:
                            Colors.grey,
                          ),

                          border:
                          InputBorder.none,

                          contentPadding:
                          const EdgeInsets
                              .symmetric(
                            vertical: 14,
                          ),

                          suffixIcon:
                          _searchKeyword
                              .isNotEmpty
                              ? IconButton(

                            icon:
                            const Icon(
                              Icons.clear,
                              color:
                              Colors.grey,
                              size: 20,
                            ),

                            onPressed:
                            _clearFilters,

                          )
                              : null,

                        ),

                        onChanged:
                        _searchStations,

                      ),

                    ),

                  ),


                  const SizedBox(
                    width: 12,
                  ),


                  // ==================================================
                  // BRAND FILTER
                  // ==================================================

                  Container(

                    height: 50,

                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 12,
                    ),

                    decoration:
                    BoxDecoration(

                      color:
                      const Color(
                        0xFF1687E8,
                      ),

                      borderRadius:
                      BorderRadius
                          .circular(
                        25,
                      ),

                      boxShadow: [

                        BoxShadow(

                          color:
                          const Color(
                            0xFF1687E8,
                          ).withAlpha(
                            102,
                          ),

                          blurRadius: 8,

                          offset:
                          const Offset(
                            0,
                            4,
                          ),

                        ),

                      ],

                    ),

                    child:
                    DropdownButtonHideUnderline(

                      child:
                      DropdownButton<String?>(

                        value:
                        _selectedBrand,

                        icon:
                        const Icon(
                          Icons
                              .arrow_drop_down,
                          color:
                          Colors.white,
                        ),

                        dropdownColor:
                        Colors.white,

                        hint:
                        const Text(
                          'All',

                          style:
                          TextStyle(
                            color:
                            Colors.white,
                            fontWeight:
                            FontWeight.bold,
                          ),

                        ),

                        items: const [

                          DropdownMenuItem<
                              String?>(
                            value: null,
                            child:
                            Text(
                              'All',
                            ),
                          ),

                          DropdownMenuItem<
                              String?>(
                            value:
                            'Petronas',
                            child:
                            Text(
                              'Petronas',
                            ),
                          ),

                          DropdownMenuItem<
                              String?>(
                            value:
                            'Shell',
                            child:
                            Text(
                              'Shell',
                            ),
                          ),

                          DropdownMenuItem<
                              String?>(
                            value:
                            'Petron',
                            child:
                            Text(
                              'Petron',
                            ),
                          ),

                          DropdownMenuItem<
                              String?>(
                            value:
                            'Caltex',
                            child:
                            Text(
                              'Caltex',
                            ),
                          ),

                          DropdownMenuItem<
                              String?>(
                            value:
                            'BHP',
                            child:
                            Text(
                              'BHP',
                            ),
                          ),

                        ],

                        onChanged:
                        _filterByBrand,

                      ),

                    ),

                  ),

                ],

              ),

            ),

          ),


          // ========================================================
          // LOADING
          // ========================================================

          if (isLoading)

            const Center(

              child: Column(

                mainAxisSize:
                MainAxisSize.min,

                children: [

                  CircularProgressIndicator(),

                  SizedBox(
                    height: 10,
                  ),

                  Text(
                    'Loading fuel stations...',
                    style:
                    TextStyle(
                      color:
                      Colors.grey,
                    ),
                  ),

                ],

              ),

            ),


          // ========================================================
          // ERROR
          // ========================================================

          if (
          errorMessage != null &&
              !isLoading
          )

            Center(

              child: Padding(

                padding:
                const EdgeInsets
                    .all(
                  30,
                ),

                child: Column(

                  mainAxisSize:
                  MainAxisSize.min,

                  children: [

                    const Icon(
                      Icons
                          .error_outline,
                      color:
                      Colors.red,
                      size: 48,
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      errorMessage!,
                      textAlign:
                      TextAlign.center,
                      style:
                      const TextStyle(
                        color:
                        Colors.grey,
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    ElevatedButton(

                      onPressed:
                      _getCurrentLocation,

                      child:
                      const Text(
                        'Retry',
                      ),

                    ),

                  ],

                ),

              ),

            ),


          // ========================================================
          // RESULT COUNT
          // ========================================================

          if (
          !isLoading &&
              errorMessage == null &&
              _displayedStations
                  .isNotEmpty
          )

            Positioned(

              bottom: 20,

              left: 20,

              right: 20,

              child: Container(

                padding:
                const EdgeInsets
                    .symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),

                decoration:
                BoxDecoration(

                  color:
                  Colors.white
                      .withAlpha(
                    230,
                  ),

                  borderRadius:
                  BorderRadius
                      .circular(
                    20,
                  ),

                  boxShadow: [

                    BoxShadow(

                      color:
                      Colors.black
                          .withAlpha(
                        13,
                      ),

                      blurRadius: 8,

                      offset:
                      const Offset(
                        0,
                        2,
                      ),

                    ),

                  ],

                ),

                child: Center(

                  child: Text(

                    '${_displayedStations.length} stations · ${_selectedBrand ?? "All Brands"}',

                    style:
                    const TextStyle(
                      fontSize: 12,
                      color:
                      Color(
                        0xFF153B60,
                      ),
                      fontWeight:
                      FontWeight.w500,
                    ),

                  ),

                ),

              ),

            ),


          // ========================================================
          // NO RESULTS
          // ========================================================

          if (
          !isLoading &&
              errorMessage == null &&
              _displayedStations.isEmpty
          )

            Positioned(

              left: 20,

              right: 20,

              bottom: 20,

              child: Container(

                padding:
                const EdgeInsets
                    .all(
                  14,
                ),

                decoration:
                BoxDecoration(

                  color:
                  Colors.white,

                  borderRadius:
                  BorderRadius
                      .circular(
                    20,
                  ),

                  boxShadow: [

                    BoxShadow(

                      color:
                      Colors.black
                          .withAlpha(
                        20,
                      ),

                      blurRadius: 8,

                    ),

                  ],

                ),

                child: const Center(

                  child: Text(
                    'No fuel stations found.',
                    style:
                    TextStyle(
                      color:
                      Colors.grey,
                    ),
                  ),

                ),

              ),

            ),

        ],

      ),

    );
  }
}