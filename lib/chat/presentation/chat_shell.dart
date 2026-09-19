import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/data/fake_chat_repository.dart';
import '../../chat/domain/chat_message.dart';
import '../../chat/domain/chat_models.dart' show ChatRoom;
import '../../chat/domain/media_policy.dart';
import '../../chat/domain/message_content.dart';
import '../../chat/domain/message_draft.dart';
import '../../chat/domain/message_status.dart';
import '../../chat/domain/message_connection_state.dart';
import '../../pet/domain/pet_world.dart';
import '../../pet/domain/pet_world_controller.dart';
import '../../pet/presentation/pet_world_overlay.dart';
import '../application/media_picker_service.dart';
import 'chat_providers.dart';
import 'widgets/media_preview_dialog.dart';

class ChatShell extends ConsumerStatefulWidget {
  const ChatShell({super.key});

  @override
  ConsumerState<ChatShell> createState() => _ChatShellState();
}

class _ChatShellState extends ConsumerState<ChatShell> {
  final _rooms = FakeChatRepository.rooms;
  final _world = PetWorldController();
  final _stackKey = GlobalKey();
  final _scrollController = ScrollController();
  final _composerController = TextEditingController();
  final Map<String, GlobalKey> _cardKeys = {};
  var _activeRoomId = 'friends';
  var _lastMessageCount = 0;

  ChatRoom get _room => FakeChatRepository.roomById(_activeRoomId);

