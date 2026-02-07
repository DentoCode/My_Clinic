import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/patient.dart';
import '../services/report_generator.dart';

class AdvancedReportsScreen extends StatefulWidget {
  const AdvancedReportsScreen({Key? key}) : super(key: key);

  @override
  State<AdvancedReportsScreen> createState() => _AdvancedReportsScreenState();
}

class _AdvancedReportsScreenState extends State<AdvancedReportsScreen> {
  List<Patient> _patients = [];
  bool _isLoading = true;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    final patients = await DatabaseHelper.instance.getAllPatients();
    setState(() {
      _patients = patients;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير المتقدمة'),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // تقرير المريض
                _buildReportCard(
                  'تقرير مريض',
                  'تقرير شامل لمريض محدد',
                  Icons.person_outline,
                  Colors.blue,
                  () => _showPatientSelectionDialog(),
                ),
                const SizedBox(height: 12),

                // تقرير المدفوعات
                _buildReportCard(
                  'تقرير المدفوعات',
                  'تقرير مفصل للمدفوعات خلال فترة زمنية',
                  Icons.payment,
                  Colors.green,
                  () => _showPaymentsReportDialog(),
                ),
                const SizedBox(height: 12),

                // تقرير العلاجات
                _buildReportCard(
                  'تقرير العلاجات',
                  'تقرير شامل لجميع العلاجات',
                  Icons.medical_services_outlined,
                  Colors.orange,
                  () => _generateAndShowReport(
                      () => ReportGenerator.generateTreatmentsReport()),
                ),
                const SizedBox(height: 12),

                // ملخص الإحصائيات
                _buildReportCard(
                  'ملخص الإحصائيات',
                  'نظرة عامة على جميع الأرقام',
                  Icons.bar_chart,
                  Colors.purple,
                  () => _showStatisticsReport(),
                ),
              ],
            ),
    );
  }

  Widget _buildReportCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showPatientSelectionDialog() {
    if (_patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد مرضى مسجلين'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر مريض'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _patients
                .map((patient) => ListTile(
                      title: Text(patient.name),
                      subtitle: Text(patient.phone),
                      onTap: () {
                        Navigator.pop(context);
                        print('Generating report for: ${patient.name}');
                        _generateAndShowReport(
                          () => ReportGenerator.generatePatientReport(patient),
                        );
                      },
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  void _showPaymentsReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تقرير المدفوعات'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('تاريخ البداية'),
                subtitle:
                    Text(DateFormat('yyyy/MM/dd', 'ar').format(_startDate)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _startDate = date);
                  }
                },
              ),
              ListTile(
                title: const Text('تاريخ النهاية'),
                subtitle: Text(DateFormat('yyyy/MM/dd', 'ar').format(_endDate)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _endDate = date);
                  }
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _generateAndShowReport(
                    () => ReportGenerator.generatePaymentsReport(
                      startDate: _startDate,
                      endDate: _endDate,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('إنشاء التقرير'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatisticsReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ملخص الإحصائيات'),
        content: SingleChildScrollView(
          child: FutureBuilder(
            future: _loadStatistics(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }

              final stats = snapshot.data as Map<String, dynamic>;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatRow('عدد المرضى:', '${stats['patientsCount']}'),
                  _buildStatRow('عدد العلاجات:', '${stats['treatmentsCount']}'),
                  _buildStatRow(
                      'المواعيد اليومية:', '${stats['todayAppointments']}'),
                  const Divider(),
                  _buildStatRow('إجمالي الإيرادات:',
                      '${stats['totalRevenue'].toStringAsFixed(2)} ج.م'),
                  _buildStatRow('المبالغ المستحقة:',
                      '${stats['pendingPayments'].toStringAsFixed(2)} ج.م'),
                  _buildStatRow('نسبة التحصيل:',
                      '${((stats['totalRevenue'] / (stats['totalRevenue'] + stats['pendingPayments'])) * 100).toStringAsFixed(1)}%'),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 14, color: Colors.blue)),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _loadStatistics() async {
    final treatments = await DatabaseHelper.instance.getAllTreatments();
    final appointments = await DatabaseHelper.instance.getAllAppointments();
    final payments = await DatabaseHelper.instance.getAllPayments();
    final patients = await DatabaseHelper.instance.getAllPatients();

    double totalCost = treatments.fold(0, (sum, t) => sum + t.cost);
    double totalPaid = payments.fold(0, (sum, p) => sum + p.amount);
    int todayAppointments =
        appointments.where((a) => a.dateTime.day == DateTime.now().day).length;

    return {
      'patientsCount': patients.length,
      'treatmentsCount': treatments.length,
      'todayAppointments': todayAppointments,
      'totalRevenue': totalPaid,
      'pendingPayments': totalCost - totalPaid,
    };
  }

  void _generateAndShowReport(
    Future<void> Function() reportGenerator,
  ) async {
    try {
      print('Starting report generation...');
      await reportGenerator();
      print('Report generated and displayed successfully');
    } catch (e) {
      print('Report generation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إنشاء التقرير: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
