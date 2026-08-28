import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../payment/models/payment_model.dart';
import '../services/reward_service.dart';
import '../models/reward_model.dart';
import 'reward_detail_screen.dart';

class RewardCatalogueScreen extends StatefulWidget {
  const RewardCatalogueScreen({super.key});

  @override
  State<RewardCatalogueScreen> createState() =>
      _RewardCatalogueScreenState();
}

class _RewardCatalogueScreenState
    extends State<RewardCatalogueScreen> {
  final RewardService _rewardService = RewardService();

  List<Voucher> _rewards = [];

  int _availablePoints = 0;
  int _totalPoints = 0;

  bool _isLoading = true;
  String? _errorMessage;
  String? _redeemingRewardId;

  // Recommended default filters.
  String _selectedTierFilter = 'unlocked';
  String _selectedBrandFilter = 'all';

  // Display eight rewards at a time.
  static const int _pageSize = 8;
  int _visibleRewardCount = _pageSize;

  final Map<String, String> _tierFilters = const {
    'all': 'All',
    'unlocked': 'Unlocked',
    'blue': 'Blue',
    'silver': 'Silver',
    'gold': 'Gold',
  };

  final Map<String, String> _brandFilters = const {
    'all': 'All Brands',
    'universal': 'Universal',
    'petronas': 'Petronas',
    'shell': 'Shell',
    'petron': 'Petron',
    'caltex': 'Caltex',
    'bhp': 'BHP',
  };

  @override
  void initState() {
    super.initState();
    _loadCatalogue();
  }

  Future<void> _loadCatalogue() async {
    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'User is not logged in.';
      });

      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _rewardService.getAvailableRewards(),
        _rewardService.getUserPoints(user.id),
      ]);

      if (!mounted) return;

      final points =
      results[1] as Map<String, dynamic>;

      setState(() {
        _rewards = results[0] as List<Voucher>;

        _availablePoints =
            points['available_points'] ?? 0;

        _totalPoints =
            points['total_points'] ?? 0;

        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _openRewardDetails(
      Voucher reward,
      ) async {
    final redeemed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RewardDetailScreen(
          reward: reward,
          availablePoints: _availablePoints,
          totalPoints: _totalPoints,
        ),
      ),
    );

    if (redeemed == true && mounted) {
      await _loadCatalogue();
    }
  }


  bool _isTierUnlocked(Voucher reward) {
    final userTier =
    getRewardTier(_totalPoints);

    return rewardTierRank(userTier) >=
        rewardTierRank(reward.minimumTier);
  }

  bool _canAfford(Voucher reward) {
    return _availablePoints >= reward.pointsRequired;
  }

  List<Voucher> get _filteredRewards {
    final filtered = _rewards.where((reward) {
      bool matchesTier;

      if (_selectedTierFilter == 'unlocked') {
        matchesTier = _isTierUnlocked(reward);
      } else if (_selectedTierFilter == 'all') {
        matchesTier = true;
      } else {
        matchesTier =
            reward.minimumTier.toLowerCase() ==
                _selectedTierFilter;
      }

      bool matchesBrand;

      if (_selectedBrandFilter == 'all') {
        matchesBrand = true;
      } else if (_selectedBrandFilter ==
          'universal') {
        matchesBrand = reward.stationBrand == null ||
            reward.stationBrand!.isEmpty;
      } else {
        matchesBrand =
            reward.stationBrand?.toLowerCase() ==
                _selectedBrandFilter;
      }

      return matchesTier && matchesBrand;
    }).toList();

    // Show affordable rewards first.
    filtered.sort((first, second) {
      final firstAffordable = _canAfford(first);
      final secondAffordable = _canAfford(second);

      if (firstAffordable != secondAffordable) {
        return firstAffordable ? -1 : 1;
      }

      return first.pointsRequired.compareTo(
        second.pointsRequired,
      );
    });

    return filtered;
  }

  void _resetFilters() {
    setState(() {
      _selectedTierFilter = 'unlocked';
      _selectedBrandFilter = 'all';
      _visibleRewardCount = _pageSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF5F8FC),
        title: const Text(
          'Reward Catalogue',
          style: TextStyle(
            color: Color(0xFF173B57),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    final allFilteredRewards = _filteredRewards;

    final visibleRewards = allFilteredRewards
        .take(_visibleRewardCount)
        .toList();

    return RefreshIndicator(
      onRefresh: _loadCatalogue,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          18,
          8,
          18,
          35,
        ),
        children: [
          _buildMemberBanner(),

          const SizedBox(height: 22),

          _buildCompactFilters(),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: Text(
                  'Showing ${visibleRewards.length} of '
                      '${allFilteredRewards.length}',
                  style: const TextStyle(
                    color: Color(0xFF173B57),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_selectedTierFilter == 'unlocked')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F7EF),
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Your tier',
                    style: TextStyle(
                      color: Color(0xFF2EAD72),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 15),

          if (allFilteredRewards.isEmpty)
            _buildEmptyState()
          else ...[
            GridView.builder(
              shrinkWrap: true,
              physics:
              const NeverScrollableScrollPhysics(),
              itemCount: visibleRewards.length,
              gridDelegate:
              const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 230,
                mainAxisExtent: 315,
                crossAxisSpacing: 13,
                mainAxisSpacing: 13,
              ),
              itemBuilder: (context, index) {
                final reward = visibleRewards[index];

                return InkWell(
                  borderRadius: BorderRadius.circular(19),
                  onTap: () {
                    _openRewardDetails(reward);
                  },
                  child: _buildRewardCard(reward),
                );
              },
            ),

            if (visibleRewards.length <
                allFilteredRewards.length) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _visibleRewardCount +=
                          _pageSize;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                    const Color(0xFF1687E8),
                    side: const BorderSide(
                      color: Color(0xFF1687E8),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(15),
                    ),
                  ),
                  icon: const Icon(
                    Icons.expand_more_rounded,
                  ),
                  label: Text(
                    'Load More '
                        '(${allFilteredRewards.length - visibleRewards.length} remaining)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildMemberBanner() {
    final tier = getRewardTier(_totalPoints);
    final colour = _tierColour(tier);

    String tierMessage;

    if (tier == 'blue') {
      tierMessage =
      '${100 - _totalPoints} points until Silver';
    } else if (tier == 'silver') {
      tierMessage =
      '${300 - _totalPoints} points until Gold';
    } else {
      tierMessage = 'Highest tier achieved';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colour,
            colour.withOpacity(0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colour.withOpacity(0.20),
            blurRadius: 17,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 51,
            height: 51,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFFFD75E),
              size: 29,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatText(tier)} Tier',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tierMessage,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              Text(
                '$_availablePoints pts',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'available',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$_totalPoints lifetime',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFilters() {
    final hasActiveFilter =
        _selectedTierFilter != 'unlocked' ||
            _selectedBrandFilter != 'all';

    return Row(
      children: [
        Expanded(
          child: _buildDropdownFilter(
            key: ValueKey(
              'tier-$_selectedTierFilter',
            ),
            label: 'Reward Level',
            selectedValue: _selectedTierFilter,
            options: _tierFilters,
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _selectedTierFilter = value;
                _visibleRewardCount = _pageSize;
              });
            },
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _buildDropdownFilter(
            key: ValueKey(
              'brand-$_selectedBrandFilter',
            ),
            label: 'Station Brand',
            selectedValue: _selectedBrandFilter,
            options: _brandFilters,
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _selectedBrandFilter = value;
                _visibleRewardCount = _pageSize;
              });
            },
          ),
        ),

        if (hasActiveFilter) ...[
          const SizedBox(width: 7),
          SizedBox(
            width: 42,
            height: 42,
            child: IconButton(
              tooltip: 'Reset filters',
              padding: EdgeInsets.zero,
              onPressed: _resetFilters,
              style: IconButton.styleFrom(
                backgroundColor:
                const Color(0xFFE8F4FF),
                foregroundColor:
                const Color(0xFF1687E8),
              ),
              icon: const Icon(
                Icons.refresh_rounded,
                size: 20,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDropdownFilter({
    required Key key,
    required String label,
    required String selectedValue,
    required Map<String, String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      key: key,
      initialValue: selectedValue,
      isExpanded: true,
      menuMaxHeight: 350,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF71869A),
          fontSize: 11,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.fromLTRB(
          12,
          7,
          8,
          7,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFFDDE7F0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFF1687E8),
            width: 1.5,
          ),
        ),
      ),
      items: options.entries.map((entry) {
        return DropdownMenuItem<String>(
          value: entry.key,
          child: Text(
            entry.value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF173B57),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildRewardCard(Voucher reward) {
    final tierUnlocked =
    _isTierUnlocked(reward);

    final canAfford = _canAfford(reward);

    final isRedeeming =
        _redeemingRewardId == reward.id;

    final tierColour =
    _tierColour(reward.minimumTier);

    String buttonText;

    if (!tierUnlocked) {
      buttonText =
      '${_formatText(reward.minimumTier)} Tier';
    } else if (!canAfford) {
      final missing =
          reward.pointsRequired - _availablePoints;

      buttonText = 'Need $missing pts';
    } else {
      buttonText = 'Redeem';
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: const Color(0xFFE5ECF3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D173B57),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 82,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: tierUnlocked
                    ? [
                  tierColour,
                  tierColour.withOpacity(0.70),
                ]
                    : [
                  const Color(0xFF9BA8B4),
                  const Color(0xFFC3CBD2),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                Icon(
                  tierUnlocked
                      ? Icons.local_offer_rounded
                      : Icons.lock_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(height: 5),
                Text(
                  _rewardValue(reward),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _buildBadge(
                        _formatText(
                          reward.minimumTier,
                        ),
                        tierColour,
                      ),
                      _buildBadge(
                        reward.stationBrand == null
                            ? 'Universal'
                            : _formatBrand(
                          reward.stationBrand!,
                        ),
                        const Color(0xFF1687E8),
                      ),
                    ],
                  ),

                  const SizedBox(height: 9),

                  Text(
                    reward.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF173B57),
                      fontSize: 13,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const Spacer(),

                  Row(
                    children: [
                      const Icon(
                        Icons.stars_rounded,
                        color: Color(0xFFFFA31A),
                        size: 17,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${reward.pointsRequired} points',
                          style: const TextStyle(
                            color: Color(0xFF173B57),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed:
                      tierUnlocked &&
                          canAfford &&
                          !isRedeeming
                          ? () {
                        _confirmRedemption(
                          reward,
                        );
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 5,
                        ),
                        elevation: 0,
                        backgroundColor:
                        const Color(0xFF1687E8),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                        const Color(0xFFE3E9EF),
                        disabledForegroundColor:
                        const Color(0xFF8795A3),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(11),
                        ),
                      ),
                      child: isRedeeming
                          ? const SizedBox(
                        width: 17,
                        height: 17,
                        child:
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Text(
                        buttonText,
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(
      String label,
      Color colour,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: colour.withOpacity(0.11),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colour,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> _confirmRedemption(
      Voucher reward,
      ) async {
    if (!_isTierUnlocked(reward)) {
      _showMessage(
        '${_formatText(reward.minimumTier)} '
            'Tier is required.',
      );

      return;
    }

    if (!_canAfford(reward)) {
      final missing =
          reward.pointsRequired - _availablePoints;

      _showMessage(
        'You need $missing more points.',
      );

      return;
    }

    final stationText =
    reward.stationBrand == null
        ? 'All participating stations'
        : '${_formatBrand(reward.stationBrand!)} stations';

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
            size: 40,
          ),
          title: const Text(
            'Redeem this reward?',
            textAlign: TextAlign.center,
          ),
          content: Text(
            '${reward.name}\n\n'
                '${reward.pointsRequired} points will be deducted.\n'
                'Valid at: $stationText',
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
      await _redeemReward(reward);
    }
  }

  Future<void> _redeemReward(
      Voucher reward,
      ) async {
    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null) return;

    setState(() {
      _redeemingRewardId = reward.id;
    });

    final success =
    await _rewardService.redeemReward(
      userId: user.id,
      voucherId: reward.id,
    );

    if (!mounted) return;

    setState(() {
      _redeemingRewardId = null;
    });

    if (success) {
      _showMessage(
        '${reward.name} redeemed successfully!',
        success: true,
      );

      await _loadCatalogue();
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 70,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: Color(0xFFB5C1CC),
            size: 58,
          ),
          const SizedBox(height: 14),
          const Text(
            'No matching rewards',
            style: TextStyle(
              color: Color(0xFF173B57),
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try changing or clearing the filters.',
            style: TextStyle(
              color: Color(0xFF8292A2),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _resetFilters,
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Color(0xFF9AA8B6),
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load rewards',
              style: TextStyle(
                color: Color(0xFF173B57),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadCatalogue,
              icon:
              const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  String _rewardValue(Voucher reward) {
    if (reward.discountType == 'percentage') {
      return '${reward.discountValue.toStringAsFixed(0)}% OFF';
    }

    return 'RM${reward.discountValue.toStringAsFixed(2)} OFF';
  }

  String _formatText(String value) {
    if (value.isEmpty) return '';

    return '${value[0].toUpperCase()}'
        '${value.substring(1).toLowerCase()}';
  }

  String _formatBrand(String brand) {
    if (brand.toLowerCase() == 'bhp') {
      return 'BHP';
    }

    return _formatText(brand);
  }

  Color _tierColour(String tier) {
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