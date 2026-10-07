import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/model_mahasiswa.dart';
import '../../models/model_tarif_mahasiswa.dart';
import '../../repositories/repo_mahasiswa.dart';
import '../../services/service_trigger.dart';
import '../../widgets/premium_header.dart';

class ScreenKegiatanMahasiswa extends StatefulWidget {
  const ScreenKegiatanMahasiswa({super.key});

  @override
  State<ScreenKegiatanMahasiswa> createState() => _ScreenKegiatanMahasiswaState();
}

class _ScreenKegiatanMahasiswaState extends State<ScreenKegiatanMahasiswa> {
  final MahasiswaRepository _repo = MahasiswaRepository();
  late Future<List<MahasiswaKegiatanModel>> _futureKegiatan;

  @override
  void initState() {
    super.initState();
    _loadData();
    refreshTrigger.addListener(_loadData);
  }

  void _loadData() {
    if (mounted) {
      setState(() {
        _futureKegiatan = _repo.getAllMahasiswaKegiatan();
      });
    }
  }

  @override
  void dispose() {
    refreshTrigger.removeListener(_loadData);
    super.dispose();
  }

  void _showFormDialog([MahasiswaKegiatanModel? existing]) async {
    final kampusList = await _repo.getAllKampus();
    final tarifList = await _repo.getAllTarif();

    if (!mounted) return;

    final namaCtrl = TextEditingController(text: existing?.nama ?? '');
    final nimCtrl = TextEditingController(text: existing?.nim ?? '');
    final durasiCtrl = TextEditingController(text: existing?.durasi.toString() ?? '1');
    final biayaCtrl = TextEditingController(text: existing?.biaya.toString() ?? '0');
    final kontakCtrl = TextEditingController(text: existing?.kontak ?? '');
    final catatanCtrl = TextEditingController(text: existing?.catatan ?? '');

    String selectedKampus = existing?.namaKampus ?? (kampusList.isNotEmpty ? kampusList.first.namaKampus : '');
    String selectedJenis = existing?.jenisKegiatan ?? 'Penelitian';
    String selectedJenjang = existing?.jenjang ?? 'S1';
    String selectedSatuan = existing?.satuan ?? 'Hari';
    String selectedStatus = existing?.status ?? 'Aktif';
    String tanggalMulai = existing?.tanggalMulai ?? DateFormat('yyyy-MM-dd').format(DateTime.now());

    void updateBiayaOtomatis() {
      try {
        final match = tarifList.firstWhere(
          (t) => t.jenis.toLowerCase() == selectedJenis.toLowerCase() && t.jenjang.toLowerCase() == selectedJenjang.toLowerCase(),
          orElse: () => TarifMahasiswaModel(jenis: '', jenjang: '', biaya: 0.0),
        );
        final durasi = int.tryParse(durasiCtrl.text) ?? 1;
        if (match.biaya > 0) {
          biayaCtrl.text = (match.biaya * durasi).toStringAsFixed(0);
          selectedSatuan = match.satuan;
        }
      } catch (_) {}
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Form Registrasi Kegiatan Mahasiswa (Awal Masuk)' : 'Edit Data Kegiatan Mahasiswa'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: namaCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Lengkap Mahasiswa *', prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nimCtrl,
                    decoration: const InputDecoration(labelText: 'NIM / Nomor Induk *', prefixIcon: Icon(Icons.badge)),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: kampusList.any((k) => k.namaKampus == selectedKampus) ? selectedKampus : (kampusList.isNotEmpty ? kampusList.first.namaKampus : null),
                    decoration: const InputDecoration(labelText: 'Asal Kampus / Institusi *', prefixIcon: Icon(Icons.school)),
                    items: kampusList.map((k) => DropdownMenuItem(value: k.namaKampus, child: Text(k.namaKampus))).toList(),
                    onChanged: (v) => setDialogState(() => selectedKampus = v ?? ''),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedJenis,
                          decoration: const InputDecoration(labelText: 'Jenis Kegiatan *'),
                          items: const [
                            DropdownMenuItem(value: 'Penelitian', child: Text('Penelitian')),
                            DropdownMenuItem(value: 'PKK', child: Text('PKK')),
                            DropdownMenuItem(value: 'PKM', child: Text('PKM')),
                            DropdownMenuItem(value: 'COAS', child: Text('COAS')),
                            DropdownMenuItem(value: 'Residen', child: Text('Residen')),
                          ],
                          onChanged: (v) {
                            setDialogState(() => selectedJenis = v!);
                            updateBiayaOtomatis();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedJenjang,
                          decoration: const InputDecoration(labelText: 'Jenjang *'),
                          items: const [
                            DropdownMenuItem(value: 'SMK', child: Text('SMK')),
                            DropdownMenuItem(value: 'D3', child: Text('D3')),
                            DropdownMenuItem(value: 'D4', child: Text('D4')),
                            DropdownMenuItem(value: 'S1', child: Text('S1')),
                            DropdownMenuItem(value: 'S2', child: Text('S2')),
                            DropdownMenuItem(value: 'Profesi', child: Text('Profesi')),
                          ],
                          onChanged: (v) {
                            setDialogState(() => selectedJenjang = v!);
                            updateBiayaOtomatis();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: durasiCtrl,
                          decoration: const InputDecoration(labelText: 'Durasi *'),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => updateBiayaOtomatis(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedSatuan,
                          decoration: const InputDecoration(labelText: 'Satuan Waktu *'),
                          items: const [
                            DropdownMenuItem(value: 'Hari', child: Text('Hari')),
                            DropdownMenuItem(value: 'Pekan', child: Text('Pekan')),
                            DropdownMenuItem(value: 'Bulan', child: Text('Bulan')),
                            DropdownMenuItem(value: 'Kegiatan', child: Text('Kegiatan')),
                          ],
                          onChanged: (v) => setDialogState(() => selectedSatuan = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: biayaCtrl,
                    decoration: const InputDecoration(labelText: 'Total Biaya / Kontribusi (Rp) *', prefixText: 'Rp '),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status Kegiatan *'),
                    items: const [
                      DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                      DropdownMenuItem(value: 'Selesai', child: Text('Selesai')),
                      DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    ],
                    onChanged: (v) => setDialogState(() => selectedStatus = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: kontakCtrl,
                    decoration: const InputDecoration(labelText: 'No HP / Kontak Mahasiswa *', prefixIcon: Icon(Icons.phone)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: catatanCtrl,
                    decoration: const InputDecoration(labelText: 'Catatan / Keterangan Tambahan', prefixIcon: Icon(Icons.note)),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              onPressed: () async {
                if (namaCtrl.text.trim().isEmpty || 
                    nimCtrl.text.trim().isEmpty || 
                    selectedKampus.trim().isEmpty || 
                    durasiCtrl.text.trim().isEmpty || 
                    biayaCtrl.text.trim().isEmpty || 
                    kontakCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Semua field wajib diisi! (Nama, NIM, Kampus, Durasi, Biaya, Kontak)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final mModel = MahasiswaKegiatanModel(
                  id: existing?.id,
                  nama: namaCtrl.text.trim(),
                  nim: nimCtrl.text.trim(),
                  namaKampus: selectedKampus,
                  jenisKegiatan: selectedJenis,
                  jenjang: selectedJenjang,
                  tanggalMulai: tanggalMulai,
                  durasi: int.tryParse(durasiCtrl.text) ?? 1,
                  satuan: selectedSatuan,
                  biaya: double.tryParse(biayaCtrl.text) ?? 0.0,
                  status: selectedStatus,
                  kontak: kontakCtrl.text.trim(),
                  catatan: catatanCtrl.text.trim(),
                );

                if (existing == null) {
                  await _repo.addMahasiswaKegiatan(mModel);
                } else {
                  await _repo.updateMahasiswaKegiatan(mModel);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data kegiatan mahasiswa berhasil disimpan!'), backgroundColor: Colors.green));
                }
              },
              child: const Text('Simpan Data'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const PremiumHeader(
            title: 'Modul Kegiatan Mahasiswa',
            subtitle: 'Manajemen Data Mahasiswa & Rekapitulasi Pendapatan',
            borderRadius: BorderRadius.zero,
          ),
          Expanded(
            child: FutureBuilder<List<MahasiswaKegiatanModel>>(
              future: _futureKegiatan,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data ?? [];
                
                // HITUNG STATISTIK & REKAPITULASI
                final int totalMahasiswa = list.length;
                final int mahasiswaAktif = list.where((m) => m.status.toLowerCase() == 'aktif').length;
                final int totalKampus = list.map((m) => m.namaKampus.trim().toLowerCase()).toSet().length;
                final double totalPendapatan = list.fold(0.0, (sum, item) => sum + item.biaya);

                // Grouping Jenis Kegiatan
                final Map<String, int> jenisKegiatanMap = {};
                for (var m in list) {
                  jenisKegiatanMap[m.jenisKegiatan] = (jenisKegiatanMap[m.jenisKegiatan] ?? 0) + 1;
                }

                // Grouping Jenjang
                final Map<String, int> jenjangMap = {};
                for (var m in list) {
                  jenjangMap[m.jenjang] = (jenjangMap[m.jenjang] ?? 0) + 1;
                }

                // Warna untuk Pie Chart
                final List<Color> chartColors = [
                  Colors.blue,
                  Colors.purple,
                  Colors.teal,
                  Colors.orange,
                  Colors.pink,
                  Colors.indigo,
                  Colors.amber,
                  Colors.cyan,
                ];

                int colorIdx = 0;
                final List<_PieData> jenisPieData = jenisKegiatanMap.entries.map((e) {
                  final color = chartColors[colorIdx % chartColors.length];
                  colorIdx++;
                  return _PieData(e.key, e.value.toDouble(), color);
                }).toList();

                colorIdx = 0;
                final List<_PieData> jenjangPieData = jenjangMap.entries.map((e) {
                  final color = chartColors[colorIdx % chartColors.length];
                  colorIdx++;
                  return _PieData(e.key, e.value.toDouble(), color);
                }).toList();

                return RefreshIndicator(
                  onRefresh: () async => _loadData(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TOMBOL AKSI & JUDUL
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ringkasan & Daftar Kegiatan Mahasiswa',
                              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _showFormDialog(),
                              icon: const Icon(Icons.person_add_rounded),
                              label: const Text('Registrasi Awal Masuk'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // KARTU METRIK UTAMA (4 Kartu)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            double cardWidth = constraints.maxWidth > 900 
                                ? (constraints.maxWidth - 48) / 4 
                                : (constraints.maxWidth > 600 ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth);
                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildMetricCard(
                                    title: 'Total Mahasiswa',
                                    value: totalMahasiswa.toString(),
                                    icon: Icons.groups_rounded,
                                    color: Colors.blue,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildMetricCard(
                                    title: 'Mahasiswa Aktif',
                                    value: mahasiswaAktif.toString(),
                                    icon: Icons.how_to_reg_rounded,
                                    color: Colors.green,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildMetricCard(
                                    title: 'Total Kampus Mitra',
                                    value: totalKampus.toString(),
                                    icon: Icons.school_rounded,
                                    color: Colors.orange,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildMetricCard(
                                    title: 'Total Pendapatan',
                                    value: NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(totalPendapatan),
                                    icon: Icons.account_balance_wallet_rounded,
                                    color: Colors.indigo,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // KARTU PIE CHART BREAKDOWN (Jenis Kegiatan & Jenjang Pendidikan)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            double breakdownWidth = constraints.maxWidth > 800 ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;
                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                SizedBox(
                                  width: breakdownWidth,
                                  child: _buildBreakdownCard(
                                    title: 'Perbandingan Jenis Kegiatan',
                                    icon: Icons.pie_chart_rounded,
                                    color: Colors.purple,
                                    sections: jenisPieData,
                                  ),
                                ),
                                SizedBox(
                                  width: breakdownWidth,
                                  child: _buildBreakdownCard(
                                    title: 'Perbandingan Jenjang Pendidikan',
                                    icon: Icons.bar_chart_rounded,
                                    color: Colors.teal,
                                    sections: jenjangPieData,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 28),

                        // TABEL RINCIAN MAHASISWA
                        Text(
                          'Rincian Mahasiswa Melakukan Kegiatan',
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 12),

                        list.isEmpty
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(40),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(Icons.folder_open_rounded, size: 48, color: Colors.grey),
                                    SizedBox(height: 12),
                                    Text('Belum ada data mahasiswa kegiatan terdaftar.', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: list.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final m = list[index];
                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                      leading: CircleAvatar(
                                        backgroundColor: m.status.toLowerCase() == 'aktif' ? Colors.green.shade50 : Colors.grey.shade100,
                                        child: Text(m.nama.isNotEmpty ? m.nama[0].toUpperCase() : 'M', style: TextStyle(color: m.status.toLowerCase() == 'aktif' ? Colors.green.shade800 : Colors.grey)),
                                      ),
                                      title: Text(m.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text('NIM: ${m.nim} • ${m.namaKampus}'),
                                          Text('Kegiatan: ${m.jenisKegiatan} (${m.jenjang}) • Durasi: ${m.durasi} ${m.satuan}'),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(m.biaya),
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 14),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: m.status.toLowerCase() == 'aktif' ? Colors.green.shade100 : Colors.orange.shade100,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  m.status,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: m.status.toLowerCase() == 'aktif' ? Colors.green.shade800 : Colors.orange.shade800,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 12),
                                          IconButton(
                                            icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                                            onPressed: () => _showFormDialog(m),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                            onPressed: () async {
                                              final conf = await showDialog<bool>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('Hapus Data'),
                                                  content: Text('Yakin ingin menghapus ${m.nama}?'),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                                                    ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
                                                  ],
                                                ),
                                              );
                                              if (conf == true && m.id != null) {
                                                await _repo.deleteMahasiswaKegiatan(m.id!);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
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

  Widget _buildMetricCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF1E293B), fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard({required String title, required IconData icon, required Color color, required List<_PieData> sections}) {
    double total = sections.fold(0, (sum, item) => sum + item.value);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF1E293B))),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: total == 0
                    ? Center(child: Text("0", style: TextStyle(color: Colors.grey.shade400)))
                    : PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 25,
                          sections: sections.map((data) {
                            return PieChartSectionData(
                              color: data.color,
                              value: data.value,
                              title: '',
                              radius: 25,
                            );
                          }).toList(),
                        ),
                      ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sections.isEmpty
                      ? [const Text('Belum ada data tersedia.', style: TextStyle(color: Colors.grey, fontSize: 13))]
                      : sections.map((data) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(color: data.color, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(data.label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                ),
                                Text('${data.value.toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PieData {
  final String label;
  final double value;
  final Color color;
  _PieData(this.label, this.value, this.color);
}
