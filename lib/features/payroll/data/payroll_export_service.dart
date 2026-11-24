import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:workaxis/features/payroll/data/payroll_export_rows.dart';
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
    sheet.appendRow([TextCellValue(PayrollExportRows.overtimeNote)]);
    sheet.appendRow(
      PayrollExportRows.summaryHeaders.map(TextCellValue.new).toList(),
    );
    final total = payroll.summary;
    if (total != null) {
      sheet.appendRow(PayrollExportRows.summaryRow('All branches', total));
    }
    for (final branch in payroll.branchSummaries) {
      sheet.appendRow(
        PayrollExportRows.summaryRow(branch.branchName, branch.summary),
      );
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
    sheet.appendRow(
      PayrollExportRows.monthlyHeaders.map(TextCellValue.new).toList(),
    );
    for (final record in payroll.records) {
      sheet.appendRow(PayrollExportRows.monthlyRow(record));
    }
    sheet.appendRow([TextCellValue(PayrollExportRows.overtimeNote)]);
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
            for (final (label, value) in PayrollExportRows.payslipLines(
              record,
              payBasis: payBasis,
              overtimeEnabled: overtimeEnabled,
            ))
              _pdfRow(label, value),
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                PayrollExportRows.overtimeNote,
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Divider(height: 32),
            _pdfRow(
              'Base pay',
              PayrollExportRows.money(record.basePay),
              bold: true,
            ),
            _pdfRow(
              'Gross pay',
              PayrollExportRows.money(record.grossPay),
              bold: true,
            ),
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
}
