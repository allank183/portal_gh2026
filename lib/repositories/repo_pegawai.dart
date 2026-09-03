import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart'; // Wajib ada untuk migrasi
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/model_pegawai.dart';

class PegawaiRepository {
  // Tambahkan baris ini kembali agar fungsi migrasi bisa memanggil Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _baseUrl = 'https://portalgh2026.mmakerapps.workers.dev';

  /// 1. Ambil Data Pegawai Login (DARI CLOUDFLARE D1)
  Future<PegawaiModel?> getCurrentPegawai() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final response = await http.get(Uri.parse('$_baseUrl/pegawai?uid=${user.uid}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data != null ? PegawaiModel.fromFirestore(data, user.uid) : null;
      }
    } catch (e) {
      debugPrint('Error getCurrentPegawai D1: $e');
    }
    return null;
  }

  /// 2. Stream Data Pegawai (Polling D1)
  Stream<PegawaiModel?> streamCurrentPegawai() async* {
    while (true) {
      yield await getCurrentPegawai();
      await Future.delayed(const Duration(seconds: 60));
    }
  }

  /// 3. Ambil Semua Data Pegawai (DARI D1)
  Future<List<PegawaiModel>> getAllPegawai() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/pegawai/all'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PegawaiModel.fromFirestore(json, json['uid'])).toList();
      }
    } catch (e) {
      debugPrint('Error getAllPegawai D1: $e');
    }
    return [];
  }

  /// --- FUNGSI MIGRASI KE CLOUDFLARE D1 ---
  Future<void> jalankanMigrasiKeCloudflare() async {
    try {
      debugPrint('Memulai Migrasi Data Pegawai...');

      // Sekarang _firestore sudah dikenali karena sudah didefinisikan di atas
      final snapshot = await _firestore.collection('pegawai').get();

      final listData = snapshot.docs.map((doc) {
        final d = doc.data();
        return {
          'uid': doc.id,
          'nip': d['nip'] ?? '',
          'nama': d['nama'] ?? '',
          'email': d['email'] ?? '',
          'role': d['role'] ?? 'pegawai',
          'golongan': d['golongan'] ?? '',
          'instalasi': d['instalasi'] ?? '',
          'jenis_kelamin': d['jenis_kelamin'] ?? '',
          'kelompok': d['kelompok'] ?? '',
          'ruangan': d['ruangan'] ?? '',
          'status_kepegawaian': d['status_kepegawaian'] ?? '',
          'jadwal_kerja': d['jadwal_kerja'] ?? 'Reguler',
          'total_jpl': (d['total_jpl'] ?? 0).toDouble(),
          'total_sertifikat': (d['total_sertifikat'] ?? 0).toInt(),
          'total_skp': (d['total_skp'] ?? 0).toDouble(),
        };
      }).toList();

      final response = await http.post(
        Uri.parse('$_baseUrl/sync-pegawai'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(listData),
      );

      if (response.statusCode == 200) {
        debugPrint('MIGRASI BERHASIL: ${response.body}');
      } else {
        debugPrint('MIGRASI GAGAL: ${response.body}');
      }
    } catch (e) {
      debugPrint('ERROR SAAT MIGRASI: $e');
    }
  }
}