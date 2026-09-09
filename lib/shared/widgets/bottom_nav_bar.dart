import 'package:flutter/material.dart';

import '../../features/fuel_price/screens/home_screen.dart';
import '../../features/user_account/screens/profile/profile_screen.dart';
import 'package:fuelwisee/features/fuel_station/screens/station_list_screen.dart';
import '../../features/payment/screens/payment_history_screen.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int currentIndex = 0;

  final pages = [
    const HomeScreen(),
    const StationListScreen(),
    const PaymentHistoryScreen(),
    const Center(child: Text("Reward")),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: pages[currentIndex],

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 0,
              selectedItemColor: Colors.lightBlue,
              unselectedItemColor: Colors.grey,
              onTap: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.local_gas_station),
                  label: "Fuel",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.map),
                  label: "Station",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.payment),
                  label: "Payment",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.card_giftcard),
                  label: "Reward",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: "Profile",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}