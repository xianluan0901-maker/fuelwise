import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../payment/models/payment_model.dart';
import '../services/reward_service.dart';

class RedemptionHistoryScreen extends StatefulWidget {
  const RedemptionHistoryScreen({super.key});

  @override
  State<RedemptionHistoryScreen> createState() =>
      _RedemptionHistoryScreenState();
}

class _RedemptionHistoryScreenState
    extends State<RedemptionHistoryScreen> {
  final RewardService _rewardService = RewardService();

  late Future<List<UserVoucher>> _historyFuture;

  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null) {
      _historyFuture =
          Future.error('User is not logged in.');
      return;
    }

    _historyFuture =
        _rewardService.getRedemptionHistory(
          user.id,
        );
  }

  Future<void> _refreshHistory() async {
    setState(_loadHistory);
    await _historyFuture;
  }

  List<UserVoucher> _filterHistory(
      List<UserVoucher> history,
      ) {
    switch (_selectedStatus) {
      case 'available':
        return history
            .where((item) => item.isAvailable)
            .toList();

      case 'used':
        return history
            .where((item) => item.isUsed)
            .toList();

      case 'expired':
        return history
            .where((item) => item.isExpired)
            .toList();

      default:
        return history;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F8FC),
        title: const Text(
          'Redemption History',
          style: TextStyle(
            color: Color(0xFF173B57),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: FutureBuilder<List<UserVoucher>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState(
              snapshot.error.toString(),
            );
          }

          final allHistory =
              snapshot.data ?? [];

          final filteredHistory =
          _filterHistory(allHistory);

          return RefreshIndicator(
            onRefresh: _refreshHistory,
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
                _buildStatusFilters(allHistory),

                const SizedBox(height: 20),

                Text(
                  '${filteredHistory.length} records',
                  style: const TextStyle(
                    color: Color(0xFF173B57),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 14),

                if (filteredHistory.isEmpty)
                  _buildEmptyState()
                else
                  ...filteredHistory.map(
                        (item) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: 14,
                      ),
                      child: _buildHistoryCard(item),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusFilters(
      List<UserVoucher> history,
      ) {
    final availableCount = history
        .where((item) => item.isAvailable)
        .length;

    final usedCount = history
        .where((item) => item.isUsed)
        .length;

    final expiredCount = history
        .where((item) => item.isExpired)
        .length;

    final filters = {
      'all': 'All (${history.length})',
      'available':
      'Available ($availableCount)',
      'used': 'Used ($usedCount)',
      'expired': 'Expired ($expiredCount)',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.entries.map((entry) {
          final selected =
              _selectedStatus == entry.key;

          return Padding(
            padding:
            const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _selectedStatus = entry.key;
                });
              },
              selectedColor:
              const Color(0xFF1687E8),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: selected
                    ? Colors.white
                    : const Color(0xFF52677A),
                fontWeight: FontWeight.w600,
              ),
              side: const BorderSide(
                color: Color(0xFFDDE7F0),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryCard(
      UserVoucher item,
      ) {
    final status = _getStatus(item);
    final statusColour =
    _getStatusColour(item);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(21),
        onTap: () {
          _showVoucherDetails(item);
        },
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(21),
            border: Border.all(
              color: const Color(0xFFE5ECF3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color:
                  statusColour.withOpacity(0.11),
                  borderRadius:
                  BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.card_giftcard_rounded,
                  color: statusColour,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.voucher?.name ??
                          'Reward Voucher',
                      style: const TextStyle(
                        color: Color(0xFF173B57),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      DateFormat(
                        'dd MMM yyyy, hh:mm a',
                      ).format(
                        item.redeemedAt.toLocal(),
                      ),
                      style: const TextStyle(
                        color: Color(0xFF8292A2),
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
                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColour
                          .withOpacity(0.11),
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColour,
                        fontSize: 10,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF9AA8B6),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVoucherDetails(
      UserVoucher item,
      ) {
    final voucher = item.voucher;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight:
              MediaQuery.sizeOf(context)
                  .height *
                  0.85,
            ),
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              25,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(27),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 35,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                        const Color(0xFFCBD4DC),
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    voucher?.name ??
                        'Reward Voucher',
                    style: const TextStyle(
                      color: Color(0xFF173B57),
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color:
                      const Color(0xFFF3F8FC),
                      borderRadius:
                      BorderRadius.circular(17),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'VOUCHER CODE',
                          style: TextStyle(
                            color:
                            Color(0xFF8292A2),
                            fontSize: 11,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 7),
                        SelectableText(
                          item.code,
                          style: const TextStyle(
                            color:
                            Color(0xFF173B57),
                            fontSize: 22,
                            fontWeight:
                            FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            _copyVoucherCode(
                              item.code,
                            );
                          },
                          icon: const Icon(
                            Icons.copy_rounded,
                          ),
                          label: const Text(
                            'Copy Code',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  _buildSheetRow(
                    'Status',
                    _getStatus(item),
                  ),
                  _buildSheetRow(
                    'Points used',
                    '${voucher?.pointsRequired ?? 0}',
                  ),
                  _buildSheetRow(
                    'Redeemed',
                    DateFormat(
                      'dd MMM yyyy, hh:mm a',
                    ).format(
                      item.redeemedAt.toLocal(),
                    ),
                  ),
                  _buildSheetRow(
                    'Expires',
                    DateFormat(
                      'dd MMM yyyy',
                    ).format(
                      item.expiryDate.toLocal(),
                    ),
                  ),
                  _buildSheetRow(
                    'Valid at',
                    _stationName(voucher),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Terms and Conditions',
                    style: TextStyle(
                      color: Color(0xFF173B57),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    '• Valid for one use only.\n'
                        '• Cannot be exchanged for cash.\n'
                        '• Cannot be combined with another voucher.\n'
                        '• Must be used before the expiry date.',
                    style: TextStyle(
                      color: Color(0xFF6F8090),
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetRow(
      String label,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8292A2),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF173B57),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyVoucherCode(
      String code,
      ) async {
    await Clipboard.setData(
      ClipboardData(text: code),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Voucher code copied'),
      ),
    );
  }

  String _getStatus(UserVoucher item) {
    if (item.isUsed) return 'Used';
    if (item.isExpired) return 'Expired';

    return 'Available';
  }

  Color _getStatusColour(UserVoucher item) {
    if (item.isUsed) {
      return const Color(0xFF8292A2);
    }

    if (item.isExpired) {
      return const Color(0xFFE85D5D);
    }

    return const Color(0xFF2EAD72);
  }

  String _stationName(Voucher? voucher) {
    final brand = voucher?.stationBrand;

    if (brand == null || brand.isEmpty) {
      return 'All participating stations';
    }

    if (brand.toLowerCase() == 'bhp') {
      return 'BHP stations';
    }

    return '${brand[0].toUpperCase()}'
        '${brand.substring(1).toLowerCase()} stations';
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 90),
      child: Column(
        children: [
          Icon(
            Icons.history_rounded,
            color: Color(0xFFB5C1CC),
            size: 60,
          ),
          SizedBox(height: 15),
          Text(
            'No matching redemptions',
            style: TextStyle(
              color: Color(0xFF173B57),
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFE85D5D),
              size: 55,
            ),
            const SizedBox(height: 15),
            const Text(
              'Unable to load history',
              style: TextStyle(
                color: Color(0xFF173B57),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                setState(_loadHistory);
              },
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}