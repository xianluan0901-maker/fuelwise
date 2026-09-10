import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../models/fuel_station_model.dart';
import '../services/fuel_station_service.dart';
import 'station_detail_screen.dart';
import 'favourite_list_screen.dart';

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



  final FuelStationService _stationService =
  FuelStationService();


  Position? currentPosition;


  List<FuelStation> _allStations = [];
  List<FuelStation> _displayedStations = [];


  bool isLoading = true;

  String? errorMessage;

  String? _selectedBrand;

  String _searchKeyword = '';

  Timer? _searchDebounce;



  static const double _nearbyRadius = 10000;



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


  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(
        JavaScriptMode.unrestricted,
      )
      ..setBackgroundColor(
        const Color(0x00000000),
      )
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


  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });


      final serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Location service is disabled. '
              'Please enable GPS.',
        );
      }



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

  bool _isMalaysianStation(
      FuelStation station,
      ) {
    final address =
    station.stationAddress.toLowerCase();


    if (address.contains('malaysia')) {
      return true;
    }

    const malaysiaLocations = [
      'kuala lumpur',
      'putrajaya',
      'labuan',
      'selangor',
      'penang',
      'pulau pinang',
      'perak',
      'kedah',
      'perlis',
      'kelantan',
      'terengganu',
      'pahang',
      'johor',
      'melaka',
      'malacca',
      'negeri sembilan',
      'sabah',
      'sarawak',
    ];

    return malaysiaLocations.any(
          (location) =>
          address.contains(location),
    );
  }


  List<FuelStation> _filterMalaysiaStations(
      List<FuelStation> stations,
      ) {
    return stations
        .where(_isMalaysianStation)
        .toList();
  }
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

      final malaysiaStations =
      _filterMalaysiaStations(stations);

      if (!mounted) return;

      setState(() {
        _allStations = malaysiaStations;

        _displayedStations =
            _applyBrandFilter(
              malaysiaStations,
            );

        isLoading = false;
      });

      _updateMap();

      debugPrint(
        'REAL nearby Malaysian stations: '
            '${malaysiaStations.length}',
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

  void _searchStations(
      String keyword,
      ) {
    _searchKeyword = keyword;

    _searchDebounce?.cancel();


    if (keyword.trim().isEmpty) {
      _selectedBrand = null;

      setState(() {
        _displayedStations =
            _allStations;
      });

      _loadNearbyStations();

      return;
    }


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


      final malaysiaResults =
      _filterMalaysiaStations(results);

      if (!mounted) return;

      final filtered =
      _applyBrandFilter(
        malaysiaResults,
      );

      setState(() {
        _allStations =
            malaysiaResults;

        _displayedStations =
            filtered;

        isLoading = false;
      });

      _updateMap();

      debugPrint(
        'REAL Malaysian search results: '
            '${malaysiaResults.length} '
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


  void _clearFilters() {
    _searchDebounce?.cancel();

    setState(() {
      _searchKeyword = '';

      _selectedBrand = null;

      _displayedStations =
          _allStations;
    });


    _loadNearbyStations();
  }


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
            _displayedStations.firstWhere(
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
      Navigator.pop<FuelStation>(
        context,
        selectedStation,
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            StationDetailScreen(
              station:
              selectedStation!,
              service:
              _stationService,
            ),
      ),
    );
  }

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

    final searchKeywordJs =
    jsonEncode(
      _searchKeyword,
    );

    final stationsJson =
    _displayedStations.map(
          (station) {
        return {
          'id': station.placeId,
          'name':
          station.stationName,
          'address':
          station.stationAddress,
          'brand':
          station.brand,
          'lat':
          station.latitude,
          'lng':
          station.longitude,
        };
      },
    ).toList();

    final stationsJs =
    jsonEncode(
      stationsJson,
    );

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


  const currentLocation = {
    lat: $lat,
    lng: $lng
  };


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



  const stations =
      $stationsJs;


  stations.forEach(
    function(station) {

      if (
        !station.lat ||
        !station.lng
      ) {
        return;
      }


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




  const searchKeyword =
      $searchKeywordJs;


  if (
    searchKeyword.length > 0 &&
    stations.length > 0
  ) {

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
    'Map initialized. Real Malaysian stations: ' +
    stations.length
  );

}

</script>


<script
  src="https://maps.googleapis.com/maps/api/js?key=$apiKey&loading=async&callback=initMap"
  async
  defer>
</script>


</body>

</html>
''';
  }

  void _updateMap() {
    if (currentPosition == null) {
      return;
    }

    final html =
    _generateMapHtml();

    _webViewController
        .loadHtmlString(html);
  }


  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FA),


      appBar: AppBar(
        title: Text(
          widget.selectionMode
            ? 'Choose a station'
            : 'Fuel Stations',
          style: const TextStyle(
            color: Color(0xFF153B60),
            fontWeight: FontWeight.bold
          ),
        ),
        backgroundColor:const Color(0xFFE1F2FF),

        elevation: 0,

        centerTitle: true,

        actions: [
          IconButton(
            icon: const Icon(
              Icons.favorite,
              color:
              Color(0xFF1687E8),
            ),

            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      FavoriteListScreen(
                        service:
                        _stationService,
                      ),
                ),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [

          Container(
            color:
            const Color(0xFFE1F2FF),

            padding:
            const EdgeInsets.fromLTRB(
              16,
              10,
              16,
              12,
            ),

            child: Row(
              children: [

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
                            size:
                            20,
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

          Expanded(
            child: Stack(
              children: [

                WebViewWidget(
                  controller:
                  _webViewController,
                ),

                if (isLoading)
                  Container(
                    color: Colors.white
                        .withAlpha(170),

                    child:
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
                  ),

                if (
                errorMessage != null &&
                    !isLoading
                )
                  Center(
                    child:
                    Container(
                      margin:
                      const EdgeInsets
                          .all(
                        30,
                      ),

                      padding:
                      const EdgeInsets
                          .all(
                        20,
                      ),

                      decoration:
                      BoxDecoration(
                        color:
                        Colors.white,

                        borderRadius:
                        BorderRadius
                            .circular(
                          16,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color:
                            Colors.black
                                .withAlpha(
                              25,
                            ),

                            blurRadius:
                            10,
                          ),
                        ],
                      ),

                      child:
                      Column(
                        mainAxisSize:
                        MainAxisSize
                            .min,

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
                            TextAlign
                                .center,

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


                if (
                !isLoading &&
                    errorMessage == null &&
                    _displayedStations
                        .isNotEmpty
                )
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,

                    child:
                    Container(
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

                            blurRadius:
                            8,

                            offset:
                            const Offset(
                              0,
                              2,
                            ),
                          ),
                        ],
                      ),

                      child:
                      Center(
                        child:
                        Text(
                          '${_displayedStations.length} stations · ${_selectedBrand ?? "All Brands"}',

                          style:
                          const TextStyle(
                            fontSize:
                            12,

                            color:
                            Color(
                              0xFF153B60,
                            ),

                            fontWeight:
                            FontWeight
                                .w500,
                          ),
                        ),
                      ),
                    ),
                  ),

                if (
                !isLoading &&
                    errorMessage == null &&
                    _displayedStations
                        .isEmpty
                )
                  Center(
                    child:
                    Container(
                      margin:
                      const EdgeInsets
                          .all(
                        30,
                      ),

                      padding:
                      const EdgeInsets
                          .all(
                        20,
                      ),

                      decoration:
                      BoxDecoration(
                        color:
                        Colors.white,

                        borderRadius:
                        BorderRadius
                            .circular(
                          16,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color:
                            Colors.black
                                .withAlpha(
                              25,
                            ),

                            blurRadius:
                            10,
                          ),
                        ],
                      ),

                      child:
                      Center(
                        child:
                        _searchKeyword
                            .trim()
                            .isNotEmpty
                            ? const Column(
                          mainAxisSize:
                          MainAxisSize
                              .min,

                          children: [
                            Icon(
                              Icons
                                  .location_off,
                              color:
                              Colors.grey,
                              size:
                              30,
                            ),

                            SizedBox(
                              height:
                              8,
                            ),

                            Text(
                              'No Malaysian fuel stations found.',
                              textAlign:
                              TextAlign
                                  .center,

                              style:
                              TextStyle(
                                color:
                                Color(
                                  0xFF153B60,
                                ),

                                fontWeight:
                                FontWeight
                                    .w600,
                              ),
                            ),

                            SizedBox(
                              height:
                              4,
                            ),

                            Text(
                              'Please search for a fuel station in Malaysia.',
                              textAlign:
                              TextAlign
                                  .center,

                              style:
                              TextStyle(
                                color:
                                Colors.grey,

                                fontSize:
                                12,
                              ),
                            ),
                          ],
                        )
                            : const Text(
                          'No fuel stations found nearby.',
                          textAlign:
                          TextAlign
                              .center,

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
          ),
        ],
      ),
    );
  }
}