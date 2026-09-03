import 'package:flutter/material.dart';

class WidgetDragDropZone extends StatelessWidget {
  final VoidCallback onTapUpload;

  const WidgetDragDropZone({super.key, required this.onTapUpload});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.indigo.shade50.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.indigo.shade200, width: 1.5),
      ),
      child: InkWell(
        onTap: onTapUpload,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.indigo.shade700),
              const SizedBox(height: 12),
              Text(
                'Tarik & Lepas File Sertifikat (PDF) di Sini',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'atau klik area ini untuk memilih berkas dari komputer',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}