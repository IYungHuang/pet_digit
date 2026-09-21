import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/data/fake_chat_repository.dart';
import '../../chat/application/message_delta.dart';
import '../../chat/domain/chat_message.dart';
import '../../chat/domain/chat_models.dart' show ChatRoom;
import '../../chat/domain/media_policy.dart';
import '../../chat/domain/message_content.dart';
import '../../chat/domain/message_draft.dart';
import '../../chat/domain/message_status.dart';
import '../../chat/domain/message_connection_state.dart';
import '../../pet/domain/pet_world.dart';
import '../../pet/domain/pet_world_controller.dart';
import '../../pet/domain/pet_message_target_factory.dart';
import '../../pet/presentation/pet_world_overlay.dart';
import '../../firebase/firebase_environment.dart';
import '../application/media_picker_service.dart';
import 'chat_providers.dart';
import 'chat_timeline_policy.dart';
import 'widgets/media_preview_dialog.dart';
import '../../user/presentation/user_pet_providers.dart';
import '../../user/presentation/widgets/create_room_dialog.dart';
import '../../user/presentation/widgets/my_pets_backpack_dialog.dart';
import '../../user/presentation/widgets/onboarding_wizard_dialog.dart';
import '../../user/presentation/widgets/room_pet_summon_dialog.dart';
import '../../pet/domain/pet_profile.dart';
import '../../pet/domain/pet_room_snapshot.dart';

class ChatShell extends ConsumerStatefulWidget {
  const ChatShell({
    super.key,
    this.showDemoAttachments = false,
    this.autoShowOnboarding = false,
  });

  final bool showDemoAttachments;
  final bool autoShowOnboarding;

  @override
  ConsumerState<ChatShell> createState() => _ChatShellState();
}

class _ChatShellState extends ConsumerState<ChatShell> {
  final _rooms = FakeChatRepository.rooms;
  final _world = PetWorldController();
  final _roomPetControllers = <String, PetWorldController>{};
  Map<String, Rect> _lastBoundsMap = const {};
  Size _lastViewportSize = Size.zero;
  String? _lastPrimaryPetId;
  final _stackKey = GlobalKey();
  final _scrollController = ScrollController();
  final _composerController = TextEditingController();
  final Map<String, GlobalKey> _cardKeys = {};
  final Map<String, double> _roomScrollOffsets = {};
  final Map<String, String> _roomDrafts = {};
  var _activeRoomId = 'friends';
  var _lastMessageCount = 0;
  var _isNearBottom = true;
  var _hasNewMessages = false;
  var _bubbleBoundsSyncScheduled = false;
  var _checkedFirstTimeUser = false;
  final Set<String> _retryingClientIds = <String>{};

  ChatRoom get _room => FakeChatRepository.roomById(_activeRoomId);

