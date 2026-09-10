import 'package:flutter/material.dart';

import '../../features/fuel_price/screens/home_screen.dart';
import '../../features/user_account/screens/profile/profile_main_screen.dart';
import '../../features/fuel_station/screens/station_list_screen.dart';
import '../../features/payment/screens/payment_history_screen.dart';
import '../../features/reward/screens/reward_home_screen.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  static const _blue = Color(0xFF1687E8);
  static const _muted = Color(0xFF9AA8B6);

  late int _currentIndex;

  final List<Widget?> _pages = [
    const HomeScreen(),
    null,
    null,
    null,
    null,
  ];

  static const _labels = [
    'Fuel',
    'Station',
    'Payment',
    'Reward',
    'Account',
  ];

  static const _icons = [
    Icons.local_gas_station_outlined,
    Icons.location_on_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.card_giftcard_outlined,
    Icons.person_outline_rounded,
  ];

  static const _activeIcons = [
    Icons.local_gas_station_rounded,
    Icons.location_on_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.card_giftcard_rounded,
    Icons.person_rounded,
  ];

  Widget _createPage(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const StationListScreen();
      case 2:
        return const PaymentHistoryScreen();
      case 3:
        return const RewardHomeScreen();
      case 4:
        return const ProfileMainScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  void initState() {
    super.initState();

    _currentIndex =
    widget.initialIndex >= 0 && widget.initialIndex < _pages.length
        ? widget.initialIndex
        : 0;

    _pages[_currentIndex] ??= _createPage(_currentIndex);
  }

  void _selectPage(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _pages[index] ??= _createPage(index);
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBody: !isLandscape,
      body: Row(
        children: [
          // Keep the page stack in the same position in the widget tree.
          isLandscape
              ? _buildSideNavigation()
              : const SizedBox.shrink(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _pages
                  .map((page) => page ?? const SizedBox.shrink())
                  .toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar:
      isLandscape ? null : _buildBottomNavigation(),
    );
  }

  Widget _buildSideNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: SafeArea(
        left: false,
        right: false,
        child: SizedBox(
          width: 68,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int index = 0;
                      index < _labels.length;
                      index++)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Semantics(
                            selected: index == _currentIndex,
                            child: Material(
                              color: index == _currentIndex
                                  ? const Color(0xFFE1F2FF)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                onTap: () => _selectPage(index),
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 7,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          index == _currentIndex
                                              ? _activeIcons[index]
                                              : _icons[index],
                                          size: 22,
                                          color: index == _currentIndex
                                              ? _blue
                                              : _muted,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          _labels[index],
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: index == _currentIndex
                                                ? _blue
                                                : const Color(0xFF718096),
                                            fontWeight:
                                            index == _currentIndex
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A173B57),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: _blue,
            unselectedItemColor: _muted,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
            onTap: _selectPage,
            items: [
              for (int index = 0; index < _labels.length; index++)
                BottomNavigationBarItem(
                  icon: Icon(_icons[index]),
                  activeIcon: Icon(_activeIcons[index]),
                  label: _labels[index],
                ),
            ],
          ),
        ),
      ),
    );
  }
}