  @override
  void initState() {
    super.initState();
    _world.loadRoom(_room);
    _scrollController.addListener(_syncBubbleBounds);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncBubbleBounds());
  }

  @override
  void dispose() {
    _composerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _syncBubbleBounds() {
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || !stackBox.hasSize) return;

    final boundsMap = <String, Rect>{};
    for (final entry in _cardKeys.entries) {
      final cardBox =
          entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (cardBox != null && cardBox.hasSize) {
        final topLeft = cardBox.localToGlobal(Offset.zero, ancestor: stackBox);
        boundsMap[entry.key] = topLeft & cardBox.size;
      }
    }
    if (boundsMap.isNotEmpty) _world.updateObjectBounds(boundsMap);
  }

  void _selectRoom(String id) {
    setState(() {
      _activeRoomId = id;
      _cardKeys.clear();
      _lastMessageCount = 0;
      _world.loadRoom(_room);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncBubbleBounds());
  }

  void _sendText(String text) {
    final value = text.trim();
    if (value.isEmpty) return;
    _composerController.clear();
    unawaited(_send(MessageContent.text(text: value)));
  }

  void _sendDemoMedia(_DemoAttachment attachment) {
    unawaited(
      _send(
        attachment.kind == _DemoAttachmentKind.image
            ? MessageContent.image(
                url: attachment.url,
                mimeType: attachment.mimeType,
                localPath: attachment.url,
              )
            : MessageContent.video(
                url: attachment.url,
                mimeType: attachment.mimeType,
                localPath: attachment.url,
                durationMs: 12_000,
              ),
      ),
    );
  }

  void _sendPickedMedia(PickedMediaFile media) {
    unawaited(
      _send(
        media.kind == MediaKind.image
            ? MessageContent.image(
                url: media.name,
                mimeType: media.mimeType,
                localPath: media.path,
              )
            : MessageContent.video(
                url: media.name,
                mimeType: media.mimeType,
                localPath: media.path,
                durationMs: media.durationMs ?? 15_000,
              ),
      ),
    );
  }

  void _openImagePreview(ImageMessageContent content) {
    showDialog<void>(
      context: context,
      builder: (_) => ImagePreviewDialog(
        url: content.url,
        mimeType: content.mimeType,
        localPath: content.localPath,
      ),
    );
  }

  void _openVideoPlayer(VideoMessageContent content) {
    showDialog<void>(
      context: context,
      builder: (_) => VideoPlayerBoundaryDialog(
        url: content.url,
        mimeType: content.mimeType,
        localPath: content.localPath,
        durationMs: content.durationMs,
        thumbnailUrl: content.thumbnailUrl,
      ),
    );
  }

  void _showFeedback(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : const Color(0xff24243a),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _send(MessageContent content, {String? clientId}) {
    final draft = MessageDraft(
      clientId: clientId ?? 'local-${DateTime.now().microsecondsSinceEpoch}',
      roomId: _activeRoomId,
      senderId: 'You',
      content: content,
      createdAt: DateTime.now(),
      isMine: true,
    );
    return ref
        .read(sendMessageProvider)(draft)
        .then<void>((_) {
          _scrollToLatest();
        })
        .catchError((_) {
          _scrollToLatest();
        });
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _retry(ChatMessage message) {
    unawaited(_send(message.content, clientId: message.clientId));
  }

  void _interact(ChatMessage message) {
    _syncBubbleBounds();
    _world.interact(message.clientId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final messageState = ref.watch(roomMessagesProvider(_activeRoomId));
    final connectionState = ref.watch(
      messageConnectionStateProvider(_activeRoomId),
    );
    final messages = messageState.asData?.value;
    if (messages != null) {
      _world.setMessageBubbleTargets(messages);
    }
    final messageCount = messageState.asData?.value.length;
    if (messageCount != null) {
      final hasNewMessage =
          _lastMessageCount > 0 && messageCount > _lastMessageCount;
      _lastMessageCount = messageCount;
      if (hasNewMessage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          }
        });
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncBubbleBounds());

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _room.name,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(_room.subtitle, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xfff0f2f8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xffdcdfe8)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final pet in PetType.values)
                      _PetSwitchButton(
                        petType: pet,
                        isSelected: _world.selectedPet == pet,
                        onTap: () => setState(() => _world.setPet(pet)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _RoomSelector(
            rooms: _rooms,
            activeRoomId: _activeRoomId,
            onSelected: _selectRoom,
          ),
          _ConnectionBanner(state: connectionState),
          Expanded(
            child: Stack(
              key: _stackKey,
              children: [
                messageState.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('載入失敗：$error')),
                  data: (messages) => ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 104),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final key = _cardKeys.putIfAbsent(
                        message.clientId,
                        GlobalKey.new,
                      );
                      return _MessageCard(
                        cardKey: key,
                        message: message,
                        controller: _world,
                        onTap: () => _interact(message),
                        onOpenImagePreview:
                            message.content is ImageMessageContent
                            ? () => _openImagePreview(
                                message.content as ImageMessageContent,
                              )
                            : null,
                        onOpenVideoPlayer:
                            message.content is VideoMessageContent
                            ? () => _openVideoPlayer(
                                message.content as VideoMessageContent,
                              )
                            : null,
                        onRetry: message.status == MessageDeliveryStatus.failed
                            ? () => _retry(message)
                            : null,
                      );
                    },
                  ),
                ),
                PetWorldOverlay(room: _room, controller: _world),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: _MessageComposer(
          controller: _composerController,
          onSend: _sendText,
          onAttachment: _sendDemoMedia,
          onPickedMedia: _sendPickedMedia,
          onError: (msg) => _showFeedback(msg, isError: true),
        ),
      ),
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.state});

  final AsyncValue<MessageConnectionState> state;

  @override
  Widget build(BuildContext context) {
    final connection = state.valueOrNull;
    if (connection == null ||
        connection == MessageConnectionState.connected ||
        connection == MessageConnectionState.disconnected) {
      return const SizedBox.shrink();
    }
    final (label, color, icon) = switch (connection) {
      MessageConnectionState.connecting => ('連線中…', Colors.orange, Icons.sync),
      MessageConnectionState.reconnecting => (
        '重新連線中…',
        Colors.orange,
        Icons.sync_problem,
      ),
      MessageConnectionState.offline => ('目前離線', Colors.grey, Icons.cloud_off),
      MessageConnectionState.error => ('連線失敗', Colors.red, Icons.error_outline),
      MessageConnectionState.disconnected => (
        '尚未連線',
        Colors.grey,
        Icons.cloud_off,
      ),
      MessageConnectionState.connected => ('', Colors.transparent, Icons.cloud),
    };
    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

class _RoomSelector extends StatelessWidget {
  const _RoomSelector({
    required this.rooms,
    required this.activeRoomId,
    required this.onSelected,
  });

  final List<ChatRoom> rooms;
  final String activeRoomId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 62,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      scrollDirection: Axis.horizontal,
      itemCount: rooms.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final room = rooms[index];
        return ChoiceChip(
          label: Text(room.name),
          selected: room.id == activeRoomId,
          onSelected: (_) => onSelected(room.id),
        );
      },
    ),
  );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.cardKey,
    required this.message,
    required this.controller,
    this.onTap,
    this.onOpenImagePreview,
    this.onOpenVideoPlayer,
    this.onRetry,
  });

  final GlobalKey cardKey;
  final ChatMessage message;
  final PetWorldController controller;
  final VoidCallback? onTap;
  final VoidCallback? onOpenImagePreview;
  final VoidCallback? onOpenVideoPlayer;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = message.isMine ? const Color(0xff6c63ff) : Colors.white;
    final textColor = message.isMine ? Colors.white : const Color(0xff24243a);

    return Align(
      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedBuilder(
          animation: controller.springNotifier,
          builder: (context, child) {
            final deflection = controller.getBubbleDeflection(message.clientId);
            final scaleY = (1.0 - (deflection / 240.0)).clamp(0.85, 1.15);
            final scaleX = (1.0 + (deflection / 340.0)).clamp(0.90, 1.15);
            return Transform.translate(
              offset: Offset(0, deflection),
              child: Transform(
                transform: Matrix4.diagonal3Values(scaleX, scaleY, 1.0),
                alignment: Alignment.bottomCenter,
                child: child,
              ),
            );
          },
          child: Container(
            key: cardKey,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: const BoxConstraints(maxWidth: 300),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(18).copyWith(
                bottomRight: message.isMine ? const Radius.circular(4) : null,
                bottomLeft: !message.isMine ? const Radius.circular(4) : null,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MessageContentView(
                  message: message,
                  textColor: textColor,
                  onOpenImagePreview: onOpenImagePreview,
                  onOpenVideoPlayer: onOpenVideoPlayer,
                ),
                if (message.status != MessageDeliveryStatus.sent)
                  _MessageStatus(
                    message: message,
                    textColor: textColor,
                    onRetry: onRetry,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageContentView extends StatelessWidget {
  const _MessageContentView({
    required this.message,
    required this.textColor,
    this.onOpenImagePreview,
    this.onOpenVideoPlayer,
  });

  final ChatMessage message;
  final Color textColor;
  final VoidCallback? onOpenImagePreview;
  final VoidCallback? onOpenVideoPlayer;

  @override
  Widget build(BuildContext context) => switch (message.content) {
    TextMessageContent(:final text) => Text(
      text,
      style: TextStyle(color: textColor, fontSize: 15),
    ),
    ImageMessageContent(:final url, :final mimeType, :final localPath) =>
      _ImageMessageCard(
        url: url,
        mimeType: mimeType,
        localPath: localPath,
        textColor: textColor,
        uploadProgress: message.status == MessageDeliveryStatus.uploading
            ? message.uploadProgress
            : null,
        onPreview: onOpenImagePreview,
      ),
    VideoMessageContent(
      :final url,
      :final mimeType,
      :final localPath,
      :final durationMs,
    ) =>
      _VideoMessageCard(
        url: url,
        mimeType: mimeType,
        localPath: localPath,
        durationMs: durationMs,
        textColor: textColor,
        uploadProgress: message.status == MessageDeliveryStatus.uploading
            ? message.uploadProgress
            : null,
        onPlay: onOpenVideoPlayer,
      ),
  };
}

class _ImageMessageCard extends StatelessWidget {
  const _ImageMessageCard({
    required this.url,
    required this.mimeType,
    this.localPath,
    this.uploadProgress,
    required this.textColor,
    this.onPreview,
  });

  final String url;
  final String mimeType;
  final String? localPath;
  final double? uploadProgress;
  final Color textColor;
  final VoidCallback? onPreview;

  String get label {
    final source = localPath ?? url;
    return source.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    final hasLocal = localPath != null && File(localPath!).existsSync();
    final isNetwork = url.startsWith('http://') || url.startsWith('https://');
    final isAsset = url.startsWith('assets/') || url.startsWith('asset:');

    if (!hasLocal && !isNetwork && !isAsset) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            mimeType == 'image/gif'
                ? Icons.gif_box_outlined
                : Icons.image_outlined,
            color: textColor.withValues(alpha: 0.8),
            size: 22,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: textColor, fontSize: 15),
            ),
          ),
          if (onPreview != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onPreview,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.fullscreen_rounded,
                  size: 18,
                  color: textColor.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ],
      );
    }

    Widget fallbackBox(String message) => Container(
      width: 240,
      height: 140,
      color: Colors.black12,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 36,
            color: textColor.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 4),
          Text(message, style: TextStyle(color: textColor, fontSize: 12)),
        ],
      ),
    );

    Widget imageWidget;
    if (hasLocal) {
      imageWidget = Image.file(
        File(localPath!),
        width: 240,
        height: 140,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallbackBox('無法載入本機圖片'),
      );
    } else if (isNetwork) {
      imageWidget = Image.network(
        url,
        width: 240,
        height: 140,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallbackBox('無法載入網路圖片'),
      );
    } else {
      imageWidget = Image.asset(
        url.replaceFirst('asset:', ''),
        width: 240,
        height: 140,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallbackBox('無法載入資源圖片'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              imageWidget,
              if (uploadProgress != null)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 34,
                          height: 34,
                          child: CircularProgressIndicator(
                            value: uploadProgress,
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${(uploadProgress! * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              mimeType == 'image/gif'
                  ? Icons.gif_box_outlined
                  : Icons.image_outlined,
              size: 16,
              color: textColor.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onPreview != null) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: onPreview,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.fullscreen_rounded,
                    size: 18,
                    color: textColor.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _VideoMessageCard extends StatelessWidget {
  const _VideoMessageCard({
    required this.url,
    required this.mimeType,
    this.localPath,
    this.durationMs,
    this.uploadProgress,
    required this.textColor,
    this.onPlay,
  });

  final String url;
  final String mimeType;
  final String? localPath;
  final int? durationMs;
  final double? uploadProgress;
  final Color textColor;
  final VoidCallback? onPlay;

  String get label {
    final source = localPath ?? url;
    return source.split('/').last;
  }

  String _formatDuration(int? ms) {
    if (ms == null) return '';
    final seconds = ms ~/ 1000;
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 240,
                height: 130,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff2b2d42), Color(0xff1f2030)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              IconButton(
                iconSize: 44,
                tooltip: '播放影片',
                icon: const Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                ),
                onPressed: onPlay,
              ),
              if (durationMs != null)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _formatDuration(durationMs),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              if (uploadProgress != null)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 34,
                          height: 34,
                          child: CircularProgressIndicator(
                            value: uploadProgress,
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${(uploadProgress! * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.movie_outlined,
              size: 16,
              color: textColor.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onPlay != null) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: onPlay,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    color: textColor.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _MessageStatus extends StatelessWidget {
  const _MessageStatus({
    required this.message,
    required this.textColor,
    this.onRetry,
  });

  final ChatMessage message;
  final Color textColor;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isFailed = message.status == MessageDeliveryStatus.failed;
    final label = isFailed
        ? '發送失敗'
        : message.status == MessageDeliveryStatus.uploading
        ? '上傳 ${(message.uploadProgress * 100).round()}%'
        : '發送中…';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isFailed)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: message.status == MessageDeliveryStatus.uploading
                    ? message.uploadProgress
                    : null,
                color: textColor.withValues(alpha: 0.8),
              ),
            ),
          if (!isFailed) const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.75),
              fontSize: 11,
            ),
          ),
          if (isFailed && onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: textColor,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(44, 32),
              ),
              child: const Text('重試'),
            ),
        ],
      ),
    );
  }
}

