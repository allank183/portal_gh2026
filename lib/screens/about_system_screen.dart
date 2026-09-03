import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'dart:ui';
import '../widgets/premium_header.dart';

class AboutSystemScreen extends StatelessWidget {
  const AboutSystemScreen({super.key});

  void _showZoomedImage(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: FadeTransition(
            opacity: anim1,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: InteractiveViewer(
                        maxScale: 4.0,
                        child: Image.asset('assets/haki.png', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PremiumHeader(
          title: 'Visi dan Tujuan',
          subtitle: 'Informasi Portal Kinerja',
          borderRadius: BorderRadius.zero,
        ),
        Expanded(
          child: Container(
            color: const Color(0xFFF8FAFC),
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isMobileMode = constraints.maxWidth < 900;

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobileMode ? 20 : 30,
                    vertical: 30,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: isMobileMode
                          ? Column(
                        children: [
                          _buildEnhancedProfileCard(),
                          const SizedBox(height: 20),
                          _buildHakiSidebarCard(context),
                          const SizedBox(height: 40),
                          _buildMainContent(),
                        ],
                      )
                          : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 280,
                            child: Column(
                              children: [
                                _buildEnhancedProfileCard(),
                                const SizedBox(height: 20),
                                _buildHakiSidebarCard(context),
                              ],
                            ),
                          ),
                          const SizedBox(width: 40),
                          Expanded(
                            child: _buildMainContent(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          "Digitalisasi, laporan di ujung jari.",
          "Sistem pelaporan kinerja berbasis digital.",
        ),
        const SizedBox(height: 24),
        _buildFeatureGrid(),
        const SizedBox(height: 32),
        _buildTechSection(),
      ],
    );
  }

  Widget _buildEnhancedProfileCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.blue[700]!, Colors.indigo[900]!],
                  ),
                ),
              ),
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Icon(Icons.person_rounded, size: 50, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Marlan Faisal M.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Admin-Portal Kinerja',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF4338CA),
                fontWeight: FontWeight.w800,
                fontSize: 9,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHakiSidebarCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: Colors.blueAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                'Terdaftar HAKI',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showZoomedImage(context),
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: AssetImage('assets/haki.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.zoom_in, color: Colors.white, size: 30),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () async {
              try {
                final data = await rootBundle.load('assets/sertifikat_haki.pdf');
                await Printing.layoutPdf(
                  onLayout: (format) => data.buffer.asUint8List(),
                  name: "Sertifikat_HAKI_Marlan",
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("File PDF tidak ditemukan."),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Colors.white),
            label: const Text(
              'Sertifikat',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid() {
    return Column(
      children: [
        _buildInfoCard(
          "Transformasi Digital",
          "Portal kinerja ini dikembangkan sebagai wujud nyata dalam mendukung 6 Pilar Transformasi Kesehatan Kemenkes RI, khususnya pada Pilar Teknologi Kesehatan.",
          Icons.auto_graph_rounded,
          Colors.blueAccent,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          "Paperless, Efisiensi & Kecepatan Data",
          "Digitalisasi adalah tulang punggung paperless & efisiensi. Dashboard ini menampilkan data secara real time.",
          Icons.speed_rounded,
          Colors.teal,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          "Pengembangan Diri",
          "Proyek ini merupakan sarana bagi saya sebagai pengembang untuk terus belajar dan berinovasi. Melalui media pengembangan diri ini diharapkan dapat memberikan dampak positif bagi instansi ditempat saya bertugas.",
          Icons.verified_user_rounded,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String desc, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  desc,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Core Technologies',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildTechBadge('Flutter 3.24', Icons.bolt, Colors.blue),
            _buildTechBadge('Firebase', Icons.cloud, Colors.orange),
            _buildTechBadge('Cloudflare', Icons.cloud_done_rounded, Colors.deepOrange),
            _buildTechBadge('HAKI Protected', Icons.security, Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _buildTechBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}