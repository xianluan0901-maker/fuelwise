import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/fuel_price_model.dart';

class FuelTrendChart extends StatelessWidget {
  final List<FuelPrice> prices;

  // Supports one, two or all three fuel types.
  final List<String> fuelTypes;

  final bool isEastMalaysia;

  // Compact mode is used on the Home screen.
  final bool compact;

  const FuelTrendChart({
    super.key,
    required this.prices,
    required this.fuelTypes,
    this.isEastMalaysia = false,
    this.compact = false,
  });

  double _getPrice(
      FuelPrice price,
      String fuelType,
      ) {
    switch (fuelType) {
      case 'RON97':
        return price.ron97;

      case 'Diesel':
        return price.dieselForRegion(isEastMalaysia);

      case 'RON95':
      default:
        return price.ron95;
    }
  }

  Color _fuelColor(String fuelType) {
    switch (fuelType) {
      case 'RON97':
        return const Color(0xFF14A6A6);

      case 'Diesel':
        return const Color(0xFF7B61D1);

      case 'RON95':
      default:
        return const Color(0xFF3563FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (prices.isEmpty || fuelTypes.isEmpty) {
      return const Center(
        child: Text('No price history available'),
      );
    }

    // The API service returns newest records first.
    // The chart needs oldest records first.
    final chartPrices = List<FuelPrice>.from(prices)
      ..sort((first, second) {
        return first.date.compareTo(second.date);
      });

    // Include values from all selected fuel types when
    // calculating the Y-axis range.
    final allValues = <double>[];

    for (final fuelType in fuelTypes) {
      allValues.addAll(
        chartPrices.map(
              (price) => _getPrice(price, fuelType),
        ),
      );
    }

    if (allValues.isEmpty) {
      return const Center(
        child: Text('No price history available'),
      );
    }

    final lowestPrice = allValues.reduce(
          (first, second) => first < second ? first : second,
    );

    final highestPrice = allValues.reduce(
          (first, second) => first > second ? first : second,
    );

    // Add some space above and below the lines.
    final minY = lowestPrice - 0.10;
    final maxY = highestPrice + 0.10;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: chartPrices.length == 1
            ? 1
            : (chartPrices.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,

        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
        ),

        borderData: FlBorderData(
          show: !compact,
          border: Border.all(
            color: const Color(0xFFE5EBF1),
          ),
        ),

        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),

          rightTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),

          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: !compact,
              reservedSize: compact ? 0 : 48,
              getTitlesWidget: (value, meta) {
                const tolerance = 0.001;

                final isMinimum =
                    (value - minY).abs() < tolerance;

                final isMaximum =
                    (value - maxY).abs() < tolerance;

                // Hide boundary labels because they may overlap
                // with the closest automatic interval labels.
                if (isMinimum || isMaximum) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    value.toStringAsFixed(2),
                    style: const TextStyle(
                      color: Color(0xFF718096),
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),

          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: compact ? 25 : 32,
              interval: chartPrices.length > 4
                  ? (chartPrices.length / 4).ceilToDouble()
                  : 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();

                if (index < 0 || index >= chartPrices.length) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat(
                      compact ? 'MMM' : 'd MMM',
                    ).format(chartPrices[index].date),
                    style: TextStyle(
                      color: const Color(0xFF718096),
                      fontSize: compact ? 8 : 9,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) {
              return const Color(0xFF153B60);
            },
            tooltipBorderRadius: BorderRadius.circular(10),
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final priceIndex = spot.x.toInt();

                if (priceIndex < 0 ||
                    priceIndex >= chartPrices.length) {
                  return null;
                }

                final fuelIndex = spot.barIndex;

                if (fuelIndex < 0 ||
                    fuelIndex >= fuelTypes.length) {
                  return null;
                }

                final fuelType = fuelTypes[fuelIndex];
                final date = chartPrices[priceIndex].date;

                return LineTooltipItem(
                  '$fuelType\n'
                      '${DateFormat('d MMM yyyy').format(date)}\n'
                      'RM ${spot.y.toStringAsFixed(2)}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                );
              }).toList();
            },
          ),
        ),

        lineBarsData: fuelTypes.map((fuelType) {
          final colour = _fuelColor(fuelType);

          final spots = List.generate(
            chartPrices.length,
                (index) {
              return FlSpot(
                index.toDouble(),
                _getPrice(
                  chartPrices[index],
                  fuelType,
                ),
              );
            },
          );

          return LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            color: colour,
            barWidth: compact ? 3 : 2.5,

            dotData: FlDotData(
              // Detailed History chart displays all points.
              // Compact Home chart does not display every point.
              show: !compact,
            ),

            belowBarData: BarAreaData(
              // Only shade the chart when displaying one fuel.
              // Multiple shaded regions would overlap.
              show: fuelTypes.length == 1,
              color: colour.withValues(alpha: 0.12),
            ),
          );
        }).toList(),
      ),
    );
  }
}