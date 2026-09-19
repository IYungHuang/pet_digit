import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../chat/domain/chat_models.dart';
import '../domain/pet_effects.dart';
import '../domain/pet_world.dart';
import '../domain/pet_world_controller.dart';
import 'pixel_pet.dart';

class PetWorldOverlay extends StatefulWidget {
  const PetWorldOverlay({
    super.key,
    required this.room,
    required this.controller,
  });

  final ChatRoom room;
  final PetWorldController controller;

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
    _ticker = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_onTick)
      ..repeat();
  }

  void _onTick() {
    final now = _ticker.lastElapsedDuration ?? Duration.zero;
    widget.controller.tick(now - _last);
    _last = now;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaceY = widget.controller.currentSurfaceY;
    final h = widget.controller.heightAboveSurface;
    final shadowScale = (1.0 - (h / 120.0)).clamp(0.55, 1.0);
    final shadowWidth = 38.0 * shadowScale;
    final shadowHeight = 8.0 * shadowScale;
    final shadowOpacity = (0.28 * (1.0 - (h / 90.0))).clamp(0.08, 0.28);
    final shadowCenterX = widget.controller.position.dx + 32.0;

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: true,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Render paw prints / feather trails (fading footsteps left behind while walking/running)
            for (final paw in widget.controller.pawPrints)
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
                      widget.controller.petConfig.trailAsset,
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
            for (final particle in widget.controller.particles
                .where((p) => p.kind == ParticleKind.dust))
              Positioned(
                left: particle.position.dx - particle.currentSize / 2,
                top: particle.position.dy - particle.currentSize / 2,
                child: Opacity(
                  opacity: particle.opacity,
                  child: Container(
                    width: particle.currentSize,
                    height: particle.currentSize,
                    decoration: const BoxDecoration(
                      color: Color(0x778892a4),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

            // 4. Render bouncing emoji toy (Video 2: Emoji chasing)
            if (widget.controller.bouncingToy != null)
              Positioned(
                left: widget.controller.bouncingToy!.position.dx - 16,
                top: widget.controller.bouncingToy!.position.dy - 16,
                child: Transform.rotate(
                  angle: widget.controller.bouncingToy!.rotation,
                  child: Text(
                    widget.controller.bouncingToy!.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),

            // 5. Render Pixel Pet
            Positioned(
              left: widget.controller.position.dx,
              top: widget.controller.position.dy,
              child: PixelPet(
                petType: widget.controller.selectedPet,
                state: widget.controller.state,
                direction: widget.controller.direction,
                frameIndex: widget.controller.frameIndex,
              ),
            ),

            // 6. Render floating particles (hearts, notes, feathers above pet)
            for (final particle in widget.controller.particles
                .where((p) => p.kind != ParticleKind.dust))
              Positioned(
                left: particle.position.dx - particle.currentSize / 2,
                top: particle.position.dy - particle.currentSize / 2,
                child: Opacity(
                  opacity: particle.opacity,
                  child: _buildParticleWidget(particle),
                ),
              ),

            // 7. Status reaction badge (pounce! / watching)
            if (widget.controller.state == PetState.pounce ||
                widget.controller.state == PetState.observe)
              Positioned(
                left: widget.controller.position.dx,
                top: (widget.controller.position.dy - 26).clamp(4, 1000),
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
                      widget.controller.state == PetState.pounce
                          ? widget.controller.petConfig.pounceLabel
                          : widget.controller.petConfig.observeLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticleWidget(PetParticle particle) {
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
