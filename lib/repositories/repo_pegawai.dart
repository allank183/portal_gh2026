import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/model_pegawai.dart';

class PegawaiRepository {

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
      debugPrint('Memanggil D1: $_baseUrl/pegawai/all');
      final response = await http.get(Uri.parse('$_baseUrl/pegawai/all'));

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);

        // Pastikan data yang diterima adalah List
        if (decodedData is List) {
          debugPrint('Data D1 diterima: ${decodedData.length} pegawai');
          return decodedData.map((json) {
            // Kita gunakan docId dari field 'uid' yang ada di JSON SQL
            return PegawaiModel.fromFirestore(json as Map<String, dynamic>, json['uid'] ?? '');
          }).toList();
        } else {
          debugPrint('Data D1 bukan List: $decodedData');
          return [];
        }
      } else {
        debugPrint('D1 Error Status: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error getAllPegawai D1: $e');
      return [];
    }
  }

  /// 4. UPDATE DATA PEGAWAI (KE D1)
  Future<void> updatePegawai(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/pegawai/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) throw Exception('Gagal update data di D1');
  }

  /// 5. HAPUS PEGAWAI (DARI D1)
  Future<void> deletePegawai(String uid) async {
    final response = await http.get(Uri.parse('$_baseUrl/pegawai/delete?uid=$uid'));
    if (response.statusCode != 200) throw Exception('Gagal hapus data di D1');
  }

  /// Mencari pegawai di D1 (Hanya ambil yang dicari, bukan semua!)
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

}