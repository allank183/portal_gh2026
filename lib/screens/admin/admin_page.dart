import 'package:flutter/material.dart';
import '../../repositories/repo_pelatihan.dart';
import '../../repositories/repo_pegawai.dart';
import 'tabs/tab_daftar_pegawai.dart';
import 'tabs/tab_tambah_manual.dart';
import 'tabs/tab_import_csv.dart';
import '../../repositories/repo_presensi.dart';

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
          actions: [
            IconButton(
              icon: const Icon(Icons.sync_problem_rounded, color: Colors.orange),
              tooltip: 'Jalankan Migrasi ke Cloudflare',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Mulai Migrasi Data?"),
                    content: const Text("Aplikasi akan memindahkan data Pegawai & Pelatihan ke Cloudflare D1."),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
                      TextButton(
                          onPressed: () async {
                            Navigator.pop(ctx);

                            // Loading Dialog
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(child: CircularProgressIndicator()),
                            );

                            try {
                              // Panggil semua fungsi migrasi satu per satu
                              await PegawaiRepository().jalankanMigrasiKeCloudflare();
                              await PelatihanRepository().jalankanMigrasiPelatihanKeCloudflare();

                              // TAMBAHKAN INI:
                              await PresensiRepository().jalankanMigrasiPresensiKeCloudflare();

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Migrasi SELURUH Data Berhasil!"), backgroundColor: Colors.green)
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
                                );
                              }
                            }
                          },
                          child: const Text("Mulai Migrasi")
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
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