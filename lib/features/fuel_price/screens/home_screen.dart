import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/fuel_price_model.dart';
import '../services/fuel_cache_service.dart';
import '../services/fuel_price_service.dart';

enum MalaysiaRegion { west, east }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FuelPriceService _fuelPriceService = FuelPriceService();
  final FuelCacheService _fuelCacheService = FuelCacheService();

  FuelPrice? _latestPrice;

  MalaysiaRegion _selectedRegion = MalaysiaRegion.west;

  bool _isLoading = true;
  bool _isUsingCachedData = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLatestPrice();
  }

  Future<void> _loadLatestPrice() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final latestPrice = await _fuelPriceService.getLatestFuelPrice();

      await _fuelCacheService.saveLatestPrice(latestPrice);

      if (!mounted) return;

      setState(() {
        _latestPrice = latestPrice;
        _isUsingCachedData = false;
        _isLoading = false;
      });
    } catch (error) {
      final cachedPrice = await _fuelCacheService.getCachedLatestPrice();

      if (!mounted) return;

      setState(() {
        _latestPrice = cachedPrice;
        _isUsingCachedData = cachedPrice != null;
        _isLoading = false;

        if (cachedPrice == null) {
          _errorMessage =
              'Unable to retrieve fuel prices. Please check your internet connection.';
        }
      });
    }
  }

  bool get _isEastMalaysia {
    return _selectedRegion == MalaysiaRegion.east;
  }

  String get _regionName {
    return _isEastMalaysia ? 'East Malaysia' : 'West Malaysia';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 18) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadLatestPrice,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 110),
            children: [
              _buildTopSection(),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFDCEFFF), Color(0xFFEDF7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xFF1687E8),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.local_gas_station_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Text(
                  'FuelWise MY',
                  style: TextStyle(
                    color: Color(0xFF183B5B),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  tooltip: 'Refresh fuel prices',
                  onPressed: _isLoading ? null : _loadLatestPrice,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFF1687E8),
                    size: 21,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getGreeting()} 👋',
                      style: const TextStyle(
                        color: Color(0xFF153B60),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                      style: const TextStyle(
                        color: Color(0xFF6B8397),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _buildRegionSelector(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegionSelector() {
    return PopupMenuButton<MalaysiaRegion>(
      initialValue: _selectedRegion,
      onSelected: (region) {
        setState(() {
          _selectedRegion = region;
        });
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: MalaysiaRegion.west,
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, color: Color(0xFF1687E8)),
              SizedBox(width: 10),
              Text('West Malaysia'),
            ],
          ),
        ),
        PopupMenuItem(
          value: MalaysiaRegion.east,
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, color: Color(0xFF1687E8)),
              SizedBox(width: 10),
              Text('East Malaysia'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: Color(0xFF1687E8),
              size: 17,
            ),
            const SizedBox(width: 5),
            Text(
              _regionName,
              style: const TextStyle(
                color: Color(0xFF284B6A),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6B8397),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 100),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _latestPrice == null) {
      return _buildErrorSection();
    }

    return _buildFuelDashboard(_latestPrice!);
  }

  Widget _buildFuelDashboard(FuelPrice price) {
    final dieselPrice = price.dieselForRegion(_isEastMalaysia);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Current Fuel Prices',
                style: TextStyle(
                  color: Color(0xFF153B60),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              'RM / Litre',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'Effective ${DateFormat('dd MMM yyyy').format(price.date)}',
          style: const TextStyle(color: Color(0xFF778B9C), fontSize: 13),
        ),
        if (_isUsingCachedData) ...[
          const SizedBox(height: 7),
          const Row(
            children: [
              Icon(Icons.cloud_off_outlined, size: 15, color: Colors.orange),
              SizedBox(width: 5),
              Text(
                'Showing the last saved prices',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ],
          ),
        ],
        const SizedBox(height: 17),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 13,
          mainAxisSpacing: 13,
          childAspectRatio: 1.18,
          children: [
            _buildFuelCard(
              fuelName: 'RON95',
              price: price.ron95,
              colour: const Color(0xFF36B37E),
              backgroundColour: const Color(0xFFE9F9F2),
              subtitle: 'Regular',
            ),
            _buildFuelCard(
              fuelName: 'BUDI95',
              price: price.ron95Budi ?? price.ron95,
              colour: const Color(0xFF1687E8),
              backgroundColour: const Color(0xFFE9F4FF),
              subtitle: 'Subsidised',
            ),
            _buildFuelCard(
              fuelName: 'RON97',
              price: price.ron97,
              colour: const Color(0xFFF5A623),
              backgroundColour: const Color(0xFFFFF5E3),
              subtitle: 'Premium',
            ),
            _buildFuelCard(
              fuelName: 'Diesel',
              price: dieselPrice,
              colour: const Color(0xFF7B61D1),
              backgroundColour: const Color(0xFFF0ECFF),
              subtitle: _isEastMalaysia ? 'East Malaysia' : 'West Malaysia',
            ),
          ],
        ),
        const SizedBox(height: 23),
        _buildTrendPreview(price),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _showFuelSelection,
                icon: const Icon(Icons.tune_rounded, size: 19),
                label: const Text('Select Fuel Type'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showHistoryMessage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1687E8),
                  side: const BorderSide(color: Color(0xFF1687E8)),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.history_rounded, size: 19),
                label: const Text('History'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFuelCard({
    required String fuelName,
    required double price,
    required Color colour,
    required Color backgroundColour,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDF1F5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C16324A),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: backgroundColour,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.local_gas_station_rounded,
                  color: colour,
                  size: 21,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: backgroundColour,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: colour,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            fuelName,
            style: const TextStyle(
              color: Color(0xFF536B7E),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'RM ${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: colour,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(
                  text: ' /L',
                  style: TextStyle(color: Color(0xFF8898A5), fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendPreview(FuelPrice price) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C16324A),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Fuel Price Trend',
                  style: TextStyle(
                    color: Color(0xFF153B60),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.show_chart_rounded, color: Color(0xFF1687E8)),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Latest fuel-price overview',
            style: TextStyle(color: Color(0xFF8393A1), fontSize: 12),
          ),
          const SizedBox(height: 19),
          SizedBox(
            height: 105,
            child: CustomPaint(
              painter: FuelTrendPainter(),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Previous',
                style: TextStyle(color: Color(0xFF8A99A6), fontSize: 10),
              ),
              Text(
                'Current',
                style: TextStyle(color: Color(0xFF8A99A6), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFuelSelection() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 5, 22, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Fuel Type',
                style: TextStyle(
                  color: Color(0xFF153B60),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildFuelOption('RON95'),
              _buildFuelOption('BUDI95'),
              _buildFuelOption('RON97'),
              _buildFuelOption('Diesel'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFuelOption(String fuelName) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFE9F4FF),
        child: Icon(Icons.local_gas_station_rounded, color: Color(0xFF1687E8)),
      ),
      title: Text(fuelName),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {
        Navigator.pop(context);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$fuelName selected')));
      },
    );
  }

  void _showHistoryMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('The fuel-price history screen will be connected next.'),
      ),
    );
  }

  Widget _buildErrorSection() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 43),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Unable to load fuel prices.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 17),
          ElevatedButton.icon(
            onPressed: _loadLatestPrice,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class FuelTrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE8EEF4)
      ..strokeWidth = 1;

    for (int index = 1; index <= 3; index++) {
      final y = size.height * index / 4;

      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final areaPath = Path()
      ..moveTo(0, size.height * 0.78)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.68,
        size.width * 0.25,
        size.height * 0.45,
        size.width * 0.38,
        size.height * 0.51,
      )
      ..cubicTo(
        size.width * 0.50,
        size.height * 0.58,
        size.width * 0.61,
        size.height * 0.27,
        size.width * 0.73,
        size.height * 0.36,
      )
      ..cubicTo(
        size.width * 0.84,
        size.height * 0.43,
        size.width * 0.90,
        size.height * 0.20,
        size.width,
        size.height * 0.15,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final areaPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x551687E8), Color(0x051687E8)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(areaPath, areaPaint);

    final linePath = Path()
      ..moveTo(0, size.height * 0.78)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.68,
        size.width * 0.25,
        size.height * 0.45,
        size.width * 0.38,
        size.height * 0.51,
      )
      ..cubicTo(
        size.width * 0.50,
        size.height * 0.58,
        size.width * 0.61,
        size.height * 0.27,
        size.width * 0.73,
        size.height * 0.36,
      )
      ..cubicTo(
        size.width * 0.84,
        size.height * 0.43,
        size.width * 0.90,
        size.height * 0.20,
        size.width,
        size.height * 0.15,
      );

    final linePaint = Paint()
      ..color = const Color(0xFF1687E8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
