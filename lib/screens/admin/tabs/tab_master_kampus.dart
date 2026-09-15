import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/model_kampus.dart';
import '../../../repositories/repo_mahasiswa.dart';
import '../../../services/service_trigger.dart';

class TabMasterKampus extends StatefulWidget {
  const TabMasterKampus({super.key});

  @override
  State<TabMasterKampus> createState() => _TabMasterKampusState();
}

class _TabMasterKampusState extends State<TabMasterKampus> {
  final MahasiswaRepository _repo = MahasiswaRepository();
  late Future<List<KampusModel>> _futureKampus;
  final _namaController = TextEditingController();
  final _singkatanController = TextEditingController();
  final _alamatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    refreshTrigger.addListener(_loadData);
  }

  void _loadData() {
    if (mounted) {
      setState(() {
        _futureKampus = _repo.getAllKampus();
      });
    }
  }

  @override
  void dispose() {
    refreshTrigger.removeListener(_loadData);
    super.dispose();
  }

  void _showAddDialog() {
    _namaController.clear();
    _singkatanController.clear();
    _alamatController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Kampus Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _namaController, decoration: const InputDecoration(labelText: 'Nama Kampus')),
            TextField(controller: _singkatanController, decoration: const InputDecoration(labelText: 'Singkatan (UNHAS, dll)')),
            TextField(controller: _alamatController, decoration: const InputDecoration(labelText: 'Alamat')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (_namaController.text.isNotEmpty) {
                await _repo.addKampus(KampusModel(
                  namaKampus: _namaController.text.trim(),
                  singkatan: _singkatanController.text.trim(),
                  alamat: _alamatController.text.trim(),
                ));
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daftar Kampus Kerja Sama', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.add),
                label: const Text('Tambah Kampus'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<KampusModel>>(
              future: _futureKampus,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final list = snapshot.data ?? [];
                if (list.isEmpty) return const Center(child: Text('Belum ada data kampus.'));

                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final k = list[index];
                    return ListTile(
                      title: Text(k.namaKampus, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${k.singkatan ?? "-"} | ${k.alamat ?? "-"}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _repo.deleteKampus(k.id!),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
