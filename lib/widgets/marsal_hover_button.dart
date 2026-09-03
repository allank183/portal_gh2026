import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MarsalHoverButton extends StatefulWidget {
  final VoidCallback onTap;

  const MarsalHoverButton({super.key, required this.onTap});

  @override
  State<MarsalHoverButton> createState() => _MarsalHoverButtonState();
}

class _MarsalHoverButtonState extends State<MarsalHoverButton> {
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
            maxWidth: _isHovered ? 145 : 50,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1E3A8A),
                Color(0xFF2563EB),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(
                  alpha: _isHovered ? 0.45 : 0.25,
                ),
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
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: Center(
                    child: Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF93C5FD),
                      size: 22,
                    ),
                  ),
                ),
                AnimatedClipRect(
                  open: _isHovered,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Text(
                      'Marsal AI',
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

class AnimatedClipRect extends StatelessWidget {
  final bool open;
  final Widget child;

  const AnimatedClipRect({super.key, required this.open, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedAlign(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.centerLeft,
      widthFactor: open ? 1.0 : 0.0,
      child: ClipRect(
        child: child,
      ),
    );
  }
}