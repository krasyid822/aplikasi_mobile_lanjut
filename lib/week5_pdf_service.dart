import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'week5_grade_model.dart';
import 'week5_user_model.dart';

class PDFService {
  Future<void> generateAndPrintKHS({
    required StudentUser student,
    required List<Grade> grades,
    required double gpa,
    required int totalSks,
  }) async {
    final pdf = pw.Document();

    // Group grades by semester
    Map<int, List<Grade>> gradesBySemester = {};
    for (var grade in grades) {
      if (!gradesBySemester.containsKey(grade.semester)) {
        gradesBySemester[grade.semester] = [];
      }
      gradesBySemester[grade.semester]!.add(grade);
    }

    // Add cover page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'KARTU HASIL STUDI',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Sistem Informasi Akademik Mahasiswa',
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 40),
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 1),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Nama:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text(student.nama),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('NIM:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text(student.nim),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Jurusan:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text(student.jurusan),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Email:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text(student.email),
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
    );

    // Add grades pages
    bool isFirstPage = true;
    for (var semesterEntry in gradesBySemester.entries) {
      final semester = semesterEntry.key;
      final semesterGrades = semesterEntry.value;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (!isFirstPage) ...[
                  pw.SizedBox(height: 20),
                ],
                pw.Text(
                  'Semester $semester',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                _buildGradesTable(semesterGrades),
                pw.SizedBox(height: 20),
                _buildSemesterSummary(semesterGrades),
              ],
            );
          },
        ),
      );
      isFirstPage = false;
    }

    // Add summary page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'RINGKASAN AKADEMIK',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1),
                ),
                child: pw.Column(
                  children: [
                    _buildSummaryRow('GPA Kumulatif', gpa.toStringAsFixed(2)),
                    pw.SizedBox(height: 10),
                    _buildSummaryRow('Total SKS', totalSks.toString()),
                    pw.SizedBox(height: 10),
                    _buildSummaryRow(
                      'Total Mata Kuliah',
                      grades.length.toString(),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 40),
              pw.Text(
                'Tanggal Cetak: ${DateTime.now().toString().split('.')[0]}',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          );
        },
      ),
    );

    // Print PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'KHS_${student.nim}.pdf',
    );
  }

  pw.Widget _buildGradesTable(List<Grade> grades) {
    return pw.Table(
      border: pw.TableBorder.all(width: 1),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColors.grey300,
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Kode MK',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Mata Kuliah',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'SKS',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Nilai',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Grade',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              ),
            ),
          ],
        ),
        ...grades.map((grade) {
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  grade.kodeMatkul,
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  grade.matkul,
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  grade.sks.toString(),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  grade.nilai.toStringAsFixed(2),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  grade.grade,
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildSemesterSummary(List<Grade> grades) {
    double totalPoints = 0;
    int totalSks = 0;

    for (var grade in grades) {
      totalPoints += grade.getGradePoint() * grade.sks;
      totalSks += grade.sks;
    }

    double semesterGpa = totalSks > 0 ? totalPoints / totalSks : 0.0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1),
        color: PdfColors.grey100,
      ),
      child: pw.Column(
        children: [
          _buildSummaryRow('IP Semester', semesterGpa.toStringAsFixed(2)),
          pw.SizedBox(height: 5),
          _buildSummaryRow('Total SKS', totalSks.toString()),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text(value),
      ],
    );
  }
}

