import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class TabPreviewPdf extends StatelessWidget {
  final String fileUrl;

  const TabPreviewPdf({super.key, required this.fileUrl});

  @override
  Widget build(BuildContext context) {
    if (fileUrl.isEmpty) {
      return const Center(
        child: Text('URL File PDF tidak valid.'),
      );
    }

    return SfPdfViewer.network(
      fileUrl,
      key: ValueKey(fileUrl),
    );
  }
}
