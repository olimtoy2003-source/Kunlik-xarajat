import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'main.dart';

class StatisticsScreen extends StatefulWidget {
  final List<Expense> expenses;

  const StatisticsScreen({super.key, required this.expenses});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int touchedIndex = -1;

  Map<String, double> getCategoryTotals() {
    Map<String, double> totals = {};
    for (var expense in widget.expenses) {
      String category = expense.displayName;
      totals[category] = (totals[category] ?? 0) + expense.amount;
    }
    return totals;
  }

  final List<Color> categoryColors = [
    const Color(0xFF667eea),
    const Color(0xFF764ba2),
    const Color(0xFFf093fb),
    const Color(0xFF4facfe),
    const Color(0xFF43e97b),
    const Color(0xFFfa709a),
    const Color(0xFFfee140),
    const Color(0xFF30cfd0),
    const Color(0xFFa8edea),
  ];

  @override
  Widget build(BuildContext context) {
    final categoryTotals = getCategoryTotals();
    final totalAmount = categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistika'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: categoryTotals.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pie_chart, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Hali ma\'lumot yo\'q',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Jami xarajat',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${totalAmount.toStringAsFixed(0)} so\'m',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    height: 300,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                touchedIndex = -1;
                                return;
                              }
                              touchedIndex = pieTouchResponse
                                  .touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        sections: categoryTotals.entries.toList().asMap().entries.map((entry) {
                          final index = entry.key;
                          final categoryEntry = entry.value;
                          final isTouched = index == touchedIndex;
                          final percentage = (categoryEntry.value / totalAmount * 100).toStringAsFixed(1);

                          return PieChartSectionData(
                            color: categoryColors[index % categoryColors.length],
                            value: categoryEntry.value,
                            title: '$percentage%',
                            radius: isTouched ? 110 : 100,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kategoriyalar bo\'yicha',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 15),
                        ...categoryTotals.entries.toList().asMap().entries.map((entry) {
                          final index = entry.key;
                          final categoryEntry = entry.value;
                          final percentage = (categoryEntry.value / totalAmount * 100).toStringAsFixed(1);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: categoryColors[index % categoryColors.length],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    categoryEntry.key,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                Text(
                                  '${categoryEntry.value.toStringAsFixed(0)} so\'m',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '$percentage%',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}