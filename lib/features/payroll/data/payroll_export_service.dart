import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:workaxis/features/payroll/domain/models/monthly_payroll.dart';

class PayrollExportService {
  const PayrollExportService();

  Future<void> exportSummaryXlsx(MonthlyPayroll payroll) async {
    final workbook = Excel.createExcel();
    workbook.rename('Sheet1', 'Payroll Summary');
    final sheet = workbook['Payroll Summary'];
    sheet.appendRow([
      TextCellValue(
        'Multi-branch employees are allocated evenly across active assigned branches.',
      ),
    ]);
    sheet.appendRow([
      for (final label in [
        'Branch',
        'Employees',
        'Scheduled hours',
        'Payable hours',
        'Unpaid leave days',
        'Overtime hours',
        'Overtime pay (INR)',
        'Gross pay (INR)',
      ])
        TextCellValue(label),
    ]);
    final total = payroll.summary;
    if (total != null) {
      sheet.appendRow([
        TextCellValue('All branches'),
        IntCellValue(total.employeeCount),
        DoubleCellValue(total.scheduledHours),
        DoubleCellValue(total.payableHours),
        DoubleCellValue(total.unpaidLeaveDays),
        DoubleCellValue(total.overtimeHours),
        DoubleCellValue(total.overtimePay),
        DoubleCellValue(total.grossPay),
      ]);
    }
    for (final branch in payroll.branchSummaries) {
      final summary = branch.summary;
      sheet.appendRow([
        TextCellValue(branch.branchName),
        IntCellValue(summary.employeeCount),
        DoubleCellValue(summary.scheduledHours),
        DoubleCellValue(summary.payableHours),
        DoubleCellValue(summary.unpaidLeaveDays),
        DoubleCellValue(summary.overtimeHours),
        DoubleCellValue(summary.overtimePay),
        DoubleCellValue(summary.grossPay),
      ]);
    }
    final bytes = workbook.encode();
    if (bytes == null) throw StateError('Could not create the summary export.');
    await FileSaver.instance.saveToDownloads(
      name: 'workaxis-payroll-summary-${payroll.month}',
      bytes: Uint8List.fromList(bytes),
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
      subfolder: 'WorkAxis',
    );
  }

  Future<void> exportMonthlyXlsx(MonthlyPayroll payroll) async {
    final workbook = Excel.createExcel();
    workbook.rename('Sheet1', 'Monthly Payroll');
    final sheet = workbook['Monthly Payroll'];
    final headers = [
      'Employee',
      'Employee ID',
      'Role',
      'Scheduled hours',
      'Payable hours',
      'Scheduled days',
      'Payable days',
      'Unpaid leave days',
      'Unpaid leave impact (INR)',
      'Overtime hours',
      'Overtime pay (INR)',
      'Base pay (INR)',
      'Gross pay (INR)',
      'Status',
    ];
    sheet.appendRow(headers.map(TextCellValue.new).toList());
    for (final record in payroll.records) {
      sheet.appendRow([
        TextCellValue(record.fullName),
        TextCellValue(record.employeeCode ?? ''),
        TextCellValue(record.role),
        DoubleCellValue(record.scheduledHours),
        DoubleCellValue(record.payableHours),
        IntCellValue(record.scheduledWorkdays),
        IntCellValue(record.payableWorkdays),
        IntCellValue(record.unpaidLeaveDays),
        DoubleCellValue(record.unpaidLeaveImpact),
        DoubleCellValue(record.overtimeHours),
        DoubleCellValue(record.overtimePay),
        DoubleCellValue(record.basePay),
        DoubleCellValue(record.grossPay),
        TextCellValue(
          record.available ? 'Available' : 'Needs schedule or salary history',
        ),
      ]);
    }
    final bytes = workbook.encode();
    if (bytes == null) throw StateError('Could not create the XLSX export.');
    await FileSaver.instance.saveToDownloads(
      name: 'workaxis-payslips-${payroll.month}',
      bytes: Uint8List.fromList(bytes),
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
      subfolder: 'WorkAxis',
    );
  }

  Future<void> exportIndividualPdf({
    required PayrollRecord record,
    required String month,
    required String payBasis,
    required bool overtimeEnabled,
  }) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          pw.Text(
            'WorkAxis payslip',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Pay period: $month'),
          pw.Text('Employee: ${record.fullName}'),
          if (record.employeeCode != null)
            pw.Text('Employee ID: ${record.employeeCode}'),
          pw.SizedBox(height: 24),
          if (!record.available)
            pw.Text(
              'This payslip is unavailable because schedule or salary history is missing.',
            )
          else ...[
            _pdfRow(
              'Calculation basis',
              payBasis == 'workdays' ? 'Workdays' : 'Hours',
            ),
            _pdfRow('Scheduled hours', _hours(record.scheduledHours)),
            _pdfRow('Payable hours', _hours(record.payableHours)),
            _pdfRow('Actual hours', _hours(record.actualHours)),
            _pdfRow('Scheduled workdays', '${record.scheduledWorkdays}'),
            _pdfRow('Payable workdays', '${record.payableWorkdays}'),
            _pdfRow('Approved unpaid leave days', '${record.unpaidLeaveDays}'),
            _pdfRow('Unpaid leave impact', _money(record.unpaidLeaveImpact)),
            _pdfRow('Overtime hours', _hours(record.overtimeHours)),
            _pdfRow('Overtime policy', overtimeEnabled ? 'Enabled' : 'Off'),
            _pdfRow('Overtime pay', _money(record.overtimePay)),
            pw.Divider(height: 32),
            _pdfRow('Base pay', _money(record.basePay), bold: true),
            _pdfRow('Gross pay', _money(record.grossPay), bold: true),
          ],
        ],
      ),
    );
    await FileSaver.instance.saveToDownloads(
      name: 'payslip-${record.employeeCode ?? record.memberId}-$month',
      bytes: Uint8List.fromList(await document.save()),
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
      subfolder: 'WorkAxis',
    );
  }

  pw.Widget _pdfRow(String label, String value, {bool bold = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ],
        ),
      );

  String _money(double value) => 'INR ${value.toStringAsFixed(2)}';
  String _hours(double value) => '${value.toStringAsFixed(2)} h';
}
