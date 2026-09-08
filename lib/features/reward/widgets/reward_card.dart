import 'package:flutter/material.dart';

import '../../payment/models/payment_model.dart';

class RewardCard extends StatelessWidget {
  final Voucher reward;
  final int availablePoints;
  final bool isRedeeming;
  final VoidCallback onRedeem;

  const RewardCard({
    super.key,
    required this.reward,
    required this.availablePoints,
    required this.isRedeeming,
    required this.onRedeem,
  });

  bool get canAfford =>
      availablePoints >= reward.pointsRequired;

  String get rewardValue {
    if (reward.discountType == 'percentage') {
      return '${reward.discountValue.toStringAsFixed(0)}% OFF';
    }

    return 'RM${reward.discountValue.toStringAsFixed(2)} OFF';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE7EDF4),
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
            height: 115,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF087EE1),
                  Color(0xFF64BDFF),
                ],
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(21),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -25,
                  right: -15,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.local_offer_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rewardValue,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  reward.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF173B57),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  reward.description ??
                      'Redeem this reward using your points.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8292A2),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: Color(0xFFFFA31A),
                      size: 20,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${reward.pointsRequired} points',
                        style: const TextStyle(
                          color: Color(0xFF173B57),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${reward.expiryDays} days',
                      style: const TextStyle(
                        color: Color(0xFF8292A2),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 43,
                  child: ElevatedButton(
                    onPressed:
                    canAfford && !isRedeeming
                        ? onRedeem
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF1687E8),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                      const Color(0xFFE5EAF0),
                      disabledForegroundColor:
                      const Color(0xFF94A1AE),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(13),
                      ),
                    ),
                    child: isRedeeming
                        ? const SizedBox(
                      width: 19,
                      height: 19,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : Text(
                      canAfford
                          ? 'Redeem Now'
                          : 'Not Enough Points',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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