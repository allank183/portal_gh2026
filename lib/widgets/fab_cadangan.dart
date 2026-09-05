import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FabCadangan extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  final IconData icon;

  const FabCadangan({
    super.key,
    required this.onTap,
    this.label = 'Menu',
    this.icon = Icons.auto_awesome
  });

  @override
  State<FabCadangan> createState() => _FabCadanganState();
}

class _FabCadanganState extends State<FabCadangan> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          height: 50,
          constraints: BoxConstraints(
            minWidth: 50,
            maxWidth: _isHovered ? 160 : 50,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: _isHovered ? 0.45 : 0.25),
                blurRadius: _isHovered ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: Center(
                    child: Icon(widget.icon, color: const Color(0xFF93C5FD), size: 22),
                  ),
                ),
                _AnimatedClipRect(
                  open: _isHovered,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      softWrap: false,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
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

class _AnimatedClipRect extends StatelessWidget {
  final bool open;
  final Widget child;

  const _AnimatedClipRect({required this.open, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedAlign(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.centerLeft,
      widthFactor: open ? 1.0 : 0.0,
      child: ClipRect(child: child),
    );
  }
}