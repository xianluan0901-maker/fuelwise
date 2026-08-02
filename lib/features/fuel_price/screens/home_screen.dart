import 'package:flutter/material.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../user_account/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../user_account/screens/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FuelWise MY"),
        actions: [],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Good Morning 👋",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height:20),
            const Text(
              "Latest Fuel Price",
              style: TextStyle(
                fontSize:18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height:15),
            fuelCard(
              "RON95",
              "RM 2.05 / Liter",
            ),
            fuelCard(
              "RON97",
              "RM 3.15 / Liter",
            ),
            fuelCard(
              "Diesel",
              "RM 2.15 / Liter",
            ),
            const SizedBox(height:20),

            const Text(
              "Monthly Fuel Spending",
              style: TextStyle(
                fontSize:18,
                fontWeight:FontWeight.bold,
              ),
            ),

            const SizedBox(height:10),
            const Text(
              "RM 280",
              style:TextStyle(
                fontSize:30,
                color:Colors.blue,
                fontWeight:FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

    );
  }

  Widget fuelCard(String type,String price){
    return Card(
      child: ListTile(
        leading: const Icon(
          Icons.local_gas_station,
        ),
        title: Text(type),
        subtitle: Text(price),
      ),
    );
  }
}