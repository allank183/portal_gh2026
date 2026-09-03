import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/model_pegawai.dart';
import 'dart:convert'; // Tambahkan ini
import 'package:http/http.dart' as http; // Tambahkan ini

class PegawaiRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Ambil Data Pegawai yang Sedang Login (Future)
  Future<PegawaiModel?> getCurrentPegawai() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // Cari dokumen berdasarkan UID Auth terlebih dahulu
      var doc = await _firestore.collection('pegawai').doc(user.uid).get();

      // Fallback: Jika ID dokumen bukan UID (misal search via email)
      if (!doc.exists && user.email != null) {
        final query = await _firestore
            .collection('pegawai')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          doc = query.docs.first;
        }
      }

      if (doc.exists && doc.data() != null) {
        return PegawaiModel.fromFirestore(doc.data()!, doc.id);
      }
    } catch (e) {
      debugPrint('Error PegawaiRepository.getCurrentPegawai: $e');
    }
    return null;
  }

  // 2. Stream Data Pegawai (Realtime Update dengan Fallback Email)
  Stream<PegawaiModel?> streamCurrentPegawai() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    // Stream berbasis email agar lebih aman jika ID dokumen != user.uid
    return _firestore
        .collection('pegawai')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return PegawaiModel.fromFirestore(doc.data(), doc.id);
      }
      return null;
    });
  }

  // 3. Ambil Semua Data Pegawai (Untuk Admin / List Pegawai)
  Future<List<PegawaiModel>> getAllPegawai() async {
    try {
      final snapshot = await _firestore.collection('pegawai').get();
      return snapshot.docs
          .map((doc) => PegawaiModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error PegawaiRepository.getAllPegawai: $e');
      return [];
    }
  }
  // --- FUNGSI MIGRASI KE CLOUDFLARE D1 ---
  Future<void> jalankanMigrasiKeCloudflare() async {
    try {
      debugPrint('Memulai Migrasi Data Pegawai...');

      // 1. Ambil semua data dari Firestore
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

      debugPrint('Data ditemukan: ${listData.length} pegawai. Mengirim ke Worker...');

      // 2. Kirim ke Worker Baru
      final response = await http.post(
        Uri.parse('https://portalgh2026.mmakerapps.workers.dev/sync-pegawai'),
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