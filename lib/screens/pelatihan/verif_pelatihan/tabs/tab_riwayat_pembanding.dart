import 'package:flutter/material.dart';
import '../../../../models/model_pelatihan.dart';
import '../../../../repositories/repo_pelatihan.dart';

class TabRiwayatPembanding extends StatelessWidget {
  final String nip;
  final PelatihanRepository _pelatihanRepository = PelatihanRepository();

  TabRiwayatPembanding({super.key, required this.nip});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PelatihanModel>>(
      // Menggunakan Future agar tidak loading terus-menerus (no polling)
      future: _pelatihanRepository.getRiwayatFuture(nip: nip),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final approvedList = (snapshot.data ?? [])
            .where((element) => element.status == 'approved')
            .toList();

        if (approvedList.isEmpty) {
          return const Center(
            child: Text(
              'Pegawai ini belum memiliki sertifikat yang di-approve sebelumnya.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: approvedList.length,
          itemBuilder: (context, index) {
            final item = approvedList[index];
            return Card(
              elevation: 0,
              color: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.verified, color: Colors.green, size: 20),
                title: Text(
                  item.judulPelatihan,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: Text(
                  'No: ${item.nomorSertifikat} | JPL: ${item.jumlahJpl}\nTgl: ${item.tanggalKegiatan}',
                  style: const TextStyle(fontSize: 11),
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}
