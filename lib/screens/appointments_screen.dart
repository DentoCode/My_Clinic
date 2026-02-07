import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/appointment.dart';
import '../models/patient.dart';
import 'settings_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<Appointment> _appointments = [];
  List<Appointment> _selectedDayAppointments = [];
  Map<String, Patient> _patientsMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final appointments = await DatabaseHelper.instance.getAllAppointments();
    final patients = await DatabaseHelper.instance.getAllPatients();

    setState(() {
      _appointments = appointments;
      _patientsMap = {for (var p in patients) p.id: p};
      _filterAppointments();
      _isLoading = false;
    });
  }

  void _filterAppointments() {
    setState(() {
      _selectedDayAppointments = _appointments.where((apt) {
        return isSameDay(apt.dateTime, _selectedDay);
      }).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المواعيد'),
        backgroundColor: Colors.green.shade700,
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
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    _filterAppointments();
                  },
                  calendarFormat: CalendarFormat.month,
                  locale: 'ar',
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextFormatter: (date, locale) =>
                        DateFormat.yMMMM('ar').format(date),
                  ),
                  eventLoader: (day) {
                    return _appointments
                        .where((apt) => isSameDay(apt.dateTime, day))
                        .toList();
                  },
                ),
                const Divider(height: 1),
                Expanded(
                  child: _selectedDayAppointments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy,
                                  size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                'لا توجد مواعيد في هذا اليوم',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _selectedDayAppointments.length,
                          itemBuilder: (context, index) {
                            final appointment = _selectedDayAppointments[index];
                            final patient = _patientsMap[appointment.patientId];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      _getStatusColor(appointment.status),
                                  child: Icon(
                                    _getStatusIcon(appointment.status),
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  patient?.name ?? 'غير معروف',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('hh:mm a', 'ar')
                                          .format(appointment.dateTime),
                                    ),
                                    Text(appointment.type),
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            _getStatusColor(appointment.status)
                                                .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        appointment.status,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _getStatusColor(
                                              appointment.status),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'complete',
                                      child: Text('تم'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'cancel',
                                      child: Text('إلغاء'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('حذف',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                  onSelected: (value) =>
                                      _handleMenuAction(value, appointment),
                                ),
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
            MaterialPageRoute(
              builder: (_) => AddAppointmentScreen(selectedDate: _selectedDay),
            ),
          );
          _loadData();
        },
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('حجز موعد'),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'محجوز':
        return Colors.blue;
      case 'مكتمل':
        return Colors.green;
      case 'ملغي':
        return Colors.red;
      case 'لم يحضر':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'محجوز':
        return Icons.event;
      case 'مكتمل':
        return Icons.check_circle;
      case 'ملغي':
        return Icons.cancel;
      case 'لم يحضر':
        return Icons.event_busy;
      default:
        return Icons.help;
    }
  }

  Future<void> _handleMenuAction(dynamic value, Appointment appointment) async {
    switch (value) {
      case 'complete':
        await DatabaseHelper.instance.updateAppointment(
          appointment.copyWith(status: 'مكتمل', updatedAt: DateTime.now()),
        );
        _loadData();
        break;
      case 'cancel':
        await DatabaseHelper.instance.updateAppointment(
          appointment.copyWith(status: 'ملغي', updatedAt: DateTime.now()),
        );
        _loadData();
        break;
      case 'delete':
        await DatabaseHelper.instance.deleteAppointment(appointment.id);
        _loadData();
        break;
    }
  }
}

class AddAppointmentScreen extends StatefulWidget {
  final DateTime selectedDate;

  const AddAppointmentScreen({Key? key, required this.selectedDate})
      : super(key: key);

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Patient> _patients = [];
  Patient? _selectedPatient;
  DateTime? _selectedDateTime;
  String _type = 'كشف';
  int _duration = 30;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _selectedDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      9,
      0,
    );
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

    final appointment = Appointment(
      id: const Uuid().v4(),
      patientId: _selectedPatient!.id,
      dateTime: _selectedDateTime!,
      duration: _duration,
      type: _type,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    await DatabaseHelper.instance.insertAppointment(appointment);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حجز موعد'),
        backgroundColor: Colors.green.shade700,
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
                labelText: 'اختر المريض',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items: _patients.map((patient) {
                return DropdownMenuItem(
                  value: patient,
                  child: Text(patient.name),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedPatient = value),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('التاريخ والوقت'),
              subtitle: Text(
                DateFormat('yyyy/MM/dd - hh:mm a', 'ar')
                    .format(_selectedDateTime!),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDateTime!,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  locale: const Locale('ar'),
                );

                if (date != null && mounted) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_selectedDateTime!),
                  );

                  if (time != null) {
                    setState(() {
                      _selectedDateTime = DateTime(
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'نوع الموعد',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_services),
              ),
              items: const [
                DropdownMenuItem(value: 'كشف', child: Text('كشف')),
                DropdownMenuItem(value: 'متابعة', child: Text('متابعة')),
                DropdownMenuItem(value: 'علاج', child: Text('علاج')),
                DropdownMenuItem(value: 'جراحة', child: Text('جراحة')),
                DropdownMenuItem(value: 'تنظيف', child: Text('تنظيف')),
                DropdownMenuItem(value: 'أشعة', child: Text('أشعة')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _duration,
              decoration: const InputDecoration(
                labelText: 'المدة (دقيقة)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer),
              ),
              items: const [
                DropdownMenuItem(value: 15, child: Text('15 دقيقة')),
                DropdownMenuItem(value: 30, child: Text('30 دقيقة')),
                DropdownMenuItem(value: 45, child: Text('45 دقيقة')),
                DropdownMenuItem(value: 60, child: Text('60 دقيقة')),
                DropdownMenuItem(value: 90, child: Text('90 دقيقة')),
                DropdownMenuItem(value: 120, child: Text('120 دقيقة')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _duration = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('حجز الموعد', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
