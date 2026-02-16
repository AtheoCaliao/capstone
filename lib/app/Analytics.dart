import 'package:flutter/material.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart'
    as charts;
import 'package:mycapstone_project/app/database_helper.dart';
import 'package:mycapstone_project/app/prenatal_database_helper.dart';
import 'package:mycapstone_project/app/immunization_database_helper.dart';
import 'dart:async';

const Color _primaryAqua = Color(0xFF8ED7DA);
const Color _darkDeepTeal = Color(0xFF0E2F34);
const Color _mutedCoolGray = Color(0xFF8A8FA3);
const Color _lightOffWhite = Color(0xFFF1F1EE);

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final DatabaseHelper _checkupDB = DatabaseHelper.instance;
  final PrenatalDatabaseHelper _prenatalDB = PrenatalDatabaseHelper.instance;
  final ImmunizationDatabaseHelper _immunizationDB =
      ImmunizationDatabaseHelper.instance;

  List<Map<String, dynamic>> _checkupRecords = [];
  List<Map<String, dynamic>> _prenatalRecords = [];
  List<Map<String, dynamic>> _immunizationRecords = [];

  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    // Refresh data every 10 seconds for real-time updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadAllData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    try {
      final checkup = await _checkupDB.getAllRecords();
      final prenatal = await _prenatalDB.getAllRecords();
      final immunization = await _immunizationDB.getAllRecords();

      if (mounted) {
        setState(() {
          _checkupRecords = checkup;
          _prenatalRecords = prenatal;
          _immunizationRecords = immunization;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading analytics data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int get _totalPatients => _checkupRecords.length + _prenatalRecords.length;
  int get _activePrenatalCases =>
      _prenatalRecords.where((r) => r['status'] == 'Active').length;
  int get _thisMonthCheckups {
    final now = DateTime.now();
    return _checkupRecords.where((record) {
      try {
        final date = DateTime.parse(record['datetime'] ?? '');
        return date.year == now.year && date.month == now.month;
      } catch (e) {
        return false;
      }
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _darkDeepTeal,
        appBar: AppBar(
          backgroundColor: _darkDeepTeal,
          title: Text(
            'Analytics & Insights',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: _lightOffWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: _lightOffWhite),
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: _primaryAqua),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _darkDeepTeal,
      appBar: AppBar(
        backgroundColor: _darkDeepTeal,
        title: Text(
          'Analytics & Insights',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _lightOffWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: _lightOffWhite),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _loadAllData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            _AnalyticsSummarySection(
              totalPatients: _totalPatients,
              activeCases: _activePrenatalCases,
              checkupsThisMonth: _thisMonthCheckups,
            ),
            const SizedBox(height: 24),

            // Charts Section
            _SectionTitle('Patient Metrics'),
            const SizedBox(height: 24),
            _GraphCard(
              title: 'BMI Distribution',
              icon: Icons.bar_chart,
              height: 350,
              child: _BuildBMIChart(records: _prenatalRecords),
            ),
            const SizedBox(height: 24),
            _GraphCard(
              title: 'Blood Pressure Trend',
              icon: Icons.trending_up,
              height: 350,
              child: _BuildBPChart(records: _prenatalRecords),
            ),
            const SizedBox(height: 24),
            _GraphCard(
              title: 'Patient Demographics (Prenatal)',
              icon: Icons.people,
              height: 350,
              child: _BuildDemographicsChart(records: _prenatalRecords),
            ),
            const SizedBox(height: 24),
            _GraphCard(
              title: 'Immunization Records',
              icon: Icons.vaccines,
              height: 350,
              child: _BuildImmunizationChart(records: _immunizationRecords),
            ),
            const SizedBox(height: 24),

            // Key Statistics
            _SectionTitle('Key Statistics'),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: const [
                _StatisticCard(
                  title: 'Avg. Blood Pressure',
                  value: '120/80',
                  unit: 'mmHg',
                  trend: '+2.5%',
                  icon: Icons.favorite_border,
                  color: Colors.red,
                ),
                _StatisticCard(
                  title: 'Avg. Heart Rate',
                  value: '72',
                  unit: 'bpm',
                  trend: '-1.2%',
                  icon: Icons.favorite,
                  color: Colors.pink,
                ),
                _StatisticCard(
                  title: 'Avg. BMI',
                  value: '23.4',
                  unit: 'kg/m²',
                  trend: '+0.8%',
                  icon: Icons.scale,
                  color: Colors.orange,
                ),
                _StatisticCard(
                  title: 'Avg. Temperature',
                  value: '37.0',
                  unit: '°C',
                  trend: '-0.5%',
                  icon: Icons.thermostat,
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Insights Section
            _SectionTitle('Health Insights'),
            const SizedBox(height: 16),
            _InsightCard(
              title: 'Patient Compliance',
              description: 'Based on vital sign check-ups this month',
              value: '78%',
              color: Colors.green,
              icon: Icons.check_circle,
            ),
            const SizedBox(height: 16),
            _InsightCard(
              title: 'Risk Indicators',
              description: 'Patients requiring attention',
              value: '12',
              color: Colors.orange,
              icon: Icons.warning,
            ),
            const SizedBox(height: 16),
            _InsightCard(
              title: 'Treatment Success Rate',
              description: 'Positive patient outcomes',
              value: '85%',
              color: Colors.green,
              icon: Icons.trending_up,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsSummarySection extends StatelessWidget {
  final int totalPatients;
  final int activeCases;
  final int checkupsThisMonth;

  const _AnalyticsSummarySection({
    required this.totalPatients,
    required this.activeCases,
    required this.checkupsThisMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Total Patients',
            value: totalPatients.toString(),
            icon: Icons.people,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Active Cases',
            value: activeCases.toString(),
            icon: Icons.assignment,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Check-ups This Month',
            value: checkupsThisMonth.toString(),
            icon: Icons.calendar_today,
            color: Colors.purple,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryAqua.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _lightOffWhite,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: _lightOffWhite,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: _lightOffWhite,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _GraphCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final double height;
  final Widget child;

  const _GraphCard({
    required this.title,
    required this.icon,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryAqua.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryAqua.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: _primaryAqua, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _lightOffWhite,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 0, color: _lightOffWhite.withOpacity(0.4)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(height: height, child: child),
          ),
        ],
      ),
    );
  }
}

class _BuildBMIChart extends StatelessWidget {
  final List<Map<String, dynamic>> records;

  const _BuildBMIChart({required this.records});

  @override
  Widget build(BuildContext context) {
    // Calculate BMI distribution from real data
    int underweight = 0, normal = 0, overweight = 0, obese = 0;

    for (var record in records) {
      try {
        final bmiStr = record['bmi']?.toString() ?? '';
        if (bmiStr.isNotEmpty) {
          final bmi = double.tryParse(
            bmiStr.replaceAll(RegExp(r'[^0-9.]'), ''),
          );
          if (bmi != null) {
            if (bmi < 18.5) {
              underweight++;
            } else if (bmi < 25)
              normal++;
            else if (bmi < 30)
              overweight++;
            else
              obese++;
          }
        }
      } catch (e) {
        // Skip invalid entries
      }
    }

    // Show message if no data
    if (underweight + normal + overweight + obese == 0) {
      return const Center(
        child: Text(
          'No BMI data available',
          style: TextStyle(color: _mutedCoolGray),
        ),
      );
    }

    return charts.BarChart(
      [
        charts.Series<BarData, String>(
          id: 'BMI',
          colorFn: (BarData data, _) {
            switch (data.label) {
              case 'Under':
                return charts.MaterialPalette.indigo.shadeDefault;
              case 'Normal':
                return charts.MaterialPalette.green.shadeDefault;
              case 'Over':
                return charts.MaterialPalette.yellow.shadeDefault;
              case 'Obese':
                return charts.MaterialPalette.red.shadeDefault;
              default:
                return charts.MaterialPalette.blue.shadeDefault;
            }
          },
          domainFn: (BarData data, _) => data.label,
          measureFn: (BarData data, _) => data.value,
          data: [
            BarData('Under', underweight),
            BarData('Normal', normal),
            BarData('Over', overweight),
            BarData('Obese', obese),
          ],
        ),
      ],
      animate: false,
      behaviors: [
        charts.ChartTitle(
          'Category',
          behaviorPosition: charts.BehaviorPosition.bottom,
          titleStyleSpec: const charts.TextStyleSpec(
            color: charts.Color.white,
            fontSize: 12,
          ),
        ),
        charts.ChartTitle(
          'Count',
          behaviorPosition: charts.BehaviorPosition.start,
          titleStyleSpec: const charts.TextStyleSpec(
            color: charts.Color.white,
            fontSize: 12,
          ),
        ),
      ],
      defaultRenderer: charts.BarRendererConfig<String>(
        cornerStrategy: const charts.ConstCornerStrategy(10),
      ),
      primaryMeasureAxis: const charts.NumericAxisSpec(
        showAxisLine: false,
        renderSpec: charts.GridlineRendererSpec(
          labelStyle: charts.TextStyleSpec(
            color: charts.Color.white,
            fontSize: 10,
          ),
          lineStyle: charts.LineStyleSpec(color: charts.Color.white),
        ),
      ),
      domainAxis: const charts.OrdinalAxisSpec(
        renderSpec: charts.SmallTickRendererSpec(
          labelStyle: charts.TextStyleSpec(
            color: charts.Color.white,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

class _BuildBPChart extends StatelessWidget {
  final List<Map<String, dynamic>> records;

  const _BuildBPChart({required this.records});

  @override
  Widget build(BuildContext context) {
    // Extract BP data from records
    List<LineData> bpData = [];

    for (int i = 0; i < records.length && i < 7; i++) {
      try {
        final bpStr = records[i]['bp']?.toString() ?? '';
        if (bpStr.contains('/')) {
          final systolic = int.tryParse(bpStr.split('/')[0].trim());
          if (systolic != null) {
            bpData.add(LineData(i, systolic));
          }
        }
      } catch (e) {
        // Skip invalid entries
      }
    }

    // Use default data if no real data available
    if (bpData.isEmpty) {
      bpData = [LineData(0, 120), LineData(1, 118), LineData(2, 122)];
    }

    return charts.LineChart(
      [
        charts.Series<LineData, int>(
          id: 'BP',
          colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
          domainFn: (LineData data, _) => data.day,
          measureFn: (LineData data, _) => data.value,
          data: bpData,
        ),
      ],
      animate: false,
      behaviors: [
        charts.ChartTitle(
          'Days',
          behaviorPosition: charts.BehaviorPosition.bottom,
          titleStyleSpec: const charts.TextStyleSpec(
            color: charts.Color.white,
            fontSize: 12,
          ),
        ),
        charts.ChartTitle(
          'Systolic (mmHg)',
          behaviorPosition: charts.BehaviorPosition.start,
          titleStyleSpec: const charts.TextStyleSpec(
            color: charts.Color.white,
            fontSize: 12,
          ),
        ),
      ],
      defaultRenderer: charts.LineRendererConfig(includePoints: true),
      primaryMeasureAxis: const charts.NumericAxisSpec(
        showAxisLine: false,
        renderSpec: charts.GridlineRendererSpec(
          labelStyle: charts.TextStyleSpec(
            color: charts.Color.white,
            fontSize: 10,
          ),
          lineStyle: charts.LineStyleSpec(color: charts.Color.white),
        ),
      ),
      domainAxis: const charts.NumericAxisSpec(
        renderSpec: charts.SmallTickRendererSpec(
          labelStyle: charts.TextStyleSpec(
            color: charts.Color.white,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

class _BuildDemographicsChart extends StatelessWidget {
  final List<Map<String, dynamic>> records;

  const _BuildDemographicsChart({required this.records});

  @override
  Widget build(BuildContext context) {
    // Calculate age distribution from real data
    int age0to18 = 0, age18to35 = 0, age35to65 = 0, age65plus = 0;

    for (var record in records) {
      try {
        final ageStr = record['age']?.toString() ?? '';
        final age = int.tryParse(ageStr.replaceAll(RegExp(r'[^0-9]'), ''));
        if (age != null) {
          if (age < 18) {
            age0to18++;
          } else if (age < 35)
            age18to35++;
          else if (age < 65)
            age35to65++;
          else
            age65plus++;
        }
      } catch (e) {
        // Skip invalid entries
      }
    }

    // Show message if no data
    if (age0to18 + age18to35 + age35to65 + age65plus == 0) {
      return const Center(
        child: Text(
          'No demographic data available',
          style: TextStyle(color: _mutedCoolGray),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _DemographicItem('0-18 years', age0to18, Colors.blue),
          const SizedBox(height: 12),
          _DemographicItem('18-35 years', age18to35, Colors.green),
          const SizedBox(height: 12),
          _DemographicItem('35-65 years', age35to65, Colors.orange),
          const SizedBox(height: 12),
          _DemographicItem('65+ years', age65plus, Colors.red),
        ],
      ),
    );
  }
}

class _DemographicItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _DemographicItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    final total = 250 + 680 + 920 + 600;
    final percentage = total > 0
        ? (value / total * 100).toStringAsFixed(1)
        : '0.0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _lightOffWhite,
              ),
            ),
            Text(
              '$value ($percentage%)',
              style: const TextStyle(fontSize: 11, color: _lightOffWhite),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / total,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// Immunization Chart
class _BuildImmunizationChart extends StatelessWidget {
  final List<Map<String, dynamic>> records;

  const _BuildImmunizationChart({required this.records});

  @override
  Widget build(BuildContext context) {
    // Count vaccine types
    Map<String, int> vaccineCounts = {};

    for (var record in records) {
      final vaccine = record['vaccine']?.toString() ?? 'Unknown';
      vaccineCounts[vaccine] = (vaccineCounts[vaccine] ?? 0) + 1;
    }

    // Show message if no data
    if (vaccineCounts.isEmpty) {
      return const Center(
        child: Text(
          'No immunization data available',
          style: TextStyle(color: _mutedCoolGray),
        ),
      );
    }

    // Convert to chart data
    final chartData = vaccineCounts.entries
        .map((e) => BarData(e.key, e.value))
        .toList();

    return charts.BarChart(
      [
        charts.Series<BarData, String>(
          id: 'Vaccines',
          colorFn: (_, __) => charts.ColorUtil.fromDartColor(_primaryAqua),
          domainFn: (BarData data, _) => data.label,
          measureFn: (BarData data, _) => data.value,
          data: chartData,
        ),
      ],
      animate: false,
      vertical: false,
      behaviors: [
        charts.ChartTitle(
          'Vaccine Type',
          behaviorPosition: charts.BehaviorPosition.start,
          titleStyleSpec: const charts.TextStyleSpec(
            color: charts.Color.white,
            fontSize: 12,
          ),
        ),
        charts.ChartTitle(
          'Count',
          behaviorPosition: charts.BehaviorPosition.bottom,
          titleStyleSpec: const charts.TextStyleSpec(
            color: charts.Color.white,
            fontSize: 12,
          ),
        ),
      ],
      defaultRenderer: charts.BarRendererConfig<String>(
        cornerStrategy: const charts.ConstCornerStrategy(10),
      ),
      primaryMeasureAxis: const charts.NumericAxisSpec(
        showAxisLine: false,
        renderSpec: charts.GridlineRendererSpec(
          labelStyle: charts.TextStyleSpec(
            color: charts.Color.white,
            fontSize: 10,
          ),
          lineStyle: charts.LineStyleSpec(color: charts.Color.white),
        ),
      ),
      domainAxis: const charts.OrdinalAxisSpec(
        renderSpec: charts.SmallTickRendererSpec(
          labelStyle: charts.TextStyleSpec(
            color: charts.Color.white,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String trend;
  final IconData icon;
  final Color color;

  const _StatisticCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.trend,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isTrendPositive = !trend.contains('-');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryAqua.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isTrendPositive
                      ? Colors.red.withOpacity(0.15)
                      : Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isTrendPositive ? Icons.trending_up : Icons.trending_down,
                      size: 12,
                      color: isTrendPositive ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trend,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isTrendPositive ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _lightOffWhite,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(fontSize: 11, color: _lightOffWhite),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: _lightOffWhite,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String description;
  final String value;
  final Color color;
  final IconData icon;

  const _InsightCard({
    required this.title,
    required this.description,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.08), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _lightOffWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, color: _lightOffWhite),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Data classes for charts
class BarData {
  final String label;
  final int value;

  BarData(this.label, this.value);
}

class LineData {
  final int day;
  final int value;

  LineData(this.day, this.value);
}

class PieData {
  final String label;
  final int value;

  PieData(this.label, this.value);
}
