import 'package:flutter/material.dart';

import 'ai_fuel_analysis_screen.dart';

class FuelReportScreen extends StatelessWidget {
  const FuelReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text(
          'Fuel Report',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // =====================================================
            // HEADER
            // =====================================================

            const Text(
              'Your Fuel Report',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF123A63),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Here is a summary of your fuel activity this month.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF61758A),
              ),
            ),

            const SizedBox(height: 24),

            // =====================================================
            // MONTHLY SUMMARY
            // =====================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    'Monthly Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF123A63),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [

                      Expanded(
                        child: _buildSummaryItem(
                          'RM180',
                          'Fuel Spending',
                        ),
                      ),

                      Expanded(
                        child: _buildSummaryItem(
                          '8',
                          'Refuelling Trips',
                        ),
                      ),

                      Expanded(
                        child: _buildSummaryItem(
                          '75%',
                          'RON95 Usage',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF7EE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Icon(
                          Icons.trending_down,
                          color: Colors.green,
                        ),

                        SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            'You spent RM32 less on fuel this month compared with last month.',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // =====================================================
            // FUEL SPENDING
            // =====================================================

            _buildReportCard(
              context: context,
              icon: Icons.attach_money,
              iconColor: Colors.green,
              title: 'Fuel Spending',
              value: 'RM180.00',
              comparison: '↓ RM32 compared with last month',
              description:
              'Your fuel spending decreased by 15% this month.',
              category: 'spending',
            ),

            const SizedBox(height: 15),

            // =====================================================
            // FUEL TYPE
            // =====================================================

            _buildReportCard(
              context: context,
              icon: Icons.local_fire_department,
              iconColor: Colors.orange,
              title: 'Fuel Type',
              value: 'RON95',
              comparison: '75% of your fuel usage',
              description:
              'RON95 is your most frequently used fuel type.',
              category: 'fuelType',
            ),

            const SizedBox(height: 15),

            // =====================================================
            // MOST USED STATION
            // =====================================================

            _buildReportCard(
              context: context,
              icon: Icons.local_gas_station,
              iconColor: const Color(0xFF1687E8),
              title: 'Most Used Station',
              value: 'Shell Taman ABC',
              comparison: '6 visits this month',
              description:
              'This is your most frequently used fuel station.',
              category: 'station',
            ),

            const SizedBox(height: 15),

            // =====================================================
            // PETROL BRAND
            // =====================================================

            _buildReportCard(
              context: context,
              icon: Icons.business,
              iconColor: Colors.purple,
              title: 'Petrol Brand',
              value: 'Shell',
              comparison: '50% of your refuelling',
              description:
              'Shell is your most frequently used petrol brand.',
              category: 'brand',
            ),

            const SizedBox(height: 25),

            // =====================================================
            // AI ADVISOR
            // =====================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1687E8),
                    Color(0xFF52B6F4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Row(
                    children: [

                      Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 28,
                      ),

                      SizedBox(width: 10),

                      Text(
                        'AI Fuel Advisor',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Get personalised insights about your fuel spending, fuel type and station usage.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const AIFuelAnalysisScreen(
                              category: 'overall',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1687E8),
                      ),
                      child: const Text(
                        'View Overall AI Analysis',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // SUMMARY ITEM
  // ===============================================================

  Widget _buildSummaryItem(
      String value,
      String label,
      ) {
    return Column(
      children: [

        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1687E8),
          ),
        ),

        const SizedBox(height: 5),

        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF61758A),
          ),
        ),
      ],
    );
  }

  // ===============================================================
  // REPORT CARD
  // ===============================================================

  Widget _buildReportCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String comparison,
    required String description,
    required String category,
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [

                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF123A63),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Text(
              value,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1687E8),
              ),
            ),

            const SizedBox(height: 5),

            Text(
              comparison,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1687E8),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF61758A),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AIFuelAnalysisScreen(
                            category: category,
                          ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.lightbulb_outline,
                  size: 18,
                ),
                label: const Text(
                  'Understand Why',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}