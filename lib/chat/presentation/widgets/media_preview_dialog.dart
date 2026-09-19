import 'dart:io';

import 'package:flutter/material.dart';

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

  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    final source = localPath ?? url;
    return source.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black.withValues(alpha: 0.92),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Bar
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
            // Image Preview Area
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 460),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(16),
                child: InteractiveViewer(
                  maxScale: 4.0,
                  child: _buildImage(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (localPath != null) {
      final file = File(localPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildFallback(),
        );
      }
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    }
    if (url.startsWith('assets/') || url.startsWith('asset:')) {
      return Image.asset(
        url.replaceFirst('asset:', ''),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
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
}

class VideoPlayerBoundaryDialog extends StatefulWidget {
  const VideoPlayerBoundaryDialog({
    super.key,
    required this.url,
    required this.mimeType,
    this.localPath,
    this.durationMs,
    this.thumbnailUrl,
  });

  final String url;
  final String mimeType;
  final String? localPath;
  final int? durationMs;
  final String? thumbnailUrl;

  @override
  State<VideoPlayerBoundaryDialog> createState() =>
      _VideoPlayerBoundaryDialogState();
}

class _VideoPlayerBoundaryDialogState extends State<VideoPlayerBoundaryDialog> {
  bool _isPlaying = false;
  double _playbackPosition = 0.0;

  String get displayName {
    final source = widget.localPath ?? widget.url;
    return source.split('/').last;
  }

  String _formatDuration(int ms) {
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.durationMs ?? 10000;

    return Dialog(
      backgroundColor: const Color(0xff181924),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.video_library_rounded,
                    color: Color(0xff6c63ff),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '影片播放器邊界',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
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

            // Video Simulated Canvas
            Container(
              margin: const EdgeInsets.all(16),
              height: 200,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff24263b), Color(0xff161726)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Play/Pause button
                  IconButton(
                    iconSize: 56,
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPlaying = !_isPlaying;
                        if (_isPlaying && _playbackPosition == 0.0) {
                          _playbackPosition = 0.35;
                        }
                      });
                    },
                  ),

                  // Bottom player controls bar
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 8,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            activeTrackColor: const Color(0xff6c63ff),
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            value: _playbackPosition,
                            onChanged: (val) {
                              setState(() => _playbackPosition = val);
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(
                                (_playbackPosition * duration).round(),
                              ),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Boundary Specification Card
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xff222436),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xff363952)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xffffb74d), size: 16),
                      SizedBox(width: 6),
                      Text(
                        '架構說明：播放引擎延後整合',
                        style: TextStyle(
                          color: Color(0xffffb74d),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '系統架構規格指定 Phase 4-5 專注於媒體元數據交換、進度反饋、去重與生命週期，完整 video_player 原生解碼引擎預留於後續階段整合。',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                  ),
                  const Divider(color: Colors.white10, height: 18),
                  _buildDetailRow('檔案名稱', displayName),
                  _buildDetailRow('MIME 類型', widget.mimeType),
                  _buildDetailRow('檔案來源', widget.localPath ?? widget.url),
                  _buildDetailRow(
                    '影片時長',
                    '${(duration / 1000).toStringAsFixed(0)} 秒',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
