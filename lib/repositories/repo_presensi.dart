import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/model_presensi.dart';
import '../services/service_trigger.dart';

class PresensiRepository {
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  String _getTodayString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// 1. AMBIL PRESENSI AKTIF (DIPANGGIL SEKALI)
  Future<PresensiModel?> getPresensiAktif(String uid) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/presensi-aktif?uid=$uid'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data != null) ? PresensiModel.fromJson(data) : null;
      }
      return null;
    } catch (e) {
      debugPrint('Error PresensiRepository.getPresensiAktif: $e');
      return null;
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
      try {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? 'Gagal rekam masuk');
      } catch (_) {
        throw Exception('Gagal rekam masuk (Server Error ${response.statusCode})');
      }
    }

    // Pemicu Update UI
    refreshTrigger.notifyPresensiUpdate();
  }

  /// 3. REKAM PULANG (KE CLOUDFLARE D1)
  Future<void> rekamPulang({
    required String docId,
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

    if (response.statusCode != 200) {
      throw Exception('Gagal rekam pulang (Server Error ${response.statusCode})');
    }

    // Pemicu Update UI
    refreshTrigger.notifyPresensiUpdate();
  }

  /// 4. AMBIL RIWAYAT PRESENSI (DIPANGGIL SEKALI)
  Future<List<PresensiModel>> getRiwayatPresensi(String uid) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/riwayat-presensi?uid=$uid'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map<PresensiModel>((json) => PresensiModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error PresensiRepository.getRiwayatPresensi: $e');
      return [];
    }
  }

  /// Menghitung status, keterlambatan, dan target jam pulang berdasarkan aturan kerja
  Map<String, dynamic> kalkulasiStatusMasuk({
    required DateTime waktuMasuk,
    required String jadwalKerja,
    String? tipeShift,
  }) {
    DateTime jamJadwalMasuk;
    DateTime jamJadwalPulang;
    DateTime batasToleransi;

    int dayOfWeek = waktuMasuk.weekday;

    if (jadwalKerja == 'Reguler') {
      jamJadwalMasuk = DateTime(waktuMasuk.year, waktuMasuk.month, waktuMasuk.day, 7, 30);
      batasToleransi = DateTime(waktuMasuk.year, waktuMasuk.month, waktuMasuk.day, 8, 0);

      int menitPulangStd = (dayOfWeek == DateTime.friday) ? 30 : 0;
      jamJadwalPulang = DateTime(waktuMasuk.year, waktuMasuk.month, waktuMasuk.day, 16, menitPulangStd);
    } else {
      if (tipeShift == 'Siang') {
        jamJadwalMasuk = DateTime(waktuMasuk.year, waktuMasuk.month, waktuMasuk.day, 14, 0);
        batasToleransi = DateTime(waktuMasuk.year, waktuMasuk.month, waktuMasuk.day, 14, 30);
        jamJadwalPulang = DateTime(waktuMasuk.year, waktuMasuk.month, waktuMasuk.day, 21, 0);
      } else if (tipeShift == 'Malam') {
        jamJadwalMasuk = DateTime(waktuMasuk.year, waktuMasuk.month, waktuMasuk.day, 21, 0);
        batasToleransi = DateTime(waktuMasuk.year, waktuMasuk.month, waktuMasuk.day, 21, 30);
        jamJadwalPulang = DateTime(waktuMasuk.year, waktuMasuk.month, waktuMasuk.day + 1, 7, 30);
      } else {
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
      status = 'Terlambat';
      menitTerlambat = waktuMasuk.difference(jamJadwalMasuk).inMinutes;
    } else if (waktuMasuk.isAfter(jamJadwalMasuk)) {
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

  /// Kirim Pengajuan Izin/Cuti/Sakit
  Future<void> kirimPengajuanIzin({
    required String uid,
    required String namaPegawai,
    required String nip,
    required String jenisIzin,
    required String alasan,
    String? lampiranUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pengajuan-izin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'nama_pegawai': namaPegawai,
          'nip': nip,
          'jenis_izin': jenisIzin,
          'alasan': alasan,
          'lampiran_url': lampiranUrl,
          'tanggal': _getTodayString(),
        }),
      );

      if (response.statusCode != 200) throw Exception('Gagal mengajukan izin ke D1');

      // Pemicu Update UI
      refreshTrigger.notifyPresensiUpdate();
    } catch (e) {
      debugPrint('Error PresensiRepository.kirimPengajuanIzin: $e');
      rethrow;
    }
  }
}
