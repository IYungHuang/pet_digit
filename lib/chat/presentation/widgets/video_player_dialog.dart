import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

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
  VideoPlayerController? _controller;
  Object? _initializationError;

  String get displayName => (widget.localPath ?? widget.url).split('/').last;

  @override
  void initState() {
    super.initState();
    unawaited(_prepareController());
  }

  Future<void> _prepareController() async {
    final localPath = widget.localPath;
    final controller = localPath != null && File(localPath).existsSync()
        ? VideoPlayerController.file(File(localPath))
        : _networkController();
    if (controller == null) return;

    _controller = controller;
    try {
      await controller.initialize();
      if (mounted) setState(() {});
    } catch (error) {
      _initializationError = error;
      await controller.dispose();
      _controller = null;
      if (mounted) setState(() {});
    }
  }

  VideoPlayerController? _networkController() {
    final uri = Uri.tryParse(widget.url);
    if (uri == null || !{'http', 'https'}.contains(uri.scheme)) return null;
    return VideoPlayerController.networkUrl(uri);
  }

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final initialized = controller?.value.isInitialized == true;
    final duration =
        widget.durationMs ??
        (initialized ? controller!.value.duration.inMilliseconds : 10_000);

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
            _header(context),
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: initialized
                  ? _player(controller!, duration)
                  : _unavailablePlayer(),
            ),
            _details(duration),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Padding(
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
            '影片播放器',
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
  );

  Widget _player(
    VideoPlayerController controller,
    int duration,
  ) => ValueListenableBuilder<VideoPlayerValue>(
    valueListenable: controller,
    builder: (context, value, _) => Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: value.aspectRatio == 0 ? 16 / 9 : value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
        Row(
          children: [
            IconButton(
              tooltip: value.isPlaying ? '暫停' : '播放',
              icon: Icon(
                value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
              ),
              onPressed: () =>
                  value.isPlaying ? controller.pause() : controller.play(),
            ),
            Expanded(
              child: Slider(
                value: value.position.inMilliseconds
                    .clamp(0, duration)
                    .toDouble(),
                max: duration.toDouble().clamp(1, double.infinity),
                onChanged: (position) =>
                    controller.seekTo(Duration(milliseconds: position.round())),
              ),
            ),
            Text(
              '${_formatDuration(value.position.inMilliseconds)} / ${_formatDuration(duration)}',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _unavailablePlayer() => Container(
    height: 220,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xff24263b), Color(0xff161726)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white12),
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _initializationError == null
                ? Icons.video_file_outlined
                : Icons.error_outline,
            color: Colors.white54,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            '影片來源尚未可播放',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '需要有效的本機檔案或 HTTP/HTTPS URL',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _details(int duration) => Container(
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
        const Text(
          '使用 video_player 引擎',
          style: TextStyle(
            color: Color(0xffffb74d),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Divider(color: Colors.white10, height: 18),
        _detail('檔案名稱', displayName),
        _detail('MIME 類型', widget.mimeType),
        _detail('檔案來源', widget.localPath ?? widget.url),
        _detail('影片時長', '${(duration / 1000).toStringAsFixed(0)} 秒'),
      ],
    ),
  );

  Widget _detail(String label, String value) => Padding(
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

  String _formatDuration(int milliseconds) {
    final totalSeconds = milliseconds ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
