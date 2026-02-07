import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/patient.dart';
import '../models/treatment.dart';
import '../models/payment.dart';
import '../models/appointment.dart';
import '../models/procedure.dart';
import '../database/database_helper.dart';
import 'add_edit_patient_screen.dart';

class PatientDetailsScreen extends StatefulWidget {
  final Patient patient;

  const PatientDetailsScreen({Key? key, required this.patient})
      : super(key: key);

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  late Patient _patient;
  List<Treatment> _treatments = [];
  List<Payment> _payments = [];
  List<Appointment> _appointments = [];
  Map<String, List<Procedure>> _proceduresMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    setState(() => _isLoading = true);

    try {
      final patient = await DatabaseHelper.instance.getPatient(_patient.id);
      final treatments =
          await DatabaseHelper.instance.getPatientTreatments(_patient.id);
      final payments =
          await DatabaseHelper.instance.getPatientPayments(_patient.id);
      final appointments =
          await DatabaseHelper.instance.getPatientAppointments(_patient.id);

      final proceduresMap = <String, List<Procedure>>{};
      for (final treatment in treatments) {
        final procs =
            await DatabaseHelper.instance.getTreatmentProcedures(treatment.id);
        proceduresMap[treatment.id] = procs;
      }

      if (mounted) {
        setState(() {
          if (patient != null) _patient = patient;
          _treatments = treatments;
          _payments = payments;
          _appointments = appointments;
          _proceduresMap = proceduresMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading patient data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editPatient() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditPatientScreen(patient: _patient),
      ),
    );
    if (result == true) _loadPatientData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ملف المريض'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'تعديل البيانات',
            onPressed: _editPatient,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // رأس المريض
                  _buildPatientHeader(),

                  // الإحصائيات السريعة
                  _buildQuickStats(),

                  // المعلومات الشخصية
                  _buildPersonalInfoSection(),

                  // المعلومات الطبية
                  _buildMedicalInfoSection(),

                  // العلاجات
                  _buildTreatmentsSection(),

                  // المواعيد
                  _buildAppointmentsSection(),

                  // المدفوعات
                  _buildPaymentsSection(),

                  // الملاحظات
                  if (_patient.notes != null) _buildNotesSection(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // رأس المريض
  Widget _buildPatientHeader() {
    return Container(
      color: Colors.blue.shade700,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Text(
              _patient.name[0].toUpperCase(),
              style: TextStyle(
                fontSize: 40,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _patient.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_patient.age} سنة • ${_patient.gender}',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'رقم المريض: ${_patient.id.substring(0, 8)}',
            style: const TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  // الإحصائيات السريعة
  Widget _buildQuickStats() {
    double totalPaid = _payments.isNotEmpty
        ? _payments.fold(0.0, (sum, p) => sum + p.amount)
        : 0.0;
    int completedTreatments =
        _treatments.where((t) => t.status == 'مكتمل').length;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            'العلاجات',
            _treatments.length.toString(),
            Colors.purple,
          ),
          _buildStatCard(
            'المكتملة',
            completedTreatments.toString(),
            Colors.green,
          ),
          _buildStatCard(
            'المدفوع',
            '${NumberFormat('#,###').format(totalPaid.toInt())} ج.م',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // المعلومات الشخصية
  Widget _buildPersonalInfoSection() {
    return _buildSection(
      'المعلومات الشخصية',
      [
        _buildInfoRow('الهاتف', _patient.phone, Icons.phone),
        if (_patient.email != null)
          _buildInfoRow('البريد الإلكتروني', _patient.email!, Icons.email),
        if (_patient.address != null)
          _buildInfoRow('العنوان', _patient.address!, Icons.location_on),
        _buildInfoRow(
          'تاريخ الميلاد',
          DateFormat('yyyy/MM/dd').format(_patient.birthDate),
          Icons.cake,
        ),
        _buildInfoRow('الجنس', _patient.gender, Icons.wc),
      ],
    );
  }

  // المعلومات الطبية
  Widget _buildMedicalInfoSection() {
    if (_patient.medicalHistory == null && _patient.allergies == null) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      'المعلومات الطبية',
      [
        if (_patient.medicalHistory != null)
          _buildInfoRow(
            'التاريخ الطبي',
            _patient.medicalHistory!,
            Icons.medical_services,
            Colors.blue,
          ),
        if (_patient.allergies != null)
          _buildInfoRow(
            'الحساسية',
            _patient.allergies!,
            Icons.warning_amber,
            Colors.red,
          ),
      ],
    );
  }

  // قسم العلاجات
  Widget _buildTreatmentsSection() {
    return _buildSection(
      'العلاجات (${_treatments.length})',
      [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _showAddTreatmentDialog,
            icon: const Icon(Icons.add),
            label: const Text('إضافة علاج'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_treatments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'لا توجد علاجات مسجلة',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        else
          ..._treatments.map((treatment) {
            int remainingDays =
                treatment.followUpDate?.difference(DateTime.now()).inDays ?? 0;

            return _buildTreatmentCard(treatment, remainingDays);
          }).toList(),
      ],
    );
  }

  Widget _buildTreatmentCard(Treatment treatment, int remainingDays) {
    Color statusColor = _getStatusColor(treatment.status);
    double remainingAmount = treatment.cost - treatment.paidAmount;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(Icons.medical_services, color: statusColor),
        ),
        title: Text(
          treatment.treatmentType,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'التاريخ: ${DateFormat('yyyy/MM/dd').format(treatment.date)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                treatment.status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${treatment.cost.toStringAsFixed(0)} ج.م',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('نوع العلاج', treatment.treatmentType),
                _buildDetailRow('التاريخ',
                    DateFormat('yyyy/MM/dd HH:mm').format(treatment.date)),
                _buildDetailRow('موقع السن', treatment.toothPosition),
                _buildDetailRow(
                    'التكلفة', '${treatment.cost.toStringAsFixed(2)} ج.م'),
                _buildDetailRow('المبلغ المدفوع',
                    '${treatment.paidAmount.toStringAsFixed(2)} ج.م'),
                if (remainingAmount > 0)
                  _buildDetailRow(
                    'المبلغ المتبقي',
                    '${remainingAmount.toStringAsFixed(2)} ج.م',
                    isWarning: true,
                  ),
                if (treatment.materials != null)
                  _buildDetailRow('المواد المستخدمة', treatment.materials!),
                if (treatment.treatmentSteps != null)
                  _buildDetailRow('خطوات العلاج', treatment.treatmentSteps!),
                if (treatment.complications != null)
                  _buildDetailRow(
                    'المضاعفات',
                    treatment.complications!,
                    isWarning: true,
                  ),
                if (treatment.followUpDate != null) ...[
                  _buildDetailRow(
                    'تاريخ المتابعة',
                    DateFormat('yyyy/MM/dd').format(treatment.followUpDate!),
                  ),
                  if (remainingDays > 0)
                    _buildDetailRow(
                      'باقي الأيام',
                      '$remainingDays يوم',
                      isHighlight: remainingDays <= 7,
                    ),
                ],
                const SizedBox(height: 16),
                // الإجراءات
                _buildTreatmentProcedures(treatment),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentProcedures(Treatment treatment) {
    final procedures = _proceduresMap[treatment.id] ?? [];

    if (procedures.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الإجراءات',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => _showProcedureDialog(treatment),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('إضافة'),
              ),
            ],
          ),
          Text(
            'لا توجد إجراءات',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      );
    }

    final completedCount = procedures.where((p) => p.isCompleted).length;
    final progress =
        procedures.isEmpty ? 0.0 : completedCount / procedures.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الإجراءات ($completedCount/${procedures.length})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: progress == 1.0 ? Colors.green : Colors.orange,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showProcedureDialog(treatment),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation(
              progress == 1.0 ? Colors.green : Colors.orange,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...procedures.map((proc) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Checkbox(
                  value: proc.isCompleted,
                  onChanged: (value) async {
                    final updated = proc.copyWith(
                      isCompleted: value ?? false,
                      completedDate: (value ?? false) ? DateTime.now() : null,
                    );
                    await DatabaseHelper.instance.updateProcedure(updated);
                    _loadPatientData();
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proc.name,
                        style: TextStyle(
                          fontSize: 13,
                          decoration: proc.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (proc.description.isNotEmpty)
                        Text(
                          proc.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (proc.isCompleted)
                  Icon(Icons.check_circle, color: Colors.green, size: 18),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  void _showProcedureDialog(Treatment treatment) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final procedures = _proceduresMap[treatment.id] ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة إجراء'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الإجراء',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'وصف الإجراء',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                try {
                  final procedure = Procedure(
                    id: const Uuid().v4(),
                    treatmentId: treatment.id,
                    name: nameController.text,
                    description: descController.text,
                    startDate: DateTime.now(),
                    order: procedures.length + 1,
                    createdAt: DateTime.now(),
                  );
                  print(
                      'Saving procedure: ${procedure.name} for treatment: ${treatment.id}');
                  await DatabaseHelper.instance.insertProcedure(procedure);
                  print('Procedure saved successfully');
                  if (mounted) {
                    Navigator.pop(context);
                    await _loadPatientData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إضافة الإجراء بنجاح')),
                    );
                  }
                } catch (e) {
                  print('Error saving procedure: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('خطأ: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  // قسم المواعيد
  Widget _buildAppointmentsSection() {
    final upcomingAppointments =
        _appointments.where((a) => a.dateTime.isAfter(DateTime.now())).toList();
    final pastAppointments = _appointments
        .where((a) => a.dateTime.isBefore(DateTime.now()))
        .toList();

    return _buildSection(
      'المواعيد (${upcomingAppointments.length + pastAppointments.length})',
      [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _showAddAppointmentDialog,
            icon: const Icon(Icons.add),
            label: const Text('إضافة موعد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (upcomingAppointments.isEmpty && pastAppointments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'لا توجد مواعيد مسجلة',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        else ...[
          if (upcomingAppointments.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'المواعيد القادمة',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                  fontSize: 13,
                ),
              ),
            ),
            ..._appointments
                .where((a) => a.dateTime.isAfter(DateTime.now()))
                .take(3)
                .map((apt) => _buildAppointmentCard(apt, isUpcoming: true))
                .toList(),
          ],
          if (pastAppointments.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'المواعيد السابقة',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ),
            ..._appointments
                .where((a) => a.dateTime.isBefore(DateTime.now()))
                .take(3)
                .map((apt) => _buildAppointmentCard(apt, isUpcoming: false))
                .toList(),
          ],
        ],
      ],
    );
  }

  Widget _buildAppointmentCard(Appointment appointment,
      {required bool isUpcoming}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isUpcoming ? Colors.green.shade50 : Colors.grey.shade50,
      child: ListTile(
        leading: Icon(
          Icons.calendar_today,
          color: isUpcoming ? Colors.green : Colors.grey,
        ),
        title: Text(appointment.notes ?? 'موعد'),
        subtitle: Text(
          DateFormat('yyyy/MM/dd HH:mm').format(appointment.dateTime),
          style: TextStyle(
            color: isUpcoming ? Colors.green.shade700 : Colors.grey.shade600,
          ),
        ),
        trailing: Text(
          isUpcoming ? 'قادم' : 'سابق',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isUpcoming ? Colors.green : Colors.grey,
          ),
        ),
      ),
    );
  }

  // قسم المدفوعات
  Widget _buildPaymentsSection() {
    double totalCost = _treatments.isNotEmpty
        ? _treatments.fold(0.0, (sum, t) => sum + t.cost)
        : 0.0;
    double totalPaid = _payments.isNotEmpty
        ? _payments.fold(0.0, (sum, p) => sum + p.amount)
        : 0.0;
    double remaining = totalCost - totalPaid;

    return _buildSection(
      'المدفوعات (${_payments.length})',
      [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _showAddPaymentDialog,
            icon: const Icon(Icons.add),
            label: const Text('إضافة دفعة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            border: Border.all(color: Colors.orange.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'إجمالي التكلفة',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  Text(
                    '${totalCost.toStringAsFixed(2)} ج.م',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'المبلغ المدفوع',
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                  Text(
                    '${totalPaid.toStringAsFixed(2)} ج.م',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'المبلغ المتبقي',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  Text(
                    '${remaining.toStringAsFixed(2)} ج.م',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_payments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'لا توجد مدفوعات مسجلة',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        else
          ..._payments.take(5).map((payment) {
            return _buildPaymentCard(payment);
          }).toList(),
      ],
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    Color methodColor = _getPaymentMethodColor(payment.paymentMethod);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: methodColor.withOpacity(0.2),
          child: Icon(
            _getPaymentMethodIcon(payment.paymentMethod),
            color: methodColor,
          ),
        ),
        title: Text(
          payment.paymentMethod,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          DateFormat('yyyy/MM/dd').format(payment.date),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${payment.amount.toStringAsFixed(2)} ج.م',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                payment.paymentStatus,
                style: const TextStyle(fontSize: 10, color: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // قسم الملاحظات
  Widget _buildNotesSection() {
    return _buildSection(
      'الملاحظات',
      [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _patient.notes!,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
          ),
        ),
      ],
    );
  }

  // دالة بناء القسم العام
  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  // دالة بناء صف التفاصيل
  Widget _buildDetailRow(
    String label,
    String value, {
    bool isWarning = false,
    bool isHighlight = false,
  }) {
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
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: (isWarning || isHighlight)
                  ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                  : null,
              decoration: (isWarning || isHighlight)
                  ? BoxDecoration(
                      color: isWarning
                          ? Colors.red.shade50
                          : Colors.orange.shade50,
                      border: Border.all(
                        color: isWarning
                            ? Colors.red.shade300
                            : Colors.orange.shade300,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    )
                  : null,
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: (isWarning || isHighlight)
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isWarning
                      ? Colors.red.shade700
                      : isHighlight
                          ? Colors.orange.shade700
                          : Colors.black,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // دالة بناء صف المعلومات
  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, [
    Color? color,
  ]) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: color ?? Colors.blue),
        title: Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // دوال مساعدة للألوان والأيقونات
  Color _getStatusColor(String status) {
    switch (status) {
      case 'مكتمل':
        return Colors.green;
      case 'جاري':
        return Colors.blue;
      case 'معلق':
        return Colors.orange;
      case 'فشل':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentMethodColor(String method) {
    switch (method) {
      case 'نقدي':
        return Colors.green;
      case 'بطاقة ائتمان':
        return Colors.blue;
      case 'تحويل بنكي':
        return Colors.purple;
      case 'شيك':
        return Colors.amber;
      default:
        return Colors.orange;
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'نقدي':
        return Icons.monetization_on;
      case 'بطاقة ائتمان':
        return Icons.credit_card;
      case 'تحويل بنكي':
        return Icons.account_balance;
      case 'شيك':
        return Icons.receipt;
      default:
        return Icons.payment;
    }
  }

  // حوار إضافة علاج
  void _showAddTreatmentDialog() {
    final treatmentTypeController = TextEditingController();
    final costController = TextEditingController();
    final toothPositionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة علاج'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: treatmentTypeController,
                decoration: const InputDecoration(
                  labelText: 'نوع العلاج',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'التكلفة',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: toothPositionController,
                decoration: const InputDecoration(
                  labelText: 'موقع السن (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (treatmentTypeController.text.isNotEmpty &&
                  costController.text.isNotEmpty) {
                final treatment = Treatment(
                  id: const Uuid().v4(),
                  patientId: _patient.id,
                  treatmentType: treatmentTypeController.text,
                  cost: double.parse(costController.text),
                  date: DateTime.now(),
                  toothPosition: toothPositionController.text.isEmpty
                      ? ''
                      : toothPositionController.text,
                  toothNumber: toothPositionController.text.isEmpty
                      ? ''
                      : toothPositionController.text,
                  description: treatmentTypeController.text,
                  paidAmount: 0.0,
                  status: 'جاري',
                  createdAt: DateTime.now(),
                );
                await DatabaseHelper.instance.insertTreatment(treatment);
                Navigator.pop(context);
                _loadPatientData();
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  // حوار إضافة موعد
  void _showAddAppointmentDialog() {
    DateTime selectedDateTime = DateTime.now();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('إضافة موعد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('التاريخ والوقت'),
                  subtitle: Text(
                    DateFormat('yyyy/MM/dd HH:mm').format(selectedDateTime),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDateTime,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                      );
                      if (time != null) {
                        setState(() {
                          selectedDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final appointment = Appointment(
                  id: const Uuid().v4(),
                  patientId: _patient.id,
                  dateTime: selectedDateTime,
                  type: 'متابعة',
                  notes: notesController.text.isEmpty
                      ? null
                      : notesController.text,
                  createdAt: DateTime.now(),
                );
                await DatabaseHelper.instance.insertAppointment(appointment);
                Navigator.pop(context);
                _loadPatientData();
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  // حوار إضافة دفعة
  void _showAddPaymentDialog() {
    final amountController = TextEditingController();
    String selectedMethod = 'نقدي';
    final paymentMethods = ['نقدي', 'بطاقة ائتمان', 'تحويل بنكي', 'شيك'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('إضافة دفعة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'المبلغ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  isExpanded: true,
                  value: selectedMethod,
                  items: paymentMethods
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedMethod = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (amountController.text.isNotEmpty) {
                  final payment = Payment(
                    id: const Uuid().v4(),
                    patientId: _patient.id,
                    amount: double.parse(amountController.text),
                    paymentMethod: selectedMethod,
                    date: DateTime.now(),
                    paymentStatus: 'مكتمل',
                    createdAt: DateTime.now(),
                  );
                  await DatabaseHelper.instance.insertPayment(payment);
                  Navigator.pop(context);
                  _loadPatientData();
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }
}
