import 'package:flutter/material.dart';

class ScreenKegiatanMahasiswa extends StatelessWidget {
  const ScreenKegiatanMahasiswa({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kegiatan Mahasiswa')),
      body: const Center(
        child: Text('Modul Kegiatan Mahasiswa (Tahap Pengembangan Selanjutnya)'),
      ),
    );
  }
}