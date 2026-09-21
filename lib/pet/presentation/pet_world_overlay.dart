import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../chat/domain/chat_models.dart';
import '../domain/pet_effects.dart' show ParticleKind;
import '../domain/pet_presentation_state.dart';
import '../domain/pet_world.dart';
import '../domain/pet_world_controller.dart';
import 'pixel_pet.dart';

class PetWorldOverlay extends StatefulWidget {
  const PetWorldOverlay({
    super.key,
    required this.room,
    required this.controller,
    this.controllers = const [],
  });

  final ChatRoom room;
  final PetWorldController controller;
  final List<PetWorldController> controllers;

  List<PetWorldController> get allControllers =>
      controllers.isNotEmpty ? controllers : [controller];

  @override
  State<PetWorldOverlay> createState() => _PetWorldOverlayState();
}

class _PetWorldOverlayState extends State<PetWorldOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker =
        AnimationController(vsync: this, duration: const Duration(days: 1))
          ..addListener(_onTick)
          ..repeat();
  }

  void _onTick() {
    final now = _ticker.lastElapsedDuration ?? Duration.zero;
    final dt = now - _last;
    _last = now;
    for (final c in widget.allControllers) {
      c.tick(dt);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: true,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (final c in widget.allControllers)
              ..._buildPetWidgets(c),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPetWidgets(PetWorldController controller) {
    final presentation = controller.presentationState;
    final config = PetConfig.of(presentation.petType);
    final surfaceY = presentation.surfaceY;
    final h = presentation.heightAboveSurface;
    final shadowScale = (1.0 - (h / 120.0)).clamp(0.55, 1.0);
    final shadowWidth = 38.0 * shadowScale;
    final shadowHeight = 8.0 * shadowScale;
    final shadowOpacity = (0.28 * (1.0 - (h / 90.0))).clamp(0.08, 0.28);
    final shadowCenterX = presentation.position.dx + 32.0;

    return [
      // 1. Render paw prints / feather trails (fading footsteps left behind while walking/running)
      for (final paw in presentation.pawPrints)
        Positioned(
          left: paw.position.dx - 8,
          top: paw.position.dy - 8,
          child: Opacity(
            opacity: (paw.opacity * 0.52).clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: paw.direction > 0
                  ? (math.pi / 2 + (paw.isLeftPaw ? -0.12 : 0.12))
                  : (-math.pi / 2 + (paw.isLeftPaw ? -0.12 : 0.12)),
              child: Image.asset(
                config.trailAsset,
                width: 16,
                height: 16,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                isAntiAlias: false,
              ),
            ),
          ),
        ),

      // 2. Render dynamic projected shadow (anchors pet to floor/bubble and tracks jump height)
      Positioned(
        left: shadowCenterX - shadowWidth / 2,
        top: surfaceY - shadowHeight / 2,
        child: Opacity(
          opacity: shadowOpacity,
          child: Container(
            width: shadowWidth,
            height: shadowHeight,
            decoration: BoxDecoration(
              color: const Color(0xff182236),
              borderRadius: BorderRadius.all(
                Radius.elliptical(shadowWidth / 2, shadowHeight / 2),
              ),
            ),
          ),
        ),
      ),

      // 3. Render ground particles (dust puffs under feet)
      for (final particle in presentation.mainParticles)
        Positioned(
          left: particle.position.dx - particle.size / 2,
          top: particle.position.dy - particle.size / 2,
          child: Opacity(
            opacity: particle.opacity,
            child: Container(
              width: particle.size,
              height: particle.size,
              decoration: const BoxDecoration(
                color: Color(0x778892a4),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),

      // 4. Render bouncing emoji toy (Video 2: Emoji chasing)
      if (presentation.toy != null)
        Positioned(
          left: presentation.toy!.position.dx - 16,
          top: presentation.toy!.position.dy - 16,
          child: Transform.rotate(
            angle: presentation.toy!.rotation,
            child: Text(
              presentation.toy!.emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),

      // 5. Render Pixel Pet
      Positioned(
        left: presentation.position.dx,
        top: presentation.position.dy,
        child: PixelPet(
          petType: presentation.petType,
          state: presentation.petState,
          direction: presentation.direction,
          frameIndex: presentation.frameIndex,
        ),
      ),

      // 6. Render floating particles (hearts, notes, feathers above pet)
      for (final particle in presentation.signatureParticles)
        Positioned(
          left: particle.position.dx - particle.size / 2,
          top: particle.position.dy - particle.size / 2,
          child: Opacity(
            opacity: particle.opacity,
            child: _buildParticleWidget(particle),
          ),
        ),

      // 7. Status reaction badge (pounce! / watching)
      if (presentation.showActionBadge)
        Positioned(
          left: presentation.position.dx,
          top: (presentation.position.dy - 26).clamp(4, 1000),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xff24243a),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              child: Text(
                switch (presentation.petState) {
                  PetState.pounce => config.pounceLabel,
                  PetState.pawTest => 'tap tap',
                  PetState.dogProbe => 'sniff',
                  PetState.parrotProbe => 'inspect',
                  _ => config.observeLabel,
                },
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),

      // 8. Name tag badge above pet
      if (controller.name.isNotEmpty)
        Positioned(
          left: presentation.position.dx - 4,
          top: (presentation.position.dy -
                  (presentation.showActionBadge ? 46 : 22))
              .clamp(2, 1000),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xdd1e2436),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x66ffffff), width: 0.8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2a000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              controller.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
    ];
  }

  Widget _buildParticleWidget(PetParticleSnapshot particle) {
    switch (particle.kind) {
      case ParticleKind.heart:
        return const Text('❤️', style: TextStyle(fontSize: 16));
      case ParticleKind.sparkle:
        return const Text('✨', style: TextStyle(fontSize: 16));
      case ParticleKind.note:
        return const Text('🎵', style: TextStyle(fontSize: 16));
      case ParticleKind.feather:
        return Image.asset(
          'assets/pets/parrot_feather.png',
          width: 16,
          height: 16,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          isAntiAlias: false,
        );
      case ParticleKind.dust:
        return const SizedBox.shrink();
    }
  }
}
