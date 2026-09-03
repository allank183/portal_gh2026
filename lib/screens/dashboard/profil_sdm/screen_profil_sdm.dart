import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/model_pegawai.dart';
import '../../../repositories/repo_pegawai.dart';
import '../../../widgets/premium_header.dart';
import 'tabs/tab_direktori_pegawai.dart';
import 'tabs/tab_statistik_sdm.dart';

class ScreenProfilSdm extends StatefulWidget {
  const ScreenProfilSdm({super.key});

  @override
  State<ScreenProfilSdm> createState() => _ScreenProfilSdmState();
}

class _ScreenProfilSdmState extends State<ScreenProfilSdm> {
  late Future<List<PegawaiModel>> _futurePegawai;

  final Map<String, Color> _colorMap = const {
    // Jenis Kelamin
    'Laki-laki': Color(0xFF2563EB), // Blue
    'Perempuan': Color(0xFFEC4899), // Pink

    // Kelompok SDM
    'Medis': Color(0xFF4F46E5),     // Indigo
    'Nakes': Color(0xFF16A34A),     // Green
    'Admin': Color(0xFFEA580C),     // Orange

    // Status Kepegawaian
    'PNS': Color(0xFFEA580C),       // Orange
    'P3K': Color(0xFFDC2626),       // Red
    'BLU': Color(0xFF475569),       // Slate
  };

  @override
  void initState() {
    super.initState();
    _futurePegawai = PegawaiRepository().getAllPegawai();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // 1. PREMIUM HEADER BIRU (Konsisten dengan halaman lain)
            const PremiumHeader(
              title: 'Profil SDM & Kepegawaian',
              subtitle: 'RINGKASAN & DIREKTORI',
              borderRadius: BorderRadius.zero,
            ),

            // 2. KONTEN DENGAN FUTUREBUILDER
            Expanded(
              child: FutureBuilder<List<PegawaiModel>>(
                future: _futurePegawai,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Terjadi kesalahan: ${snapshot.error}',
                        style: GoogleFonts.plusJakartaSans(color: Colors.red),
                      ),
                    );
                  }

                  final listPegawai = snapshot.data ?? [];

                  return Column(
                    children: [
                      // Sub-Header Fixed (Total SDM & TabBar Navigation)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 16.0),
                        child: Column(
                          children: [
                            // Card Ringkasan Total SDM
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Direktori & Statistik SDM',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Visualisasi statistik demografi dan daftar seluruh pegawai',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFF64748B),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 8,
                                      )
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.groups_rounded, color: Color(0xFF2563EB), size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Total SDM',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF64748B),
                                            ),
                                          ),
                                          Text(
                                            '${listPegawai.length} Orang',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // TabBar Custom Segmented
                            Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TabBar(
                                indicator: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                labelColor: const Color(0xFF2563EB),
                                unselectedLabelColor: const Color(0xFF64748B),
                                labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                                unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
                                dividerColor: Colors.transparent,
                                padding: const EdgeInsets.all(4),
                                tabs: const [
                                  Tab(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.badge_rounded, size: 18),
                                        SizedBox(width: 8),
                                        Text('Direktori Pegawai'),
                                      ],
                                    ),
                                  ),
                                  Tab(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.pie_chart_rounded, size: 18),
                                        SizedBox(width: 8),
                                        Text('Statistik Demografi'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // TabBarView Content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: TabBarView(
                            children: [
                              TabDirektoriPegawai(
                                listPegawai: listPegawai,
                                colorMap: _colorMap,
                              ),
                              const TabStatistikSdm(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}