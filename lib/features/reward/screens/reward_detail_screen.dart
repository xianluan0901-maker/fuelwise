import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../payment/models/payment_model.dart';
import '../models/reward_model.dart';
import '../services/reward_service.dart';

class RewardDetailScreen extends StatefulWidget {
  final Voucher reward;
  final int availablePoints;
  final int totalPoints;

  const RewardDetailScreen({
    super.key,
    required this.reward,
    required this.availablePoints,
    required this.totalPoints,
  });

  @override
  State<RewardDetailScreen> createState() =>
      _RewardDetailScreenState();
}

class _RewardDetailScreenState
    extends State<RewardDetailScreen> {
  final RewardService _rewardService = RewardService();

  bool _isRedeeming = false;

  bool get _tierUnlocked {
    final userTier =
    getRewardTier(widget.totalPoints);

    return rewardTierRank(userTier) >=
        rewardTierRank(widget.reward.minimumTier);
  }

  bool get _canAfford {
    return widget.availablePoints >=
        widget.reward.pointsRequired;
  }

  String get _rewardValue {
    if (widget.reward.discountType ==
        'percentage') {
      return '${widget.reward.discountValue.toStringAsFixed(0)}% OFF';
    }

    return 'RM${widget.reward.discountValue.toStringAsFixed(2)} OFF';
  }

  String get _stationName {
    final brand = widget.reward.stationBrand;

    if (brand == null || brand.isEmpty) {
      return 'All participating stations';
    }

    if (brand.toLowerCase() == 'bhp') {
      return 'BHP stations';
    }

    return '${brand[0].toUpperCase()}'
        '${brand.substring(1).toLowerCase()} stations';
  }

  String get _buttonText {
    if (!_tierUnlocked) {
      return '${formatRewardTier(widget.reward.minimumTier)} '
          'Tier Required';
    }

    if (!_canAfford) {
      final missing =
          widget.reward.pointsRequired -
              widget.availablePoints;

      return 'Need $missing More Points';
    }

    return 'Redeem Reward';
  }

  Future<void> _confirmRedemption() async {
    if (!_tierUnlocked || !_canAfford) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          icon: const Icon(
            Icons.card_giftcard_rounded,
            color: Color(0xFF1687E8),
            size: 42,
          ),
          title: const Text(
            'Redeem this reward?',
            textAlign: TextAlign.center,
          ),
          content: Text(
            '${widget.reward.pointsRequired} points '
                'will be deducted.\n\n'
                'The voucher will expire '
                '${widget.reward.expiryDays} days '
                'after redemption.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment:
          MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Redeem'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _redeemReward();
    }
  }

  Future<void> _redeemReward() async {
    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null) {
      _showMessage('User is not logged in.');
      return;
    }

    setState(() {
      _isRedeeming = true;
    });

    final success =
    await _rewardService.redeemReward(
      userId: user.id,
      voucherId: widget.reward.id,
    );

    if (!mounted) return;

    setState(() {
      _isRedeeming = false;
    });

    if (success) {
      _showMessage(
        'Reward redeemed successfully!',
        success: true,
      );

      Navigator.pop(context, true);
    } else {
      _showMessage(
        'Unable to redeem reward.',
      );
    }
  }

  void _showMessage(
      String message, {
        bool success = false,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: success
            ? const Color(0xFF2EAD72)
            : const Color(0xFFE85D5D),
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tierColour =
    _getTierColour(
      widget.reward.minimumTier,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F8FC),
        title: const Text(
          'Reward Details',
          style: TextStyle(
            color: Color(0xFF173B57),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          18,
          8,
          18,
          35,
        ),
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  tierColour,
                  tierColour.withOpacity(0.70),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.local_offer_rounded,
                  color: Colors.white,
                  size: 45,
                ),
                const SizedBox(height: 12),
                Text(
                  _rewardValue,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  widget.reward.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          Text(
            widget.reward.description ??
                'Redeem this reward using '
                    'your FuelWise points.',
            style: const TextStyle(
              color: Color(0xFF52677A),
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 22),

          _buildInformationCard(),

          const SizedBox(height: 20),

          _buildTermsCard(),

          const SizedBox(height: 25),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed:
              _tierUnlocked &&
                  _canAfford &&
                  !_isRedeeming
                  ? _confirmRedemption
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFF1687E8),
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                const Color(0xFFE1E7ED),
                disabledForegroundColor:
                const Color(0xFF8795A3),
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(16),
                ),
              ),
              child: _isRedeeming
                  ? const SizedBox(
                width: 21,
                height: 21,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Text(
                _buttonText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: const Color(0xFFE5ECF3),
        ),
      ),
      child: Column(
        children: [
          _buildInformationRow(
            icon: Icons.stars_rounded,
            label: 'Points required',
            value:
            '${widget.reward.pointsRequired} points',
          ),
          const Divider(height: 25),
          _buildInformationRow(
            icon:
            Icons.workspace_premium_rounded,
            label: 'Minimum tier',
            value:
            '${formatRewardTier(widget.reward.minimumTier)} Tier',
          ),
          const Divider(height: 25),
          _buildInformationRow(
            icon:
            Icons.local_gas_station_rounded,
            label: 'Valid station',
            value: _stationName,
          ),
          const Divider(height: 25),
          _buildInformationRow(
            icon: Icons.schedule_rounded,
            label: 'Validity',
            value:
            '${widget.reward.expiryDays} days',
          ),
          const Divider(height: 25),
          _buildInformationRow(
            icon: Icons.discount_rounded,
            label: 'Discount type',
            value:
            widget.reward.discountType ==
                'percentage'
                ? 'Percentage discount'
                : 'Fixed discount',
          ),
        ],
      ),
    );
  }

  Widget _buildInformationRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xFFE8F4FF),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: const Color(0xFF1687E8),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8292A2),
              fontSize: 13,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF173B57),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EB),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: const Color(0xFFFFE5A3),
        ),
      ),
      child: const Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Color(0xFFE69A10),
              ),
              SizedBox(width: 8),
              Text(
                'Terms and Conditions',
                style: TextStyle(
                  color: Color(0xFF173B57),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 13),
          Text(
            '• This voucher is valid for one use only.\n'
                '• It cannot be exchanged for cash.\n'
                '• It cannot be combined with another voucher.\n'
                '• It must be used before its expiry date.\n'
                '• Station-specific vouchers are valid only '
                'at the stated station brand.',
            style: TextStyle(
              color: Color(0xFF6D6042),
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTierColour(String tier) {
    switch (tier.toLowerCase()) {
      case 'gold':
        return const Color(0xFFF2A51A);
      case 'silver':
        return const Color(0xFF7A8B9B);
      default:
        return const Color(0xFF1687E8);
    }
  }
}