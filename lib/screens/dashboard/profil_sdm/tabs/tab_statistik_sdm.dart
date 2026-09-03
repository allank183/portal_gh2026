import 'package:flutter/material.dart';
import 'package:portal_lapker/repositories/repo_statistik.dart';

class TabStatistikSdm extends StatefulWidget {
  const TabStatistikSdm({super.key});

  @override
  State<TabStatistikSdm> createState() => _TabStatistikSdmState();
}

// AutomaticKeepAliveClientMixin mencegah widget rebuild/fetch ulang saat pindah tab
class _TabStatistikSdmState extends State<TabStatistikSdm>
    with AutomaticKeepAliveClientMixin {

  // Inisialisasi Repository 1x saja, bukan di dalam build()
  late final StatistikRepository _statistikRepository;
  late final Stream<DataStatistikPegawai> _statistikStream;

  @override
  void initState() {
    super.initState();
    _statistikRepository = StatistikRepository();
    _statistikStream = _statistikRepository.getStatistikStream();
  }

  @override
  bool get wantKeepAlive => true; // Menyimpan status agar tidak re-fetch

  @override
  Widget build(BuildContext context) {
    super.build(context); // Wajib dipanggil untuk AutomaticKeepAliveClientMixin

    return StreamBuilder<DataStatistikPegawai>(
      stream: _statistikStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ??
            DataStatistikPegawai(
              totalPegawai: 0,
              totalLaki: 0,
              totalPerempuan: 0,
              totalMedis: 0,
              totalNakes: 0,
              totalAdmin: 0,
              totalPns: 0,
              totalP3k: 0,
              totalBlu: 0,
              totalCukup40Jpl: 0,
            );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: LayoutBuilder(
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
                        _buildProgressItem('Nakes', data.totalNakes, data.totalPegawai, Colors.cyan),
                        _buildProgressItem('Medis', data.totalMedis, data.totalPegawai, Colors.teal),
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
        );
      },
    );
  }

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
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
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

  Widget _buildProgressItem(String label, int value, int total, Color color) {
    double percentage = total > 0 ? (value / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
              Text('$value (${(percentage * 100).toStringAsFixed(1)}%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
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
}