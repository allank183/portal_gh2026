import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/premium_header.dart';

class ScreenVerifikasiPresensi extends StatefulWidget {
  const ScreenVerifikasiPresensi({super.key});

  @override
  State<ScreenVerifikasiPresensi> createState() => _ScreenVerifikasiPresensiState();
}

class _ScreenVerifikasiPresensiState extends State<ScreenVerifikasiPresensi> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> _updateStatusPengajuan({
    required String pengajuanId,
    required String statusBaru, // 'Disetujui' atau 'Ditolak'
    required String jenisIzin,
    String? catatanPenolakan,
  }) async {
    try {
      // 1. Update status di pengajuan_izin
      await _db.collection('pengajuan_izin').doc(pengajuanId).update({
        'status': statusBaru,
        'catatan_penolakan': catatanPenolakan,
        'approved_at': FieldValue.serverTimestamp(),
      });

      // 2. Update status & catatan di presensi
      final presensiQuery = await _db
          .collection('presensi')
          .where('pengajuan_id', isEqualTo: pengajuanId)
          .get();

      for (var doc in presensiQuery.docs) {
        if (statusBaru == 'Disetujui') {
          await doc.reference.update({
            'status': jenisIzin,
            'catatan_penolakan': FieldValue.delete(),
          });
        } else {
          await doc.reference.update({
            'status': 'Ditolak',
            'catatan_penolakan': catatanPenolakan,
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pengajuan berhasil di-$statusBaru'),
            backgroundColor: statusBaru == 'Disetujui' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showDialogPenolakan(String docId, String jenis) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Alasan Penolakan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tuliskan alasan penolakan pengajuan ini:', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Contoh: Surat dokter tidak melampirkan cap resmi.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alasan penolakan wajib diisi!')),
                );
                return;
              }
              Navigator.pop(context);
              _updateStatusPengajuan(
                pengajuanId: docId,
                statusBaru: 'Ditolak',
                jenisIzin: jenis,
                catatanPenolakan: controller.text.trim(),
              );
            },
            child: const Text('Konfirmasi Tolak', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      body: Column(
        children: [
          const PremiumHeader(
            title: 'Persetujuan Non-Hadir',
            subtitle: 'Verifikasi Pengajuan Izin / Sakit / Cuti Pegawai',
            borderRadius: BorderRadius.zero,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _db
                        .collection('pengajuan_izin')
                        .orderBy('created_at', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: Text('Belum ada pengajuan izin.')),
                          ),
                        );
                      }

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: docs.length,
                            separatorBuilder: (_, _) => const Divider(),
                            itemBuilder: (context, index) {
                              final data = docs[index].data() as Map<String, dynamic>;
                              final docId = docs[index].id;

                              String nama = data['nama_pegawai'] ?? '-';
                              String nip = data['nip'] ?? '-';
                              String jenis = data['jenis_izin'] ?? '-';
                              String alasan = data['alasan'] ?? '-';
                              String status = data['status'] ?? 'Pending';
                              String? catatan = data['catatan_penolakan'];
                              String? lampiranUrl = data['lampiran_url'];
                              Timestamp? createdAt = data['created_at'];

                              String tgl = createdAt != null
                                  ? DateFormat('dd MMM yyyy, HH:mm').format(createdAt.toDate())
                                  : '-';

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: status == 'Pending'
                                      ? Colors.orange.shade100
                                      : status == 'Disetujui'
                                      ? Colors.green.shade100
                                      : Colors.red.shade100,
                                  child: Icon(
                                    status == 'Pending'
                                        ? Icons.hourglass_top
                                        : status == 'Disetujui'
                                        ? Icons.check
                                        : Icons.close,
                                    color: status == 'Pending'
                                        ? Colors.orange.shade900
                                        : status == 'Disetujui'
                                        ? Colors.green.shade900
                                        : Colors.red.shade900,
                                  ),
                                ),
                                title: Text('$nama ($nip)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Jenis: $jenis | Tgl: $tgl'),
                                    Text('Alasan: $alasan', style: TextStyle(color: Colors.grey.shade700)),
                                    if (catatan != null && catatan.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          'Catatan Penolakan: $catatan',
                                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                                    if (lampiranUrl != null && lampiranUrl.isNotEmpty)
                                      InkWell(
                                        onTap: () async {
                                          Uri url = Uri.parse(lampiranUrl);
                                          if (await canLaunchUrl(url)) await launchUrl(url);
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 4.0),
                                          child: Text(
                                            '📎 Lihat Lampiran Surat',
                                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: status == 'Pending'
                                    ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                                      tooltip: 'Setujui',
                                      onPressed: () => _updateStatusPengajuan(
                                        pengajuanId: docId,
                                        statusBaru: 'Disetujui',
                                        jenisIzin: jenis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cancel, color: Colors.red, size: 28),
                                      tooltip: 'Tolak',
                                      onPressed: () => _showDialogPenolakan(docId, jenis),
                                    ),
                                  ],
                                )
                                    : Chip(
                                  label: Text(status),
                                  backgroundColor: status == 'Disetujui' ? Colors.green.shade50 : Colors.red.shade50,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}