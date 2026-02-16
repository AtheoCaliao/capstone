import 'package:flutter/material.dart';

const Color _primaryAqua = Color(0xFF8ED7DA);
const Color _darkDeepTeal = Color(0xFF0E2F34);
const Color _mutedCoolGray = Color(0xFF8A8FA3);
const Color _lightOffWhite = Color(0xFFF1F1EE);

class HealthMetricsPage extends StatelessWidget {
  const HealthMetricsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightOffWhite,
      appBar: AppBar(
        backgroundColor: _darkDeepTeal,
        title: Text(
          'Summary',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _lightOffWhite,
                fontWeight: FontWeight.bold,
              ),
        ),
        iconTheme: const IconThemeData(color: _lightOffWhite),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Section
            _HealthOverviewCard(),
            const SizedBox(height: 24),

            // Vital Signs Section
            _SectionTitle('Vital Signs'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: const [
                _VitalCard(
                  title: 'Blood Pressure',
                  value: '120/80',
                  unit: 'mmHg',
                  icon: Icons.favorite,
                  status: 'Normal',
                  color: Colors.green,
                ),
                _VitalCard(
                  title: 'Heart Rate',
                  value: '72',
                  unit: 'bpm',
                  icon: Icons.favorite,
                  status: 'Normal',
                  color: Colors.green,
                ),
                _VitalCard(
                  title: 'Temperature',
                  value: '36.7',
                  unit: '°C',
                  icon: Icons.thermostat,
                  status: 'Normal',
                  color: Colors.green,
                ),
                _VitalCard(
                  title: 'Oxygen Level',
                  value: '98',
                  unit: '%',
                  icon: Icons.air,
                  status: 'Normal',
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Body Metrics Section
            _SectionTitle('Body Metrics'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: const [
                _MetricCard(
                  title: 'BMI',
                  value: '22.5',
                  status: 'Healthy',
                  icon: Icons.scale,
                  color: Colors.blue,
                ),
                _MetricCard(
                  title: 'Weight',
                  value: '70',
                  unit: 'kg',
                  status: 'Stable',
                  icon: Icons.monitor_weight,
                  color: Colors.orange,
                ),
                _MetricCard(
                  title: 'Height',
                  value: '175',
                  unit: 'cm',
                  status: 'Recorded',
                  icon: Icons.height,
                  color: Colors.purple,
                ),
                _MetricCard(
                  title: 'Hydration',
                  value: '8/8',
                  unit: 'cups',
                  status: 'Optimal',
                  icon: Icons.local_drink,
                  color: Colors.cyan,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Activity Section
            _SectionTitle('Activity'),
            const SizedBox(height: 12),
            _ActivityCard(),
            const SizedBox(height: 24),

            // Sleep Section
            _SectionTitle('Sleep'),
            const SizedBox(height: 12),
            _SleepCard(),
          ],
        ),
      ),
    );
  }
}

class _HealthOverviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryAqua, _primaryAqua.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryAqua.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall Health Status',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _darkDeepTeal,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatusIndicator(label: 'Vitals', value: 'Good', color: Colors.green),
              _StatusIndicator(label: 'Activity', value: 'Fair', color: Colors.orange),
              _StatusIndicator(label: 'Sleep', value: 'Good', color: Colors.green),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.white.withOpacity(0.3),
            ),
            child: FractionallySizedBox(
              widthFactor: 0.85,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.green,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Health Score: 85/100',
            style: TextStyle(
              color: _darkDeepTeal,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatusIndicator({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  color == Colors.green ? Icons.check_circle : Icons.info,
                  color: color,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: _darkDeepTeal,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
            color: _darkDeepTeal,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _VitalCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final String status;
  final Color color;

  const _VitalCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryAqua.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _mutedCoolGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
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
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _darkDeepTeal,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _mutedCoolGray,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? unit;
  final String status;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.status,
    required this.icon,
    required this.color,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryAqua.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _mutedCoolGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
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
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _darkDeepTeal,
                  ),
                ),
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _mutedCoolGray,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryAqua.withOpacity(0.3), width: 1),
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
              Text(
                'Daily Activity',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _darkDeepTeal,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.directions_walk, color: Colors.orange, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ActivityMetric(label: 'Steps', value: '8,432', icon: Icons.directions_run),
              _ActivityMetric(label: 'Calories', value: '480', icon: Icons.local_fire_department),
              _ActivityMetric(label: 'Distance', value: '6.2km', icon: Icons.location_on),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.84,
              minHeight: 6,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.withOpacity(0.7)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Goal: 10,000 steps/day',
            style: TextStyle(
              fontSize: 12,
              color: _mutedCoolGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ActivityMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _darkDeepTeal,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _mutedCoolGray,
          ),
        ),
      ],
    );
  }
}

class _SleepCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryAqua.withOpacity(0.3), width: 1),
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
              Text(
                'Sleep Tracking',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _darkDeepTeal,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bedtime, color: Colors.blue, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SleepMetric(label: 'Last Night', value: '7h 24m'),
              _SleepMetric(label: 'Average', value: '7h 15m'),
              _SleepMetric(label: 'Quality', value: 'Good'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Sleep Stages',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _darkDeepTeal,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SleepStageBar(label: 'REM', percentage: 20, color: Colors.green),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SleepStageBar(label: 'Light', percentage: 45, color: Colors.blue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SleepStageBar(label: 'Deep', percentage: 35, color: Colors.purple),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SleepMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SleepMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _darkDeepTeal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _mutedCoolGray,
          ),
        ),
      ],
    );
  }
}

class _SleepStageBar extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;

  const _SleepStageBar({
    required this.label,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _mutedCoolGray,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 24,
            backgroundColor: Colors.grey.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${percentage.toInt()}%',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _darkDeepTeal,
          ),
        ),
      ],
    );
  }
}