  @override
  void initState() {
    super.initState();
    _world.loadRoom(_room);
    _scrollController.addListener(_scheduleBubbleBoundsSync);
    _scrollController.addListener(_handleScroll);
    _composerController.addListener(_saveDraft);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncBubbleBounds());
  }

  @override
  void dispose() {
    _composerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _saveDraft() {
    _roomDrafts[_activeRoomId] = _composerController.text;
  }

  void _handlePetMessageDelta(MessageDelta delta) {
    if (delta case MessageAdded(
      :final message,
      :final origin,
    ) when message.roomId == _activeRoomId) {
      if (origin == MessageAddedOrigin.localOptimistic) return;
      _world.handleMessageAdded(
        message,
        isLive: origin != MessageAddedOrigin.initialSnapshot,
      );
    } else if (delta case MessageModified(:final message)
        when message.roomId == _activeRoomId &&
            message.isMine &&
            message.status == MessageDeliveryStatus.sent) {
      _world.handleMessageAdded(message, isLive: true);
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final isNearBottom = ChatTimelinePolicy.isNearBottom(
      pixels: _scrollController.position.pixels,
      maxScrollExtent: _scrollController.position.maxScrollExtent,
    );
    _roomScrollOffsets[_activeRoomId] = _scrollController.position.pixels;
    if (isNearBottom != _isNearBottom) {
      _isNearBottom = isNearBottom;
      if (isNearBottom && _hasNewMessages && mounted) {
        setState(() => _hasNewMessages = false);
      }
    }
  }

  void _syncBubbleBounds() {
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || !stackBox.hasSize) return;
    _lastViewportSize = stackBox.size;
    _world.updateViewportSize(stackBox.size);
    for (final c in _roomPetControllers.values) {
      c.updateViewportSize(stackBox.size);
    }

    final boundsMap = <String, Rect>{};
    for (final entry in _cardKeys.entries) {
      final cardBox =
          entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (cardBox != null && cardBox.hasSize) {
        final topLeft = cardBox.localToGlobal(Offset.zero, ancestor: stackBox);
        boundsMap[entry.key] = topLeft & cardBox.size;
      }
    }
    _lastBoundsMap = boundsMap;
    if (boundsMap.isNotEmpty) {
      _world.updateObjectBounds(boundsMap);
      for (final c in _roomPetControllers.values) {
        c.updateObjectBounds(boundsMap);
      }
    }
  }

  void _scheduleBubbleBoundsSync() {
    if (_bubbleBoundsSyncScheduled) return;
    _bubbleBoundsSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bubbleBoundsSyncScheduled = false;
      if (mounted) _syncBubbleBounds();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _selectRoom(String id) {
    _saveDraft();
    if (_scrollController.hasClients) {
      _roomScrollOffsets[_activeRoomId] = _scrollController.position.pixels;
    }
    setState(() {
      _activeRoomId = id;
      _cardKeys.clear();
      _roomPetControllers.clear();
      _lastPrimaryPetId = null;
      _lastMessageCount = 0;
      _hasNewMessages = false;
      _isNearBottom = true;
      _world.loadRoom(_room);
    });
    _resetStagingMembershipForRoomSwitch();
    _composerController.value = TextEditingValue(
      text: _roomDrafts[id] ?? '',
      selection: TextSelection.collapsed(
        offset: (_roomDrafts[id] ?? '').length,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncBubbleBounds());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final offset = _roomScrollOffsets[id];
      if (offset == null) return;
      _scrollController.jumpTo(
        offset.clamp(0, _scrollController.position.maxScrollExtent),
      );
    });
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
        _scheduleBubbleBoundsSync();
        _isNearBottom = true;
        if (_hasNewMessages && mounted) setState(() => _hasNewMessages = false);
      }
    });
  }

  bool get _roomAccessReady {
    final status = ref.read(stagingMembershipControllerProvider);
    return status == StagingMembershipStatus.ready ||
        status == StagingMembershipStatus.notRequired;
  }

  void _reconnect() {
    if (!_roomAccessReady) return;
    if (_scrollController.hasClients) {
      _roomScrollOffsets[_activeRoomId] = _scrollController.position.pixels;
    }
    unawaited(ref.read(chatRepositoryProvider).reconnect());
  }

  /// Invalidates the room-scoped providers so they re-evaluate against the
  /// current staging membership gate. Shared by [_retryMembership] and
  /// [_resetStagingMembershipForRoomSwitch] so the two call sites can't
  /// drift apart.
  void _invalidateRoomScopedProviders() {
    ref.invalidate(roomMessagesProvider(_activeRoomId));
    ref.invalidate(chatConnectionProvider);
    ref.invalidate(messageDeltaProvider);
    ref.invalidate(messageConnectionStateProvider);
    ref.invalidate(sendMessageProvider);
  }

  /// Resets the staging membership gate back to `waiting` when switching
  /// rooms, so a room switch can't silently inherit membership proven for a
  /// different room. Fake/emulator transports never require this gate and
  /// stay `notRequired`.
  void _resetStagingMembershipForRoomSwitch() {
    final environment = ref.read(firebaseEnvironmentProvider);
    if (environment.mode != FirebaseEnvironmentMode.staging) return;
    ref.read(stagingMembershipControllerProvider.notifier).reset();
    _invalidateRoomScopedProviders();
  }

  Future<void> _retryMembership() async {
    final controller = ref.read(stagingMembershipControllerProvider.notifier);
    final success = await controller.verify(_activeRoomId);
    if (!success || !mounted) return;
    _invalidateRoomScopedProviders();
  }

  void _retry(ChatMessage message) {
    if (!_retryingClientIds.add(message.clientId)) return;
    setState(() {});
    unawaited(
      _send(message.content, clientId: message.clientId).whenComplete(() {
        if (mounted) {
          setState(() => _retryingClientIds.remove(message.clientId));
        }
      }),
    );
  }

  void _interact(ChatMessage message) {
    _syncBubbleBounds();
    _world.interact(PetMessageTargetFactory.domainMessageId(message));
    setState(() {});
  }

  Widget _buildMessageCard(ChatMessage message) {
    final key = _cardKeys.putIfAbsent(
      PetMessageTargetFactory.domainMessageId(message),
      GlobalKey.new,
    );
    return _MessageCard(
      cardKey: key,
      message: message,
      controller: _world,
      onTap: () => _interact(message),
      onOpenImagePreview: message.content is ImageMessageContent
          ? () => _openImagePreview(message.content as ImageMessageContent)
          : null,
      onOpenVideoPlayer: message.content is VideoMessageContent
          ? () => _openVideoPlayer(message.content as VideoMessageContent)
          : null,
      onRetry:
          message.status == MessageDeliveryStatus.failed &&
              !_retryingClientIds.contains(message.clientId)
          ? () => _retry(message)
          : null,
      retrying: _retryingClientIds.contains(message.clientId),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(messageDeltaProvider, (_, next) {
      next.whenData(_handlePetMessageDelta);
    });
    final messageState = ref.watch(roomMessagesProvider(_activeRoomId));
    final connectionState = ref.watch(messageConnectionStateProvider);
    final membershipStatus = ref.watch(stagingMembershipControllerProvider);
    final membershipUid = ref.watch(firebaseAuthProvider)?.currentUser?.uid;
    final roomAccessReady =
        membershipStatus == StagingMembershipStatus.ready ||
        membershipStatus == StagingMembershipStatus.notRequired;
    final messages = messageState.asData?.value;
    if (messages != null) {
      _world.setMessageBubbleTargets(messages, roomId: _activeRoomId);
      for (final c in _roomPetControllers.values) {
        c.setMessageBubbleTargets(messages, roomId: _activeRoomId);
      }
    }
    final messageCount = messageState.asData?.value.length;
    if (messageCount != null) {
      final hasNewMessage =
          _lastMessageCount > 0 && messageCount > _lastMessageCount;
      _lastMessageCount = messageCount;
      if (hasNewMessage) {
        if (ChatTimelinePolicy.shouldFollowNewMessage(
          isNearBottom: _isNearBottom,
        )) {
          _scrollToLatest();
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _hasNewMessages = true);
          });
        }
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncBubbleBounds());

    final isFirstTime = ref.watch(isFirstTimeUserProvider);
    if (widget.autoShowOnboarding && isFirstTime && !_checkedFirstTimeUser) {
      _checkedFirstTimeUser = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) OnboardingWizardDialog.show(context);
      });
    }

    final roomSummariesAsync = ref.watch(userRoomSummariesProvider);
    final currentRooms = roomSummariesAsync.maybeWhen(
      data: (summaries) {
        if (summaries.isEmpty) return _rooms;
        final list = <ChatRoom>[];
        for (final s in summaries) {
          final existingIndex = _rooms.indexWhere((r) => r.id == s.roomId);
          if (existingIndex != -1) {
            list.add(_rooms[existingIndex]);
          } else {
            list.add(ChatRoom(
              id: s.roomId,
              name: s.name,
              subtitle: s.lastMessageText ?? '即時聊天室',
              messages: const [],
            ));
          }
        }
        for (final r in _rooms) {
          if (!list.any((item) => item.id == r.id)) {
            list.add(r);
          }
        }
        return list;
      },
      orElse: () => _rooms,
    );

    final roomMembersAsync = ref.watch(roomMembersProvider(_activeRoomId));
    final activePets = <PetRoomSnapshot>[];
    roomMembersAsync.whenData((members) {
      for (final m in members) {
        if (m.active) {
          activePets.addAll(m.pets);
        }
      }
    });

    final activeControllers = <PetWorldController>[_world];
    if (activePets.isNotEmpty) {
      final primary = activePets.first;
      if (_lastPrimaryPetId != primary.petId) {
        _lastPrimaryPetId = primary.petId;
        _world.id = primary.petId;
        _world.name = primary.name;
        _world.selectedPet = primary.species.toPetType();
      } else {
        _world.name = primary.name;
      }

      final remainingPets = activePets.skip(1).toList();
      final remainingIds = remainingPets.map((p) => p.petId).toSet();
      _roomPetControllers.removeWhere((id, _) => !remainingIds.contains(id));

      for (var i = 0; i < remainingPets.length; i++) {
        final pet = remainingPets[i];
        final existing = _roomPetControllers[pet.petId];
        if (existing == null) {
          final spawnX = 24.0 + ((i + 1) * 72.0);
          final c = PetWorldController(
            id: pet.petId,
            name: pet.name,
            spawnOffset: Offset(spawnX.clamp(24.0, 260.0), 24.0),
          )..selectedPet = pet.species.toPetType();
          c.loadRoom(_room);
          c.updateViewportSize(_lastViewportSize);
          if (_lastBoundsMap.isNotEmpty) {
            c.updateObjectBounds(_lastBoundsMap);
          }
          if (messages != null) {
            c.setMessageBubbleTargets(messages, roomId: _activeRoomId);
          }
          _roomPetControllers[pet.petId] = c;
          activeControllers.add(c);
        } else {
          existing.name = pet.name;
          existing.selectedPet = pet.species.toPetType();
          activeControllers.add(existing);
        }
      }
    } else {
      _roomPetControllers.clear();
    }

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
          IconButton(
            tooltip: '我的毛孩背包',
            icon: const Icon(Icons.backpack_outlined, color: Color(0xff4361ee)),
            onPressed: () => MyPetsBackpackDialog.show(context),
          ),
          IconButton(
            tooltip: '毛孩出動調度',
            icon: const Icon(Icons.pets_rounded, color: Color(0xff4361ee)),
            onPressed: () => RoomPetSummonDialog.show(
              context,
              roomId: _activeRoomId,
            ),
          ),
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
            rooms: currentRooms,
            activeRoomId: _activeRoomId,
            onSelected: _selectRoom,
            onCreateRoom: () => CreateRoomDialog.show(
              context,
              onRoomCreated: _selectRoom,
            ),
          ),
          _MembershipBanner(
            status: membershipStatus,
            uid: membershipUid,
            onRetry: _retryMembership,
          ),
          if (roomAccessReady)
            _ConnectionBanner(state: connectionState, onReconnect: _reconnect),
          Expanded(
            child: Stack(
              key: _stackKey,
              children: [
                Positioned.fill(
                  child: messageState.when(
                    loading: () => const _TimelineLoading(),
                    error: (error, _) => _TimelineError(
                      onRetry: () =>
                          ref.invalidate(roomMessagesProvider(_activeRoomId)),
                    ),
                    data: (messages) => LayoutBuilder(
                      builder: (context, constraints) {
                        const verticalPadding = 44.0;
                        final minTimelineHeight =
                            constraints.maxHeight > verticalPadding
                            ? constraints.maxHeight - verticalPadding
                            : 0.0;
                        final content = messages.isEmpty
                            ? const <Widget>[_TimelineEmpty()]
                            : messages.map(_buildMessageCard).toList();
                        final timelineWidth = constraints.maxWidth > 900
                            ? 900.0
                            : constraints.maxWidth;
                        return Center(
                          child: SizedBox(
                            width: timelineWidth,
                            height: constraints.maxHeight,
                            child: ListView(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                20,
                                18,
                                24,
                              ),
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: minTimelineHeight,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: messages.isEmpty
                                        ? MainAxisAlignment.center
                                        : MainAxisAlignment.end,
                                    children: content,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (_hasNewMessages)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Center(
                      child: FilledButton.tonalIcon(
                        onPressed: _scrollToLatest,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        label: const Text('有新訊息'),
                      ),
                    ),
                  ),
                PetWorldOverlay(
                  room: _room,
                  controller: _world,
                  controllers: activeControllers,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: _MessageComposer(
          controller: _composerController,
          enabled: roomAccessReady,
          onSend: _sendText,
          onAttachment: _sendDemoMedia,
          onPickedMedia: _sendPickedMedia,
          onError: (msg) => _showFeedback(msg, isError: true),
          showDemoAttachments: widget.showDemoAttachments,
        ),
      ),
    );
  }
}

class _MembershipBanner extends StatelessWidget {
  const _MembershipBanner({
    required this.status,
    required this.uid,
    required this.onRetry,
  });

  final StagingMembershipStatus status;
  final String? uid;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (status == StagingMembershipStatus.ready ||
        status == StagingMembershipStatus.notRequired) {
      return const SizedBox.shrink();
    }
    final displayUid = uid ?? 'unknown';
    final (label, retryEnabled) = switch (status) {
      StagingMembershipStatus.waiting => (
        'Administrator membership required for $displayUid',
        true,
      ),
      StagingMembershipStatus.checking => (
        'Checking membership for $displayUid…',
        false,
      ),
      StagingMembershipStatus.denied => (
        'Access not ready for $displayUid',
        true,
      ),
      StagingMembershipStatus.ready ||
      StagingMembershipStatus.notRequired => ('', false),
    };
    return Container(
      width: double.infinity,
      color: Colors.orange.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Row(
        children: [
          if (status == StagingMembershipStatus.checking)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(Icons.lock_outline, size: 15, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          TextButton(
            onPressed: retryEnabled ? onRetry : null,
            style: TextButton.styleFrom(minimumSize: const Size(44, 36)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.state, required this.onReconnect});

  final AsyncValue<MessageConnectionState> state;
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    final connection = state.valueOrNull;
    if (connection == null || connection == MessageConnectionState.connected) {
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
          Expanded(
            child: Text(label, style: TextStyle(color: color, fontSize: 12)),
          ),
          if (connection == MessageConnectionState.offline ||
              connection == MessageConnectionState.error ||
              connection == MessageConnectionState.disconnected)
            TextButton(
              onPressed: onReconnect,
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 36),
                foregroundColor: color,
              ),
              child: const Text('重新連線'),
            ),
        ],
      ),
    );
  }
}

class _TimelineLoading extends StatelessWidget {
  const _TimelineLoading();

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
    itemCount: 4,
    itemBuilder: (context, index) => Align(
      alignment: index.isEven ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        width: 180 + (index % 2) * 48,
        height: 52,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),
  );
}

class _TimelineEmpty extends StatelessWidget {
  const _TimelineEmpty();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          const Text('這裡還沒有訊息'),
          const SizedBox(height: 4),
          Text(
            '發送第一則訊息，讓寵物開始互動吧！',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _TimelineError extends StatelessWidget {
  const _TimelineError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('訊息載入失敗'),
          const SizedBox(height: 4),
          Text('請檢查連線後再試一次。', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('重試'),
          ),
        ],
      ),
    ),
  );
}

class _RoomSelector extends StatelessWidget {
  const _RoomSelector({
    required this.rooms,
    required this.activeRoomId,
    required this.onSelected,
    this.onCreateRoom,
  });

  final List<ChatRoom> rooms;
  final String activeRoomId;
  final ValueChanged<String> onSelected;
  final VoidCallback? onCreateRoom;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 62,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      scrollDirection: Axis.horizontal,
      itemCount: rooms.length + (onCreateRoom != null ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        if (index == rooms.length && onCreateRoom != null) {
          return ActionChip(
            avatar: const Icon(Icons.add, size: 16),
            label: const Text('新增對話'),
            onPressed: onCreateRoom,
          );
        }
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
    this.retrying = false,
  });

  final GlobalKey cardKey;
  final ChatMessage message;
  final PetWorldController controller;
  final VoidCallback? onTap;
  final VoidCallback? onOpenImagePreview;
  final VoidCallback? onOpenVideoPlayer;
  final VoidCallback? onRetry;
  final bool retrying;

  String get _semanticsLabel {
    final contentLabel = switch (message.content) {
      TextMessageContent(:final text) => text,
      ImageMessageContent() => '圖片訊息',
      VideoMessageContent() => '影片訊息',
    };
    final statusLabel = switch (message.status) {
      MessageDeliveryStatus.sent => '已送出',
      MessageDeliveryStatus.failed => '送出失敗',
      MessageDeliveryStatus.pending => '準備送出',
      MessageDeliveryStatus.uploading => '上傳中',
      MessageDeliveryStatus.sending => '送出中',
    };
    return '${message.senderId}：$contentLabel，$statusLabel。點擊讓寵物互動。';
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor = message.isMine ? const Color(0xff6c63ff) : Colors.white;
    final textColor = message.isMine ? Colors.white : const Color(0xff24243a);

    return Align(
      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Semantics(
        button: onTap != null,
        label: _semanticsLabel,
        onTap: onTap,
        child: GestureDetector(
          onTap: onTap,
          child: RepaintBoundary(
            key: cardKey,
            child: AnimatedBuilder(
              animation: controller.springNotifier,
              builder: (context, child) {
                final deflection = controller.getBubbleDeflection(
                  PetMessageTargetFactory.domainMessageId(message),
                );
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
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                constraints: const BoxConstraints(maxWidth: 300),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(18).copyWith(
                    bottomRight: message.isMine
                        ? const Radius.circular(4)
                        : null,
                    bottomLeft: !message.isMine
                        ? const Radius.circular(4)
                        : null,
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
                        retrying: retrying,
                      ),
                  ],
                ),
              ),
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
            IconButton(
              onPressed: onPreview,
              tooltip: '預覽圖片',
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.fullscreen_rounded,
                size: 18,
                color: textColor.withValues(alpha: 0.9),
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
              IconButton(
                onPressed: onPreview,
                tooltip: '預覽圖片',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.fullscreen_rounded,
                  size: 18,
                  color: textColor.withValues(alpha: 0.9),
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
              IconButton(
                onPressed: onPlay,
                tooltip: '開啟影片',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.open_in_new_rounded,
                  size: 16,
                  color: textColor.withValues(alpha: 0.9),
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
    this.retrying = false,
  });

  final ChatMessage message;
  final Color textColor;
  final VoidCallback? onRetry;
  final bool retrying;

  String get _failureLabel {
    final error = message.error?.toLowerCase() ?? '';
    if (error.contains('socket') ||
        error.contains('offline') ||
        error.contains('network')) {
      return '目前離線，尚未送出';
    }
    if (error.contains('permission') || error.contains('unauthorized')) {
      return '沒有權限，無法送出';
    }
    if (error.contains('size') || error.contains('format')) {
      return '檔案格式或大小不符合';
    }
    return '發送失敗，可重試';
  }

  @override
  Widget build(BuildContext context) {
    final isFailed = message.status == MessageDeliveryStatus.failed;
    final label = retrying
        ? '重試中…'
        : isFailed
        ? _failureLabel
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
          if (isFailed && retrying)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: textColor.withValues(alpha: 0.8),
              ),
            ),
          if (isFailed && onRetry != null && !retrying)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: textColor,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(44, 32),
              ),
              child: const Text('重試發送'),
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
    required this.enabled,
    required this.onSend,
    required this.onAttachment,
    required this.onPickedMedia,
    required this.onError,
    required this.showDemoAttachments,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onSend;
  final ValueChanged<_DemoAttachment> onAttachment;
  final ValueChanged<PickedMediaFile> onPickedMedia;
  final ValueChanged<String> onError;
  final bool showDemoAttachments;

  Future<void> _handleAttachment(BuildContext context, WidgetRef ref) async {
    final canUseCamera = Platform.isAndroid || Platform.isIOS;
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
              if (canUseCamera)
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xff6c63ff),
                  ),
                  title: const Text('拍攝照片'),
                  subtitle: const Text('開啟相機拍攝'),
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
              if (canUseCamera)
                ListTile(
                  leading: const Icon(
                    Icons.videocam_outlined,
                    color: Color(0xff6c63ff),
                  ),
                  title: const Text('錄製影片'),
                  subtitle: const Text('開啟攝影機錄製'),
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_AttachmentChoice.pickCameraVideo),
                ),
              if (showDemoAttachments) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.image_outlined),
                  title: const Text('圖片（demo）'),
                  onTap: () =>
                      Navigator.of(context).pop(_AttachmentChoice.fakeImage),
                ),
                ListTile(
                  leading: const Icon(Icons.video_file_outlined),
                  title: const Text('影片（demo）'),
                  onTap: () =>
                      Navigator.of(context).pop(_AttachmentChoice.fakeVideo),
                ),
              ],
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
            onPressed: enabled ? () => _handleAttachment(context, ref) : null,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              textInputAction: TextInputAction.send,
              onSubmitted: enabled ? onSend : null,
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
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final canSend = enabled && value.text.trim().isNotEmpty;
              return IconButton(
                tooltip: '發送',
                onPressed: canSend ? () => onSend(value.text) : null,
                icon: const Icon(Icons.send_rounded),
              );
            },
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
