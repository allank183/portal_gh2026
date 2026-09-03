import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class StorageService {
  late final String _workerUrl;

  StorageService() {
    _workerUrl = dotenv.env['R2_WORKER_URL'] ?? '';
  }

  /// Upload File Sertifikat PDF ke Cloudflare R2 via Worker
  Future<String> uploadSertifikatFile({
    required Uint8List bytes,
    required String fileName,
    required String nip,
  }) async {
    return _uploadToR2(
      bytes: bytes,
      fileName: fileName,
      nip: nip,
      contentType: 'application/pdf',
      folderPrefix: 'sertifikat',
    );
  }

  /// Upload Foto Presensi Masuk / Pulang (JPG/PNG)
  Future<String> uploadFotoPresensi({
    required Uint8List bytes,
    required String fileName,
    required String nip,
  }) async {
    return _uploadToR2(
      bytes: bytes,
      fileName: fileName,
      nip: nip,
      contentType: 'image/jpeg',
      folderPrefix: 'presensi_foto',
    );
  }

  /// Upload Dokumen Pendukung Izin/Sakit/Cuti (PDF/JPG)
  Future<String> uploadDokumenIzin({
    required Uint8List bytes,
    required String fileName,
    required String nip,
    required String contentType, // 'application/pdf' atau 'image/jpeg'
  }) async {
    return _uploadToR2(
      bytes: bytes,
      fileName: fileName,
      nip: nip,
      contentType: contentType,
      folderPrefix: 'dokumen_izin',
    );
  }

  /// Core Helper Upload ke Cloudflare Worker
  Future<String> _uploadToR2({
    required Uint8List bytes,
    required String fileName,
    required String nip,
    required String contentType,
    required String folderPrefix,
  }) async {
    try {
      final safeFileName = fileName
          .replaceAll(RegExp(r'[^\x00-\x7F]'), '_')
          .replaceAll(RegExp(r'\s+'), '_');

      // Sertakan prefix folder di nama file agar R2 menyimpannya dengan rapi
      final fullPath = '${folderPrefix}_$safeFileName';

      final response = await http.post(
        Uri.parse(_workerUrl),
        headers: {
          'Content-Type': contentType,
          'X-File-Name': fullPath,
          'X-NIP': nip,
        },
        body: bytes,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'] as String;
      } else {
        throw Exception('Worker error HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal mengunggah file ke Cloudflare R2: $e');
    }
  }
}