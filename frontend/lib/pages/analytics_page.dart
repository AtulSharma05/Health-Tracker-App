import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/meal_service.dart';
import '../services/profile_service.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  int _periodDays = 7;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mealService = context.read<MealService>();
      mealService.fetchMeals();
    });
  }

  Future<void> _refresh() async {
    final mealService = context.read<MealService>();
    await mealService.fetchMeals();
  }

  @override
  Widget build(BuildContext context) {
    final mealService = context.watch<MealService>();
    final profileService = context.watch<ProfileService>();
    final now = DateTime.now();
    final todayDay = DateTime(now.year, now.month, now.day);
    final startDay = todayDay.subtract(Duration(days: _periodDays - 1));

    final filteredEntries = mealService.entries.where((meal) {
      final day = DateTime(meal.createdAt.year, meal.createdAt.month, meal.createdAt.day);
      return !day.isBefore(startDay) && !day.isAfter(todayDay);
    }).toList();

    final dayKeys = List<String>.generate(_periodDays, (index) {
      final d = startDay.add(Duration(days: index));
      return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    });

    final dayMap = <String, int>{
      for (final key in dayKeys) key: 0,
    };

    for (final meal in filteredEntries) {
      final d = DateTime(meal.createdAt.year, meal.createdAt.month, meal.createdAt.day);
      final key = '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      dayMap[key] = (dayMap[key] ?? 0) + meal.calories;
    }

    final daily = dayKeys
        .map((key) => ({
              'date': DateTime.parse(key),
              'calories': dayMap[key] ?? 0,
            }))
        .toList();

    final periodCalories = filteredEntries.fold<int>(0, (sum, m) => sum + m.calories);
    final periodProtein = filteredEntries.fold<int>(0, (sum, m) => sum + m.protein);
    final periodCarbs = filteredEntries.fold<int>(0, (sum, m) => sum + m.carbs);
    final periodFats = filteredEntries.fold<int>(0, (sum, m) => sum + m.fats);

    final proteinCal = periodProtein * 4;
    final carbsCal = periodCarbs * 4;
    final fatsCal = periodFats * 9;
    final macroCalTotal = (proteinCal + carbsCal + fatsCal) == 0 ? 1 : (proteinCal + carbsCal + fatsCal);
    final periodLabel = _periodDays == 1 ? 'Today' : '$_periodDays days';

    // ── 7-day adherence (always last 7 days regardless of selected period) ──
    final calTarget = profileService.calculations?.targetCalories ?? 0;
    final proteinTarget = profileService.calculations?.proteinG ?? 0;
    List<Map<String, dynamic>>? adherenceData;
    if (calTarget > 0) {
      final aStart = todayDay.subtract(const Duration(days: 6));
      final aMap = <DateTime, Map<String, int>>{};
      for (final meal in mealService.entries) {
        final d = DateTime(meal.createdAt.year, meal.createdAt.month, meal.createdAt.day);
        if (!d.isBefore(aStart) && !d.isAfter(todayDay)) {
          final cur = aMap[d] ?? {'cal': 0, 'protein': 0};
          aMap[d] = {'cal': cur['cal']! + meal.calories, 'protein': cur['protein']! + meal.protein};
        }
      }
      adherenceData = List.generate(7, (i) {
        final day = aStart.add(Duration(days: i));
        final data = aMap[day];
        final cal = data?['cal'] ?? 0;
        final protein = data?['protein'] ?? 0;
        final hasData = data != null;
        return {
          'day': day,
          'calories': cal,
          'protein': protein,
          'hasData': hasData,
          'calAdherent': hasData && cal >= calTarget * 0.8 && cal <= calTarget * 1.2,
          'proteinAdherent': hasData && protein >= proteinTarget * 0.8,
        };
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Analytics'),
        actions: [
          PopupMenuButton<int>(
            onSelected: (value) async {
              setState(() => _periodDays = value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 1, child: Text('Today')),
              PopupMenuItem(value: 7, child: Text('Last 7 days')),
              PopupMenuItem(value: 30, child: Text('Last 30 days')),
              PopupMenuItem(value: 90, child: Text('Last 90 days')),
            ],
            icon: const Icon(Icons.calendar_month),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text('Calories: ${mealService.todayCalories} kcal'),
                    Text('Protein: ${mealService.todayProtein} g'),
                    Text('Carbs: ${mealService.todayCarbs} g'),
                    Text('Fats: ${mealService.todayFats} g'),
                  ],
                ),
              ),
            ),
            if (adherenceData != null) ...[  
              const SizedBox(height: 12),
              _buildAdherenceCard(adherenceData, calTarget),
            ],
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Calories ($periodLabel)',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 220,
                      child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                gridData: FlGridData(show: true, drawVerticalLine: false),
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 36,
                                      getTitlesWidget: (value, meta) => Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final idx = value.toInt();
                                        if (idx < 0 || idx >= daily.length) {
                                          return const SizedBox.shrink();
                                        }
                                        final date = daily[idx]['date'] as DateTime;
                                        final label = _periodDays == 1 ? 'Today' : DateFormat('MM/dd').format(date);
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Text(
                                            label,
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                barGroups: daily.asMap().entries.map((entry) {
                                  return BarChartGroupData(
                                    x: entry.key,
                                    barRods: [
                                      BarChartRodData(
                                        toY: (entry.value['calories'] as int).toDouble(),
                                        color: Colors.orange,
                                        width: 12,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Macro Split', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(value: proteinCal.toDouble(), title: 'Protein', color: Colors.green),
                            PieChartSectionData(value: carbsCal.toDouble(), title: 'Carbs', color: Colors.orange),
                            PieChartSectionData(value: fatsCal.toDouble(), title: 'Fats', color: Colors.pink),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Logged Calories ($periodLabel): $periodCalories kcal'),
                    Text('Macro calories ($periodLabel): ${proteinCal + carbsCal + fatsCal} kcal'),
                    Text('Protein calories: ${((proteinCal / macroCalTotal) * 100).toStringAsFixed(1)}%'),
                    Text('Carb calories: ${((carbsCal / macroCalTotal) * 100).toStringAsFixed(1)}%'),
                    Text('Fat calories: ${((fatsCal / macroCalTotal) * 100).toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherenceCard(List<Map<String, dynamic>> data, int calTarget) {
    final adherentDays = data.where((d) => d['calAdherent'] == true).length;
    final daysWithData = data.where((d) => d['hasData'] == true).length;
    final pct = daysWithData == 0 ? 0 : (adherentDays / 7 * 100).round();
    final isGood = pct >= 70;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('7-Day Adherence',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isGood
                        ? Colors.green.withOpacity(0.15)
                        : Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$pct%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isGood ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'On target: $adherentDays / 7 days  •  Target: $calTarget kcal ±20%',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: data.map((d) {
                final day = d['day'] as DateTime;
                final hasData = d['hasData'] as bool;
                final adherent = d['calAdherent'] as bool;
                final dotColor = !hasData
                    ? Colors.grey.shade300
                    : adherent
                        ? Colors.green
                        : Colors.orange;
                return Column(
                  children: [
                    Text(
                      DateFormat('EEE').format(day),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                      child: hasData
                          ? Center(
                              child: Icon(
                                adherent ? Icons.check : Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasData ? '${d['calories']}' : '–',
                      style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _legend(Colors.green, 'On target (80–120%)'),
                const SizedBox(width: 12),
                _legend(Colors.orange, 'Off target'),
                const SizedBox(width: 12),
                _legend(Colors.grey.shade300, 'No data'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Row _legend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
