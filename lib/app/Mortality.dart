import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;

const Color _primaryAqua = Color(0xFF00A8B5);
const Color _secondaryIceBlue = Color(0xFF1E5A7A);
const Color _darkDeepTeal = Color(0xFF0A1F24);
const Color _mutedCoolGray = Color(0xFF546E7A);
const Color _lightOffWhite = Color(0xFFF5F5F5);

class MortalityPage extends StatefulWidget {
  const MortalityPage({super.key});

  @override
  State<MortalityPage> createState() => _MortalityPageState();
}

class _MortalityPageState extends State<MortalityPage> {
  // Metrics
  int _totalDeaths = 0;
  String _leadingCause = '';
  int _elderlyDeaths = 0;
  double _verificationRate = 0.0;
  bool _isLoadingMetrics = false;
  bool _isDataLoaded = false;

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Data
  List<Map<String, dynamic>> _mortalityRecords = [];
  List<Map<String, dynamic>> _filteredRecords = [];
  List<MonthlyTrend> _monthlyTrends = [];
  List<CauseData> _causeData = [];
  List<AgeDistribution> _ageDistributions = [];

  @override
  void initState() {
    super.initState();
    // Load data asynchronously to avoid blocking UI
    Future.microtask(() => _loadData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingMetrics = true);

    try {
      // TODO: Replace with actual database queries
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _totalDeaths = 247;
        _leadingCause = 'Cardiovascular Disease';
        _elderlyDeaths = 156;
        _verificationRate = 89.5;

        // Monthly Trends Data
        _monthlyTrends = [
          MonthlyTrend('Aug', 18),
          MonthlyTrend('Sep', 22),
          MonthlyTrend('Oct', 19),
          MonthlyTrend('Nov', 25),
          MonthlyTrend('Dec', 21),
          MonthlyTrend('Jan', 23),
        ];

        // Cause of Death Data
        _causeData = [
          CauseData('Cardiovascular Disease', 89, 36.0),
          CauseData('Cancer', 52, 21.1),
          CauseData('Respiratory Disease', 38, 15.4),
          CauseData('Infectious Disease', 31, 12.6),
          CauseData('Accidents', 22, 8.9),
          CauseData('Others', 15, 6.0),
        ];

        // Age Distribution Data
        _ageDistributions = [
          AgeDistribution('0-18', 12, 4.9),
          AgeDistribution('19-40', 28, 11.3),
          AgeDistribution('41-60', 51, 20.6),
          AgeDistribution('61-80', 98, 39.7),
          AgeDistribution('81+', 58, 23.5),
        ];

        // Mortality Records
        _mortalityRecords = [
          {
            'id': '001',
            'name': 'Jose Martinez',
            'date': '2026-01-28',
            'age': 76,
            'gender': 'Male',
            'causeOfDeath': 'Myocardial Infarction',
            'place': 'City General Hospital',
            'reportedBy': 'Dr. Elena Santos',
            'verification': 'Verified',
          },
          {
            'id': '002',
            'name': 'Maria Gonzales',
            'date': '2026-01-27',
            'age': 84,
            'gender': 'Female',
            'causeOfDeath': 'Stroke (Ischemic)',
            'place': 'Home',
            'reportedBy': 'Dr. Ramon Cruz',
            'verification': 'Verified',
          },
          {
            'id': '003',
            'name': 'Carlos Reyes',
            'date': '2026-01-26',
            'age': 62,
            'gender': 'Male',
            'causeOfDeath': 'Lung Cancer',
            'place': 'St. Mary Medical Center',
            'reportedBy': 'Dr. Patricia Diaz',
            'verification': 'Verified',
          },
          {
            'id': '004',
            'name': 'Luz Hernandez',
            'date': '2026-01-25',
            'age': 71,
            'gender': 'Female',
            'causeOfDeath': 'Pneumonia',
            'place': 'Community Health Center',
            'reportedBy': 'Dr. Miguel Torres',
            'verification': 'Pending',
          },
          {
            'id': '005',
            'name': 'Roberto Sanchez',
            'date': '2026-01-24',
            'age': 55,
            'gender': 'Male',
            'causeOfDeath': 'Road Traffic Accident',
            'place': 'Emergency Room',
            'reportedBy': 'Dr. Ana Lopez',
            'verification': 'Verified',
          },
          {
            'id': '006',
            'name': 'Isabel Ramos',
            'date': '2026-01-23',
            'age': 89,
            'gender': 'Female',
            'causeOfDeath': 'Heart Failure',
            'place': 'Nursing Home',
            'reportedBy': 'Dr. Juan Mendoza',
            'verification': 'Verified',
          },
        ];

        _filteredRecords = List.from(_mortalityRecords);
        _isLoadingMetrics = false;
        _isDataLoaded = true;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoadingMetrics = false;
        _isDataLoaded = true;
      });
    }
  }

  void _filterRecords(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredRecords = List.from(_mortalityRecords);
      } else {
        _filteredRecords = _mortalityRecords.where((record) {
          return record['name'].toString().toLowerCase().contains(_searchQuery) ||
              record['causeOfDeath'].toString().toLowerCase().contains(_searchQuery) ||
              record['place'].toString().toLowerCase().contains(_searchQuery) ||
              record['verification'].toString().toLowerCase().contains(_searchQuery);
        }).toList();
      }
    });
  }

  Color _getVerificationColor(String verification) {
    return verification.toLowerCase() == 'verified'
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFFA726);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Mortality Monitoring',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _primaryAqua,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddRecordDialog();
            },
            tooltip: 'Add Record',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mortality Overview Dashboard
              _buildOverviewDashboard(),

              const SizedBox(height: 20),

              // Graphs Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildGraphsSection(),
              ),

              const SizedBox(height: 20),

              // Tables Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTablesSection(),
              ),

              const SizedBox(height: 20),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSearchBar(),
              ),

              const SizedBox(height: 20),

              // Mortality Record Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildRecordCards(),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Overview Dashboard
  Widget _buildOverviewDashboard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _primaryAqua,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mortality Overview',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoadingMetrics)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Total Deaths',
                          value: _totalDeaths.toString(),
                          icon: Icons.assignment,
                          color: Colors.white,
                          textColor: _primaryAqua,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Elderly Deaths',
                          value: _elderlyDeaths.toString(),
                          icon: Icons.elderly,
                          color: Colors.white,
                          textColor: const Color(0xFFD84315),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Leading Cause',
                          value: _leadingCause,
                          icon: Icons.warning,
                          color: Colors.white,
                          textColor: const Color(0xFF7B1FA2),
                          isSmallText: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Verification Rate',
                          value: '${_verificationRate.toStringAsFixed(1)}%',
                          icon: Icons.verified,
                          color: Colors.white,
                          textColor: const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color textColor,
    bool isSmallText = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
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
              Icon(icon, color: textColor, size: 28),
              if (!isSmallText)
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (isSmallText)
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: textColor.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Graphs Section
  Widget _buildGraphsSection() {
    if (!_isDataLoaded) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: CircularProgressIndicator(color: _primaryAqua),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistical Analysis',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _darkDeepTeal,
          ),
        ),
        const SizedBox(height: 16),
        
        // Monthly Trends (Line Graph)
        if (_monthlyTrends.isNotEmpty)
          _buildGraphCard(
            title: 'Monthly Trends',
            icon: Icons.show_chart,
            child: SizedBox(
              height: 250,
              child: charts.LineChart(
                [
                  charts.Series<MonthlyTrend, int>(
                    id: 'Deaths',
                    colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
                    domainFn: (MonthlyTrend trend, int? index) => index ?? 0,
                    measureFn: (MonthlyTrend trend, _) => trend.deaths,
                    data: _monthlyTrends,
                  )
                ],
                animate: true,
                defaultRenderer: charts.LineRendererConfig(
                  includeArea: true,
                  stacked: false,
                ),
              ),
          ),
        ),
        if (_causeData.isNotEmpty && _ageDistributions.isNotEmpty)
          const SizedBox(height: 16),

        if (_causeData.isNotEmpty && _ageDistributions.isNotEmpty)
          Row(
            children: [
              // Leading Causes (Pie Chart)
              Expanded(
                child: _buildGraphCard(
                  title: 'Leading Causes',
                  icon: Icons.pie_chart,
                  child: SizedBox(
                    height: 200,
        child: charts.PieChart<String>(
          [
            charts.Series<CauseData, String>(
              id: 'Causes',
              domainFn: (CauseData data, _) => data.cause,
              measureFn: (CauseData data, _) => data.count,
              data: _causeData,
              labelAccessorFn: (CauseData data, _) =>
                  '${data.percentage.toStringAsFixed(1)}%',
            )
          ],
          animate: true,
          defaultRenderer: charts.ArcRendererConfig<String>(
            arcWidth: 60,
            arcRendererDecorators: [
              charts.ArcLabelDecorator<String>(
                labelPosition: charts.ArcLabelPosition.auto,
              )
            ],
          ),
        ),
      ),
    ),
          ),
    
    const SizedBox(width: 12),

            // Age Distribution (Bar Chart)
            Expanded(
              child: _buildGraphCard(
                title: 'Age Distribution',
                icon: Icons.bar_chart,
                child: SizedBox(
                  height: 200,
                  child: charts.BarChart(
                    [
                      charts.Series<AgeDistribution, String>(
                        id: 'Ages',
                        colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
                        domainFn: (AgeDistribution dist, _) => dist.ageRange,
                        measureFn: (AgeDistribution dist, _) => dist.count,
                        data: _ageDistributions,
                      )
                    ],
                    animate: true,
                    vertical: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGraphCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _primaryAqua, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _darkDeepTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // Tables Section
  Widget _buildTablesSection() {
    if (!_isDataLoaded) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: CircularProgressIndicator(color: _primaryAqua),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Statistics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _darkDeepTeal,
          ),
        ),
        const SizedBox(height: 16),

        // Cause of Death Table
        _buildCauseTable(),
        const SizedBox(height: 16),

        // Age Distribution Table
        _buildAgeTable(),
      ],
    );
  }

  Widget _buildCauseTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                Icon(Icons.table_chart, color: _primaryAqua, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Cause of Death Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _darkDeepTeal,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                _primaryAqua.withOpacity(0.1),
              ),
              columns: [
                DataColumn(
                  label: Text(
                    'Cause of Death',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _darkDeepTeal,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Percentage',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _darkDeepTeal,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Progress',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _darkDeepTeal,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Death Count',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _darkDeepTeal,
                    ),
                  ),
                ),
              ],
              rows: _causeData.map((cause) {
                return DataRow(cells: [
                  DataCell(Text(cause.cause)),
                  DataCell(Text('${cause.percentage.toStringAsFixed(1)}%')),
                  DataCell(
                    SizedBox(
                      width: 100,
                      child: LinearProgressIndicator(
                        value: cause.percentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(_primaryAqua),
                      ),
                    ),
                  ),
                  DataCell(Text(cause.count.toString())),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                Icon(Icons.table_rows, color: _primaryAqua, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Age Distribution',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _darkDeepTeal,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                _primaryAqua.withOpacity(0.1),
              ),
              columns: [
                DataColumn(
                  label: Text(
                    'Age Range',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _darkDeepTeal,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Death Count',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _darkDeepTeal,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Percentage',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _darkDeepTeal,
                    ),
                  ),
                ),
              ],
              rows: _ageDistributions.map((age) {
                return DataRow(cells: [
                  DataCell(Text(age.ageRange)),
                  DataCell(Text(age.count.toString())),
                  DataCell(Text('${age.percentage.toStringAsFixed(1)}%')),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Search Bar
  Widget _buildSearchBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mortality Records',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _darkDeepTeal,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _filterRecords,
            decoration: InputDecoration(
              hintText: 'Search by name, cause, place, or verification status...',
              hintStyle: TextStyle(color: _mutedCoolGray),
              prefixIcon: Icon(Icons.search, color: _primaryAqua),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: _mutedCoolGray),
                      onPressed: () {
                        _searchController.clear();
                        _filterRecords('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  // Record Cards
  Widget _buildRecordCards() {
    if (_filteredRecords.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 64, color: _mutedCoolGray.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty ? 'No records found' : 'No results for "$_searchQuery"',
                style: TextStyle(
                  fontSize: 16,
                  color: _mutedCoolGray,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _filteredRecords.map((record) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildRecordCard(record),
        );
      }).toList(),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryAqua.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _primaryAqua,
                  child: Text(
                    record['name'].toString().substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record['name'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _darkDeepTeal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${record['age']} years • ${record['gender']}',
                        style: TextStyle(
                          fontSize: 13,
                          color: _mutedCoolGray,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getVerificationColor(record['verification']),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    record['verification'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow(
                  icon: Icons.calendar_today,
                  label: 'Date',
                  value: _formatDate(record['date']),
                  color: _primaryAqua,
                ),
                const Divider(height: 20),
                _buildDetailRow(
                  icon: Icons.warning_amber,
                  label: 'Cause of Death',
                  value: record['causeOfDeath'],
                  color: const Color(0xFFD84315),
                ),
                const Divider(height: 20),
                _buildDetailRow(
                  icon: Icons.location_on,
                  label: 'Place',
                  value: record['place'],
                  color: const Color(0xFF7B1FA2),
                ),
                const Divider(height: 20),
                _buildDetailRow(
                  icon: Icons.person,
                  label: 'Reported By',
                  value: record['reportedBy'],
                  color: const Color(0xFF2196F3),
                ),
              ],
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.visibility,
                  label: 'View',
                  color: _primaryAqua,
                  onTap: () => _viewRecordDetails(record),
                ),
                _buildActionButton(
                  icon: Icons.edit,
                  label: 'Edit',
                  color: const Color(0xFF7B1FA2),
                  onTap: () => _editRecord(record),
                ),
                _buildActionButton(
                  icon: Icons.verified,
                  label: 'Verify',
                  color: const Color(0xFF4CAF50),
                  onTap: () => _verifyRecord(record),
                ),
                _buildActionButton(
                  icon: Icons.print,
                  label: 'Print',
                  color: const Color(0xFF607D8B),
                  onTap: () => _printRecord(record),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: _mutedCoolGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: _darkDeepTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  // Action Methods
  void _showAddRecordDialog() {
    Get.snackbar(
      'Add Record',
      'Mortality record form coming soon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: _primaryAqua,
      colorText: Colors.white,
    );
  }

  void _viewRecordDetails(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Mortality Record Details',
          style: TextStyle(color: _darkDeepTeal, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoItem('Record ID', record['id']),
              _buildInfoItem('Name', record['name']),
              _buildInfoItem('Date of Death', record['date']),
              _buildInfoItem('Age', '${record['age']} years'),
              _buildInfoItem('Gender', record['gender']),
              _buildInfoItem('Cause of Death', record['causeOfDeath']),
              _buildInfoItem('Place', record['place']),
              _buildInfoItem('Reported By', record['reportedBy']),
              _buildInfoItem('Verification Status', record['verification']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: _primaryAqua)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _mutedCoolGray,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: _darkDeepTeal,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editRecord(Map<String, dynamic> record) {
    Get.snackbar(
      'Edit Record',
      'Editing record for ${record['name']}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF7B1FA2),
      colorText: Colors.white,
    );
  }

  void _verifyRecord(Map<String, dynamic> record) {
    Get.snackbar(
      'Verify Record',
      'Verifying record for ${record['name']}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF4CAF50),
      colorText: Colors.white,
    );
  }

  void _printRecord(Map<String, dynamic> record) {
    Get.snackbar(
      'Print Record',
      'Printing death certificate for ${record['name']}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF607D8B),
      colorText: Colors.white,
    );
  }
}

// Data Models for Charts
class MonthlyTrend {
  final String month;
  final int deaths;

  MonthlyTrend(this.month, this.deaths);
}

class CauseData {
  final String cause;
  final int count;
  final double percentage;

  CauseData(this.cause, this.count, this.percentage);
}

class AgeDistribution {
  final String ageRange;
  final int count;
  final double percentage;

  AgeDistribution(this.ageRange, this.count, this.percentage);
}
