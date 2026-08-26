import 'package:flutter/material.dart';
//import 'package:fuelwisee/features/user_account/screens/profile/profile_main_screen.dart';

import '../../features/fuel_price/screens/home_screen.dart';
import '../../features/user_account/screens/profile/profile_main_screen.dart';
import '../../features/fuel_station/screens/station_list_screen.dart';
import '../../features/payment/screens/payment_history_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    StationListScreen(),
    PaymentHistoryScreen(),
    Center(child: Text('Reward')),
    ProfileMainScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: SafeArea(
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
              selectedItemColor: const Color(0xFF1687E8),
              unselectedItemColor: const Color(0xFF9AA8B6),
              selectedFontSize: 11,
              unselectedFontSize: 11,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.local_gas_station_outlined),
                  activeIcon: Icon(Icons.local_gas_station_rounded),
                  label: 'Fuel',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.location_on_outlined),
                  activeIcon: Icon(Icons.location_on_rounded),
                  label: 'Station',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  activeIcon: Icon(Icons.account_balance_wallet_rounded),
                  label: 'Payment',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.card_giftcard_outlined),
                  activeIcon: Icon(Icons.card_giftcard_rounded),
                  label: 'Reward',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
