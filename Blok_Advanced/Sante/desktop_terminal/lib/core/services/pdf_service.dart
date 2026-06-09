import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> generateAndPrint(Map<String, dynamic> record) async {
    final pdf = await _generateDocument(record);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Dossier_${record['nom'] ?? 'Patient'}.pdf',
    );
  }

  static Future<void> generateAndShare(Map<String, dynamic> record) async {
    final pdf = await _generateDocument(record);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Dossier_${record['nom'] ?? 'Patient'}.pdf',
    );
  }

  static Future<pw.Document> _generateDocument(Map<String, dynamic> record) async {
    final pdf = pw.Document();
    final allergies = (record['allergies'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(record),
            pw.SizedBox(height: 20),
            _buildCriticalSection(allergies),
            pw.SizedBox(height: 20),
            _buildSectionTitle('Informations Générales'),
            _buildInfoRow('Date de naissance', record['dob'] ?? 'N/A'),
            _buildInfoRow('Groupe Sanguin', record['groupeSanguin'] ?? 'N/A'),
            pw.SizedBox(height: 20),
            _buildSectionTitle('Notes Médicales'),
            pw.Paragraph(
              text: record['notes'] ?? 'Aucune note particulière.',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.Spacer(),
            pw.Divider(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Généré par Santé Pocket • ${DateTime.now().toString().split('.')[0]}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader(Map<String, dynamic> record) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'DOSSIER MÉDICAL',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.teal),
            ),
            pw.Text(
              '${record['nom']?.toUpperCase()} ${record['prenom']}',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.PdfLogo(),
      ],
    );
  }

  static pw.Widget _buildCriticalSection(List<String> allergies) {
    if (allergies.isEmpty) return pw.SizedBox();
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.red50,
        border: pw.Border.all(color: PdfColors.red, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('ATTENTION - ALLERGIES :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
          pw.Bullet(text: allergies.join(', ')),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey)),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 150, child: pw.Text('$label :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
          pw.Text(value),
        ],
      ),
    );
  }
}
