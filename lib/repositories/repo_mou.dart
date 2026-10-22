import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/model_mou.dart';
import '../services/service_storage.dart';
import '../services/service_trigger.dart';

class MouRepository {
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  Future<List<MouModel>> getAllMou() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/mou/all'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => MouModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error MouRepository.getAllMou: $e');
    }
    return [];
  }

  Future<void> addMou(MouModel mou, {Uint8List? fileBytes, String? fileName}) async {
    String? fileUrl = mou.fileUrl;
    
    if (fileBytes != null && fileName != null) {
      fileUrl = await StorageService().uploadDokumenIzin(
        bytes: fileBytes,
        fileName: fileName,
        nip: 'mou_${DateTime.now().millisecondsSinceEpoch}',
        contentType: 'application/pdf',
      );
    }

    final newMou = MouModel(
      id: mou.id,
      nomorMou: mou.nomorMou,
      judul: mou.judul,
      mitra: mou.mitra,
      kategori: mou.kategori,
      tanggalMulai: mou.tanggalMulai,
      tanggalSelesai: mou.tanggalSelesai,
      fileUrl: fileUrl,
      status: mou.status,
      catatan: mou.catatan,
    );

    final response = await http.post(
      Uri.parse('$_baseUrl/mou/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(newMou.toMap()),
    );

    if (response.statusCode != 200) throw Exception('Gagal menambah data MoU');

    refreshTrigger.notifyMahasiswaUpdate();
  }

  Future<void> updateMou(MouModel mou, {Uint8List? fileBytes, String? fileName}) async {
    String? fileUrl = mou.fileUrl;
    
    if (fileBytes != null && fileName != null) {
      fileUrl = await StorageService().uploadDokumenIzin(
        bytes: fileBytes,
        fileName: fileName,
        nip: 'mou_${DateTime.now().millisecondsSinceEpoch}',
        contentType: 'application/pdf',
      );
    }

    final updatedMou = MouModel(
      id: mou.id,
      nomorMou: mou.nomorMou,
      judul: mou.judul,
      mitra: mou.mitra,
      kategori: mou.kategori,
      tanggalMulai: mou.tanggalMulai,
      tanggalSelesai: mou.tanggalSelesai,
      fileUrl: fileUrl,
      status: mou.status,
      catatan: mou.catatan,
    );

    final response = await http.post(
      Uri.parse('$_baseUrl/mou/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updatedMou.toMap()),
    );

    if (response.statusCode != 200) throw Exception('Gagal memperbarui data MoU');

    refreshTrigger.notifyMahasiswaUpdate();
  }

  Future<void> deleteMou(int id) async {
    final response = await http.get(Uri.parse('$_baseUrl/mou/delete?id=$id'));
    if (response.statusCode != 200) throw Exception('Gagal menghapus data MoU');

    refreshTrigger.notifyMahasiswaUpdate();
  }
}
