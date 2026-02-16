import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:mycapstone_project/web/login.dart';
import 'package:mycapstone_project/web/checkup.dart';
import 'package:mycapstone_project/web/health_metrics.dart';
import 'package:mycapstone_project/web/analytics.dart';
import 'package:mycapstone_project/web/prenatal.dart';
import 'package:mycapstone_project/web/Immunization.dart';
import 'package:mycapstone_project/web/patient.dart';
import 'package:mycapstone_project/web/communicable.dart';
import 'package:mycapstone_project/web/non-communicable.dart';
import 'package:mycapstone_project/web/Mortality.dart';
import 'package:mycapstone_project/web/database_helper.dart';
import 'package:mycapstone_project/web/prenatal_database_helper.dart';
import 'package:mycapstone_project/web/immunization_database_helper.dart';
import 'package:mycapstone_project/web/patient_database_helper.dart';

const Color _primaryAqua = Color(0xFF00A8B5);
const Color _secondaryIceBlue = Color(0xFF1E5A7A);
const Color _darkDeepTeal = Color(0xFF0A1F24);
const Color _mutedCoolGray = Color(0xFF546E7A);
const Color _lightOffWhite = Color(0xFFF5F5F5);
const Color _sidebarDark = Color(0xFF0E2F34);

class HomePage extends StatefulWidget {
  final User? user;
  const HomePage({super.key, this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _checkupHelper = DatabaseHelper.instance;
  final _prenatalHelper = PrenatalDatabaseHelper.instance;
  final _immunizationHelper = ImmunizationDatabaseHelper.instance;
  final _patientHelper = PatientDatabaseHelper.instance;

  int _totalPatients = 0;
  int _checkupsThisMonth = 0;
  int _prenatalRecords = 0;
  int _immunizationRecords = 0;
  bool _isLoadingMetrics = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    if (!mounted) return;
    setState(() => _isLoadingMetrics = true);

    try {
      final patients = await _patientHelper.getAllRecords();
      final checkups = await _checkupHelper.getAllRecords();
      final prenatal = await _prenatalHelper.getAllRecords();
      final immunizations = await _immunizationHelper.getAllRecords();

      final now = DateTime.now();
      final checkupsThisMonth = checkups.where((record) {
        try {
          final date = DateTime.parse(record['datetime'] ?? '');
          return date.year == now.year && date.month == now.month;
        } catch (e) {
          return false;
        }
      }).length;

      if (!mounted) return;
      setState(() {
        _totalPatients = patients.length;
        _checkupsThisMonth = checkupsThisMonth;
        _prenatalRecords = prenatal.length;
        _immunizationRecords = immunizations.length;
        _isLoadingMetrics = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMetrics = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.email?.split('@')[0] ?? 'User';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
        ? 'Good Afternoon'
        : 'Good Evening';

    return Scaffold(
      backgroundColor: _lightOffWhite,
      body: Row(
        children: [
          Container(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 10,
                    ),
                    children: [
                      _buildSidebarItem(
                        icon: Icons.dashboard_rounded,
                        label: 'Dashboard',
                        isActive: true,
                        onTap: () {},
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
                        onTap: () => Get.to(() => const AnalyticsPage()),
                      ),
                      const SizedBox(height: 4),
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
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
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
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
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
          ),
          Expanded(
            child: Column(
              children: [
                Container(
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
                      Text(
                        'Healthcare Dashboard',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: _darkDeepTeal,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
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
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32.0),
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$greeting, $userName!',
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Welcome to your Healthcare Management Dashboard',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        _buildQuickStatChip(
                                          icon: Icons.calendar_today,
                                          label: DateTime.now()
                                              .toString()
                                              .split(' ')[0],
                                        ),
                                        const SizedBox(width: 16),
                                        _buildQuickStatChip(
                                          icon: Icons.access_time,
                                          label:
                                              '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 150,
                                height: 150,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Image.asset(
                                  'assets/bg2.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            const Icon(
                              Icons.trending_up_rounded,
                              color: _primaryAqua,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Key Performance Metrics',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _darkDeepTeal,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _loadMetrics,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Refresh'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        GridView.count(
                          crossAxisCount: 4,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 24,
                          crossAxisSpacing: 24,
                          childAspectRatio: 1.4,
                          children: [
                            _buildWebMetricCard(
                              title: 'Total Patients',
                              value: _isLoadingMetrics
                                  ? '...'
                                  : '$_totalPatients',
                              subtitle: 'Registered in system',
                              icon: Icons.people_rounded,
                              color: _primaryAqua,
                              trend: '+12%',
                            ),
                            _buildWebMetricCard(
                              title: 'Check-ups',
                              value: _isLoadingMetrics
                                  ? '...'
                                  : '$_checkupsThisMonth',
                              subtitle: 'Completed this month',
                              icon: Icons.assignment_turned_in_rounded,
                              color: _darkDeepTeal,
                              trend: '+8%',
                            ),
                            _buildWebMetricCard(
                              title: 'Prenatal Care',
                              value: _isLoadingMetrics
                                  ? '...'
                                  : '$_prenatalRecords',
                              subtitle: 'Active records',
                              icon: Icons.pregnant_woman_rounded,
                              color: const Color(0xFFD84315),
                              trend: '+15%',
                            ),
                            _buildWebMetricCard(
                              title: 'Immunizations',
                              value: _isLoadingMetrics
                                  ? '...'
                                  : '$_immunizationRecords',
                              subtitle: 'Administered total',
                              icon: Icons.vaccines_rounded,
                              color: const Color(0xFF4CAF50),
                              trend: '+10%',
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _darkDeepTeal,
                          ),
                        ),
                        const SizedBox(height: 24),
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          childAspectRatio: 2.5,
                          children: [
                            _buildWebActionCard(
                              title: 'New Check-up',
                              subtitle: 'Record patient visit',
                              icon: Icons.add_circle_rounded,
                              color: _primaryAqua,
                              onTap: () => Get.to(() => const CheckUpPage()),
                            ),
                            _buildWebActionCard(
                              title: 'View Analytics',
                              subtitle: 'System insights',
                              icon: Icons.analytics_rounded,
                              color: _secondaryIceBlue,
                              onTap: () => Get.to(() => const AnalyticsPage()),
                            ),
                            _buildWebActionCard(
                              title: 'Patient Records',
                              subtitle: 'Manage patients',
                              icon: Icons.folder_shared_rounded,
                              color: const Color(0xFF4CAF50),
                              onTap: () =>
                                  Get.to(() => const PatientRecordPage()),
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

  Widget _buildQuickStatChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trend,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
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
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: _mutedCoolGray.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.2), width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _darkDeepTeal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: _mutedCoolGray.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
