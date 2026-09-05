import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/premium_header.dart';

class ScreenVerifikasiPresensi extends StatefulWidget {
  const ScreenVerifikasiPresensi({super.key});

  @override
  State<ScreenVerifikasiPresensi> createState() => _ScreenVerifikasiPresensiState();
}

class _ScreenVerifikasiPresensiState extends State<ScreenVerifikasiPresensi> {
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  List<dynamic> _listPengajuan = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPengajuanIzin();
  }

  // --- 1. MEMUAT DATA DARI CLOUDFLARE WORKER D1 ---
  Future<void> _fetchPengajuanIzin() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$_baseUrl/pengajuan-izin/list'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _listPengajuan = data;
          _isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat data');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error memuat data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- 2. UPDATE STATUS PENGAJUAN VIA CLOUDFLARE WORKER ---
  Future<void> _updateStatusPengajuan({
    required String pengajuanId,
    required String statusBaru, // 'Disetujui' atau 'Ditolak'
    required String jenisIzin,
    String? catatanPenolakan,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pengajuan-izin/update-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pengajuan_id': pengajuanId,
          'status': statusBaru,
          'jenis_izin': jenisIzin,
          'catatan_penolakan': catatanPenolakan,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pengajuan berhasil di-$statusBaru'),
              backgroundColor: statusBaru == 'Disetujui' ? Colors.green : Colors.red,
            ),
          );
        }
        // Refresh daftar data
        _fetchPengajuanIzin();
      } else {
        throw Exception('Server mengembalikan error');
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
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _listPengajuan.isEmpty
                      ? Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('Belum ada pengajuan izin.')),
                    ),
                  )
                      : Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _listPengajuan.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, index) {
                          final data = _listPengajuan[index] as Map<String, dynamic>;
                          final String docId = data['id'] ?? '';

                          String nama = data['nama_pegawai'] ?? '-';
                          String nip = data['nip'] ?? '-';
                          String jenis = data['jenis_izin'] ?? '-';
                          String alasan = data['alasan'] ?? '-';
                          String status = data['status'] ?? 'Pending';
                          String? catatan = data['catatan_penolakan'];
                          String? lampiranUrl = data['lampiran_url'];
                          String? createdAtStr = data['tanggal_pengajuan'];

                          String tgl = '-';
                          if (createdAtStr != null && createdAtStr.isNotEmpty) {
                            try {
                              DateTime dt = DateTime.parse(createdAtStr);
                              tgl = DateFormat('dd MMM yyyy, HH:mm').format(dt);
                            } catch (_) {
                              tgl = createdAtStr;
                            }
                          }

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