enum _AttachmentChoice {
  pickGalleryImage,
  pickCameraImage,
  pickGalleryVideo,
  pickCameraVideo,
  fakeImage,
  fakeVideo,
}

class _MessageComposer extends ConsumerWidget {
  const _MessageComposer({
    required this.controller,
    required this.onSend,
    required this.onAttachment,
    required this.onPickedMedia,
    required this.onError,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final ValueChanged<_DemoAttachment> onAttachment;
  final ValueChanged<PickedMediaFile> onPickedMedia;
  final ValueChanged<String> onError;

  Future<void> _handleAttachment(BuildContext context, WidgetRef ref) async {
    final choice = await showDialog<_AttachmentChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增附件'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: Color(0xff6c63ff),
                ),
                title: const Text('從相簿選擇圖片'),
                subtitle: const Text('選取本機或電腦圖片 (JPG, PNG, GIF, WebP)'),
                onTap: () => Navigator.of(
                  context,
                ).pop(_AttachmentChoice.pickGalleryImage),
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: Color(0xff6c63ff),
                ),
                title: const Text('拍攝照片'),
                subtitle: const Text('開啟相機拍攝（行動裝置支援）'),
                onTap: () => Navigator.of(
                  context,
                ).pop(_AttachmentChoice.pickCameraImage),
              ),
              ListTile(
                leading: const Icon(
                  Icons.video_library_outlined,
                  color: Color(0xff6c63ff),
                ),
                title: const Text('從相簿選擇影片'),
                subtitle: const Text('選取本機或電腦影片 (MP4, MOV，最大 50MB)'),
                onTap: () => Navigator.of(
                  context,
                ).pop(_AttachmentChoice.pickGalleryVideo),
              ),
              ListTile(
                leading: const Icon(
                  Icons.videocam_outlined,
                  color: Color(0xff6c63ff),
                ),
                title: const Text('錄製影片'),
                subtitle: const Text('開啟攝影機錄製（行動裝置支援）'),
                onTap: () => Navigator.of(
                  context,
                ).pop(_AttachmentChoice.pickCameraVideo),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('圖片（fake）'),
                onTap: () =>
                    Navigator.of(context).pop(_AttachmentChoice.fakeImage),
              ),
              ListTile(
                leading: const Icon(Icons.video_file_outlined),
                title: const Text('影片（fake）'),
                onTap: () =>
                    Navigator.of(context).pop(_AttachmentChoice.fakeVideo),
              ),
            ],
          ),
        ),
      ),
    );

    if (choice == null) return;
    final picker = ref.read(mediaPickerServiceProvider);

    try {
      switch (choice) {
        case _AttachmentChoice.pickGalleryImage:
          final file = await picker.pickImage(
            source: MediaPickerSource.gallery,
          );
          if (file != null) onPickedMedia(file);
        case _AttachmentChoice.pickCameraImage:
          final file = await picker.pickImage(source: MediaPickerSource.camera);
          if (file != null) onPickedMedia(file);
        case _AttachmentChoice.pickGalleryVideo:
          final file = await picker.pickVideo(
            source: MediaPickerSource.gallery,
          );
          if (file != null) onPickedMedia(file);
        case _AttachmentChoice.pickCameraVideo:
          final file = await picker.pickVideo(source: MediaPickerSource.camera);
          if (file != null) onPickedMedia(file);
        case _AttachmentChoice.fakeImage:
          onAttachment(_DemoAttachment.image);
        case _AttachmentChoice.fakeVideo:
          onAttachment(_DemoAttachment.video);
      }
    } on MediaValidationException catch (e) {
      onError(e.message);
    } catch (e) {
      onError('選擇媒體失敗：$e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        children: [
          IconButton(
            tooltip: '新增附件',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _handleAttachment(context, ref),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              onSubmitted: onSend,
              decoration: const InputDecoration(
                hintText: '輸入訊息…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(22)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: '發送',
            onPressed: () => onSend(controller.text),
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    ),
  );
}

enum _DemoAttachmentKind { image, video }

class _DemoAttachment {
  const _DemoAttachment({
    required this.kind,
    required this.url,
    required this.mimeType,
  });

  static const image = _DemoAttachment(
    kind: _DemoAttachmentKind.image,
    url: 'photo.jpg',
    mimeType: 'image/jpeg',
  );

  static const video = _DemoAttachment(
    kind: _DemoAttachmentKind.video,
    url: 'clip.mp4',
    mimeType: 'video/mp4',
  );

  final _DemoAttachmentKind kind;
  final String url;
  final String mimeType;
}

class _PetSwitchButton extends StatelessWidget {
  const _PetSwitchButton({
    required this.petType,
    required this.isSelected,
    required this.onTap,
  });

  final PetType petType;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final config = PetConfig.of(petType);
    final theme = Theme.of(context);

    return Tooltip(
      message: config.displayName,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.35,
                        ),
                        blurRadius: 5,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(config.avatarEmoji, style: const TextStyle(fontSize: 16)),
                if (isSelected) ...[
                  const SizedBox(width: 4),
                  Text(
                    config.voiceGreeting,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
