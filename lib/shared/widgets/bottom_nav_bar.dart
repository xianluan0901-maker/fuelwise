import 'package:flutter/material.dart';
import 'package:fuelwisee/features/user_account/screens/profile/profile_main_screen.dart';

import '../../features/fuel_price/screens/home_screen.dart';
import '../../features/user_account/screens/profile/profile_screen.dart';
import 'package:fuelwisee/features/fuel_station/screens/station_list_screen.dart';
import '../../features/payment/screens/payment_history_screen.dart';
import '../../features/user_account/screens/profile/profile_screen.dart';
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
    const ProfileMainScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.lightBlue,
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
    );
  }
}