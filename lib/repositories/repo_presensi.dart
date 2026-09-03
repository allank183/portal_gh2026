import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/model_presensi.dart';

class PresensiRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _baseUrl = 'https://portalgh2026.mmakerapps.workers.dev';

  String _getTodayString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// 1. AMBIL PRESENSI AKTIF (Optimasi: Polling 30 Detik)
  /// Kita naikkan ke 30 detik agar hemat kuota request Cloudflare (Limit 100k/hari).
  Stream<PresensiModel?> getPresensiAktifStream(String uid) async* {
    while (true) {
      try {
        final response = await http.get(Uri.parse('$_baseUrl/presensi-aktif?uid=$uid'));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          yield (data != null) ? PresensiModel.fromJson(data) : null;
        }
      } catch (e) {
        debugPrint('Error fetch aktif: $e');
        yield null;
      }
      await Future.delayed(const Duration(seconds: 30)); // <--- Jeda lebih lama
    }
  }

  /// 2. REKAM MASUK (KE CLOUDFLARE D1)
  Future<void> rekamMasuk({
    required String uid,
    required String nip,
    required String namaPegawai,
    required String jadwalKerja,
    String? tipeShift,
    String? catatan,
    String? fotoUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/rekam-masuk'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'uid': uid,
        'nip': nip,
        'nama_pegawai': namaPegawai,
        'tanggal': _getTodayString(),
        'jadwal_kerja': jadwalKerja,
        'tipe_shift': tipeShift,
        'catat_masuk': catatan,
        'foto_masuk_url': fotoUrl,
      }),
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Gagal rekam masuk');
    }
  }

  /// 3. REKAM PULANG (KE CLOUDFLARE D1)
  Future<void> rekamPulang({
    required String docId, // ID Integer dari D1, dinamakan docId agar kompatibel dengan UI
    String? catatan,
    String? fotoUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/rekam-pulang'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': docId,
        'catat_pulang': catatan,
        'foto_pulang_url': fotoUrl,
      }),
    );

    if (response.statusCode != 200) throw Exception('Gagal rekam pulang');
  }

  /// 4. AMBIL RIWAYAT PRESENSI (DARI D1)
  Stream<List<PresensiModel>> getRiwayatPresensiStream(String uid) async* {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/riwayat-presensi?uid=$uid'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        yield data.map<PresensiModel>((json) => PresensiModel.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error riwayat: $e');
      yield [];
    }
  }

  /// Menghitung status, keterlambatan, dan target jam pulang berdasarkan aturan kerja
  Map<String, dynamic> kalkulasiStatusMasuk({
    required DateTime waktuMasuk,
    required String jadwalKerja, // 'Reguler' atau 'Shift'
    String? tipeShift,           // 'Pagi', 'Siang', atau 'Malam'
  }) {
    DateTime jamJadwalMasuk;
    DateTime jamJadwalPulang;
    DateTime batasToleransi;

    int dayOfWeek = waktuMasuk.weekday; // 1 = Senin, ..., 5 = Jumat

    if (jadwalKerja == 'Reguler') {
      // Reguler: Masuk 07:30, Toleransi s.d 08:00
      jamJadwalMasuk = DateTime(waktuMasuk.year, waktuMasuk.month, waktuMasuk.day, 7, 30);
      batasToleransi = DateTime(waktuMasuk.year, waktuMasuk.month, waktuMasuk.day, 8, 0);

      // Pulang: Jumat 16:30, Senin-Kamis 16:00
      int menitPulangStd = (dayOfWeek == DateTime.friday) ? 30 : 0;
      jamJadwalPulang = DateTime(waktuMasuk.year, waktuMasuk.month, waktuMasuk.day, 16, menitPulangStd);
    } else {
      // Mode Shift
      if (tipeShift == 'Siang') {
        jamJadwalMasuk = DateTime(waktuMasuk.year, waktuMasuk.month, waktuMasuk.day, 14, 0);
        batasToleransi = DateTime(waktuMasuk.year, waktuMasuk.month, waktuMasuk.day, 14, 30);
        jamJadwalPulang = DateTime(waktuMasuk.year, waktuMasuk.month, waktuMasuk.day, 21, 0);
      } else if (tipeShift == 'Malam') {
        jamJadwalMasuk = DateTime(waktuMasuk.year, waktuMasuk.month, waktuMasuk.day, 21, 0);
        batasToleransi = DateTime(waktuMasuk.year, waktuMasuk.month, waktuMasuk.day, 21, 30);
        // Shift Malam pulang H+1 jam 07:30
        jamJadwalPulang = DateTime(waktuMasuk.year, waktuMasuk.month, waktuMasuk.day + 1, 7, 30);
      } else {
        // Shift Pagi (Default)
        jamJadwalMasuk = DateTime(waktuMasuk.year, waktuMasuk.month, waktuMasuk.day, 7, 30);
        batasToleransi = DateTime(waktuMasuk.year, waktuMasuk.month, waktuMasuk.day, 8, 0);
        jamJadwalPulang = DateTime(waktuMasuk.year, waktuMasuk.month, waktuMasuk.day, 14, 0);
      }
    }

    String status = 'Tepat Waktu';
    int menitTerlambat = 0;
    int menitWajibGanti = 0;
    DateTime targetJamPulang = jamJadwalPulang;

    if (waktuMasuk.isAfter(batasToleransi)) {
      // Masuk > batas toleransi (Terlambat total dari jamJadwalMasuk)
      status = 'Terlambat';
      menitTerlambat = waktuMasuk.difference(jamJadwalMasuk).inMinutes;
    } else if (waktuMasuk.isAfter(jamJadwalMasuk)) {
      // Masuk di rentang toleransi (Wajib mengganti menit kekurangan saat pulang)
      menitWajibGanti = waktuMasuk.difference(jamJadwalMasuk).inMinutes;
      targetJamPulang = jamJadwalPulang.add(Duration(minutes: menitWajibGanti));
    }

    return {
      'status': status,
      'menitTerlambat': menitTerlambat,
      'menitWajibGanti': menitWajibGanti,
      'targetJamPulang': targetJamPulang,
    };
  }

  // Kirim Pengajuan Izin/Cuti/Sakit (Update Jalan Tengah)
  Future<void> kirimPengajuanIzin({
    required String uid,
    required String namaPegawai,
    required String nip,
    required String jenisIzin,
    required String alasan,
    String? lampiranUrl,
  }) async {
    String today = _getTodayString();

    // 1. Simpan ke koleksi pengajuan_izin
    final docRef = await _db.collection('pengajuan_izin').add({
      'uid': uid,
      'nama_pegawai': namaPegawai,
      'nip': nip,
      'jenis_izin': jenisIzin,
      'alasan': alasan,
      'status': 'Pending',
      'lampiran_url': lampiranUrl,
      'tanggal_pengajuan': Timestamp.fromDate(DateTime.now()),
      'created_at': FieldValue.serverTimestamp(),
    });

    // 2. Simpan paralel ke koleksi presensi agar LANGSUNG MUNCUL di riwayat pegawai
    await _db.collection('presensi').add({
      'uid': uid,
      'nip': nip,
      'nama_pegawai': namaPegawai,
      'tanggal': today,
      'jam_masuk': null,
      'jam_pulang': null,
      'status': '$jenisIzin (Pending)', // Contoh: 'Sakit (Pending)' atau 'Izin (Pending)'
      'pengajuan_id': docRef.id,        // ID referensi pengajuan untuk di-update Admin
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Stream Riwayat Presensi
  // Dipindahkan ke versi D1
  /*
  Stream<List<PresensiModel>> getRiwayatPresensiStream(String uid) {
    ...
  }
  */

  Future<void> jalankanMigrasiPresensiKeCloudflare() async {
    try {
      debugPrint('Memulai Migrasi Presensi & Izin...');

      // Ambil Data Izin
      final snapIzin = await _db.collection('pengajuan_izin').get();
      final listIzin = snapIzin.docs.map((doc) => {
        'id': doc.id,
        'uid': doc['uid'],
        'nama_pegawai': doc['nama_pegawai'],
        'nip': doc['nip'],
        'jenis_izin': doc['jenis_izin'],
        'alasan': doc['alasan'],
        'status': doc['status'],
        'lampiran_url': doc['lampiran_url'],
        'tanggal_pengajuan': (doc['tanggal_pengajuan'] as Timestamp).toDate().toIso8601String(),
      }).toList();

      // Ambil Data Presensi
      final snapPresensi = await _db.collection('presensi').get();
      final listPresensi = snapPresensi.docs.map((doc) {
        final d = doc.data();
        return {
          'uid': d['uid'],
          'nip': d['nip'],
          'nama_pegawai': d['nama_pegawai'],
          'tanggal': d['tanggal'],
          'jam_masuk': d['jam_masuk'] != null ? (d['jam_masuk'] as Timestamp).toDate().toIso8601String() : null,
          'jam_pulang': d['jam_pulang'] != null ? (d['jam_pulang'] as Timestamp).toDate().toIso8601String() : null,
          'status': d['status'],
          'jadwal_kerja': d['jadwal_kerja'] ?? 'Reguler',
          'tipe_shift': d['tipe_shift'],
          'menit_terlambat': d['menit_terlambat'] ?? 0,
          'menit_wajib_ganti': d['menit_wajib_ganti'] ?? 0,
          'target_jam_pulang': d['target_jam_pulang'] != null ? (d['target_jam_pulang'] as Timestamp).toDate().toIso8601String() : null,
          'catat_masuk': d['catat_masuk'],
          'catat_pulang': d['catat_pulang'],
          'pengajuan_id': d['pengajuan_id'],
          'catatan_penolakan': d['catatan_penolakan'],
        };
      }).toList();

      // Kirim Gabungan ke Worker
      final response = await http.post(
        Uri.parse('https://portalgh2026.mmakerapps.workers.dev/sync-presensi-izin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'listIzin': listIzin, 'listPresensi': listPresensi}),
      );

      if (response.statusCode == 200) {
        debugPrint('MIGRASI PRESENSI & IZIN BERHASIL!');
      }
    } catch (e) {
      debugPrint('Error Migrasi Presensi: $e');
    }
  }


}