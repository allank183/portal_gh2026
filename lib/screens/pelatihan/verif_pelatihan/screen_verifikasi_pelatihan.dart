import 'package:flutter/material.dart';
import '../../../models/model_pelatihan.dart';
import '../../../repositories/repo_pelatihan.dart';
import '../../../services/service_trigger.dart';
import 'tabs/tab_preview_pdf.dart';
import 'tabs/tab_riwayat_pembanding.dart';

class ScreenVerifikasiPelatihan extends StatefulWidget {
  final String adminId;

  const ScreenVerifikasiPelatihan({super.key, required this.adminId});

  @override
  State<ScreenVerifikasiPelatihan> createState() =>
      _ScreenVerifikasiPelatihanState();
}

class _ScreenVerifikasiPelatihanState extends State<ScreenVerifikasiPelatihan> {
  final PelatihanRepository _pelatihanRepository = PelatihanRepository();
  String? _selectedPendingId;
  late Future<List<PelatihanModel>> _pendingFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Dengarkan lonceng: Jika ada data pelatihan berubah, muat ulang Future
    refreshTrigger.addListener(_loadData);
  }

  void _loadData() {
    if (mounted) {
      setState(() {
        _pendingFuture = _pelatihanRepository.getPendingPelatihanFuture();
      });
    }
  }

  @override
  void dispose() {
    refreshTrigger.removeListener(_loadData);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Sertifikat Pelatihan'),
        elevation: 1,
      ),
      body: FutureBuilder<List<PelatihanModel>>(
        future: _pendingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }

          final listPending = snapshot.data ?? [];

          if (listPending.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada antrean verifikasi sertifikat.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          PelatihanModel activeItem;
          final matchIndex = listPending.indexWhere((e) => e.id == _selectedPendingId);

          if (matchIndex != -1) {
            activeItem = listPending[matchIndex];
          } else {
            activeItem = listPending.first;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _selectedPendingId != activeItem.id) {
                setState(() {
                  _selectedPendingId = activeItem.id;
                });
              }
            });
          }

          return Row(
            children: [
              // PANEL KIRI: Daftar Antrean Pending
              Expanded(
                flex: 4,
                child: Card(
                  margin: const EdgeInsets.all(12),
                  child: ListView.separated(
                    itemCount: listPending.length,
                    separatorBuilder: (context, index) =>
                    const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = listPending[index];
                      final isSelected = activeItem.id == item.id;

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor:
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        title: Text(
                          item.judulPelatihan,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pegawai: ${item.namaPegawai} (${item.nip})'),
                            Text(
                              'No: ${item.nomorSertifikat} | JPL: ${item.jumlahJpl} | SKP: ${item.jumlahSkp}',
                            ),
                            if (item.isPossibleDuplicate) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.red.shade300),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Peringatan: No. sertifikat terdeteksi ganda!',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          setState(() {
                            _selectedPendingId = item.id;
                          });
                        },
                      );
                    },
                  ),
                ),
              ),

              // PANEL KANAN: Detail Verifikasi, Pembanding & PDF Preview
              Expanded(
                flex: 6,
                child: _buildDetailPanel(activeItem),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailPanel(PelatihanModel pending) {
    return Card(
      key: ValueKey(pending.id),
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pending.isPossibleDuplicate) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Peringatan: Nomor sertifikat terdeteksi ganda di sistem!',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Header Info & Aksi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pending.judulPelatihan,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text('Atas Nama: ${pending.namaPegawai} (${pending.nip})'),
                    ],
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      onPressed: () => _showRejectDialog(pending),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      onPressed: () => _approve(pending),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),

            // Tabs Pembanding & PDF Preview
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(
                            icon: Icon(Icons.picture_as_pdf),
                            text: 'Preview Dokumen PDF'),
                        Tab(
                            icon: Icon(Icons.compare_arrows),
                            text: 'Riwayat Approved (Pembanding)'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          TabPreviewPdf(fileUrl: pending.fileUrl),
                          TabRiwayatPembanding(nip: pending.nip),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(PelatihanModel pending) async {
    try {
      await _pelatihanRepository.approveSertifikat(
        pelatihan: pending,
        adminId: widget.adminId,
      );
      
      // Trigger Refresh Global
      refreshTrigger.notifyPelatihanUpdate();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sertifikat berhasil di-approve!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal approve: $e')),
        );
      }
    }
  }

  void _showRejectDialog(PelatihanModel pending) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Sertifikat'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Alasan Penolakan',
            hintText: 'Misal: Sertifikat buram / Nomor tidak sesuai / Sertifikat ganda',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (pending.id == null) return;
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);

              await _pelatihanRepository.rejectSertifikat(
                docIdSertifikat: pending.id!,
                adminId: widget.adminId,
                catatanAdmin: reasonController.text.isEmpty
                    ? 'Sertifikat tidak memenuhi syarat.'
                    : reasonController.text,
              );

              // Trigger Refresh Global
              refreshTrigger.notifyPelatihanUpdate();

              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(content: Text('Sertifikat berhasil ditolak.')),
              );
            },
            child: const Text('Tolak', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
