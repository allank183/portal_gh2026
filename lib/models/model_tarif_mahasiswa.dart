class TarifMahasiswaModel {
  final int? id;
  final String jenis; // PKM, PKK, Penelitian
  final String jenjang; // D3, S1, Profesi, S2
  final double biaya;
  final String satuan; // hari, minggu, bulan
  final DateTime? createdAt;

  TarifMahasiswaModel({
    this.id,
    required this.jenis,
    required this.jenjang,
    required this.biaya,
    this.satuan = 'hari',
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jenis': jenis,
      'jenjang': jenjang,
      'biaya': biaya,
      'satuan': satuan,
    };
  }

  factory TarifMahasiswaModel.fromJson(Map<String, dynamic> json) {
    return TarifMahasiswaModel(
      id: json['id'],
      jenis: json['jenis'] ?? '',
      jenjang: json['jenjang'] ?? '',
      biaya: (json['biaya'] as num?)?.toDouble() ?? 0.0,
      satuan: json['satuan'] ?? 'hari',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}
