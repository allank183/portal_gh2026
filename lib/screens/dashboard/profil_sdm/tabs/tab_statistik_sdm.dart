import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:portal_gh2026/repositories/repo_statistik.dart';
import 'package:portal_gh2026/services/service_trigger.dart';

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
  late Future<DataStatistikPegawai> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statistikRepository = StatistikRepository();
    _loadStats();
    // Dengarkan lonceng perubahan statistik
    refreshTrigger.addListener(_loadStats);
  }

  void _loadStats() {
    if (mounted) {
      setState(() {
        _statsFuture = _statistikRepository.getStatistikData();
      });
    }
  }

  @override
  void dispose() {
    refreshTrigger.removeListener(_loadStats);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true; // Menyimpan status agar tidak re-fetch

  @override
  Widget build(BuildContext context) {
    super.build(context); // Wajib dipanggil untuk AutomaticKeepAliveClientMixin

    return FutureBuilder<DataStatistikPegawai>(
      future: _statsFuture,
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
                      sections: [
                        _PieData(value: data.totalLaki.toDouble(), color: Colors.blue, label: 'Laki-laki'),
                        _PieData(value: data.totalPerempuan.toDouble(), color: Colors.pink, label: 'Perempuan'),
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
                        _PieData(value: data.totalMedis.toDouble(), color: Colors.teal, label: 'Medis'),
                        _PieData(value: data.totalNakes.toDouble(), color: Colors.cyan, label: 'Nakes'),
                        _PieData(value: data.totalAdmin.toDouble(), color: Colors.amber.shade800, label: 'Admin'),
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
                        _PieData(value: data.totalPns.toDouble(), color: Colors.orange, label: 'PNS'),
                        _PieData(value: data.totalP3k.toDouble(), color: Colors.deepOrange, label: 'P3K'),
                        _PieData(value: data.totalBlu.toDouble(), color: Colors.brown, label: 'BLU'),
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

// Data model bantuan untuk Pie Chart
class _PieData {
  final double value;
  final Color color;
  final String label;

  _PieData({required this.value, required this.color, required this.label});
}
