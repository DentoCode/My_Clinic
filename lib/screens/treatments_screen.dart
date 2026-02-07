import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import '../database/database_helper.dart';
import '../models/treatment.dart';
import '../models/payment.dart';
import '../models/patient.dart';
import '../models/procedure.dart';
import 'settings_screen.dart';

class TreatmentsScreen extends StatefulWidget {
  const TreatmentsScreen({Key? key}) : super(key: key);

  @override
  State<TreatmentsScreen> createState() => _TreatmentsScreenState();
}

class _TreatmentsScreenState extends State<TreatmentsScreen> {
  List<Treatment> _treatments = [];
  List<Treatment> _filteredTreatments = [];
  Map<String, Patient> _patientsMap = {};
  Map<String, List<Procedure>> _proceduresMap = {};
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // شريط التقدم والإجراءات
  Widget _buildProgressSection(Treatment treatment) {
    final procedures = _proceduresMap[treatment.id] ?? [];

    if (procedures.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'لا توجد إجراءات',
            style: TextStyle(color: Colors.grey.shade600),
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
        // عنوان الإجراءات
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الإجراءات ($completedCount/${procedures.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: progress == 1.0 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // شريط التقدم
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation(
              progress == 1.0 ? Colors.green : Colors.orange,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // قائمة الإجراءات
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
                    _loadData();
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proc.name,
                        style: TextStyle(
                          decoration: proc.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (proc.description.isNotEmpty)
                        Text(
                          proc.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () async {
                    await DatabaseHelper.instance.deleteProcedure(proc.id);
                    _loadData();
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final treatments = await DatabaseHelper.instance
          .getAllTreatments()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('تأخر تحميل البيانات');
      });
      final patients = await DatabaseHelper.instance.getAllPatients();

      final proceduresMap = <String, List<Procedure>>{};
      for (final treatment in treatments) {
        try {
          final procs = await DatabaseHelper.instance
              .getTreatmentProcedures(treatment.id)
              .timeout(const Duration(seconds: 5));
          proceduresMap[treatment.id] = procs;
        } catch (e) {
          print('Error loading procedures for ${treatment.id}: $e');
          proceduresMap[treatment.id] = [];
        }
      }

      setState(() {
        _treatments = treatments;
        _filteredTreatments = treatments;
        _patientsMap = {for (var p in patients) p.id: p};
        _proceduresMap = proceduresMap;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
        _treatments = [];
        _filteredTreatments = [];
      });
    }
  }

  void _filterTreatments(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTreatments = _treatments;
      } else {
        _filteredTreatments = _treatments.where((treatment) {
          final patient = _patientsMap[treatment.patientId];
          final patientName = patient?.name.toLowerCase() ?? '';
          final treatmentType = treatment.treatmentType.toLowerCase();
          final toothNumber = treatment.toothNumber.toLowerCase();
          final description = treatment.description.toLowerCase();
          final queryLower = query.toLowerCase();

          return patientName.contains(queryLower) ||
              treatmentType.contains(queryLower) ||
              toothNumber.contains(queryLower) ||
              description.contains(queryLower);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('العلاجات'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _treatments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medical_services_outlined,
                          size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد علاجات مسجلة',
                        style: TextStyle(
                            fontSize: 18, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // حقل البحث
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterTreatments,
                        decoration: InputDecoration(
                          hintText: 'ابحث عن علاج أو مريض...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterTreatments('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                        ),
                      ),
                    ),
                    // قائمة العلاجات
                    Expanded(
                      child: _filteredTreatments.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off,
                                      size: 80, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchController.text.isNotEmpty
                                        ? 'لم يتم العثور على نتائج'
                                        : 'لا توجد علاجات مسجلة',
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredTreatments.length,
                              itemBuilder: (context, index) {
                                final treatment = _filteredTreatments[index];
                                final patient =
                                    _patientsMap[treatment.patientId];

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ExpansionTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.purple.shade100,
                                      child: Icon(Icons.medical_services,
                                          color: Colors.purple.shade700),
                                    ),
                                    title: Text(
                                      patient?.name ?? 'غير معروف',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(treatment.treatmentType),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildInfoRow(
                                                'التاريخ',
                                                DateFormat('yyyy/MM/dd')
                                                    .format(treatment.date)),
                                            _buildInfoRow(
                                                'السن', treatment.toothNumber),
                                            _buildInfoRow('موضع السن',
                                                treatment.toothPosition),
                                            _buildInfoRow(
                                                'الوصف', treatment.description),
                                            if (treatment.materials != null)
                                              _buildInfoRow('المواد المستخدمة',
                                                  treatment.materials!),
                                            if (treatment.treatmentSteps !=
                                                null)
                                              _buildInfoRow('خطوات العلاج',
                                                  treatment.treatmentSteps!),
                                            _buildInfoRow(
                                                'الحالة', treatment.status),
                                            if (treatment.complications != null)
                                              _buildInfoRow('المضاعفات',
                                                  treatment.complications!,
                                                  isWarning: true),
                                            if (treatment.followUpDate != null)
                                              _buildInfoRow(
                                                  'تاريخ المتابعة',
                                                  DateFormat('yyyy/MM/dd')
                                                      .format(treatment
                                                          .followUpDate!)),
                                            _buildInfoRow('التكلفة',
                                                '${treatment.cost.toStringAsFixed(2)} ج.م'),
                                            _buildInfoRow('المدفوع',
                                                '${treatment.paidAmount.toStringAsFixed(2)} ج.م'),
                                            _buildInfoRow('المتبقي',
                                                '${treatment.remainingAmount.toStringAsFixed(2)} ج.م'),
                                            if (treatment.notes != null)
                                              _buildInfoRow('ملاحظات عامة',
                                                  treatment.notes!),
                                            const SizedBox(height: 16),
                                            // شريط التقدم والإجراءات
                                            _buildProgressSection(treatment),
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                TextButton.icon(
                                                  onPressed: () =>
                                                      _showProcedureDialog(
                                                          treatment),
                                                  icon: const Icon(
                                                      Icons.checklist),
                                                  label:
                                                      const Text('إضافة إجراء'),
                                                ),
                                                if (!treatment.isFullyPaid)
                                                  TextButton.icon(
                                                    onPressed: () =>
                                                        _addPayment(treatment),
                                                    icon: const Icon(
                                                        Icons.payment),
                                                    label: const Text(
                                                        'إضافة دفعة'),
                                                  ),
                                                TextButton.icon(
                                                  onPressed: () =>
                                                      _deleteTreatment(
                                                          treatment),
                                                  icon: const Icon(Icons.delete,
                                                      color: Colors.red),
                                                  label: const Text('حذف',
                                                      style: TextStyle(
                                                          color: Colors.red)),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTreatmentScreen()),
          );
          _loadData();
        },
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('إضافة علاج'),
      ),
    );
  }

  // حوار إضافة إجراء
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
                    await _loadData();
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

  Widget _buildInfoRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Container(
              padding: isWarning
                  ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                  : null,
              decoration: isWarning
                  ? BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.shade300),
                    )
                  : null,
              child: Text(
                value,
                style: TextStyle(
                  color: isWarning ? Colors.red.shade800 : Colors.black,
                  fontWeight: isWarning ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addPayment(Treatment treatment) async {
    final amountController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة دفعة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'المبلغ المتبقي: ${treatment.remainingAmount.toStringAsFixed(2)} ج.م'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ المدفوع',
                border: OutlineInputBorder(),
                suffixText: 'ج.م',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0) {
                // تحديث المبلغ المدفوع في العلاج
                final updatedTreatment = treatment.copyWith(
                  paidAmount: treatment.paidAmount + amount,
                  updatedAt: DateTime.now(),
                );
                await DatabaseHelper.instance.updateTreatment(updatedTreatment);

                // إضافة الدفعة في جدول المدفوعات
                final payment = Payment(
                  id: const Uuid().v4(),
                  patientId: treatment.patientId,
                  treatmentId: treatment.id,
                  amount: amount,
                  paymentMethod: 'نقدي', // الطريقة الافتراضية من العلاجات
                  date: DateTime.now(),
                  paymentStatus: 'مكتمل',
                  createdAt: DateTime.now(),
                );
                await DatabaseHelper.instance.insertPayment(payment);

                Navigator.pop(context);
                _loadData();
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTreatment(Treatment treatment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف علاج'),
        content: const Text('هل أنت متأكد من حذف هذا العلاج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteTreatment(treatment.id);
      _loadData();
    }
  }
}

class AddTreatmentScreen extends StatefulWidget {
  const AddTreatmentScreen({Key? key}) : super(key: key);

  @override
  State<AddTreatmentScreen> createState() => _AddTreatmentScreenState();
}

class _AddTreatmentScreenState extends State<AddTreatmentScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Patient> _patients = [];
  Patient? _selectedPatient;
  DateTime _date = DateTime.now();
  DateTime? _followUpDate;
  String _treatmentType = 'حشو';
  String _toothPosition = 'أمامي';
  String _status = 'جاري';
  final _toothNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _materialsController = TextEditingController();
  final _treatmentStepsController = TextEditingController();
  final _costController = TextEditingController();
  final _paidController = TextEditingController(text: '0');
  final _complicationsController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    final patients = await DatabaseHelper.instance.getAllPatients();
    setState(() => _patients = patients);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار مريض')),
      );
      return;
    }

    final treatment = Treatment(
      id: const Uuid().v4(),
      patientId: _selectedPatient!.id,
      date: _date,
      treatmentType: _treatmentType,
      toothNumber: _toothNumberController.text.trim(),
      toothPosition: _toothPosition,
      description: _descriptionController.text.trim(),
      materials: _materialsController.text.trim().isEmpty
          ? null
          : _materialsController.text.trim(),
      treatmentSteps: _treatmentStepsController.text.trim().isEmpty
          ? null
          : _treatmentStepsController.text.trim(),
      cost: double.parse(_costController.text),
      paidAmount: double.parse(_paidController.text),
      status: _status,
      complications: _complicationsController.text.trim().isEmpty
          ? null
          : _complicationsController.text.trim(),
      followUpDate: _followUpDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    await DatabaseHelper.instance.insertTreatment(treatment);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة علاج'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<Patient>(
              value: _selectedPatient,
              decoration: const InputDecoration(
                labelText: 'المريض',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items: _patients.map((patient) {
                return DropdownMenuItem(
                    value: patient, child: Text(patient.name));
              }).toList(),
              onChanged: (value) => setState(() => _selectedPatient = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _treatmentType,
              decoration: const InputDecoration(
                labelText: 'نوع العلاج',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_services),
              ),
              items: const [
                DropdownMenuItem(value: 'حشو', child: Text('حشو')),
                DropdownMenuItem(value: 'خلع', child: Text('خلع')),
                DropdownMenuItem(value: 'علاج عصب', child: Text('علاج عصب')),
                DropdownMenuItem(value: 'تنظيف', child: Text('تنظيف')),
                DropdownMenuItem(value: 'تبييض', child: Text('تبييض')),
                DropdownMenuItem(value: 'تقويم', child: Text('تقويم')),
                DropdownMenuItem(value: 'تركيبات', child: Text('تركيبات')),
                DropdownMenuItem(value: 'جراحة', child: Text('جراحة')),
                DropdownMenuItem(value: 'أخرى', child: Text('أخرى')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _treatmentType = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _toothNumberController,
              decoration: const InputDecoration(
                labelText: 'رقم السن (11-48)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'الرجاء إدخال رقم السن';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _toothPosition,
              decoration: const InputDecoration(
                labelText: 'موضع السن',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              items: const [
                DropdownMenuItem(value: 'أمامي', child: Text('أمامي')),
                DropdownMenuItem(value: 'خلفي', child: Text('خلفي')),
                DropdownMenuItem(value: 'ضرس حكمة', child: Text('ضرس حكمة')),
                DropdownMenuItem(value: 'ضرس', child: Text('ضرس')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _toothPosition = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'الوصف',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'الرجاء إدخال الوصف';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _materialsController,
              decoration: const InputDecoration(
                labelText: 'المواد المستخدمة',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory),
                hintText: 'مثل: ملغم، راتنج، سيراميك، إلخ',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _treatmentStepsController,
              decoration: const InputDecoration(
                labelText: 'خطوات العلاج',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timeline),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'حالة العلاج',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info),
              ),
              items: const [
                DropdownMenuItem(value: 'جاري', child: Text('جاري')),
                DropdownMenuItem(value: 'مكتمل', child: Text('مكتمل')),
                DropdownMenuItem(value: 'معلق', child: Text('معلق')),
                DropdownMenuItem(value: 'فشل', child: Text('فشل')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _status = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _complicationsController,
              decoration: const InputDecoration(
                labelText: 'المضاعفات (إن وجدت)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.warning),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('تاريخ المتابعة'),
              subtitle: Text(
                _followUpDate == null
                    ? 'لم يتم تحديد'
                    : DateFormat('yyyy-MM-dd').format(_followUpDate!),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _followUpDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _followUpDate = picked);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _costController,
              decoration: const InputDecoration(
                labelText: 'التكلفة',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                suffixText: 'ج.م',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'الرجاء إدخال التكلفة';
                }
                if (double.tryParse(value) == null) {
                  return 'الرجاء إدخال رقم صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _paidController,
              decoration: const InputDecoration(
                labelText: 'المبلغ المدفوع',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment),
                suffixText: 'ج.م',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'الرجاء إدخال المبلغ المدفوع';
                }
                if (double.tryParse(value) == null) {
                  return 'الرجاء إدخال رقم صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات عامة',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('حفظ العلاج', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  // (تم نقل شريط التقدم والإجراءات إلى _TreatmentsScreenState)
}
