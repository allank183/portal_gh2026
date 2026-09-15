import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/model_kampus.dart';
import '../models/model_tarif_mahasiswa.dart';
import '../services/service_trigger.dart';

class MahasiswaRepository {
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  // --- 1. MASTER KAMPUS ---
  Future<List<KampusModel>> getAllKampus() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/kampus/all'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => KampusModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error MahasiswaRepository.getAllKampus: $e');
    }
    return [];
  }

  Future<void> addKampus(KampusModel kampus) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/kampus/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(kampus.toMap()),
    );
    if (response.statusCode != 200) throw Exception('Gagal tambah data kampus');
    
    refreshTrigger.notifyMahasiswaUpdate();
  }

  Future<void> deleteKampus(int id) async {
    final response = await http.get(Uri.parse('$_baseUrl/kampus/delete?id=$id'));
    if (response.statusCode != 200) throw Exception('Gagal hapus data kampus');
    
    refreshTrigger.notifyMahasiswaUpdate();
  }

  // --- 2. MASTER TARIF ---
  Future<List<TarifMahasiswaModel>> getAllTarif() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/tarif-mahasiswa/all'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TarifMahasiswaModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error MahasiswaRepository.getAllTarif: $e');
    }
    return [];
  }

  Future<void> addTarif(TarifMahasiswaModel tarif) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/tarif-mahasiswa/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(tarif.toMap()),
    );
    if (response.statusCode != 200) throw Exception('Gagal tambah data tarif');
    
    refreshTrigger.notifyMahasiswaUpdate();
  }

  Future<void> updateTarif(TarifMahasiswaModel tarif) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/tarif-mahasiswa/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(tarif.toMap()),
    );
    if (response.statusCode != 200) throw Exception('Gagal update data tarif');
    
    refreshTrigger.notifyMahasiswaUpdate();
  }
}
