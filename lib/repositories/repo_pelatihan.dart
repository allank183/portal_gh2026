import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/model_pelatihan.dart';

class PelatihanRepository {
  final String _baseUrl = 'https://portalgh2026.mmakerapps.workers.dev';

  /// 1. AMBIL RIWAYAT BERDASARKAN UID ATAU NIP (Digunakan AI & Verifikasi)
  Stream<List<PelatihanModel>> getRiwayatByUidOrNip({String? uid, String? nip}) async* {
    while (true) {
      try {
        final query = uid != null ? 'uid=$uid' : 'nip=$nip';
        final response = await http.get(Uri.parse('$_baseUrl/pelatihan/riwayat?$query'));
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          yield data.map((json) => PelatihanModel.fromJson(json)).toList();
        }
      } catch (_) { yield []; }
      await Future.delayed(const Duration(seconds: 60));
    }
  }

  /// 2. CEK DUPLIKASI NOMOR SERTIFIKAT
  Future<bool> isSertifikatExists(String nomorSertifikat) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/pelatihan/check-nomor?nomor=$nomorSertifikat'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] ?? false;
      }
    } catch (_) {}
    return false;
  }

  /// 3. CEK KOMBINASI DUPLIKAT (NIP + JUDUL + TAHUN)
  Future<bool> isKombinasiExists({required String nip, required String judulPelatihan, required String tanggalAtauTahun}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pelatihan/check-kombinasi'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nip': nip, 'judul': judulPelatihan, 'tahun': tanggalAtauTahun}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] ?? false;
      }
    } catch (_) {}
    return false;
  }

  /// 4. RECALCULATE STATS (HITUNG ULANG JPL PEGAWAI DI D1)
  Future<void> recalculatePegawaiStats({required String uid, required String nip}) async {
    // Di SQL D1, kita cukup panggil endpoint yang menjalankan hitungan SUM secara otomatis
    await http.get(Uri.parse('$_baseUrl/pegawai/recalculate?uid=$uid'));
  }

  /// 1. SIMPAN SERTIFIKAT BARU (KE D1)
  Future<void> simpanSertifikat(PelatihanModel pelatihan) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pelatihan/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(pelatihan.toMap()),
      );
      if (response.statusCode != 200) throw Exception('Gagal simpan ke D1');
    } catch (e) {
      debugPrint('Error simpanSertifikat: $e');
      rethrow;
    }
  }

  /// 2. APPROVE SERTIFIKAT (KE D1)
  /// Fungsi ini akan memicu Worker untuk update status pelatihan DAN tambah JPL pegawai secara atomik
  Future<void> approveSertifikat({
    required PelatihanModel pelatihan,
    required String adminId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pelatihan/approve'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': pelatihan.id,
          'uid': pelatihan.uid,
          'jumlah_jpl': pelatihan.jumlahJpl,
          'jumlah_skp': pelatihan.jumlahSkp,
          'admin_id': adminId,
        }),
      );
      if (response.statusCode != 200) throw Exception('Gagal approve di D1');
    } catch (e) {
      debugPrint('Error approveSertifikat: $e');
      rethrow;
    }
  }

  /// 3. REJECT SERTIFIKAT (KE D1)
  Future<void> rejectSertifikat({
    required String docIdSertifikat,
    required String adminId,
    required String catatanAdmin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pelatihan/reject'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': docIdSertifikat,
          'admin_id': adminId,
          'catatan': catatanAdmin,
        }),
      );
      if (response.statusCode != 200) throw Exception('Gagal reject di D1');
    } catch (e) {
      debugPrint('Error rejectSertifikat: $e');
      rethrow;
    }
  }

  /// 4. AMBIL RIWAYAT PELATIH PELATIHAN (DARI D1)
  /// Menggantikan getRiwayatPelatihanPegawaiStream yang lama
  Stream<List<PelatihanModel>> getRiwayatPelatihanPegawaiStream(String nip) async* {
    while (true) {
      try {
        final response = await http.get(Uri.parse('$_baseUrl/pelatihan/riwayat?nip=$nip'));
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          yield data.map((json) => PelatihanModel.fromJson(json)).toList();
        }
      } catch (e) {
        debugPrint('Error fetch riwayat: $e');
        yield [];
      }
      // Polling setiap 60 detik agar hemat kuota
      await Future.delayed(const Duration(seconds: 60));
    }
  }

  /// 5. AMBIL ANTREAN PENDING (UNTUK ADMIN)
  Stream<List<PelatihanModel>> getPendingPelatihanStream() async* {
    while (true) {
      try {
        final response = await http.get(Uri.parse('$_baseUrl/pelatihan/pending'));
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          yield data.map((json) => PelatihanModel.fromJson(json)).toList();
        }
      } catch (_) { yield []; }
      await Future.delayed(const Duration(seconds: 60));
    }
  }
}