import 'package:flutter/material.dart';
import '../../features/fuel_price/screens/home_screen.dart';
import '../../features/user_account/screens/profile_screen.dart';


class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}


class _MainNavigationState extends State<MainNavigation> {

  int currentIndex = 0;


  final pages = [
    const HomeScreen(),
    const Center(child: Text("Station")),
    const Center(child: Text("Payment")),
    const Center(child: Text("Reward")),
    const ProfileScreen(),
  ];


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: pages[currentIndex],

      bottomNavigationBar: BottomNavigationBar(

        currentIndex: currentIndex,

        type: BottomNavigationBarType.fixed,

        selectedItemColor: Colors.lightBlue,


        onTap: (index){

          setState((){

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