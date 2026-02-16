import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mycapstone_project/web/ai_summary.dart' as ai;
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mycapstone_project/firebase_helper.dart';

// Health Metrics now integrates the AI summarizer and provides a professional UI

const Color _primaryAqua = Color(0xFF8ED7DA);
const Color _darkDeepTeal = Color(0xFF0E2F34);
const Color _mutedCoolGray = Color(0xFF8A8FA3);
const Color _lightOffWhite = Color(0xFFF1F1EE);

class HealthMetricsPage extends StatefulWidget {
  const HealthMetricsPage({super.key});

  @override
  State<HealthMetricsPage> createState() => _HealthMetricsPageState();
}

class _HealthMetricsPageState extends State<HealthMetricsPage> {
  bool _loading = false;
  String _summary = '';
  String _summaryTitle = '';
  DateTime _selectedDate = DateTime.now();
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  String _mode = 'Daily'; // Daily, Monthly, Yearly

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      String result;
      String period = '';
      String type = '';
      if (_mode == 'Daily') {
        result = await ai.generateDailySummaryForCurrentUser(_selectedDate);
        _summaryTitle = 'Daily Summary — ${DateFormat.yMMMd().format(_selectedDate)}';
        period = DateFormat('yyyy-MM-dd').format(_selectedDate);
        type = 'daily';
      } else if (_mode == 'Monthly') {
        result = await ai.generateMonthlySummaryForCurrentUser(_selectedYear, _selectedMonth);
        _summaryTitle = 'Monthly Summary — ${_selectedYear}-${_selectedMonth.toString().padLeft(2, '0')}';
        period = '${_selectedYear}-${_selectedMonth.toString().padLeft(2, '0')}';
        type = 'monthly';
      } else {
        result = await ai.generateYearlySummaryForCurrentUser(_selectedYear);
        _summaryTitle = 'Yearly Summary — ${_selectedYear}';
        period = '$_selectedYear';
        type = 'yearly';
      }
      setState(() => _summary = result);
      await _saveSummaryToFirestore(type: type, period: period, text: result);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveSummaryToFirestore({required String type, required String period, required String text}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? 'anonymous';
      final firestore = getFirestoreInstance();
      await firestore.collection('summary_records').add({
        'patientId': uid,
        'type': type,
        'period': period,
        'text': text,
        'generatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Returns a stream of the most recent summary doc for the current user and selected period/type.
  Stream<QuerySnapshot> _savedSummaryStream() {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'anonymous';
    final firestore = getFirestoreInstance();
    String period;
    String type;
    if (_mode == 'Daily') {
      period = DateFormat('yyyy-MM-dd').format(_selectedDate);
      type = 'daily';
    } else if (_mode == 'Monthly') {
      period = '${_selectedYear}-${_selectedMonth.toString().padLeft(2, '0')}';
      type = 'monthly';
    } else {
      period = '$_selectedYear';
      type = 'yearly';
    }
    return firestore
      .collection('summary_records')
        .where('patientId', isEqualTo: uid)
        .where('type', isEqualTo: type)
        .where('period', isEqualTo: period)
        .orderBy('generatedAt', descending: true)
        .limit(1)
        .snapshots();
  }

  void _copySummaryToClipboard() {
    if (_summary.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _summary));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Summary copied to clipboard')));
  }

  void _clearSummary() {
    setState(() {
      _summary = '';
      _summaryTitle = '';
    });
  }

  Widget _buildSummaryControls() {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: _primaryAqua.withOpacity(0.5), width: 1.5)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DropdownButton<String>(
                  value: _mode,
                  dropdownColor: _darkDeepTeal,
                  items: const [DropdownMenuItem(value: 'Daily', child: Text('Daily', style: TextStyle(color: _lightOffWhite))), DropdownMenuItem(value: 'Monthly', child: Text('Monthly', style: TextStyle(color: _lightOffWhite))), DropdownMenuItem(value: 'Yearly', child: Text('Yearly', style: TextStyle(color: _lightOffWhite)))],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _mode = v);
                  },
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _generate,
                  icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.play_arrow),
                  label: Text(_loading ? 'Generating...' : 'Generate'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_mode == 'Daily')
              Row(children: [
                Text('Date: ', style: TextStyle(color: _lightOffWhite, fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: () async {
                    final d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime.now());
                    if (d != null) setState(() => _selectedDate = d);
                  },
                  child: Text(DateFormat.yMMMd().format(_selectedDate)),
                ),
              ])
            else if (_mode == 'Monthly')
              Row(children: [
                Text('Month: ', style: TextStyle(color: _lightOffWhite, fontWeight: FontWeight.w600)),
                DropdownButton<int>(value: _selectedMonth, dropdownColor: _darkDeepTeal, items: List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(value: m, child: Text(DateFormat.MMMM().format(DateTime(0, m)), style: const TextStyle(color: _lightOffWhite)))).toList(), onChanged: (v) { if (v!=null) setState(()=>_selectedMonth = v); }),
                const SizedBox(width: 12),
                DropdownButton<int>(value: _selectedYear, dropdownColor: _darkDeepTeal, items: List.generate(6, (i) => DateTime.now().year - i).map((y) => DropdownMenuItem(value: y, child: Text(y.toString(), style: const TextStyle(color: _lightOffWhite)))).toList(), onChanged: (v) { if (v!=null) setState(()=>_selectedYear = v); }),
              ])
            else
              Row(children: [
                Text('Year: ', style: TextStyle(color: _lightOffWhite, fontWeight: FontWeight.w600)),
                DropdownButton<int>(value: _selectedYear, dropdownColor: _darkDeepTeal, items: List.generate(6, (i) => DateTime.now().year - i).map((y) => DropdownMenuItem(value: y, child: Text(y.toString(), style: const TextStyle(color: _lightOffWhite)))).toList(), onChanged: (v) { if (v!=null) setState(()=>_selectedYear = v); }),
              ]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkDeepTeal,
      appBar: AppBar(
        backgroundColor: _darkDeepTeal,
        title: Text('Summary', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: _lightOffWhite, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: _lightOffWhite),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Overview Section
          _HealthOverviewCard(),
          const SizedBox(height: 12),
          // Professional Summary Controls
          _SectionTitle('AI Summaries'),
          const SizedBox(height: 8),
          _buildSummaryControls(),
          const SizedBox(height: 12),
          // Main summary card with actions
          Card(
            color: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: _primaryAqua.withOpacity(0.5), width: 1.5)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Text(_summaryTitle.isEmpty ? 'No summary generated' : _summaryTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: _lightOffWhite))),
                  Row(children: [
                    IconButton(onPressed: _summary.isEmpty ? null : _copySummaryToClipboard, icon: const Icon(Icons.copy, color: _lightOffWhite), tooltip: 'Copy'),
                    IconButton(onPressed: _summary.isEmpty ? null : _clearSummary, icon: const Icon(Icons.clear, color: _lightOffWhite), tooltip: 'Clear'),
                  ])
                ]),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: _primaryAqua.withOpacity(0.3))),
                  child: _summary.isNotEmpty
                      ? SelectableText(_summary, style: const TextStyle(height: 1.4, color: _lightOffWhite))
                      : Text('Generate a summary to see detailed insights, trends and anomalies.', style: TextStyle(color: _lightOffWhite.withOpacity(0.7))),
                ),
                const SizedBox(height: 12),
                // Saved summaries history (latest first)
                StreamBuilder<QuerySnapshot>(
                  stream: _savedSummaryStream(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) return const SizedBox();
                    if (!snap.hasData || snap.data!.docs.isEmpty) return const SizedBox();
                    final docs = snap.data!.docs;
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Divider(),
                      Text('Recent saved summary', style: TextStyle(fontWeight: FontWeight.w600, color: _darkDeepTeal)),
                      const SizedBox(height: 8),
                      ...docs.map((d) {
                        final m = d.data() as Map<String, dynamic>;
                        final text = (m['text'] as String?) ?? '';
                        final ts = m['generatedAt'] as Timestamp?;
                        final when = ts != null ? DateFormat.yMMMd().add_jm().format(ts.toDate()) : 'recent';
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(when, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () {
                              setState(() {
                                _summary = text;
                                _summaryTitle = 'Saved — $when';
                              });
                            },
                          ),
                        );
                      }).toList()
                    ]);
                  },
                ),
              ]),
            ),
          ),
          const SizedBox(height: 24),
        ]),
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
              color: _lightOffWhite,
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
            color: _lightOffWhite,
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
            color: _lightOffWhite,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

