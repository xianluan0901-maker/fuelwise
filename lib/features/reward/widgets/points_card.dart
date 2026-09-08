import 'package:flutter/material.dart';

import '../models/reward_model.dart';

class PointsCard extends StatelessWidget {
  final int availablePoints;
  final int totalPoints;
  final int pointsSpent;

  const PointsCard({
    super.key,
    required this.availablePoints,
    required this.totalPoints,
    required this.pointsSpent,
  });

  @override
  Widget build(BuildContext context) {
    final tier = getRewardTier(totalPoints);

    final nextTierThreshold =
    getNextTierThreshold(totalPoints);

    final nextTierName =
    getNextTierName(totalPoints);

    final currentTierStart =
    _getCurrentTierStart(tier);

    final progress =
    _calculateProgress(
      totalPoints: totalPoints,
      currentTierStart: currentTierStart,
      nextTierThreshold: nextTierThreshold,
    );

    final pointsRemaining =
    nextTierThreshold == null
        ? 0
        : nextTierThreshold - totalPoints;

    final tierColours =
    _getTierColours(tier);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tierColours,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: tierColours.first.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMembershipHeader(tier),

          const SizedBox(height: 26),

          const Text(
            'AVAILABLE POINTS',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '$availablePoints',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 27),

          _buildTierProgressText(
            nextTierName: nextTierName,
            nextTierThreshold:
            nextTierThreshold,
            pointsRemaining: pointsRemaining,
          ),

          const SizedBox(height: 9),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor:
              Colors.white.withOpacity(0.22),
              valueColor:
              const AlwaysStoppedAnimation<Color>(
                Color(0xFFFFD75E),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding:
            const EdgeInsets.symmetric(
              vertical: 13,
            ),
            decoration: BoxDecoration(
              color:
              Colors.white.withOpacity(0.14),
              borderRadius:
              BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildStat(
                  label: 'Total Earned',
                  value: totalPoints,
                ),
                Container(
                  width: 1,
                  height: 35,
                  color: Colors.white30,
                ),
                _buildStat(
                  label: 'Points Spent',
                  value: pointsSpent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipHeader(
      String tier,
      ) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color:
            Colors.white.withOpacity(0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getTierIcon(tier),
            color: const Color(0xFFFFD75E),
            size: 29,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                'FuelWise Member',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              Text(
                '${formatRewardTier(tier)} Tier',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color:
            Colors.white.withOpacity(0.18),
            borderRadius:
            BorderRadius.circular(20),
          ),
          child: const Text(
            'ACTIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTierProgressText({
    required String? nextTierName,
    required int? nextTierThreshold,
    required int pointsRemaining,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            nextTierName == null
                ? 'Highest tier achieved'
                : '$pointsRemaining points until '
                '$nextTierName Tier',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),

        const SizedBox(width: 10),

        Text(
          nextTierThreshold == null
              ? 'MAX'
              : '$totalPoints/'
              '$nextTierThreshold',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStat({
    required String label,
    required int value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  int _getCurrentTierStart(String tier) {
    switch (tier.toLowerCase()) {
      case 'gold':
        return 300;
      case 'silver':
        return 100;
      default:
        return 0;
    }
  }

  double _calculateProgress({
    required int totalPoints,
    required int currentTierStart,
    required int? nextTierThreshold,
  }) {
    if (nextTierThreshold == null) {
      return 1;
    }

    final tierRange =
        nextTierThreshold - currentTierStart;

    if (tierRange <= 0) {
      return 1;
    }

    final tierProgress =
        totalPoints - currentTierStart;

    return (tierProgress / tierRange)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  List<Color> _getTierColours(
      String tier,
      ) {
    switch (tier.toLowerCase()) {
      case 'gold':
        return const [
          Color(0xFFE69A10),
          Color(0xFFFFC857),
        ];

      case 'silver':
        return const [
          Color(0xFF667D91),
          Color(0xFF9DAFBE),
        ];

      default:
        return const [
          Color(0xFF087EE1),
          Color(0xFF55B6FF),
        ];
    }
  }

  IconData _getTierIcon(String tier) {
    switch (tier.toLowerCase()) {
      case 'gold':
        return Icons.workspace_premium_rounded;
      case 'silver':
        return Icons.military_tech_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }
}