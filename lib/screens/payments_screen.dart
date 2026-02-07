import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/payment.dart';
import '../models/patient.dart';
import '../models/treatment.dart';
import 'settings_screen.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<Payment> _payments = [];
  Map<String, Patient> _patientsMap = {};
  Map<String, Treatment> _treatmentsMap = {};
  bool _isLoading = true;
  String _filterStatus = 'الكل';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final payments = await DatabaseHelper.instance.getAllPayments();
    final patients = await DatabaseHelper.instance.getAllPatients();
    final treatments = await DatabaseHelper.instance.getAllTreatments();

    setState(() {
      _payments = payments;
      _patientsMap = {for (var p in patients) p.id: p};
      _treatmentsMap = {for (var t in treatments) t.id: t};
      _isLoading = false;
    });
  }

  List<Payment> get _filteredPayments {
    var filtered = _payments;

    // فلتر الحالة
    if (_filterStatus != 'الكل') {
      filtered =
          filtered.where((p) => p.paymentStatus == _filterStatus).toList();
    }

    // فلتر التاريخ
    if (_startDate != null) {
      filtered = filtered
          .where((p) =>
              p.date.isAfter(_startDate!) || p.date.isSameDay(_startDate!))
          .toList();
    }
    if (_endDate != null) {
      filtered = filtered
          .where((p) =>
              p.date.isBefore(_endDate!.add(const Duration(days: 1))) ||
              p.date.isSameDay(_endDate!))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المدفوعات'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showAddPaymentDialog(),
            icon: const Icon(Icons.add),
            tooltip: 'إضافة دفعة جديدة',
          ),
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
          : Column(
              children: [
                // إحصائيات المدفوعات
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade700, Colors.orange.shade500],
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'إجمالي المدفوعات',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${NumberFormat('#,###.00').format(_filteredPayments.fold(0.0, (sum, p) => sum + p.amount))} ج.م',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'عدد المدفوعات',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_filteredPayments.length}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // فلتر الحالة
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatusChip('الكل', _payments.length),
                        _buildStatusChip(
                            'مكتمل',
                            _payments
                                .where((p) => p.paymentStatus == 'مكتمل')
                                .length),
                        _buildStatusChip(
                            'معلق',
                            _payments
                                .where((p) => p.paymentStatus == 'معلق')
                                .length),
                        _buildStatusChip(
                            'ملغى',
                            _payments
                                .where((p) => p.paymentStatus == 'ملغى')
                                .length),
                      ],
                    ),
                  ),
                ),
                // فلتر التاريخ
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() => _startDate = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 18, color: Colors.orange.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _startDate == null
                                        ? 'من التاريخ'
                                        : DateFormat('yyyy/MM/dd')
                                            .format(_startDate!),
                                    style: TextStyle(
                                      color: _startDate == null
                                          ? Colors.grey.shade600
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() => _endDate = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 18, color: Colors.orange.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _endDate == null
                                        ? 'إلى التاريخ'
                                        : DateFormat('yyyy/MM/dd')
                                            .format(_endDate!),
                                    style: TextStyle(
                                      color: _endDate == null
                                          ? Colors.grey.shade600
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_startDate != null || _endDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _startDate = null;
                              _endDate = null;
                            });
                          },
                          color: Colors.red,
                        ),
                    ],
                  ),
                ),
                // قائمة المدفوعات
                Expanded(
                  child: _filteredPayments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payment_outlined,
                                  size: 80, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                'لا توجد مدفوعات مسجلة',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredPayments.length,
                          itemBuilder: (context, index) {
                            final payment = _filteredPayments[index];
                            final patient = _patientsMap[payment.patientId];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getPaymentMethodColor(
                                      payment.paymentMethod),
                                  child: Icon(
                                      _getPaymentMethodIcon(
                                          payment.paymentMethod),
                                      color: Colors.white),
                                ),
                                title: Text(
                                  patient?.name ?? 'غير معروف',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(payment.paymentMethod),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${payment.amount.toStringAsFixed(2)} ج.م',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                    _buildStatusBadge(payment.paymentStatus),
                                  ],
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildDetailRow(
                                            'التاريخ',
                                            DateFormat('yyyy/MM/dd HH:mm')
                                                .format(payment.date)),
                                        _buildDetailRow('طريقة الدفع',
                                            payment.paymentMethod),
                                        if (payment.cardType != null)
                                          _buildDetailRow(
                                              'نوع البطاقة', payment.cardType!),
                                        if (payment.checkNumber != null)
                                          _buildDetailRow('رقم الشيك',
                                              payment.checkNumber!),
                                        if (payment.transferReference != null)
                                          _buildDetailRow('مرجع التحويل',
                                              payment.transferReference!),
                                        if (payment.receiptNumber != null)
                                          _buildDetailRow('رقم الإيصال',
                                              payment.receiptNumber!),
                                        _buildDetailRow(
                                            'الحالة', payment.paymentStatus),
                                        _buildDetailRow('المبلغ',
                                            '${payment.amount.toStringAsFixed(2)} ج.م',
                                            isHighlight: true),
                                        if (payment.notes != null)
                                          _buildDetailRow(
                                              'ملاحظات', payment.notes!),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              onPressed: () =>
                                                  _editPayment(payment),
                                              icon: const Icon(Icons.edit),
                                              label: const Text('تعديل'),
                                            ),
                                            const SizedBox(width: 8),
                                            TextButton.icon(
                                              onPressed: () =>
                                                  _deletePayment(payment),
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              label: const Text('حذف'),
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
    );
  }

  Widget _buildStatusChip(String label, int count) {
    bool isSelected = _filterStatus == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filterStatus = label);
        },
        selectedColor: Colors.orange.shade700,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'مكتمل':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'معلق':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'ملغى':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(statusIcon, size: 16, color: statusColor),
        const SizedBox(width: 4),
        Text(
          status,
          style: TextStyle(
            fontSize: 12,
            color: statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
              padding: isHighlight
                  ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                  : null,
              decoration: isHighlight
                  ? BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border.all(color: Colors.orange.shade300),
                      borderRadius: BorderRadius.circular(4),
                    )
                  : null,
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                  color: isHighlight ? Colors.orange.shade700 : Colors.black,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

  void _showAddPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddPaymentDialog(
        patients: _patientsMap.values.toList(),
        treatments: _treatmentsMap.values.toList(),
        onSave: (payment) {
          Navigator.pop(context);
          _savePayment(payment);
        },
      ),
    );
  }

  void _editPayment(Payment payment) {
    showDialog(
      context: context,
      builder: (context) => _AddPaymentDialog(
        patients: _patientsMap.values.toList(),
        treatments: _treatmentsMap.values.toList(),
        payment: payment,
        onSave: (updatedPayment) {
          Navigator.pop(context);
          _savePayment(updatedPayment);
        },
      ),
    );
  }

  Future<void> _savePayment(Payment payment) async {
    if (payment.id.isEmpty) {
      payment = payment.copyWith(id: const Uuid().v4());
      await DatabaseHelper.instance.insertPayment(payment);
    } else {
      await DatabaseHelper.instance.updatePayment(payment);
    }
    _loadData();
  }

  Future<void> _deletePayment(Payment payment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الدفعة'),
        content: const Text('هل أنت متأكد من حذف هذه الدفعة؟'),
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
      await DatabaseHelper.instance.deletePayment(payment.id);
      _loadData();
    }
  }
}

