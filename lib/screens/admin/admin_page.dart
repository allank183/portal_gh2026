import 'package:flutter/material.dart';
import 'tabs/tab_daftar_pegawai.dart';
import 'tabs/tab_tambah_manual.dart';
import 'tabs/tab_import_csv.dart';

class ScreenImportPegawai extends StatelessWidget {
  const ScreenImportPegawai({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Kelola Data Pegawai', style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,

          // --- TOMBOL MIGRASI SUDAH DIHAPUS DARI SINI ---

          bottom: const TabBar(
            labelColor: Colors.indigo,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.indigo,
            tabs: [
              Tab(icon: Icon(Icons.people_alt_rounded), text: 'Daftar Pegawai'),
              Tab(icon: Icon(Icons.person_add_alt_1_rounded), text: 'Tambah Manual'),
              Tab(icon: Icon(Icons.upload_file_rounded), text: 'Import Massal (CSV)'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TabDaftarPegawai(),
            TabTambahManual(),
            TabImportCsv(),
          ],
        ),
      ),
    );
  }
}