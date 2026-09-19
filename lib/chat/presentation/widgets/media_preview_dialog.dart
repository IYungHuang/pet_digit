import 'dart:io';

import 'package:flutter/material.dart';

export 'video_player_dialog.dart' show VideoPlayerBoundaryDialog;

class ImagePreviewDialog extends StatelessWidget {
  const ImagePreviewDialog({
    super.key,
    required this.url,
    required this.mimeType,
    this.localPath,
    this.name,
  });

  final String url;
  final String mimeType;
  final String? localPath;
  final String? name;

  String get displayName =>
      name?.isNotEmpty == true ? name! : (localPath ?? url).split('/').last;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.black.withValues(alpha: 0.92),
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
            child: Row(
              children: [
                const Icon(Icons.image, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        mimeType,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '關閉',
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 460),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16),
              child: InteractiveViewer(child: _image()),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _image() {
    if (localPath != null) {
      final file = File(localPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _fallback(),
        );
      }
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    if (url.startsWith('assets/') || url.startsWith('asset:')) {
      return Image.asset(
        url.replaceFirst('asset:', ''),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() => Container(
    width: double.infinity,
    height: 240,
    decoration: BoxDecoration(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.broken_image_rounded, color: Colors.white38, size: 48),
        const SizedBox(height: 12),
        Text(
          displayName,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 4),
        const Text(
          '（本機示範路徑／預覽圖佔位）',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    ),
  );
}
