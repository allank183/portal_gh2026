import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../repositories/repo_statistik.dart';
import '../../../repositories/repo_mahasiswa.dart';
import '../../../models/model_mahasiswa.dart';
import '../../../services/service_trigger.dart';
import 'package:portal_gh2026/widgets/premium_header.dart';

class ScreenDashboardUtama extends StatefulWidget {
  const ScreenDashboardUtama({super.key});

  @override
  State<ScreenDashboardUtama> createState() => _ScreenDashboardUtamaState();
}

class _ScreenDashboardUtamaState extends State<ScreenDashboardUtama> {
  final StatistikRepository _statistikRepository = StatistikRepository();
  final MahasiswaRepository _mahasiswaRepository = MahasiswaRepository();
  late Future<List<dynamic>> _dashboardDataFuture;

  @override
  void initState() {
    super.initState();
    _loadStats();
    // Dengarkan lonceng perubahan statistik
    refreshTrigger.addListener(_loadStats);
  }

  void _loadStats() {
    if (mounted) {
      setState(() {
        _dashboardDataFuture = Future.wait([
          _statistikRepository.getStatistikData(),
          _mahasiswaRepository.getAllMahasiswaKegiatan(),
        ]);
      });
    }
  }

  @override
  void dispose() {
    refreshTrigger.removeListener(_loadStats);
    super.dispose();
  }

