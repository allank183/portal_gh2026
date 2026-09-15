import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/model_tarif_mahasiswa.dart';
import '../../../repositories/repo_mahasiswa.dart';
import '../../../services/service_trigger.dart';

class TabMasterTarif extends StatefulWidget {
  const TabMasterTarif({super.key});

  @override
  State<TabMasterTarif> createState() => _TabMasterTarifState();
}

class _TabMasterTarifState extends State<TabMasterTarif> {
  final MahasiswaRepository _repo = MahasiswaRepository();
  late Future<List<TarifMahasiswaModel>> _futureTarif;

  @override
  void initState() {
    super.initState();
    _loadData();
    refreshTrigger.addListener(_loadData);
  }

  void _loadData() {
    if (mounted) {
      setState(() {
        _futureTarif = _repo.getAllTarif();
      });
    }
  }

  @override
  void dispose() {
    refreshTrigger.removeListener(_loadData);
    super.dispose();
  }

  void _showAddEditDialog([TarifMahasiswaModel? existing]) {
    String selectedJenis = existing?.jenis ?? 'Penelitian';
    String selectedJenjang = existing?.jenjang ?? 'S1';
    String selectedSatuan = existing?.satuan ?? 'Hari';
    final biayaCtrl = TextEditingController(text: existing?.biaya.toString() ?? '0');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Tambah Tarif Baru' : 'Edit Tarif'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedJenis,
                  decoration: const InputDecoration(labelText: 'Jenis Kegiatan'),
                  items: const [
                    DropdownMenuItem(value: 'Penelitian', child: Text('Penelitian')),
                    DropdownMenuItem(value: 'Data Awal', child: Text('Data Awal')),
                    DropdownMenuItem(value: 'PKK', child: Text('PKK (Praktek Klinik Kesehatan)')),
                    DropdownMenuItem(value: 'COAS', child: Text('COAS')),
                    DropdownMenuItem(value: 'Residen', child: Text('Residen')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedJenis = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedJenjang,
                  decoration: const InputDecoration(labelText: 'Jenjang Pendidikan'),
                  items: const [
                    DropdownMenuItem(value: 'SMK', child: Text('SMK')),
                    DropdownMenuItem(value: 'D3', child: Text('D3')),
                    DropdownMenuItem(value: 'D4', child: Text('D4')),
                    DropdownMenuItem(value: 'S1', child: Text('S1')),
                    DropdownMenuItem(value: 'S2', child: Text('S2')),
                    DropdownMenuItem(value: 'S3', child: Text('S3')),
                    DropdownMenuItem(value: 'Profesi', child: Text('Profesi')),
                    DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedJenjang = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: biayaCtrl,
                  decoration: const InputDecoration(labelText: 'Tarif / Biaya (Rp)', prefixText: 'Rp '),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedSatuan,
                  decoration: const InputDecoration(labelText: 'Satuan Waktu'),
                  items: const [
                    DropdownMenuItem(value: 'Hari', child: Text('Hari')),
                    DropdownMenuItem(value: 'Pekan', child: Text('Pekan')),
                    DropdownMenuItem(value: 'Bulan', child: Text('Bulan')),
                    DropdownMenuItem(value: 'Kegiatan', child: Text('Kegiatan')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedSatuan = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final newTarif = TarifMahasiswaModel(
                  id: existing?.id,
                  jenis: selectedJenis,
                  jenjang: selectedJenjang,
                  biaya: double.tryParse(biayaCtrl.text) ?? 0.0,
                  satuan: selectedSatuan,
                );
                if (existing == null) {
                  await _repo.addTarif(newTarif);
                } else {
                  await _repo.updateTarif(newTarif);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
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
              Text('Konfigurasi Tarif Mahasiswa', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _showAddEditDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Tarif'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<TarifMahasiswaModel>>(
              future: _futureTarif,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final list = snapshot.data ?? [];
                if (list.isEmpty) return const Center(child: Text('Belum ada data tarif.'));

                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final t = list[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text(t.jenis[0])),
                      title: Text('${t.jenis} - ${t.jenjang}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Tarif: Rp ${t.biaya} / ${t.satuan}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showAddEditDialog(t),
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
