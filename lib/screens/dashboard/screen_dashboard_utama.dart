import 'package:flutter/material.dart';
import '../../repositories/repo_statistik.dart';
import 'package:portal_lapker/widgets/premium_header.dart';

class ScreenDashboardUtama extends StatefulWidget {
  const ScreenDashboardUtama({super.key});

  @override
  State<ScreenDashboardUtama> createState() => _ScreenDashboardUtamaState();
}

class _ScreenDashboardUtamaState extends State<ScreenDashboardUtama> {
  final StatistikRepository _statistikRepository = StatistikRepository();

  // Fungsi untuk refresh data manual
  Future<void> _handleRefresh() async {
    setState(() {}); // Memicu pembangunan ulang widget dan panggil API D1 lagi
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: FutureBuilder<DataStatistikPegawai>(
          future: _statistikRepository.getStatistikData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data ?? DataStatistikPegawai.empty();

            return Column(
              children: [
                const PremiumHeader(
                  title: 'Dashboard Utama',
                  subtitle: 'Data Real-time Cloudflare D1',
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

                        // METRIK UTAMA
                        Text(
                          'Ringkasan Pegawai & Pelatihan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            double statCardWidth = constraints.maxWidth > 600
                                ? 260.0
                                : constraints.maxWidth;

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
                                    items: [
                                      _buildProgressItem('Laki-laki', data.totalLaki, data.totalPegawai, Colors.blue),
                                      _buildProgressItem('Perempuan', data.totalPerempuan, data.totalPegawai, Colors.pink),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildBreakdownCard(
                                    title: 'Kelompok SDM',
                                    icon: Icons.local_hospital_rounded,
                                    color: Colors.teal,
                                    items: [
                                      _buildProgressItem('Medis', data.totalMedis, data.totalPegawai, Colors.teal),
                                      _buildProgressItem('Nakes', data.totalNakes, data.totalPegawai, Colors.cyan),
                                      _buildProgressItem('Admin', data.totalAdmin, data.totalPegawai, Colors.amber.shade800),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildBreakdownCard(
                                    title: 'Status Kepegawaian',
                                    icon: Icons.badge_rounded,
                                    color: Colors.orange.shade800,
                                    items: [
                                      _buildProgressItem('PNS', data.totalPns, data.totalPegawai, Colors.orange),
                                      _buildProgressItem('P3K', data.totalP3k, data.totalPegawai, Colors.deepOrange),
                                      _buildProgressItem('BLU', data.totalBlu, data.totalPegawai, Colors.brown),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // MODUL INTEGRASI
                        Text(
                          'Modul Integrasi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            double moduleWidth = constraints.maxWidth > 600
                                ? (constraints.maxWidth - 16) / 2
                                : constraints.maxWidth;

                            return Wrap(
                              spacing: 16,
                              runSpacing: 12,
                              children: [
                                SizedBox(
                                  width: moduleWidth,
                                  child: _buildPlaceholderModuleCard(
                                    title: 'Kegiatan Mahasiswa',
                                    description: 'Integrasi data magang & bimbingan',
                                    icon: Icons.school_rounded,
                                    color: Colors.purple,
                                  ),
                                ),
                                SizedBox(
                                  width: moduleWidth,
                                  child: _buildPlaceholderModuleCard(
                                    title: 'Sistem Presensi',
                                    description: 'Rekap kehadiran & kedisiplinan',
                                    icon: Icons.fingerprint_rounded,
                                    color: Colors.blueGrey,
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
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                const SizedBox(height: 4),
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

  // WIDGET CARD BREAKDOWN
  Widget _buildBreakdownCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> items,
  }) {
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
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }

  // WIDGET PROGRESS ITEM BAR
  Widget _buildProgressItem(String label, int value, int total, Color color) {
    double percentage = total > 0 ? (value / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
              ),
              Text(
                '$value (${(percentage * 100).toStringAsFixed(0)}%)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey.shade100,
              color: color,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET MODULE PLACEHOLDER
  Widget _buildPlaceholderModuleCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Text(
                        'Menyusul',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}