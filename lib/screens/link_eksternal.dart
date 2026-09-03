import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/premium_header.dart'; // Import PremiumHeader (sesuaikan relative path jika perlu)

class ExternalLinksScreen extends StatefulWidget {
  const ExternalLinksScreen({super.key});

  @override
  State<ExternalLinksScreen> createState() => _ExternalLinksScreenState();
}

class _ExternalLinksScreenState extends State<ExternalLinksScreen> {
  final List<Map<String, dynamic>> links = [
    {
      'title': 'E-Office Kemenkes',
      'subtitle': 'Sistem Administrasi Perkantoran',
      'desc':
      'Portal utama layanan administrasi digital Kementerian Kesehatan. Digunakan untuk pengelolaan surat menyurat elektronik, tanda tangan digital, dan akses berbagai aplikasi internal Kemenkes dalam satu pintu.',
      'url': 'https://portal-eoffice.kemkes.go.id/',
      'icon': Icons.business_center_rounded,
      'color': Colors.indigo,
      'tags': ['IPSN', 'PDM', 'Proses Kepegawaian', 'PGA']
    },
    {
      'title': 'LMS Kemenkes',
      'subtitle': 'Platform Pembelajaran Mandiri',
      'desc':
      'LMS (Learning Management System) Kemenkes adalah platform resmi untuk pengembangan kompetensi Tenaga Kesehatan. Di sini Anda dapat mengikuti pelatihan sertifikasi, webinar, dan modul pembelajaran mandiri untuk memenuhi kredit SKP.',
      'url': 'https://lms.kemkes.go.id',
      'icon': Icons.school_rounded,
      'color': Colors.blue,
      'tags': ['Pendidikan', 'Pelatihan', 'JPL', 'SKP']
    },
    {
      'title': 'E-Kinerja',
      'subtitle': 'Manajemen Kinerja Pegawai',
      'desc':
      'Sistem informasi untuk mengelola kinerja pegawai di lingkungan instansi pemerintah. Digunakan untuk pengisian SKP (Sasaran Kinerja Pegawai) tahunan, pelaporan aktivitas harian, dan penilaian capaian target kerja secara transparan.',
      'url': 'https://ekinerja-portal-eoffice.kemkes.go.id/index.cj',
      'icon': Icons.trending_up_rounded,
      'color': Colors.green,
      'tags': ['Log Book', 'Kinerja', 'Kemenkes']
    },
    {
      'title': 'DJP Online',
      'subtitle': 'Layanan Pajak Elektronik',
      'desc':
      'Akses resmi untuk wajib pajak dalam melaporkan SPT Tahunan (e-Filing), melakukan pembayaran pajak (e-Billing), dan administrasi perpajakan lainnya secara online tanpa perlu ke kantor pajak.',
      'url': 'https://djponline.pajak.go.id',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Colors.orange,
      'tags': ['Pajak', 'Keuangan', 'SPT']
    },
  ];

  int _selectedLinkIndex = 0;

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Gagal membuka $urlString');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka tautan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. TAMBAHKAN PREMIUM HEADER DI SINI
          const PremiumHeader(
            title: 'Tautan Eksternal',
            subtitle: 'Akses Cepat Layanan Digital',
            borderRadius: BorderRadius.zero,
          ),

          // 2. KONTEN UTAMA DIBUNGKUS EXPANDED
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isDesktop = constraints.maxWidth >= 800;

                if (isDesktop) {
                  return Row(
                    children: [
                      _buildSidebar(isDesktop: true),
                      Expanded(child: _buildMainContent()),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildSidebar(isDesktop: false),
                      Expanded(child: _buildMainContent()),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget Sidebar / Daftar Tautan
  Widget _buildSidebar({required bool isDesktop}) {
    return Container(
      width: isDesktop ? 320 : double.infinity,
      height: isDesktop ? double.infinity : 220,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
              color: isDesktop ? const Color(0xFFE2E8F0) : Colors.transparent),
          bottom: BorderSide(
              color: !isDesktop ? const Color(0xFFE2E8F0) : Colors.transparent),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Daftar Tautan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: links.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                bool isSelected = _selectedLinkIndex == index;
                Color itemColor = links[index]['color'];

                return InkWell(
                  onTap: () => setState(() => _selectedLinkIndex = index),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? itemColor.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? itemColor : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          links[index]['icon'],
                          color: isSelected ? itemColor : Colors.blueGrey[300],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            links[index]['title'],
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? itemColor
                                  : Colors.blueGrey[700],
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.chevron_right, color: itemColor, size: 18),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget Detail Isi Tautan
  Widget _buildMainContent() {
    final selectedItem = links[_selectedLinkIndex];
    Color itemColor = selectedItem['color'];

    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: itemColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(selectedItem['icon'],
                      color: itemColor, size: 50),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (selectedItem['tags'] as List<String>)
                      .map((tag) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[600],
                      ),
                    ),
                  ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  selectedItem['title'],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  selectedItem['subtitle'],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: itemColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),
                Text(
                  'Tentang Sistem:',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedItem['desc'],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: Colors.blueGrey[600],
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 36),
                ElevatedButton.icon(
                  onPressed: () => _launchURL(selectedItem['url']),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text('Kunjungi Website Resmi ${selectedItem['title']}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: itemColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}