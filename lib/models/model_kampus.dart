class KampusModel {
  final int? id;
  final String namaKampus;
  final String? singkatan;
  final String? alamat;
  final DateTime? createdAt;

  KampusModel({
    this.id,
    required this.namaKampus,
    this.singkatan,
    this.alamat,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_kampus': namaKampus,
      'singkatan': singkatan,
      'alamat': alamat,
    };
  }

  factory KampusModel.fromJson(Map<String, dynamic> json) {
    return KampusModel(
      id: json['id'],
      namaKampus: json['nama_kampus'] ?? '',
      singkatan: json['singkatan'],
      alamat: json['alamat'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}
