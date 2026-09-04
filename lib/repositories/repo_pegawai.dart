import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/model_pegawai.dart';

class PegawaiRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // PERBAIKAN: Gunakan domain worker yang benar
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
        final dynamic decodedData = jsonDecode(response.body);
        if (decodedData is List) {
          return decodedData.map((json) {
            return PegawaiModel.fromFirestore(json as Map<String, dynamic>, json['uid'] ?? '');
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Error getAllPegawai D1: $e');
    }
    return [];
  }

  /// 4. TAMBAH PEGAWAI BARU (KE D1) [BARU]
  Future<void> addPegawai(PegawaiModel pegawai) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/pegawai/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(pegawai.toMap()),
    );
    if (response.statusCode != 200) throw Exception('Gagal tambah data di D1');
  }

  /// 5. UPDATE DATA PEGAWAI (KE D1)
  Future<void> updatePegawai(dynamic data) async {
    Map<String, dynamic> payload;

    if (data is PegawaiModel) {
      payload = data.toMap();
    } else if (data is Map<String, dynamic>) {
      payload = data;
    } else if (data is Map) {
      payload = Map<String, dynamic>.from(data);
    } else {
      throw Exception('Tipe data tidak valid untuk updatePegawai');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/pegawai/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal update data di D1: ${response.body}');
    }
  }

  /// 6. HAPUS PEGAWAI (DARI D1)
  Future<void> deletePegawai(String uid) async {
    final response = await http.get(Uri.parse('$_baseUrl/pegawai/delete?uid=$uid'));
    if (response.statusCode != 200) throw Exception('Gagal hapus data di D1');
  }

  /// 7. CARI PEGAWAI DI D1
  Future<List<PegawaiModel>> searchPegawai(String query) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/pegawai/search?q=$query'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PegawaiModel.fromFirestore(json, json['uid'])).toList();
      }
    } catch (e) {
      debugPrint('Error searchPegawai: $e');
    }
    return [];
  }

  /// 8. CEK NIP SUDAH ADA (KE D1) [BARU]
  Future<bool> isNipExists(String nip) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/pegawai/check-nip?nip=$nip'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] ?? false;
      }
    } catch (e) {
      debugPrint('Error check-nip: $e');
    }
    return false;
  }
}