  // Fungsi untuk refresh data manual
  Future<void> _handleRefresh() async {
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: FutureBuilder<List<dynamic>>(
          future: _dashboardDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.hasData && snapshot.data!.isNotEmpty 
                ? snapshot.data![0] as DataStatistikPegawai 
                : DataStatistikPegawai.empty();
            
            final mahasiswaList = snapshot.hasData && snapshot.data!.length > 1 
                ? snapshot.data![1] as List<MahasiswaKegiatanModel> 
                : <MahasiswaKegiatanModel>[];

            final int totalMahasiswa = mahasiswaList.length;
            final double totalPendapatanMhs = mahasiswaList.fold(0.0, (sum, m) => sum + m.biaya);

            return Column(
              children: [
                const PremiumHeader(
                  title: 'Dashboard Utama',
                  subtitle: 'Ringkasam Data',
                  borderRadius: BorderRadius.zero,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPengumumanSection(),
                        const SizedBox(height: 24),

                        // SEMUA KARTU METRIK UTAMA DISATUKAN DALAM 1 SECTION AGAR TIDAK ADA RUANG KOSONG
                        Text(
                          'Ringkasan SDM, Pelatihan & Mahasiswa',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            double statCardWidth;
                            if (constraints.maxWidth > 1100) {
                              statCardWidth = (constraints.maxWidth - 48) / 4;
                            } else if (constraints.maxWidth > 600) {
                              statCardWidth = (constraints.maxWidth - 16) / 2;
                            } else {
                              statCardWidth = constraints.maxWidth;
                            }

                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                SizedBox(
                                  width: statCardWidth,
                                  child: _buildStatCard(
                                    title: 'Total Pegawai',
                                    value: '${data.totalPegawai}',
                                    subtitle: 'SDM Terdaftar',
                                    icon: Icons.people_alt_rounded,
                                    gradientColors: [Colors.blue.shade700, Colors.blue.shade500],
                                  ),
                                ),
                                SizedBox(
                                  width: statCardWidth,
                                  child: _buildStatCard(
                                    title: 'Cukup 40 JPL',
                                    value: '${data.totalCukup40Jpl}',
                                    subtitle: 'Memenuhi Target JPL',
                                    icon: Icons.verified_rounded,
                                    gradientColors: [Colors.teal.shade700, Colors.teal.shade500],
                                  ),
                                ),
                                SizedBox(
                                  width: statCardWidth,
                                  child: _buildStatCard(
                                    title: 'Total Mahasiswa',
                                    value: '$totalMahasiswa',
                                    subtitle: 'Mahasiswa Terdaftar',
                                    icon: Icons.groups_rounded,
                                    gradientColors: [Colors.purple.shade700, Colors.purple.shade500],
                                  ),
                                ),
                                SizedBox(
                                  width: statCardWidth,
                                  child: _buildStatCard(
                                    title: 'Pendapatan Mahasiswa',
                                    value: NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(totalPendapatanMhs),
                                    subtitle: 'Total Kontribusi',
                                    icon: Icons.account_balance_wallet_rounded,
                                    gradientColors: [Colors.cyan.shade700, Colors.cyan.shade500],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // BREAKDOWN DATA PEGAWAI
                        LayoutBuilder(
                          builder: (context, constraints) {
                            double cardWidth;
                            if (constraints.maxWidth > 900) {
                              cardWidth = (constraints.maxWidth - 32) / 3;
                            } else if (constraints.maxWidth > 600) {
                              cardWidth = (constraints.maxWidth - 16) / 2;
                            } else {
                              cardWidth = constraints.maxWidth;
                            }

                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildBreakdownCard(
                                    title: 'Jenis Kelamin',
                                    icon: Icons.wc_rounded,
                                    color: Colors.indigo,
                                    sections: [
                                      _PieData(label: 'Laki-laki', value: data.totalLaki.toDouble(), color: Colors.blue),
                                      _PieData(label: 'Perempuan', value: data.totalPerempuan.toDouble(), color: Colors.pink),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildBreakdownCard(
                                    title: 'Kelompok SDM',
                                    icon: Icons.local_hospital_rounded,
                                    color: Colors.teal,
                                    sections: [
                                      _PieData(label: 'Medis', value: data.totalMedis.toDouble(), color: Colors.teal),
                                      _PieData(label: 'Nakes', value: data.totalNakes.toDouble(), color: Colors.cyan),
                                      _PieData(label: 'Admin', value: data.totalAdmin.toDouble(), color: Colors.amber.shade800),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildBreakdownCard(
                                    title: 'Status Kepegawaian',
                                    icon: Icons.badge_rounded,
                                    color: Colors.orange.shade800,
                                    sections: [
                                      _PieData(label: 'PNS', value: data.totalPns.toDouble(), color: Colors.orange),
                                      _PieData(label: 'P3K', value: data.totalP3k.toDouble(), color: Colors.deepOrange),
                                      _PieData(label: 'BLU', value: data.totalBlu.toDouble(), color: Colors.brown),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // WIDGET PENGUMUMAN
  Widget _buildPengumumanSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade900, Colors.indigo.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'PENGUMUMAN',
                      style: TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Penting',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Batas Akhir Update Presensi Setiap Tanggal 01 Setiap Bulan untuk Bulan Sebelumnya',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  'Diharapkan seluruh pegawai memperbarui riwayat pelatihan setiap akhir bulan.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET CARD STATISTIK UTAMA
  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
              ],
            ),
          ),
          Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 40),
        ],
      ),
    );
  }

  // WIDGET CARD BREAKDOWN DENGAN PIE CHART
  Widget _buildBreakdownCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<_PieData> sections,
  }) {
    double total = sections.fold(0, (sum, item) => sum + item.value);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // PIE CHART
              SizedBox(
                height: 100,
                width: 100,
                child: total == 0
                    ? Center(child: Text("0", style: TextStyle(color: Colors.grey.shade400)))
                    : PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 20,
                          sections: sections.map((data) {
                            return PieChartSectionData(
                              color: data.color,
                              value: data.value,
                              title: '',
                              radius: 25,
                            );
                          }).toList(),
                        ),
                      ),
              ),
              const SizedBox(width: 20),
              // LEGENDA
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sections.map((data) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: data.color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data.label,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ),
                          Text(
                            '${data.value.toInt()}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PieData {
  final String label;
  final double value;
  final Color color;
  _PieData({required this.label, required this.value, required this.color});
}
