import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/model_pegawai.dart';
import '../../models/model_presensi.dart';
import '../../services/service_location.dart';
import '../../repositories/repo_pegawai.dart';
import '../../repositories/repo_presensi.dart';
import '../../services/service_storage.dart';
import '../../widgets/premium_header.dart';

class ScreenPresensi extends StatefulWidget {
  const ScreenPresensi({super.key});

  @override
  State<ScreenPresensi> createState() => _ScreenPresensiState();
}

class _ScreenPresensiState extends State<ScreenPresensi> {
  final PresensiRepository _presensiRepository = PresensiRepository();
  final PegawaiRepository _pegawaiRepository = PegawaiRepository();
  final ServiceLocation _serviceLocation = ServiceLocation();

  PegawaiModel? _currentUser;
  bool _isLoadingUser = true;
  bool _isSubmitting = false;

  String? _selectedShift;

  // Cache Stream agar tidak membuat koneksi baru saat rebuild (Mencegah Request Storm)
  late Stream<PresensiModel?> _presensiAktifStream;
  late Stream<List<PresensiModel>> _riwayatPresensiStream;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Inisialisasi stream hanya sekali di awal
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _presensiAktifStream = _presensiRepository.getPresensiAktifStream(user.uid);
      _riwayatPresensiStream = _presensiRepository.getRiwayatPresensiStream(user.uid);
    }
  }

  Future<void> _loadUserData() async {
    final pegawai = await _pegawaiRepository.getCurrentPegawai();
    if (mounted) {
      setState(() {
        _currentUser = pegawai;
        _isLoadingUser = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Pengguna tidak ditemukan.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      body: Column(
        children: [
          const PremiumHeader(
            title: 'Presensi Pegawai',
            subtitle: 'Rekam Hadir Masuk & Pulang Kerja Real-time',
            borderRadius: BorderRadius.zero,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPresensiHariIniCard(),
                      const SizedBox(height: 24),
                      Text(
                        'Riwayat Presensi Anda',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildRiwayatPresensiTable(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresensiHariIniCard() {
    bool isShiftUser = _currentUser?.jadwalKerja == 'Shift';

    return StreamBuilder<PresensiModel?>(
      stream: _presensiAktifStream, // Menggunakan cache variabel
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final presensi = snapshot.data;
        String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        bool isToday = presensi?.tanggal == todayStr;
        bool isShiftMalamAktif = presensi != null &&
            presensi.tipeShift == 'Malam' &&
            presensi.jamPulang == null;

        // Logika status masuk hari ini
        bool sudahMasuk = presensi != null && (isToday || isShiftMalamAktif);
        bool sudahPulang = sudahMasuk && presensi.jamPulang != null;

        String waktuMasukText = (sudahMasuk && presensi.jamMasuk != null)
            ? DateFormat('HH:mm:ss').format(presensi.jamMasuk!)
            : '-- : --';

        String waktuPulangText = (sudahMasuk && presensi.jamPulang != null)
            ? DateFormat('HH:mm:ss').format(presensi.jamPulang!)
            : '-- : --';

        bool canSubmitMasuk = !isShiftUser || _selectedShift != null;

        bool isIzinAtauSakit = sudahMasuk && (
            presensi.status.contains('Pending') ||
                presensi.status.contains('Izin') ||
                presensi.status.contains('Sakit') ||
                presensi.status.contains('Cuti') ||
                presensi.status.contains('Ditolak')
        );

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Presensi Hari Ini (${DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now())})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    if (sudahMasuk)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: presensi.status.contains('Ditolak')
                              ? Colors.red.shade100
                              : presensi.status == 'Terlambat'
                              ? Colors.orange.shade100
                              : isIzinAtauSakit
                              ? Colors.blue.shade100
                              : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          presensi.status,
                          style: GoogleFonts.plusJakartaSans(
                            color: presensi.status.contains('Ditolak')
                                ? Colors.red.shade900
                                : presensi.status == 'Terlambat'
                                ? Colors.orange.shade900
                                : isIzinAtauSakit
                                ? Colors.blue.shade900
                                : Colors.green.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const Divider(height: 32),

                if (!sudahMasuk && isShiftUser) ...[
                  Text(
                    'Pilih Shift Kerja Hari Ini:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Pagi', label: Text('Pagi\n07:30')),
                      ButtonSegment(value: 'Siang', label: Text('Siang\n14:00')),
                      ButtonSegment(value: 'Malam', label: Text('Malam\n21:00')),
                    ],
                    selected: _selectedShift != null ? {_selectedShift!} : {},
                    emptySelectionAllowed: true,
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _selectedShift = newSelection.isNotEmpty ? newSelection.first : null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                Row(
                  children: [
                    Expanded(
                      child: _buildTimeBox('Jam Masuk', waktuMasukText, Icons.login_rounded, Colors.green),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTimeBox('Jam Pulang', waktuPulangText, Icons.logout_rounded, Colors.redAccent),
                    ),
                  ],
                ),

                if (sudahMasuk && presensi.targetJamPulang != null && !isIzinAtauSakit) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      'Target Jam Pulang Minimal: ${DateFormat('HH:mm').format(presensi.targetJamPulang!)} WIB'
                          '${presensi.menitWajibGanti > 0 ? " (Termasuk ganti ${presensi.menitWajibGanti} menit)" : ""}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                if (sudahMasuk && presensi.status.contains('Ditolak') && presensi.catatanPenolakan != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catatan Penolakan:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          presensi.catatanPenolakan!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                Row(
                  children: [
                    if (!sudahMasuk) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (_isSubmitting || !canSubmitMasuk)
                              ? null
                              : () => _confirmAndSubmitMasuk(_currentUser!.uid, isShiftUser),
                          icon: _isSubmitting
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                              : const Icon(Icons.touch_app_rounded),
                          label: Text(
                            isShiftUser
                                ? (_selectedShift != null
                                ? 'REKAM PRESENSI (SHIFT $_selectedShift)'
                                : 'PILIH SHIFT TERLEBIH DAHULU')
                                : 'REKAM PRESENSI MASUK',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canSubmitMasuk ? const Color(0xFF2563EB) : Colors.grey.shade400,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _showDialogPengajuanIzin(_currentUser!.uid),
                        icon: const Icon(Icons.note_add_outlined, color: Color(0xFFD97706)),
                        label: Text(
                          'AJUKAN IZIN / NON-HADIR',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFD97706), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],

                    if (sudahMasuk && !sudahPulang && !isIzinAtauSakit)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting
                              ? null
                              : () => _confirmAndSubmitPulang(presensi.id.toString()),
                          icon: _isSubmitting
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                              : const Icon(Icons.exit_to_app_rounded),
                          label: Text(
                            'REKAM PRESENSI PULANG',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDialogPengajuanIzin(String uid) {
    String selectedJenis = 'Sakit';
    final alasanController = TextEditingController();

    Uint8List? selectedFileBytes;
    String? selectedFileName;
    String? selectedContentType;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Form Pengajuan Non-Hadir', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pilih Alasan Ketidakhadiran:', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedJenis,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Sakit', child: Text('Sakit')),
                        DropdownMenuItem(value: 'Izin', child: Text('Izin Alasan Penting')),
                        DropdownMenuItem(value: 'Cuti', child: Text('Cuti Tahunan')),
                        DropdownMenuItem(value: 'Dinas Luar', child: Text('Dinas Luar Kantor')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedJenis = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Keterangan / Alasan:', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: alasanController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Tuliskan alasan lengkap...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Lampiran Surat / Dokumen (Wajib):', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                          withData: true,
                        );

                        if (result != null && result.files.single.bytes != null) {
                          setDialogState(() {
                            selectedFileBytes = result.files.single.bytes;
                            selectedFileName = result.files.single.name;

                            String ext = result.files.single.extension?.toLowerCase() ?? '';
                            if (ext == 'pdf') {
                              selectedContentType = 'application/pdf';
                            } else if (ext == 'png') {
                              selectedContentType = 'image/png';
                            } else if (ext == 'jpg' || ext == 'jpeg') {
                              selectedContentType = 'image/jpeg';
                            } else {
                              selectedContentType = 'application/octet-stream';
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.attach_file),
                      label: Text(selectedFileName ?? 'Pilih File (PDF / Gambar)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                  onPressed: () async {
                    if (alasanController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Keterangan wajib diisi!')),
                      );
                      return;
                    }

                    if (selectedFileBytes == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Anda wajib melampirkan dokumen bukti (PDF/Gambar)!'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    final messenger = ScaffoldMessenger.of(context);

                    Navigator.pop(context);
                    setState(() => _isSubmitting = true);

                    try {
                      String? lampiranUrl;

                      if (selectedFileBytes != null && selectedFileName != null) {
                        final storageService = StorageService();
                        lampiranUrl = await storageService.uploadDokumenIzin(
                          bytes: selectedFileBytes!,
                          fileName: selectedFileName!,
                          nip: _currentUser?.nip ?? '0000',
                          contentType: selectedContentType ?? 'application/pdf',
                        );
                      }

                      await _presensiRepository.kirimPengajuanIzin(
                        uid: uid,
                        namaPegawai: _currentUser?.nama ?? '',
                        nip: _currentUser?.nip ?? '',
                        jenisIzin: selectedJenis,
                        alasan: alasanController.text.trim(),
                        lampiranUrl: lampiranUrl,
                      );

                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Pengajuan $selectedJenis berhasil dikirim!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Gagal mengirim pengajuan: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isSubmitting = false);
                      }
                    }
                  },
                  child: const Text('Kirim Pengajuan', style: TextStyle(color: Colors.white)),
                ),              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmAndSubmitMasuk(String uid, bool isShiftUser) async {
    String detailShift = isShiftUser ? ' (Shift $_selectedShift)' : '';

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Presensi Masuk', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin merekam presensi MASUK$detailShift sekarang?',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Masuk', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _handlePresensiMasuk(uid, isShiftUser);
    }
  }

  Future<void> _confirmAndSubmitPulang(String docId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Presensi Pulang', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin merekam presensi PULANG sekarang?',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Pulang', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _handlePresensiPulang(docId);
    }
  }

  Future<void> _handlePresensiMasuk(String uid, bool isShiftUser) async {
    setState(() => _isSubmitting = true);
    try {
      await _serviceLocation.getCurrentLocationAndValidate();
      await _presensiRepository.rekamMasuk(
        uid: uid,
        nip: _currentUser?.nip ?? '',
        namaPegawai: _currentUser?.nama ?? '',
        jadwalKerja: _currentUser?.jadwalKerja ?? 'Reguler',
        tipeShift: isShiftUser ? _selectedShift : null,
      );
      if (mounted) {
        setState(() {
          _selectedShift = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Presensi Masuk Berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal Presensi: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handlePresensiPulang(String docId) async {
    setState(() => _isSubmitting = true);
    try {
      await _serviceLocation.getCurrentLocationAndValidate();
      await _presensiRepository.rekamPulang(docId: docId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Presensi Pulang Berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal Presensi: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildTimeBox(String title, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatPresensiTable() {
    return StreamBuilder<List<PresensiModel>>(
      stream: _riwayatPresensiStream, // Menggunakan cache variabel
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final riwayatList = snapshot.data ?? [];

        if (riwayatList.isEmpty) {
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'Belum ada riwayat presensi.',
                  style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600),
                ),
              ),
            ),
          );
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                showCheckboxColumn: false,
                columns: const [
                  DataColumn(label: Text('Tanggal')),
                  DataColumn(label: Text('Jam Masuk')),
                  DataColumn(label: Text('Jam Pulang')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Aksi')),
                ],
                rows: riwayatList.map((p) {
                  String tglStr = '-';
                  if (p.jamMasuk != null) {
                    tglStr = DateFormat('dd MMM yyyy', 'id_ID').format(p.jamMasuk!);
                  } else if (p.tanggal.isNotEmpty) {
                    try {
                      DateTime dt = DateTime.parse(p.tanggal);
                      tglStr = DateFormat('dd MMM yyyy', 'id_ID').format(dt);
                    } catch (_) {
                      tglStr = p.tanggal;
                    }
                  } else if (p.createdAt != null) {
                    tglStr = DateFormat('dd MMM yyyy', 'id_ID').format(p.createdAt!);
                  }

                  String masukStr = p.jamMasuk != null
                      ? DateFormat('HH:mm').format(p.jamMasuk!)
                      : '-- : --';
                  String pulangStr = p.jamPulang != null
                      ? DateFormat('HH:mm').format(p.jamPulang!)
                      : '-- : --';

                  bool isDitolak = p.status.contains('Ditolak');

                  return DataRow(
                    onSelectChanged: (_) => _showDetailRiwayatDialog(p),
                    cells: [
                      DataCell(Text(tglStr)),
                      DataCell(Text(masukStr)),
                      DataCell(Text(pulangStr)),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDitolak
                                ? Colors.red.shade50
                                : p.status.contains('Pending')
                                ? Colors.orange.shade50
                                : p.status.contains('Sakit') || p.status.contains('Izin')
                                ? Colors.blue.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p.status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDitolak
                                  ? Colors.red.shade900
                                  : p.status.contains('Pending')
                                  ? Colors.orange.shade900
                                  : p.status.contains('Sakit') || p.status.contains('Izin')
                                  ? Colors.blue.shade900
                                  : Colors.green.shade900,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 20),
                          onPressed: () => _showDetailRiwayatDialog(p),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDetailRiwayatDialog(PresensiModel presensi) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Detail Presensi / Pengajuan',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Tanggal', presensi.tanggal.isNotEmpty ? presensi.tanggal : '-'),
            _buildDetailRow('Status', presensi.status),
            _buildDetailRow('Jam Masuk', presensi.jamMasuk != null ? DateFormat('HH:mm:ss').format(presensi.jamMasuk!) : '-'),
            _buildDetailRow('Jam Pulang', presensi.jamPulang != null ? DateFormat('HH:mm:ss').format(presensi.jamPulang!) : '-'),
            if (presensi.tipeShift != null) _buildDetailRow('Shift Kerja', presensi.tipeShift!),
            if (presensi.catatanPenolakan != null && presensi.catatanPenolakan!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Catatan Penolakan:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      presensi.catatanPenolakan!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (presensi.pengajuanId != null) ...[
              const Divider(height: 20),
              if (presensi.fotoMasukUrl != null && presensi.fotoMasukUrl!.isNotEmpty)
                InkWell(
                  onTap: () async {
                    Uri url = Uri.parse(presensi.fotoMasukUrl!);
                    if (await canLaunchUrl(url)) await launchUrl(url);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      '📎 Lihat Lampiran Dokumen',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
