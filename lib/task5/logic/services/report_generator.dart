import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/user_model.dart';
import '../models/grade_model.dart';

// Generate Laporan PDF (KHS - Kartu Hasil Studi)
class ReportGenerator {
  static Future<void> generateKHS({
    required StudentUser student,
    required List<Grade> grades,
    required double gpa,
    required int totalSks,
  }) async {
    final pdf = pw.Document();

    // Contoh penggunaan
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text("Kartu Hasil Studi (KHS)"),
              pw.SizedBox(height: 20),
              pw.Text("Nama: ${student.nama}"),
              pw.Text("NIM: ${student.nim}"),
              pw.Text("Email: ${student.email}"),
              pw.Text("Jurusan: ${student.jurusan}"),
              pw.SizedBox(height: 20),
              pw.Text("GPA Kumulatif: ${gpa.toStringAsFixed(2)}"),
              pw.Text("Total SKS: $totalSks"),
              pw.SizedBox(height: 20),
              if (grades.isNotEmpty) ...[
                pw.Text("Daftar Nilai:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(width: 1),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Text("Mata Kuliah", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text("Nilai", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text("Grade", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text("SKS", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                        ...grades.map((grade) {
                      return pw.TableRow(children: [
                        pw.Text(grade.matkul),
                        pw.Text(grade.nilai.toStringAsFixed(2)),
                        pw.Text(grade.grade),
                        pw.Text(grade.sks.toString()),
                      ]);
                            }),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );

    // Tampilkan / print:
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'KHS_${student.nim}.pdf',
    );
  }
}
