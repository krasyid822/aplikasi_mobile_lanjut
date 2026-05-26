import 'package:flutter/material.dart';
import '../../logic/services/auth_service.dart';
import '../../logic/services/firestore_service.dart';

class Week5NilaiPage extends StatefulWidget {
  const Week5NilaiPage({super.key});

  @override
  State<Week5NilaiPage> createState() => _Week5NilaiPageState();
}

class _Week5NilaiPageState extends State<Week5NilaiPage> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  int? _selectedSemester;

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) return const Center(child: Text('Pengguna tidak ditemukan'));

    return FutureBuilder<List<int>>(
      future: _getSemesters(user.uid),
      builder: (context, semesterSnapshot) {
        if (!semesterSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final semesters = semesterSnapshot.data ?? [];
        final selectedSemester = _selectedSemester ?? (semesters.isNotEmpty ? semesters.first : null);

        return Column(
          children: [
            if (semesters.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButton<int>(
                  value: selectedSemester,
                  isExpanded: true,
                  items: semesters.map((sem) {
                    return DropdownMenuItem(
                      value: sem,
                      child: Text('Semester $sem'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedSemester = value);
                  },
                ),
              ),
            Expanded(
              child: selectedSemester != null
                  ? StreamBuilder(
                      stream: _firestoreService.getGradesBySemesterStream(
                        user.uid,
                        selectedSemester,
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final grades = snapshot.data ?? [];
                        if (grades.isEmpty) {
                          return const Center(child: Text('Tidak ada nilai'));
                        }

                        return ListView(
                          children: grades.map((doc) {
                            return ListTile(
                              title: Text(doc.matkul),
                              subtitle: Text("Nilai: ${doc.nilai.toStringAsFixed(1)}"),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  doc.grade,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    )
                  : const Center(child: Text('Pilih semester')),
            ),
          ],
        );
      },
    );
  }

  Future<List<int>> _getSemesters(String uid) async {
    final grades = await _firestoreService.getGradesByUser(uid);
    final semesters = <int>{};
    for (var grade in grades) {
      semesters.add(grade.semester);
    }
    return semesters.toList()..sort((a, b) => b.compareTo(a));
  }
}
