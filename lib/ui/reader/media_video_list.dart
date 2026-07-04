import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/media_collection.dart';
import 'media_player_dialog.dart';
import 'web_player_dialog.dart';

/// Plays a curated media item: YouTube ids open the in-app player (or the
/// browser on Windows/Linux, where the webview backend is unavailable), other
/// urls open the web player. Shared by the reader's Media panel and the
/// Explorer passage page so both behave identically.
void openMediaItem(BuildContext context, MediaItem item) {
  if (item.id != null) {
    if (Platform.isWindows || Platform.isLinux) {
      launchUrl(
        Uri.parse('https://www.youtube.com/watch?v=${item.id}'),
        mode: LaunchMode.externalApplication,
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => MediaPlayerDialog(videoId: item.id!),
      );
    }
  } else if (item.url != null) {
    if (Platform.isWindows || Platform.isLinux) {
      launchUrl(
        Uri.parse(item.url!),
        mode: LaunchMode.externalApplication,
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => WebPlayerDialog(url: item.url!),
      );
    }
  }
}

/// One curated video/web item as a tappable tile with a YouTube thumbnail.
class MediaVideoTile extends StatelessWidget {
  const MediaVideoTile({super.key, required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Container(
        width: 80,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(4),
          image: item.id != null
              ? DecorationImage(
                  image: NetworkImage(
                    'https://img.youtube.com/vi/${item.id}/hqdefault.jpg',
                  ),
                  fit: BoxFit.cover,
                  onError: (_, _) {
                    // Ignore image loading errors (offline / bad id).
                  },
                )
              : null,
        ),
        child: const Icon(Icons.play_circle_outline, color: Colors.white),
      ),
      title: Text(item.title),
      subtitle: item.description != null
          ? Text(item.description!, maxLines: 2, overflow: TextOverflow.ellipsis)
          : null,
      trailing: Text(
        item.duration ?? '',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      onTap: () => openMediaItem(context, item),
    );
  }
}
