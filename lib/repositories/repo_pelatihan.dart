import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/model_pelatihan.dart';

class PelatihanRepository {
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  /// 1. AMBIL RIWAYAT (No Polling - Future Only)
  Future<List<PelatihanModel>> getRiwayatFuture({String? uid, String? nip}) async {
    try {
      final query = uid != null ? 'uid=$uid' : 'nip=$nip';
      final response = await http.get(Uri.parse('$_baseUrl/pelatihan/riwayat?$query'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PelatihanModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error PelatihanRepository.getRiwayatFuture: $e');
    }
    return [];
  }

  /// 2. AMBIL ANTREAN PENDING (No Polling - Future Only)
  Future<List<PelatihanModel>> getPendingPelatihanFuture() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/pelatihan/pending'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PelatihanModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error PelatihanRepository.getPendingPelatihanFuture: $e');
    }
    return [];
  }

  /// 3. CEK DUPLIKASI NOMOR SERTIFIKAT
  Future<bool> isSertifikatExists(String nomorSertifikat) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/pelatihan/check-nomor?nomor=$nomorSertifikat'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] ?? false;
      }
    } catch (e) {
      debugPrint('Error isSertifikatExists: $e');
    }
    return false;
  }

  /// 4. CEK KOMBINASI DUPLIKAT (NIP + JUDUL + TAHUN)
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
    } catch (e) {
      debugPrint('Error isKombinasiExists: $e');
    }
    return false;
  }

  /// 5. RECALCULATE STATS (HITUNG ULANG JPL PEGAWAI DI D1)
  Future<void> recalculatePegawaiStats({required String uid, required String nip}) async {
    try {
      await http.get(Uri.parse('$_baseUrl/pegawai/recalculate?uid=$uid'));
    } catch (e) {
      debugPrint('Error recalculatePegawaiStats: $e');
    }
  }

  /// 6. SIMPAN SERTIFIKAT BARU (KE D1)
  Future<void> simpanSertifikat(PelatihanModel pelatihan) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pelatihan/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(pelatihan.toMap()),
      );
      if (response.statusCode != 200) throw Exception('Gagal simpan ke D1: ${response.body}');
    } catch (e) {
      debugPrint('Error simpanSertifikat: $e');
      rethrow;
    }
  }

  /// 7. APPROVE SERTIFIKAT (KE D1)
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
      if (response.statusCode != 200) throw Exception('Gagal approve di D1: ${response.body}');
    } catch (e) {
      debugPrint('Error approveSertifikat: $e');
      rethrow;
    }
  }

  /// 8. REJECT SERTIFIKAT (KE D1)
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
      if (response.statusCode != 200) throw Exception('Gagal reject di D1: ${response.body}');
    } catch (e) {
      debugPrint('Error rejectSertifikat: $e');
      rethrow;
    }
  }

  // --- STREAM FUNCTIONS DIHAPUS UNTUK EFISIENSI KUOTA ---
}
