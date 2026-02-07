import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../database/database_helper.dart';
import '../models/patient.dart';

class ReportGenerator {
  // تقرير شامل عن مريض واحد
  static Future<void> generatePatientReport(Patient patient) async {
    final treatments =
        await DatabaseHelper.instance.getPatientTreatments(patient.id);
    final payments =
        await DatabaseHelper.instance.getPatientPayments(patient.id);

    double totalCost = treatments.fold(0, (sum, t) => sum + t.cost);
    double totalPaid = payments.fold(0, (sum, p) => sum + p.amount);
    double remaining = totalCost - totalPaid;

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Center(
            child: pw.Text('تقرير مريض',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('معلومات المريض',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                _buildRow('الاسم:', patient.name),
                _buildRow('الهاتف:', patient.phone),
                _buildRow('البريد:', patient.email ?? '-'),
                _buildRow('العنوان:', patient.address ?? '-'),
                _buildRow('تاريخ الميلاد:',
                    DateFormat('yyyy/MM/dd', 'ar').format(patient.birthDate)),
                _buildRow('النوع:', patient.gender == 'male' ? 'ذكر' : 'أنثى'),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('إحصائيات مالية',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                _buildRow(
                    'إجمالي التكاليف:', '${totalCost.toStringAsFixed(2)} ج.م'),
                _buildRow(
                    'المبلغ المدفوع:', '${totalPaid.toStringAsFixed(2)} ج.م'),
                _buildRow(
                    'المبلغ المتبقي:', '${remaining.toStringAsFixed(2)} ج.م'),
                _buildRow('عدد العلاجات:', '${treatments.length}'),
              ],
            ),
          ),
          if (treatments.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text('تفاصيل العلاجات',
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['النوع', 'التاريخ', 'التكلفة', 'المدفوع', 'الحالة'],
              data: treatments
                  .map((t) => [
                        t.treatmentType,
                        DateFormat('yyyy/MM/dd', 'ar').format(t.date),
                        t.cost.toStringAsFixed(2),
                        t.paidAmount.toStringAsFixed(2),
                        t.status,
                      ])
                  .toList(),
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ],
      ),
    );

    await _savePdfFile(pdf, 'تقرير_مريض_${patient.name}');
  }

  // تقرير المدفوعات
  static Future<void> generatePaymentsReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final allPayments = await DatabaseHelper.instance.getAllPayments();
    final filteredPayments = allPayments.where((p) {
      return p.date.isAfter(startDate) &&
          p.date.isBefore(endDate.add(Duration(days: 1)));
    }).toList();

    double totalAmount = filteredPayments.fold(0, (sum, p) => sum + p.amount);

    Map<String, double> paymentMethods = {};
    for (var payment in filteredPayments) {
      paymentMethods[payment.paymentMethod] =
          (paymentMethods[payment.paymentMethod] ?? 0) + payment.amount;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Center(
            child: pw.Text('تقرير المدفوعات',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Center(
            child: pw.Text(
              'من ${DateFormat('yyyy/MM/dd', 'ar').format(startDate)} إلى ${DateFormat('yyyy/MM/dd', 'ar').format(endDate)}',
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('ملخص المدفوعات',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                _buildRow('إجمالي المدفوعات:',
                    '${totalAmount.toStringAsFixed(2)} ج.م'),
                _buildRow('عدد المدفوعات:', '${filteredPayments.length}'),
                _buildRow('متوسط الدفعة:',
                    '${(totalAmount / (filteredPayments.isEmpty ? 1 : filteredPayments.length)).toStringAsFixed(2)} ج.م'),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text('توزيع المدفوعات حسب الطريقة',
              style:
                  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Column(
            children: paymentMethods.entries
                .map((entry) => _buildRow(
                    '${entry.key}:', '${entry.value.toStringAsFixed(2)} ج.م'))
                .toList(),
          ),
          if (filteredPayments.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text('تفاصيل المدفوعات',
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['التاريخ', 'المريض', 'المبلغ', 'الطريقة', 'الحالة'],
              data: filteredPayments
                  .map((p) => [
                        DateFormat('yyyy/MM/dd', 'ar').format(p.date),
                        p.patientId.substring(0, 8),
                        p.amount.toStringAsFixed(2),
                        p.paymentMethod,
                        p.paymentStatus,
                      ])
                  .toList(),
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ],
      ),
    );

    await _savePdfFile(pdf, 'تقرير_المدفوعات');
  }

  // تقرير العلاجات
  static Future<void> generateTreatmentsReport() async {
    final treatments = await DatabaseHelper.instance.getAllTreatments();
    final patients = await DatabaseHelper.instance.getAllPatients();

    double totalCost = treatments.fold(0, (sum, t) => sum + t.cost);
    double totalPaid = treatments.fold(0, (sum, t) => sum + t.paidAmount);
    int completed = treatments.where((t) => t.status == 'مكتمل').length;

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Center(
            child: pw.Text('تقرير العلاجات',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('إحصائيات العلاجات',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                _buildRow('إجمالي عدد العلاجات:', '${treatments.length}'),
                _buildRow('العلاجات المكتملة:', '$completed'),
                _buildRow(
                    'إجمالي التكاليف:', '${totalCost.toStringAsFixed(2)} ج.م'),
                _buildRow(
                    'المبلغ المقبوض:', '${totalPaid.toStringAsFixed(2)} ج.م'),
                _buildRow('المبلغ المتبقي:',
                    '${(totalCost - totalPaid).toStringAsFixed(2)} ج.م'),
              ],
            ),
          ),
          if (treatments.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text('تفاصيل العلاجات',
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: [
                'المريض',
                'النوع',
                'التاريخ',
                'التكلفة',
                'المدفوع',
                'الحالة'
              ],
              data: treatments.take(50).map((t) {
                final patient = patients.firstWhere(
                  (p) => p.id == t.patientId,
                  orElse: () => Patient(
                    id: '',
                    name: 'غير معروف',
                    phone: '',
                    gender: 'male',
                    birthDate: DateTime.now(),
                    createdAt: DateTime.now(),
                  ),
                );
                return [
                  patient.name,
                  t.treatmentType,
                  DateFormat('yyyy/MM/dd', 'ar').format(t.date),
                  t.cost.toStringAsFixed(2),
                  t.paidAmount.toStringAsFixed(2),
                  t.status,
                ];
              }).toList(),
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ],
      ),
    );

    await _savePdfFile(pdf, 'تقرير_العلاجات');
  }

  // دالة مساعدة لحفظ PDF وفتحه
  static Future<void> _savePdfFile(pw.Document pdf, String filename) async {
    try {
      final pdfBytes = await pdf.save();

      // محاولة حفظ الملف
      String filePath;
      try {
        final directory = await getApplicationDocumentsDirectory();
        filePath = '${directory.path}/$filename.pdf';
      } catch (e) {
        // احفظ في المجلد المؤقت إذا فشل path_provider
        final tmp = Directory.systemTemp;
        filePath = '${tmp.path}/$filename.pdf';
        print('Saving to temp directory: $filePath');
      }

      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);
      print('PDF saved to: $filePath');

      // فتح في نافذة الطباعة
      await Printing.layoutPdf(
        name: filename,
        format: PdfPageFormat.a4,
        onLayout: (_) async => pdfBytes,
      );
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  // دالة مساعدة لبناء صفوف الجدول
  static pw.Widget _buildRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(value),
        ],
      ),
    );
  }
}