class _AddPaymentDialog extends StatefulWidget {
  final List<Patient> patients;
  final List<Treatment> treatments;
  final Payment? payment;
  final Function(Payment) onSave;

  const _AddPaymentDialog({
    required this.patients,
    required this.treatments,
    this.payment,
    required this.onSave,
  });

  @override
  State<_AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<_AddPaymentDialog> {
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late TextEditingController _receiptNumberController;
  late TextEditingController _cardTypeController;
  late TextEditingController _checkNumberController;
  late TextEditingController _transferReferenceController;

  String? _selectedPatientId;
  String _paymentMethod = 'نقدي';
  String _paymentStatus = 'مكتمل';
  DateTime _selectedDate = DateTime.now();

  final List<String> _paymentMethods = [
    'نقدي',
    'بطاقة ائتمان',
    'تحويل بنكي',
    'شيك'
  ];
  final List<String> _paymentStatuses = ['مكتمل', 'معلق', 'ملغى'];
  final List<String> _cardTypes = ['Visa', 'MasterCard', 'Amex', 'Others'];

  @override
  void initState() {
    super.initState();
    final payment = widget.payment;
    _amountController =
        TextEditingController(text: payment?.amount.toString() ?? '');
    _notesController = TextEditingController(text: payment?.notes ?? '');
    _receiptNumberController =
        TextEditingController(text: payment?.receiptNumber ?? '');
    _cardTypeController = TextEditingController(text: payment?.cardType ?? '');
    _checkNumberController =
        TextEditingController(text: payment?.checkNumber ?? '');
    _transferReferenceController =
        TextEditingController(text: payment?.transferReference ?? '');

    _selectedPatientId = payment?.patientId;
    _paymentMethod = payment?.paymentMethod ?? 'نقدي';
    _paymentStatus = payment?.paymentStatus ?? 'مكتمل';
    _selectedDate = payment?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _receiptNumberController.dispose();
    _cardTypeController.dispose();
    _checkNumberController.dispose();
    _transferReferenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.payment == null ? 'إضافة دفعة جديدة' : 'تعديل الدفعة'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // اختيار المريض
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedPatientId,
              hint: const Text('اختر المريض'),
              items: widget.patients
                  .map(
                      (p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedPatientId = value),
            ),
            const SizedBox(height: 12),
            // المبلغ
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            // طريقة الدفع
            DropdownButton<String>(
              isExpanded: true,
              value: _paymentMethod,
              items: _paymentMethods
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _paymentMethod = value ?? 'نقدي'),
            ),
            const SizedBox(height: 12),
            // الحقول المشروطة
            if (_paymentMethod == 'بطاقة ائتمان') ...[
              DropdownButton<String>(
                isExpanded: true,
                value: _cardTypeController.text.isEmpty
                    ? null
                    : _cardTypeController.text,
                hint: const Text('نوع البطاقة'),
                items: _cardTypes
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _cardTypeController.text = value ?? ''),
              ),
              const SizedBox(height: 12),
            ],
            if (_paymentMethod == 'شيك') ...[
              TextField(
                controller: _checkNumberController,
                decoration: const InputDecoration(
                  labelText: 'رقم الشيك',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_paymentMethod == 'تحويل بنكي') ...[
              TextField(
                controller: _transferReferenceController,
                decoration: const InputDecoration(
                  labelText: 'مرجع التحويل',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // رقم الإيصال
            TextField(
              controller: _receiptNumberController,
              decoration: const InputDecoration(
                labelText: 'رقم الإيصال (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            // حالة الدفع
            DropdownButton<String>(
              isExpanded: true,
              value: _paymentStatus,
              items: _paymentStatuses
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _paymentStatus = value ?? 'مكتمل'),
            ),
            const SizedBox(height: 12),
            // التاريخ
            Row(
              children: [
                Expanded(
                  child: Text(
                      DateFormat('yyyy/MM/dd HH:mm').format(_selectedDate)),
                ),
                IconButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ملاحظات
            TextField(
              controller: _notesController,
              maxLines: 3,
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
          onPressed: _savePayment,
          child: const Text('حفظ'),
        ),
      ],
    );
  }

  void _savePayment() {
    if (_selectedPatientId == null || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء ملء جميع الحقول المطلوبة')),
      );
      return;
    }

    final payment = Payment(
      id: widget.payment?.id ?? '',
      patientId: _selectedPatientId!,
      amount: double.parse(_amountController.text),
      paymentMethod: _paymentMethod,
      date: _selectedDate,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      cardType:
          _cardTypeController.text.isEmpty ? null : _cardTypeController.text,
      checkNumber: _checkNumberController.text.isEmpty
          ? null
          : _checkNumberController.text,
      transferReference: _transferReferenceController.text.isEmpty
          ? null
          : _transferReferenceController.text,
      paymentStatus: _paymentStatus,
      receiptNumber: _receiptNumberController.text.isEmpty
          ? null
          : _receiptNumberController.text,
      updatedAt: DateTime.now(),
      createdAt: widget.payment?.createdAt ?? DateTime.now(),
    );

    widget.onSave(payment);
  }
}

extension DateTimeExtension on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
