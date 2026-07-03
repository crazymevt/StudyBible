import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ImageViewerDialog extends StatelessWidget {
  final String title;
  final File file;

  const ImageViewerDialog({super.key, required this.title, required this.file});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AppBar(
            title: Text(title),
            leading: const CloseButton(),
            actions: [
              IconButton(
                icon: const Icon(Icons.open_in_new),
                tooltip: 'Open externally',
                onPressed: () {
                  launchUrl(file.uri, mode: LaunchMode.externalApplication);
                },
              ),
            ],
          ),
          Expanded(
            child: InteractiveViewer(
              child: Image.file(file, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}
