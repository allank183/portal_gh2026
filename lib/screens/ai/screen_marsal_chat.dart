import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../services/groq_service.dart';
import '../../../widgets/premium_header.dart';

class ScreenMarsalChat extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ScreenMarsalChat({super.key, required this.userData});

  @override
  State<ScreenMarsalChat> createState() => _ScreenMarsalChatState();
}

class _ScreenMarsalChatState extends State<ScreenMarsalChat> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  final List<Map<String, String>> _chatMessages = [];
  bool _isLoading = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _chatMessages.add({'sender': 'user', 'text': text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();
    _inputFocusNode.requestFocus();

    final response = await GroqService.askUnifiedAI(
      promptUser: text,
      userData: widget.userData,
    );

    if (mounted) {
      setState(() {
        _chatMessages.add({'sender': 'ai', 'text': response});
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. HEADER PREMIUM
          const PremiumHeader(
            title: 'Marsal AI Assistant',
            subtitle: 'ANALISIS DATA & LAYANAN PORTAL',
            borderRadius: BorderRadius.zero,
          ),

          // 2. AREA CHAT
          Expanded(
            child: _chatMessages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final msg = _chatMessages[index];
                return _buildChatBubble(msg);
              },
            ),
          ),

          // 3. INPUT FIELD (FIXED DI BAWAH)
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 64, color: Colors.indigo.shade100),
          const SizedBox(height: 16),
          Text(
            'Halo ${widget.userData['nama'] ?? 'Pegawai'}!\nSaya Marsal, asisten cerdas Anda.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: Colors.blueGrey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tanyakan apa saja seputar data JPL, sertifikat,\natau profil rekan kerja Anda.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, String> msg) {
    bool isUser = msg['sender'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75, // Lebih lebar
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.indigo.shade600 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
          ],
          border: isUser ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: MarkdownBody(
          data: msg['text'] ?? '',
          styleSheet: MarkdownStyleSheet(
            p: GoogleFonts.plusJakartaSans(
              color: isUser ? Colors.white : Colors.black87,
              fontSize: 14,
              height: 1.5,
            ),
            tableBody: GoogleFonts.plusJakartaSans(fontSize: 13),
            tableBorder: TableBorder.all(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _inputFocusNode,
              autofocus: true,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Ketik pertanyaan Anda di sini...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            onPressed: _sendMessage,
            backgroundColor: Colors.indigo,
            child: const Icon(Icons.send_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}