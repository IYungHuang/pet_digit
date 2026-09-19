import 'dart:ui';

enum ParticleKind { dust, heart, sparkle, note, feather }

class PetParticle {
  PetParticle({
    required this.position,
    required this.kind,
    this.velocity = Offset.zero,
    this.maxLifetime = 0.8,
    this.initialSize = 8.0,
  }) : lifetime = maxLifetime;

  Offset position;
  final ParticleKind kind;
  final Offset velocity;
  final double maxLifetime;
  final double initialSize;
  double lifetime;

  bool get isDead => lifetime <= 0;
  double get progress => (1.0 - (lifetime / maxLifetime)).clamp(0.0, 1.0);
  double get opacity => (lifetime / maxLifetime).clamp(0.0, 1.0);
  double get currentSize =>
      initialSize * (kind == ParticleKind.dust ? (1.0 + progress * 0.5) : (1.0 - progress * 0.3));

  void update(double dt) {
    lifetime -= dt;
    position = Offset(
      position.dx + velocity.dx * dt,
      position.dy + velocity.dy * dt,
    );
  }
}

class PawPrint {
  PawPrint({
    required this.position,
    required this.isLeftPaw,
    required this.direction,
    this.maxLifetime = 2.8,
  }) : lifetime = maxLifetime;

  final Offset position;
  final bool isLeftPaw;
  final double direction;
  final double maxLifetime;
  double lifetime;

  bool get isDead => lifetime <= 0;
  double get progress => (1.0 - (lifetime / maxLifetime)).clamp(0.0, 1.0);
  double get opacity => (lifetime / maxLifetime).clamp(0.0, 1.0);

  void update(double dt) {
    lifetime -= dt;
  }
}

class BouncingEmojiToy {
  BouncingEmojiToy({
    required this.emoji,
    required Offset start,
    required this.groundY,
    required this.direction,
  })  : position = start,
        velocityX = direction * 140.0,
        velocityY = -180.0;

  final String emoji;
  final double groundY;
  final double direction;
  Offset position;
  double velocityX;
  double velocityY;
  double rotation = 0.0;
  double lifetime = 0.0;
  bool isCaught = false;

  bool get isFinished => lifetime > 3.5 || (isCaught && lifetime > 0.4);

  void update(double dt) {
    lifetime += dt;
    if (isCaught) return;

    // Apply gravity
    velocityY += 600.0 * dt;
    position = Offset(
      position.dx + velocityX * dt,
      position.dy + velocityY * dt,
    );
    rotation += direction * 5.0 * dt;

    // Bounce off ground
    if (position.dy >= groundY) {
      position = Offset(position.dx, groundY);
      velocityY = -velocityY * 0.65;
      velocityX *= 0.82;
      if (velocityY.abs() < 30) {
        velocityY = 0;
        velocityX = 0;
      }
    }
  }
}

/// Damped harmonic oscillator representing the spring elasticity of a message bubble.
class BubbleSpring {
  double offset = 0.0;
  double velocity = 0.0;

  bool get isActive => offset.abs() > 0.05 || velocity.abs() > 0.5;

  void impulse(double force) {
    velocity += force;
  }

  void update(double dt) {
    if (offset == 0.0 && velocity == 0.0) return;

    // Substep integration to ensure physical stability even if dt is large
    const stepSize = 0.016;
    var remaining = dt;
    while (remaining > 0) {
      final subDt = remaining > stepSize ? stepSize : remaining;
      const k = 320.0;
      const c = 22.0;

      final acceleration = -k * offset - c * velocity;
      velocity += acceleration * subDt;
      offset += velocity * subDt;
      remaining -= subDt;

      if (offset.abs() < 0.1 && velocity.abs() < 0.8) {
        offset = 0.0;
        velocity = 0.0;
        break;
      }
    }
  }
}
