import 'package:flutter/material.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart'
    as charts;
import 'package:mycapstone_project/web/database_helper.dart';
import 'package:mycapstone_project/web/prenatal_database_helper.dart';
import 'package:mycapstone_project/web/immunization_database_helper.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mycapstone_project/web/login.dart';
import 'package:mycapstone_project/web/homepage.dart';
import 'package:mycapstone_project/web/checkup.dart';
import 'package:mycapstone_project/web/health_metrics.dart';
import 'package:mycapstone_project/web/prenatal.dart';
import 'package:mycapstone_project/web/Immunization.dart';
import 'package:mycapstone_project/web/patient.dart';
import 'package:mycapstone_project/web/communicable.dart';
import 'package:mycapstone_project/web/non-communicable.dart';
import 'package:mycapstone_project/web/Mortality.dart';
import 'dart:async';

const Color _primaryAqua = Color(0xFF00A8B5);
const Color _secondaryIceBlue = Color(0xFF1E5A7A);
const Color _darkDeepTeal = Color(0xFF0A1F24);
const Color _mutedCoolGray = Color(0xFF546E7A);
const Color _lightOffWhite = Color(0xFFF5F5F5);
const Color _sidebarDark = Color(0xFF0E2F34);

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
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.email?.split('@')[0] ?? 'User';

    if (_isLoading) {
      return Scaffold(
        backgroundColor: _lightOffWhite,
        body: Row(
          children: [
            _buildSidebar(context, userName),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(context),
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: _primaryAqua),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: _lightOffWhite,
      body: Row(
        children: [
          // Sidebar Navigation
          _buildSidebar(context, userName),
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(context),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page Header with Gradient Background
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryAqua, _secondaryIceBlue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryAqua.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.analytics_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Healthcare Analytics Dashboard',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Real-time health data insights and performance metrics',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.greenAccent,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.greenAccent,
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Live Data',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Summary Cards Section
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _primaryAqua.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.speed_rounded,
                                color: _primaryAqua,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Performance Overview',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _darkDeepTeal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _AnalyticsSummarySection(
                          totalPatients: _totalPatients,
                          activeCases: _activePrenatalCases,
                          checkupsThisMonth: _thisMonthCheckups,
                        ),
                        const SizedBox(height: 40),

                        // Charts Section Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_primaryAqua, _secondaryIceBlue],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.show_chart_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Data Visualization',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _darkDeepTeal,
                              ),
                            ),
                            const Spacer(),
                            // Time Range Selector
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _mutedCoolGray.withOpacity(0.2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: _mutedCoolGray,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Last 30 Days',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _mutedCoolGray,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 18,
                                    color: _mutedCoolGray,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Main Chart - Full Width
                        _buildPowerBICard(
                          context,
                          title: 'Patient Check-ups Trend',
                          subtitle:
                              'Monthly check-up distribution and patterns',
                          icon: Icons.trending_up_rounded,
                          child: Container(
                            height: 350,
                            padding: const EdgeInsets.all(20),
                            child: _buildMockLineChart(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Record Distribution Chart
                        _buildPowerBICard(
                          context,
                          title: 'Record Distribution',
                          subtitle: 'Breakdown by category',
                          icon: Icons.pie_chart_rounded,
                          child: Container(
                            height: 350,
                            padding: const EdgeInsets.all(20),
                            child: _buildMockPieChart(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Vital Signs Summary Chart
                        _buildPowerBICard(
                          context,
                          title: 'Vital Signs Summary',
                          subtitle: 'Average readings across metrics',
                          icon: Icons.favorite_rounded,
                          child: Container(
                            height: 350,
                            padding: const EdgeInsets.all(20),
                            child: _buildMockBarChart(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Immunization Coverage Chart
                        _buildPowerBICard(
                          context,
                          title: 'Immunization Coverage',
                          subtitle: 'Distribution by vaccine type',
                          icon: Icons.vaccines_rounded,
                          child: Container(
                            height: 350,
                            padding: const EdgeInsets.all(20),
                            child: _BuildImmunizationChart(
                              records: _immunizationRecords,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Patient Demographics Chart
                        _buildPowerBICard(
                          context,
                          title: 'Patient Demographics',
                          subtitle: 'Age and gender distribution',
                          icon: Icons.people_alt_rounded,
                          child: Container(
                            height: 350,
                            padding: const EdgeInsets.all(20),
                            child: _buildDemographicsChart(),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Key Statistics Section
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_primaryAqua, _secondaryIceBlue],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryAqua.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.insights_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Key Health Insights',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _darkDeepTeal,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _lightOffWhite,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _mutedCoolGray.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: _mutedCoolGray,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Updated ${DateTime.now().toString().split(' ')[0]}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: _mutedCoolGray,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          children: [
                            SizedBox(
                              width:
                                  (MediaQuery.of(context).size.width -
                                      280 -
                                      64 -
                                      60) /
                                  4,
                              child: _PowerBIStatCard(
                                title: 'Patient Compliance',
                                value: '78%',
                                subtitle: 'Check-ups this month',
                                icon: Icons.check_circle_rounded,
                                color: Color(0xFF4CAF50),
                                trend: '+5%',
                              ),
                            ),
                            SizedBox(
                              width:
                                  (MediaQuery.of(context).size.width -
                                      280 -
                                      64 -
                                      60) /
                                  4,
                              child: _PowerBIStatCard(
                                title: 'Risk Indicators',
                                value: '12',
                                subtitle: 'Patients need attention',
                                icon: Icons.warning_rounded,
                                color: Color(0xFFFF9800),
                                trend: '-2',
                              ),
                            ),
                            SizedBox(
                              width:
                                  (MediaQuery.of(context).size.width -
                                      280 -
                                      64 -
                                      60) /
                                  4,
                              child: _PowerBIStatCard(
                                title: 'Success Rate',
                                value: '85%',
                                subtitle: 'Positive outcomes',
                                icon: Icons.trending_up_rounded,
                                color: Color(0xFF2196F3),
                                trend: '+8%',
                              ),
                            ),
                            SizedBox(
                              width:
                                  (MediaQuery.of(context).size.width -
                                      280 -
                                      64 -
                                      60) /
                                  4,
                              child: _PowerBIStatCard(
                                title: 'Avg Wait Time',
                                value: '15m',
                                subtitle: 'Patient waiting time',
                                icon: Icons.access_time_rounded,
                                color: _primaryAqua,
                                trend: '-3m',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),

                        // Additional Insights Row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _secondaryIceBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.lightbulb_outline_rounded,
                                color: _secondaryIceBlue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Performance Indicators',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _darkDeepTeal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          children: [
                            SizedBox(
                              width:
                                  (MediaQuery.of(context).size.width -
                                      280 -
                                      64 -
                                      60) /
                                  4,
                              child: _buildCompactStatCard(
                                title: 'Today\'s Appointments',
                                value: '24',
                                icon: Icons.event_available_rounded,
                                color: _primaryAqua,
                                trend: '+6 vs yesterday',
                              ),
                            ),
                            SizedBox(
                              width:
                                  (MediaQuery.of(context).size.width -
                                      280 -
                                      64 -
                                      60) /
                                  4,
                              child: _buildCompactStatCard(
                                title: 'Active Treatments',
                                value: '156',
                                icon: Icons.medical_services_rounded,
                                color: Color(0xFF9C27B0),
                                trend: '+12 this week',
                              ),
                            ),
                            SizedBox(
                              width:
                                  (MediaQuery.of(context).size.width -
                                      280 -
                                      64 -
                                      60) /
                                  4,
                              child: _buildCompactStatCard(
                                title: 'Completed Today',
                                value: '18',
                                icon: Icons.task_alt_rounded,
                                color: Color(0xFF4CAF50),
                                trend: '75% completion',
                              ),
                            ),
                            SizedBox(
                              width:
                                  (MediaQuery.of(context).size.width -
                                      280 -
                                      64 -
                                      60) /
                                  4,
                              child: _buildCompactStatCard(
                                title: 'Critical Cases',
                                value: '3',
                                icon: Icons.priority_high_rounded,
                                color: Color(0xFFD32F2F),
                                trend: 'Requires attention',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, String userName) {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      width: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_sidebarDark, _sidebarDark.withOpacity(0.95)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: 16.0,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryAqua, _secondaryIceBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryAqua.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/bg2.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 35,
                            color: _primaryAqua,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent,
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Online',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _primaryAqua,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'MAIN MENU',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              children: [
                _buildSidebarItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  onTap: () => Get.to(() => const HomePage()),
                ),
                _buildSidebarItem(
                  icon: Icons.assignment_turned_in_rounded,
                  label: 'Check-ups',
                  onTap: () => Get.to(() => const CheckUpPage()),
                ),
                _buildSidebarItem(
                  icon: Icons.favorite_rounded,
                  label: 'Health Metrics',
                  onTap: () => Get.to(() => const HealthMetricsPage()),
                ),
                _buildSidebarItem(
                  icon: Icons.analytics_rounded,
                  label: 'Analytics',
                  isActive: true,
                  onTap: () {},
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _primaryAqua,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'PATIENT CARE',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSidebarItem(
                  icon: Icons.pregnant_woman_rounded,
                  label: 'Prenatal Care',
                  onTap: () => Get.to(() => const PrenatalPage()),
                ),
                _buildSidebarItem(
                  icon: Icons.vaccines_rounded,
                  label: 'Immunization',
                  onTap: () => Get.to(() => const ImmunizationPage()),
                ),
                _buildSidebarItem(
                  icon: Icons.person_rounded,
                  label: 'Patient Records',
                  onTap: () => Get.to(() => const PatientRecordPage()),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _primaryAqua,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'DISEASE TRACKING',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSidebarItem(
                  icon: Icons.coronavirus_rounded,
                  label: 'Communicable',
                  onTap: () => Get.to(() => const CommunicablePage()),
                ),
                _buildSidebarItem(
                  icon: Icons.health_and_safety_rounded,
                  label: 'Non-Communicable',
                  onTap: () => Get.to(() => const NonCommunicablePage()),
                ),
                _buildSidebarItem(
                  icon: Icons.analytics_outlined,
                  label: 'Mortality',
                  onTap: () => Get.to(() => const MortalityPage()),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Get.offAll(() => const Login());
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade600, Colors.red.shade700],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.white.withOpacity(0.08),
          splashColor: _primaryAqua.withOpacity(0.2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                      colors: [
                        _primaryAqua.withOpacity(0.15),
                        _primaryAqua.withOpacity(0.05),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(
                  color: isActive ? _primaryAqua : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _primaryAqua.withOpacity(0.15)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: isActive
                        ? _primaryAqua
                        : Colors.white.withOpacity(0.8),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withOpacity(0.8),
                      fontSize: 12.5,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _primaryAqua,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.analytics_rounded, color: _primaryAqua, size: 32),
          const SizedBox(width: 16),
          Text(
            'Analytics & Insights',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: _darkDeepTeal,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Data',
            onPressed: _loadAllData,
            color: _mutedCoolGray,
            iconSize: 28,
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            color: _mutedCoolGray,
            iconSize: 28,
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
            color: _mutedCoolGray,
            iconSize: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: _darkDeepTeal,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              trend,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryAqua, _secondaryIceBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _primaryAqua.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.insights_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Healthcare Analytics Dashboard',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: _darkDeepTeal,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Real-time insights and data visualization',
              style: TextStyle(fontSize: 14, color: _mutedCoolGray),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPowerBICard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primaryAqua.withOpacity(0.05),
                        _secondaryIceBlue.withOpacity(0.02),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primaryAqua, _secondaryIceBlue],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _darkDeepTeal,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: _mutedCoolGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: Colors.green, size: 8),
                            SizedBox(width: 6),
                            Text(
                              'Live',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Card body
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Real Chart Widgets (Power BI Style)
  Widget _buildMockLineChart() {
    if (_checkupRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 60,
              color: _mutedCoolGray.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No check-up data available',
              style: TextStyle(fontSize: 14, color: _mutedCoolGray),
            ),
          ],
        ),
      );
    }

    // Group records by month
    Map<String, int> monthlyData = {};
    for (var record in _checkupRecords) {
      String date = record['date'] ?? '';
      if (date.isNotEmpty) {
        String month = date.substring(0, 7); // YYYY-MM
        monthlyData[month] = (monthlyData[month] ?? 0) + 1;
      }
    }

    // Sort and get last 12 months
    var sortedMonths = monthlyData.keys.toList()..sort();
    if (sortedMonths.length > 12) {
      sortedMonths = sortedMonths.sublist(sortedMonths.length - 12);
    }

    var seriesData = sortedMonths.map((month) {
      return TimeSeriesCheckups(
        DateTime.parse('$month-01'),
        monthlyData[month] ?? 0,
      );
    }).toList();

    var series = [
      charts.Series<TimeSeriesCheckups, DateTime>(
        id: 'Checkups',
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(_primaryAqua),
        domainFn: (TimeSeriesCheckups sales, _) => sales.time,
        measureFn: (TimeSeriesCheckups sales, _) => sales.checkups,
        data: seriesData,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: charts.TimeSeriesChart(
        series,
        animate: true,
        dateTimeFactory: const charts.LocalDateTimeFactory(),
        behaviors: [
          charts.ChartTitle(
            'Month',
            behaviorPosition: charts.BehaviorPosition.bottom,
            titleOutsideJustification:
                charts.OutsideJustification.middleDrawArea,
          ),
          charts.ChartTitle(
            'Number of Check-ups',
            behaviorPosition: charts.BehaviorPosition.start,
            titleOutsideJustification:
                charts.OutsideJustification.middleDrawArea,
          ),
        ],
        defaultRenderer: charts.LineRendererConfig(
          includeArea: true,
          includeLine: true,
          areaOpacity: 0.2,
          strokeWidthPx: 3,
        ),
      ),
    );
  }

  Widget _buildMockPieChart() {
    final checkupCount = _checkupRecords.length;
    final prenatalCount = _prenatalRecords.length;
    final immunizationCount = _immunizationRecords.length;
    final total = checkupCount + prenatalCount + immunizationCount;

    if (total == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_rounded,
              size: 60,
              color: _mutedCoolGray.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No records available',
              style: TextStyle(fontSize: 14, color: _mutedCoolGray),
            ),
          ],
        ),
      );
    }

    var seriesData = [
      RecordDistribution('Check-ups', checkupCount, _primaryAqua),
      RecordDistribution('Prenatal', prenatalCount, _secondaryIceBlue),
      RecordDistribution(
        'Immunization',
        immunizationCount,
        const Color(0xFF4CAF50),
      ),
    ];

    var series = [
      charts.Series<RecordDistribution, String>(
        id: 'Distribution',
        domainFn: (RecordDistribution dist, _) => dist.category,
        measureFn: (RecordDistribution dist, _) => dist.count,
        colorFn: (RecordDistribution dist, _) =>
            charts.ColorUtil.fromDartColor(dist.color),
        data: seriesData,
        labelAccessorFn: (RecordDistribution dist, _) =>
            '${dist.category}\n${dist.count}',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: charts.PieChart<String>(
        series,
        animate: true,
        defaultRenderer: charts.ArcRendererConfig<String>(
          arcWidth: 80,
          arcRendererDecorators: [
            charts.ArcLabelDecorator<String>(
              labelPosition: charts.ArcLabelPosition.auto,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockBarChart() {
    if (_checkupRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 60,
              color: _mutedCoolGray.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No vital signs data available',
              style: TextStyle(fontSize: 14, color: _mutedCoolGray),
            ),
          ],
        ),
      );
    }

    // Calculate averages from checkup records
    double totalBP = 0, totalTemp = 0, totalWeight = 0;
    int bpCount = 0, tempCount = 0, weightCount = 0;

    for (var record in _checkupRecords) {
      if (record['bloodPressure'] != null &&
          record['bloodPressure'].toString().isNotEmpty) {
        try {
          var bp = record['bloodPressure'].toString().split('/');
          if (bp.isNotEmpty) {
            totalBP += double.parse(bp[0]);
            bpCount++;
          }
        } catch (e) {}
      }
      if (record['temperature'] != null) {
        try {
          totalTemp += double.parse(record['temperature'].toString());
          tempCount++;
        } catch (e) {}
      }
      if (record['weight'] != null) {
        try {
          totalWeight += double.parse(record['weight'].toString());
          weightCount++;
        } catch (e) {}
      }
    }
    // If there are no parsed vital sign values, show a placeholder
    final totalVitalsCount = bpCount + tempCount + weightCount;
    if (totalVitalsCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 60,
              color: _mutedCoolGray.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No vital signs recorded',
              style: TextStyle(fontSize: 14, color: _mutedCoolGray),
            ),
          ],
        ),
      );
    }

    var seriesData = [
      VitalSignsData(
        'BP\n(mmHg)',
        bpCount > 0 ? totalBP / bpCount : 0,
        const Color(0xFFE91E63),
      ),
      VitalSignsData(
        'Temp\n(°C)',
        tempCount > 0 ? totalTemp / tempCount : 0,
        const Color(0xFFFF9800),
      ),
      VitalSignsData(
        'Weight\n(kg)',
        weightCount > 0 ? totalWeight / weightCount : 0,
        const Color(0xFF4CAF50),
      ),
    ];

    var series = [
      charts.Series<VitalSignsData, String>(
        id: 'VitalSigns',
        domainFn: (VitalSignsData data, _) => data.category,
        measureFn: (VitalSignsData data, _) => data.value,
        colorFn: (VitalSignsData data, _) =>
            charts.ColorUtil.fromDartColor(data.color),
        data: seriesData,
        labelAccessorFn: (VitalSignsData data, _) =>
            data.value.toStringAsFixed(1),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: charts.BarChart(
        series,
        animate: true,
        barRendererDecorator: charts.BarLabelDecorator<String>(),
        domainAxis: charts.OrdinalAxisSpec(
          renderSpec: charts.SmallTickRendererSpec(
            labelStyle: charts.TextStyleSpec(
              fontSize: 12,
              color: charts.MaterialPalette.gray.shade800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemographicsChart() {
    // Mock demographics data for demonstration
    var ageGroups = [
      DemographicsData('0-18', 45, _primaryAqua),
      DemographicsData('19-35', 78, _secondaryIceBlue),
      DemographicsData('36-50', 62, const Color(0xFF4CAF50)),
      DemographicsData('51-65', 38, const Color(0xFFFF9800)),
      DemographicsData('65+', 22, const Color(0xFFE91E63)),
    ];

    var series = [
      charts.Series<DemographicsData, String>(
        id: 'Demographics',
        domainFn: (DemographicsData data, _) => data.ageGroup,
        measureFn: (DemographicsData data, _) => data.count,
        colorFn: (DemographicsData data, _) =>
            charts.ColorUtil.fromDartColor(data.color),
        data: ageGroups,
        labelAccessorFn: (DemographicsData data, _) => '${data.count}',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 220,
            child: charts.BarChart(
              series,
              animate: true,
              vertical: false,
              barRendererDecorator: charts.BarLabelDecorator<String>(
                insideLabelStyleSpec: const charts.TextStyleSpec(
                  fontSize: 12,
                  color: charts.MaterialPalette.white,
                ),
              ),
              domainAxis: charts.OrdinalAxisSpec(
                renderSpec: charts.SmallTickRendererSpec(
                  labelStyle: charts.TextStyleSpec(
                    fontSize: 12,
                    color: charts.MaterialPalette.gray.shade800,
                  ),
                ),
              ),
              primaryMeasureAxis: charts.NumericAxisSpec(
                renderSpec: charts.GridlineRendererSpec(
                  labelStyle: charts.TextStyleSpec(
                    fontSize: 11,
                    color: charts.MaterialPalette.gray.shade800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: ageGroups.map((data) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: data.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    data.ageGroup,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _mutedCoolGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMockHorizontalBarChart() {
    if (_immunizationRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.align_horizontal_left_rounded,
              size: 60,
              color: _mutedCoolGray.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No immunization data available',
              style: TextStyle(fontSize: 14, color: _mutedCoolGray),
            ),
          ],
        ),
      );
    }

    // Count immunizations by type
    Map<String, int> immunizationTypes = {};
    for (var record in _immunizationRecords) {
      String type = record['vaccineType'] ?? 'Unknown';
      immunizationTypes[type] = (immunizationTypes[type] ?? 0) + 1;
    }

    // Get top 5 types
    var sortedTypes = immunizationTypes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sortedTypes.length > 5) {
      sortedTypes = sortedTypes.sublist(0, 5);
    }

    final colors = [
      const Color(0xFF4CAF50),
      _primaryAqua,
      _secondaryIceBlue,
      const Color(0xFFFF9800),
      const Color(0xFFE91E63),
    ];

    var seriesData = sortedTypes.asMap().entries.map((entry) {
      return ImmunizationCoverage(
        entry.value.key,
        entry.value.value,
        colors[entry.key % colors.length],
      );
    }).toList();

    var series = [
      charts.Series<ImmunizationCoverage, String>(
        id: 'Immunization',
        domainFn: (ImmunizationCoverage data, _) => data.type,
        measureFn: (ImmunizationCoverage data, _) => data.count,
        colorFn: (ImmunizationCoverage data, _) =>
            charts.ColorUtil.fromDartColor(data.color),
        data: seriesData,
        labelAccessorFn: (ImmunizationCoverage data, _) => '${data.count}',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: charts.BarChart(
        series,
        animate: true,
        vertical: false,
        barRendererDecorator: charts.BarLabelDecorator<String>(),
        domainAxis: charts.OrdinalAxisSpec(
          renderSpec: charts.SmallTickRendererSpec(
            labelStyle: charts.TextStyleSpec(
              fontSize: 11,
              color: charts.MaterialPalette.gray.shade800,
            ),
            labelRotation: 0,
          ),
        ),
      ),
    );
  }
}

class _PowerBIStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String trend;

  const _PowerBIStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _darkDeepTeal,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 11, color: _mutedCoolGray)),
        ],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 60) / 4; // 3 gaps of 20px
        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'Total Patients',
                value: totalPatients.toString(),
                icon: Icons.people_rounded,
                color: _primaryAqua,
                gradient: LinearGradient(
                  colors: [_primaryAqua, _secondaryIceBlue],
                ),
                trend: '+12%',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'Active Cases',
                value: activeCases.toString(),
                icon: Icons.assignment_turned_in_rounded,
                color: const Color(0xFFFF9800),
                gradient: LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFFF6F00)],
                ),
                trend: '+5%',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'Check-ups This Month',
                value: checkupsThisMonth.toString(),
                icon: Icons.calendar_month_rounded,
                color: const Color(0xFF9C27B0),
                gradient: LinearGradient(
                  colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                ),
                trend: '+18%',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'Health Score',
                value: '8.5',
                icon: Icons.favorite_rounded,
                color: const Color(0xFF4CAF50),
                gradient: LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                ),
                trend: '+3%',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Gradient gradient;
  final String trend;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.gradient,
    required this.trend,
  });

  @override
  State<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<_SummaryCard> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (mounted) {
      setState(() => _isHovered = value);
    }
  }

  @override
  void dispose() {
    _isHovered = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.color.withOpacity(0.2)
                  : Colors.black.withOpacity(0.08),
              blurRadius: _isHovered ? 25 : 15,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
          border: Border.all(
            color: _isHovered
                ? widget.color.withOpacity(0.3)
                : Colors.transparent,
            width: 2,
          ),
        ),
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.trending_up,
                        color: Colors.green,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.trend,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              widget.value,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: widget.color,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 14,
                color: _mutedCoolGray,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
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
        color: _darkDeepTeal,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryAqua.withOpacity(0.1),
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
                    color: _darkDeepTeal,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 0, color: _primaryAqua.withOpacity(0.1)),
          Padding(
            padding: const EdgeInsets.all(16),
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
            } else if (bmi < 25) {
              normal++;
            } else if (bmi < 30) {
              overweight++;
            } else {
              obese++;
            }
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
        ),
        charts.ChartTitle(
          'Count',
          behaviorPosition: charts.BehaviorPosition.start,
        ),
      ],
      defaultRenderer: charts.BarRendererConfig<String>(
        cornerStrategy: const charts.ConstCornerStrategy(10),
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
        ),
        charts.ChartTitle(
          'Systolic (mmHg)',
          behaviorPosition: charts.BehaviorPosition.start,
        ),
      ],
      defaultRenderer: charts.LineRendererConfig(includePoints: true),
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
          } else if (age < 35) {
            age18to35++;
          } else if (age < 65) {
            age35to65++;
          } else {
            age65plus++;
          }
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
        color: Colors.white,
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
                color: _darkDeepTeal,
              ),
            ),
            Text(
              '$value ($percentage%)',
              style: const TextStyle(fontSize: 11, color: _mutedCoolGray),
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
        ),
        charts.ChartTitle(
          'Count',
          behaviorPosition: charts.BehaviorPosition.bottom,
        ),
      ],
      defaultRenderer: charts.BarRendererConfig<String>(
        cornerStrategy: const charts.ConstCornerStrategy(10),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
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
                    color: _darkDeepTeal,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(fontSize: 11, color: _mutedCoolGray),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: _mutedCoolGray,
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
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
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
                    color: _darkDeepTeal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, color: _mutedCoolGray),
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
class TimeSeriesCheckups {
  final DateTime time;
  final int checkups;

  TimeSeriesCheckups(this.time, this.checkups);
}

class RecordDistribution {
  final String category;
  final int count;
  final Color color;

  RecordDistribution(this.category, this.count, this.color);
}

class VitalSignsData {
  final String category;
  final double value;
  final Color color;

  VitalSignsData(this.category, this.value, this.color);
}

class ImmunizationCoverage {
  final String type;
  final int count;
  final Color color;

  ImmunizationCoverage(this.type, this.count, this.color);
}

class DemographicsData {
  final String ageGroup;
  final int count;
  final Color color;

  DemographicsData(this.ageGroup, this.count, this.color);
}

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
