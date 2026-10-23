import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/model_mou.dart';
import '../../models/model_pegawai.dart';
import '../../repositories/repo_mou.dart';
import '../../services/service_trigger.dart';
import '../../widgets/premium_header.dart';

class ScreenMou extends StatefulWidget {
  final PegawaiModel? currentUser;
  const ScreenMou({super.key, this.currentUser});

  @override
  State<ScreenMou> createState() => _ScreenMouState();
}

class _ScreenMouState extends State<ScreenMou> {
  final MouRepository _repo = MouRepository();
  late Future<List<MouModel>> _futureMou;

  @override
  void initState() {
    super.initState();
    _loadData();
    refreshTrigger.addListener(_loadData);
  }

  void _loadData() {
    if (mounted) {
      setState(() {
        _futureMou = _repo.getAllMou();
      });
    }
  }

  @override
  void dispose() {
    refreshTrigger.removeListener(_loadData);
    super.dispose();
  }

  bool get _canManageMou {
    if (widget.currentUser == null) return false;
    return widget.currentUser!.isSuperAdmin ||
           widget.currentUser!.permissions.contains('mou') ||
           widget.currentUser!.permissions.contains('admin');
  }

  void _showFormDialog([MouModel? existing]) async {
    if (!_canManageMou) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda tidak memiliki izin (permission "mou") untuk mengelola dokumen MoU.')),
      );
      return;
    }

    final nomorCtrl = TextEditingController(text: existing?.nomorMou ?? '');
    final judulCtrl = TextEditingController(text: existing?.judul ?? '');
    final mitraCtrl = TextEditingController(text: existing?.mitra ?? '');
    final mulaiCtrl = TextEditingController(text: existing?.tanggalMulai ?? '');
    final selesaiCtrl = TextEditingController(text: existing?.tanggalSelesai ?? '');
    final catatanCtrl = TextEditingController(text: existing?.catatan ?? '');

    String selectedKategori = existing?.kategori ?? 'Pendidikan';
    String selectedStatus = existing?.status ?? 'Aktif';

    Uint8List? fileBytes;
    String? fileName;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Tambah Dokumen MoU / Kerja Sama' : 'Edit Dokumen MoU'),
          content: SizedBox(
            width: 550,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomorCtrl,
                    decoration: const InputDecoration(labelText: 'Nomor MoU / Perjanjian *', prefixIcon: Icon(Icons.confirmation_number_rounded)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: judulCtrl,
                    decoration: const InputDecoration(labelText: 'Judul / Tentang Kerjasama *', prefixIcon: Icon(Icons.title)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: mitraCtrl,
                    decoration: const InputDecoration(labelText: 'Instansi Mitra (Kampus / RS / Perusahaan) *', prefixIcon: Icon(Icons.business_rounded)),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedKategori,
                    decoration: const InputDecoration(labelText: 'Kategori Kerja Sama *'),
                    items: const [
                      DropdownMenuItem(value: 'Pendidikan', child: Text('Pendidikan & Mahasiswa')),
                      DropdownMenuItem(value: 'Penelitian', child: Text('Penelitian & Riset')),
                      DropdownMenuItem(value: 'Pelayanan', child: Text('Pelayanan Kesehatan')),
                      DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya')),
                    ],
                    onChanged: (v) => setDialogState(() => selectedKategori = v!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: mulaiCtrl,
                          decoration: const InputDecoration(labelText: 'Tanggal Mulai (YYYY-MM-DD) *', prefixIcon: Icon(Icons.calendar_today_rounded)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: selesaiCtrl,
                          decoration: const InputDecoration(labelText: 'Tanggal Berakhir (YYYY-MM-DD) *', prefixIcon: Icon(Icons.event_busy_rounded)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status MoU *'),
                    items: const [
                      DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                      DropdownMenuItem(value: 'Kadaluarsa', child: Text('Kadaluarsa')),
                    ],
                    onChanged: (v) => setDialogState(() => selectedStatus = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: catatanCtrl,
                    decoration: const InputDecoration(labelText: 'Catatan / Keterangan', prefixIcon: Icon(Icons.note_rounded)),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                        withData: true,
                      );
                      if (result != null && result.files.single.bytes != null) {
                        setDialogState(() {
                          fileBytes = result.files.single.bytes;
                          fileName = result.files.single.name;
                        });
                      }
                    },
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: Text(fileName ?? (existing?.fileUrl != null ? 'Ganti File Dokumen PDF' : 'Upload Berkas MoU (PDF)')),
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
                if (nomorCtrl.text.trim().isEmpty || judulCtrl.text.trim().isEmpty || mitraCtrl.text.trim().isEmpty || mulaiCtrl.text.trim().isEmpty || selesaiCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap isi semua field yang wajib (*)')));
                  return;
                }

                final mouModel = MouModel(
                  id: existing?.id,
                  nomorMou: nomorCtrl.text.trim(),
                  judul: judulCtrl.text.trim(),
                  mitra: mitraCtrl.text.trim(),
                  kategori: selectedKategori,
                  tanggalMulai: mulaiCtrl.text.trim(),
                  tanggalSelesai: selesaiCtrl.text.trim(),
                  fileUrl: existing?.fileUrl,
                  status: selectedStatus,
                  catatan: catatanCtrl.text.trim(),
                );

                if (existing == null) {
                  await _repo.addMou(mouModel, fileBytes: fileBytes, fileName: fileName);
                } else {
                  await _repo.updateMou(mouModel, fileBytes: fileBytes, fileName: fileName);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dokumen MoU berhasil disimpan!'), backgroundColor: Colors.green));
                }
              },
              child: const Text('Simpan Dokumen'),
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
            title: 'Dokumen MoU & Kerja Sama',
            subtitle: 'Kelola Nota Kesepahaman & Perjanjian Kerja Sama Instansi',
            borderRadius: BorderRadius.zero,
          ),
          Expanded(
            child: FutureBuilder<List<MouModel>>(
              future: _futureMou,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data ?? [];

                final int totalMou = list.length;
                final int mouAktif = list.where((m) => m.status.toLowerCase() == 'aktif').length;
                final int totalMitra = list.map((m) => m.mitra.trim().toLowerCase()).toSet().length;

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
                              'Daftar Perjanjian Kerja Sama (MoU)',
                              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                            ),
                            if (_canManageMou)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => _showFormDialog(),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Tambah MoU Baru'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // KARTU METRIK UTAMA (3 Kartu)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            double cardWidth = constraints.maxWidth > 800
                                ? (constraints.maxWidth - 32) / 3
                                : constraints.maxWidth;
                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildMetricCard(
                                    title: 'Total Dokumen MoU',
                                    value: totalMou.toString(),
                                    icon: Icons.folder_shared_rounded,
                                    color: Colors.blue,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildMetricCard(
                                    title: 'MoU Aktif',
                                    value: mouAktif.toString(),
                                    icon: Icons.verified_rounded,
                                    color: Colors.green,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildMetricCard(
                                    title: 'Total Instansi Mitra',
                                    value: totalMitra.toString(),
                                    icon: Icons.business_rounded,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 28),

                        // TABEL DAFTAR MOU
                        Text(
                          'Rincian Perjanjian Kerja Sama',
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
                                    Icon(Icons.handshake_rounded, size: 48, color: Colors.grey),
                                    SizedBox(height: 12),
                                    Text('Belum ada dokumen MoU terdaftar.', style: TextStyle(color: Colors.grey)),
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
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      leading: CircleAvatar(
                                        backgroundColor: m.status.toLowerCase() == 'aktif' ? Colors.green.shade50 : Colors.red.shade50,
                                        child: Icon(
                                          Icons.description_rounded,
                                          color: m.status.toLowerCase() == 'aktif' ? Colors.green.shade800 : Colors.red.shade800,
                                        ),
                                      ),
                                      title: Text(m.judul, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text('No: ${m.nomorMou} • Mitra: ${m.mitra} (${m.kategori})'),
                                          Text('Masa Berlaku: ${m.tanggalMulai} s.d. ${m.tanggalSelesai}'),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (m.fileUrl != null && m.fileUrl!.isNotEmpty)
                                            IconButton(
                                              icon: const Icon(Icons.download_rounded, color: Colors.green),
                                              tooltip: 'Unduh Dokumen PDF',
                                              onPressed: () async {
                                                final uri = Uri.parse(m.fileUrl!);
                                                if (await canLaunchUrl(uri)) {
                                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                }
                                              },
                                            ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: m.status.toLowerCase() == 'aktif' ? Colors.green.shade100 : Colors.red.shade100,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              m.status,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: m.status.toLowerCase() == 'aktif' ? Colors.green.shade800 : Colors.red.shade800,
                                              ),
                                            ),
                                          ),
                                          if (_canManageMou) ...[
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                                              tooltip: 'Edit MoU',
                                              onPressed: () => _showFormDialog(m),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                              tooltip: 'Hapus MoU',
                                              onPressed: () async {
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: const Text('Hapus MoU'),
                                                    content: Text('Yakin ingin menghapus dokumen MoU "${m.judul}"?'),
                                                    actions: [
                                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                                                      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true && m.id != null) {
                                                  await _repo.deleteMou(m.id!);
                                                }
                                              },
                                            ),
                                          ],
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
}
