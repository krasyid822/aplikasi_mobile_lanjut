import 'package:flutter/material.dart';
import 'week5_firestore_service.dart';
import 'week5_grade_model.dart';
import 'week5_admin_service.dart';

class Week5GradeRecapPage extends StatefulWidget {
  const Week5GradeRecapPage({super.key});

  @override
  State<Week5GradeRecapPage> createState() => _Week5GradeRecapPageState();
}

class _Week5GradeRecapPageState extends State<Week5GradeRecapPage> {
  final _firestoreService = FirestoreService();
  final _adminService = AdminService();
  String? _selectedCourse;
  List<Grade> _grades = [];
  bool _isLoading = false;

  // Filter variables
  String _searchName = '';
  String? _filterGrade;

  List<Grade> get _filteredGrades {
    return _grades.where((g) {
      final matchName = g.namaMahasiswa.toLowerCase().contains(_searchName.toLowerCase()) || 
                       g.uid.toLowerCase().contains(_searchName.toLowerCase());
      final matchGrade = _filterGrade == null || g.grade == _filterGrade;
      
      return matchName && matchGrade;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Nilai Mahasiswa'),
        backgroundColor: Colors.orange.shade600,
      ),
      body: StreamBuilder<AdminUser?>(
        stream: _adminService.getAdminProfileStream(_adminService.currentUser?.uid ?? ''),
        builder: (context, adminSnapshot) {
          final admin = adminSnapshot.data;
          final courses = admin?.matkulList ?? [];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Mata Kuliah Anda:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                if (courses.isEmpty)
                  const Text('Anda belum memiliki daftar mata kuliah yang diampu.', 
                    style: TextStyle(color: Colors.red))
                else
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCourse,
                    hint: const Text('Pilih Matkul'),
                    items: courses.map((course) => DropdownMenuItem(
                      value: course,
                      child: Text(course),
                    )).toList(),
                    onChanged: (val) async {
                      setState(() {
                        _selectedCourse = val;
                        _isLoading = true;
                      });
                      final results = await _firestoreService.getGradesByCourse(val!);
                      setState(() {
                        _grades = results;
                        _isLoading = false;
                      });
                    },
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                const SizedBox(height: 16),
                if (_selectedCourse != null) ...[
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          onChanged: (val) => setState(() => _searchName = val),
                          decoration: InputDecoration(
                            hintText: 'Cari nama mahasiswa...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: () => _showFilterDialog(),
                        tooltip: 'Filter Lanjutan',
                      ),
                    ],
                  ),
                  if (_filterGrade != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          if (_filterGrade != null)
                            Chip(
                              label: Text('Grade $_filterGrade'),
                              onDeleted: () => setState(() => _filterGrade = null),
                            ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Daftar Nilai:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredGrades.isEmpty 
                      ? const Center(child: Text('Tidak ada data nilai yang sesuai filter.'))
                      : ListView.builder(
                          itemCount: _filteredGrades.length,
                          itemBuilder: (context, index) {
                            final g = _filteredGrades[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getGradeColor(g.grade),
                                  child: Text(g.grade, style: const TextStyle(color: Colors.white)),
                                ),
                                title: Text(g.namaMahasiswa.isNotEmpty ? g.namaMahasiswa : 'Mahasiswa UID: ${g.uid}'),
                                subtitle: Text('Nilai: ${g.nilai} | SKS: ${g.sks}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Sem ${g.semester}'),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _confirmDelete(context, g),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Lanjutan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _filterGrade,
                hint: const Text('Filter Grade'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Semua Grade')),
                  ...['A', 'B', 'C', 'D', 'E'].map((g) => DropdownMenuItem(value: g, child: Text('Grade $g'))),
                ],
                onChanged: (val) => setDialogState(() => _filterGrade = val),
                decoration: const InputDecoration(labelText: 'Grade'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _filterGrade = null;
                });
                Navigator.pop(context);
              },
              child: const Text('Reset'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {}); // Trigger rebuild with new filters
                Navigator.pop(context);
              },
              child: const Text('Terapkan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Grade grade) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Nilai'),
        content: Text('Anda yakin ingin menghapus nilai ${grade.namaMahasiswa} pada mata kuliah ${grade.matkul}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              await _firestoreService.deleteGrade(grade.id);
              if (mounted) {
                if (context.mounted) Navigator.pop(context);
                // Refresh list
                final results = await _firestoreService.getGradesByCourse(_selectedCourse!);
                if (mounted) {
                  setState(() {
                    _grades = results;
                  });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nilai berhasil dihapus')),
                    );
                  }
                }
              }
            }, 
            child: const Text('Hapus', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A': return Colors.green;
      case 'B': return Colors.blue;
      case 'C': return Colors.orange;
      case 'D': return Colors.deepOrange;
      default: return Colors.red;
    }
  }
}
