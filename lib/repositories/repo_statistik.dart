import 'dart:convert';
import 'package:http/http.dart' as http;

class DataStatistikPegawai {
  final int totalPegawai;
  final int totalLaki;
  final int totalPerempuan;
  final int totalMedis;
  final int totalNakes;
  final int totalAdmin;
  final int totalPns;
  final int totalP3k;
  final int totalBlu;
  final int totalCukup40Jpl;

  DataStatistikPegawai({
    required this.totalPegawai,
    required this.totalLaki,
    required this.totalPerempuan,
    required this.totalMedis,
    required this.totalNakes,
    required this.totalAdmin,
    required this.totalPns,
    required this.totalP3k,
    required this.totalBlu,
    required this.totalCukup40Jpl,
  });

  factory DataStatistikPegawai.fromJson(Map<String, dynamic> json) {
    return DataStatistikPegawai(
      totalPegawai: json['totalPegawai'] ?? 0,
      totalLaki: json['totalLaki'] ?? 0,
      totalPerempuan: json['totalPerempuan'] ?? 0,
      totalMedis: json['totalMedis'] ?? 0,
      totalNakes: json['totalNakes'] ?? 0,
      totalAdmin: json['totalAdmin'] ?? 0,
      totalPns: json['totalPns'] ?? 0,
      totalP3k: json['totalP3k'] ?? 0,
      totalBlu: json['totalBlu'] ?? 0,
      totalCukup40Jpl: json['totalCukup40Jpl'] ?? 0,
    );
  }

  // Helper untuk data kosong jika terjadi error
  factory DataStatistikPegawai.empty() {
    return DataStatistikPegawai(
      totalPegawai: 0, totalLaki: 0, totalPerempuan: 0, totalMedis: 0,
      totalNakes: 0, totalAdmin: 0, totalPns: 0, totalP3k: 0, totalBlu: 0, totalCukup40Jpl: 0,
    );
  }
}

class StatistikRepository {
  // URL Worker Cloudflare D1 Anda
  final String _baseUrl = 'https://portalgh2026.mmakerapps.workers.dev';

  /// MENGAMBIL DATA DARI CLOUDFLARE D1 (SQL)
  /// Ini menggantikan pola lama yang boros kuota Firestore
  Future<DataStatistikPegawai> getStatistikData() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/statistik'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return DataStatistikPegawai.fromJson(data);
      } else {
        throw Exception('Gagal memuat data dari Worker (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('Error StatistikRepository.getStatistikData: $e');
      return DataStatistikPegawai.empty();
    }
  }

  /// Alias Stream agar tidak merusak kode UI yang sudah ada (menggunakan Future di dalam Stream)
  Stream<DataStatistikPegawai> getStatistikStream() async* {
    yield await getStatistikData();
  }
}