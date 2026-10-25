import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'main.dart';

class StatisticsScreen extends StatefulWidget {
  final List<Expense> expenses;
  final DateTime? startDate;

  const StatisticsScreen({super.key, required this.expenses, this.startDate});

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryTotals = getCategoryTotals();
    final totalAmount = categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistika', style: TextStyle(color: Colors.white)),
        backgroundColor: isDark ? const Color(0xFF1a1a2e) : const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: categoryTotals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pie_chart, size: 80, color: isDark ? Colors.grey[700] : Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Hali ma\'lumot yo\'q',
                    style: TextStyle(fontSize: 18, color: isDark ? Colors.grey[500] : Colors.grey),
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
                      gradient: LinearGradient(
                        colors: isDark 
                            ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)]
                            : [const Color(0xFF667eea), const Color(0xFF764ba2)],
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
                          '${formatMoney(totalAmount)} so\'m',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (widget.startDate != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.indigo.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.indigo, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ilova ishga tushirilgan sana',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('dd.MM.yyyy').format(widget.startDate!),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.emoji_events,
                            color: Colors.amber[700],
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  Container(
                    height: 300,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                        Text(
                          'Kategoriyalar bo\'yicha',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
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
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${formatMoney(categoryEntry.value)} so\'m',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '$percentage%',
                                  style: TextStyle(
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
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