import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/reward_service.dart';
import '../widgets/points_card.dart';
import 'reward_catalogue_screen.dart';
import 'redemption_history_screen.dart';

class RewardHomeScreen extends StatefulWidget {
  const RewardHomeScreen({super.key});

  @override
  State<RewardHomeScreen> createState() =>
      _RewardHomeScreenState();
}

class _RewardHomeScreenState extends State<RewardHomeScreen> {
  final RewardService _rewardService = RewardService();

  late Future<Map<String, dynamic>> _pointsFuture;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  void _loadPoints() {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      _pointsFuture = Future.error(
        'User is not logged in',
      );
      return;
    }

    _pointsFuture = _rewardService.getUserPoints(user.id);
  }

  Future<void> _refreshPoints() async {
    setState(() {
      _loadPoints();
    });

    await _pointsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('My Rewards'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _pointsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error);
          }

          final points = snapshot.data ?? {};

          final int availablePoints =
              points['available_points'] ?? 0;
          final int totalPoints =
              points['total_points'] ?? 0;
          final int pointsSpent =
              points['points_spent'] ?? 0;

          return RefreshIndicator(
            onRefresh: _refreshPoints,
            child: ListView(
              physics:
              const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                18,
                12,
                18,
                120,
              ),
              children: [
                PointsCard(
                  availablePoints: availablePoints,
                  totalPoints: totalPoints,
                  pointsSpent: pointsSpent,
                ),

                const SizedBox(height: 28),

                _buildSectionHeader(
                  title: 'Explore Rewards',
                  subtitle:
                  'Use your points and enjoy more benefits',
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.card_giftcard_rounded,
                        title: 'Catalogue',
                        subtitle: 'Explore rewards',
                        iconColor:
                        const Color(0xFF7447E8),
                        iconBackground:
                        const Color(0xFFF0EAFF),
                        onTap: _openCatalogue,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.history_rounded,
                        title: 'History',
                        subtitle: 'Past redemptions',
                        iconColor:
                        const Color(0xFFFF8736),
                        iconBackground:
                        const Color(0xFFFFEEE2),
                        onTap: _openHistory,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                _buildSectionHeader(
                  title: 'How It Works',
                  subtitle:
                  'Earn and redeem points in three easy steps',
                ),

                const SizedBox(height: 15),

                _buildHowItWorks(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF173B57),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF8292A2),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color iconBackground,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 174,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE8EEF5),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D173B57),
                blurRadius: 15,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 27,
                ),
              ),

              const Spacer(),

              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF173B57),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8292A2),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: iconColor,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 22,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE8EEF5),
        ),
      ),
      child: Row(
        children: [
          _buildStep(
            icon: Icons.local_gas_station_rounded,
            label: 'Refuel',
            color: const Color(0xFF1687E8),
            background: const Color(0xFFE8F4FF),
          ),
          _buildStepArrow(),
          _buildStep(
            icon: Icons.stars_rounded,
            label: 'Earn',
            color: const Color(0xFFFFA31A),
            background: const Color(0xFFFFF3DB),
          ),
          _buildStepArrow(),
          _buildStep(
            icon: Icons.redeem_rounded,
            label: 'Redeem',
            color: const Color(0xFF7447E8),
            background: const Color(0xFFF0EAFF),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required IconData icon,
    required String label,
    required Color color,
    required Color background,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 25,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF173B57),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepArrow() {
    return const Padding(
      padding: EdgeInsets.only(
        left: 2,
        right: 2,
        bottom: 22,
      ),
      child: Icon(
        Icons.arrow_forward_rounded,
        color: Color(0xFFB4C0CB),
        size: 17,
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return RefreshIndicator(
      onRefresh: _refreshPoints,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(30),
        children: [
          const SizedBox(height: 140),
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFF9AA8B6),
            size: 60,
          ),
          const SizedBox(height: 18),
          const Text(
            'Unable to load rewards',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF173B57),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8292A2),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _loadPoints();
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCatalogue() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const RewardCatalogueScreen(),
      ),
    );

    if (!mounted) return;

    setState(() {
      _loadPoints();
    });
  }

  Future<void> _openHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const RedemptionHistoryScreen(),
      ),
    );
  }
}