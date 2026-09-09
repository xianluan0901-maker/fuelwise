import 'package:flutter/material.dart';

class AIFuelAnalysisScreen extends StatelessWidget {
  final String category;

  const AIFuelAnalysisScreen({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text(
          'AI Analysis',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _buildAnalysis(),
      ),
    );
  }

  // ===============================================================
  // SELECT ANALYSIS
  // ===============================================================

  Widget _buildAnalysis() {
    switch (category) {

      case 'spending':
        return _buildSpendingAnalysis();

      case 'fuelType':
        return _buildFuelTypeAnalysis();

      case 'station':
        return _buildStationAnalysis();

      case 'brand':
        return _buildBrandAnalysis();

      case 'overall':
        return _buildOverallAnalysis();

      default:
        return _buildSpendingAnalysis();
    }
  }

  // ===============================================================
  // SPENDING ANALYSIS
  // ===============================================================

  Widget _buildSpendingAnalysis() {
    return _buildPage(
      icon: Icons.attach_money,
      title: 'Fuel Spending Analysis',
      summary:
      'You spent RM180 this month, which is RM32 less than last month.',
      why:
      'Your fuel spending decreased by approximately 15%. This is mainly associated with fewer refuelling trips. You made 8 trips this month compared with 10 trips last month.',
      recommendation:
      'Your fuel spending is currently trending downward. Continue tracking your monthly fuel expenses to maintain better control over your fuel budget.',
    );
  }

  // ===============================================================
  // FUEL TYPE ANALYSIS
  // ===============================================================

  Widget _buildFuelTypeAnalysis() {
    return _buildPage(
      icon: Icons.local_fire_department,
      title: 'Fuel Type Analysis',
      summary:
      'RON95 accounted for 75% of your fuel usage this month.',
      why:
      'RON95 was selected for most of your recorded refuelling transactions. It is currently your most frequently used fuel type.',
      recommendation:
      'Continue tracking your fuel type usage to understand how your fuel choices affect your monthly fuel spending.',
    );
  }

  // ===============================================================
  // STATION ANALYSIS
  // ===============================================================

  Widget _buildStationAnalysis() {
    return _buildPage(
      icon: Icons.local_gas_station,
      title: 'Station Analysis',
      summary:
      'Shell Taman ABC was your most frequently used fuel station with 6 visits this month.',
      why:
      'You visited this station more frequently than the other stations recorded in your fuel history. Your repeated visits may indicate that this station is convenient for your regular travel routes.',
      recommendation:
      'You can continue using this station if it is convenient, while comparing other nearby stations when fuel prices or distance make another option more suitable.',
    );
  }

  // ===============================================================
  // BRAND ANALYSIS
  // ===============================================================

  Widget _buildBrandAnalysis() {
    return _buildPage(
      icon: Icons.business,
      title: 'Petrol Brand Analysis',
      summary:
      'Shell accounted for 50% of your recorded refuelling activity.',
      why:
      'You selected Shell more frequently than the other petrol brands in your recorded fuel transactions this month.',
      recommendation:
      'Continue tracking your petrol brand usage so you can compare your preferences and spending patterns over time.',
    );
  }

  // ===============================================================
  // OVERALL ANALYSIS
  // ===============================================================

  Widget _buildOverallAnalysis() {
    return _buildPage(
      icon: Icons.auto_awesome,
      title: 'Overall Fuel Analysis',
      summary:
      'Your fuel spending improved this month, with RM32 less spent compared with last month.',
      why:
      'You made fewer refuelling trips and RON95 remained your main fuel type. Shell was also your most frequently used petrol brand and station.',
      recommendation:
      'Your current fuel behaviour shows a positive spending trend. Continue recording your refuelling activity so FuelWise MY can provide more personalised insights.',
    );
  }

  // ===============================================================
  // COMMON AI PAGE
  // ===============================================================

  Widget _buildPage({
    required IconData icon,
    required String title,
    required String summary,
    required String why,
    required String recommendation,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // =========================================================
        // AI HEADER
        // =========================================================

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1687E8),
                Color(0xFF52B6F4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 32,
              ),

              const SizedBox(height: 12),

              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'AI-powered insight based on your fuel activity.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // =========================================================
        // SUMMARY
        // =========================================================

        _buildSectionCard(
          icon: icon,
          title: 'What happened?',
          text: summary,
        ),

        const SizedBox(height: 15),

        // =========================================================
        // WHY
        // =========================================================

        _buildSectionCard(
          icon: Icons.help_outline,
          title: 'Why did this happen?',
          text: why,
        ),

        const SizedBox(height: 15),

        // =========================================================
        // RECOMMENDATION
        // =========================================================

        _buildSectionCard(
          icon: Icons.lightbulb_outline,
          title: 'AI Recommendation',
          text: recommendation,
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  // ===============================================================
  // SECTION CARD
  // ===============================================================

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF1687E8),
                ),
              ),

              const SizedBox(width: 12),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF123A63),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF61758A),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}