import 'dart:math';
import 'package:flutter/material.dart';
import '../core/models/position.dart';
import '../core/enums/snake_skin.dart';

/// Represents a single particle-like trail element
class TrailSegment {
  final Position position;
  final SnakeSkin skin;
  final int bornAtMs;
  final int lifetimeMs;
  double angle; // for spinning effects
  double vx;   // horizontal drift
  double vy;   // vertical drift

  TrailSegment({
    required this.position,
    required this.skin,
    required this.bornAtMs,
    int? lifetime,
    this.angle = 0.0,
    this.vx = 0.0,
    this.vy = 0.0,
  }) : lifetimeMs = lifetime ?? _defaultLifetime(skin);

  static int _defaultLifetime(SnakeSkin skin) {
    switch (skin) {
      case SnakeSkin.dragon: return 900;     // Long-burning fire embers
      case SnakeSkin.robot: return 700;       // Tron ribbon stays a bit
      case SnakeSkin.golden: return 600;      // Sparkle trail
      case SnakeSkin.rainbow: return 500;     // Short rainbow dabs
      case SnakeSkin.vampire: return 750;     // Blood droplets
      case SnakeSkin.ghost: return 400;       // Wispy, quick
      case SnakeSkin.ninja: return 300;       // Minimal streak
      default: return 350;
    }
  }

  double progress(int nowMs) =>
      ((nowMs - bornAtMs) / lifetimeMs).clamp(0.0, 1.0);

  bool isExpired(int nowMs) => nowMs - bornAtMs >= lifetimeMs;
}

/// Manages skin-specific trail effects for the snake.
/// The game engine populates [add] each tick, and the painter calls [expired]
/// to remove stale segments before drawing.
class TailTrailService {
  static final TailTrailService _instance = TailTrailService._();
  factory TailTrailService() => _instance;
  TailTrailService._();

  final List<TrailSegment> _segments = [];
  final Random _rng = Random();

  List<TrailSegment> get segments => _segments;

  void add(Position position, SnakeSkin skin, int nowMs) {
    // Number of sub-particles per segment depends on skin drama
    int count = 1;
    if (skin == SnakeSkin.dragon || skin == SnakeSkin.golden) count = 3;
    if (skin == SnakeSkin.rainbow) count = 2;

    for (int i = 0; i < count; i++) {
      final jitterX = (_rng.nextDouble() - 0.5) * 0.4;
      final jitterY = (_rng.nextDouble() - 0.5) * 0.4;
      _segments.add(TrailSegment(
        position: position,
        skin: skin,
        bornAtMs: nowMs,
        angle: _rng.nextDouble() * 2 * pi,
        vx: jitterX,
        vy: jitterY - (skin == SnakeSkin.dragon ? 0.5 : 0.0), // embers rise
      ));
    }
  }

  void purge(int nowMs) {
    _segments.removeWhere((s) => s.isExpired(nowMs));
  }

  void clear() => _segments.clear();

  /// Returns the visual properties for a trail segment so the painter
  /// stays decoupled from this service.
  TrailVisuals visualsFor(TrailSegment seg, int nowMs, double cellSize) {
    final t = seg.progress(nowMs); // 0=fresh, 1=dead
    final fade = (1.0 - t).clamp(0.0, 1.0);

    switch (seg.skin) {
      // ── FIRE EMBERS (Dragon / Volcano) ──────────────────────────
      case SnakeSkin.dragon:
        final heat = t < 0.3 ? 1.0 : (1.0 - (t - 0.3) / 0.7);
        return TrailVisuals(
          color: Color.lerp(
            const Color(0xFFFFDD00), // bright yellow core
            const Color(0xFFFF3300), // deep red as it cools
            t,
          )!.withValues(alpha: fade * 0.85),
          radius: (cellSize * 0.25) * heat,
          shape: TrailShape.ember,
          blurSigma: 3.0 * heat,
        );

      // ── TRON LIGHT RIBBON (Robot / Cyber) ───────────────────────
      case SnakeSkin.robot:
        return TrailVisuals(
          color: const Color(0xFF00FFFF).withValues(alpha: fade * 0.7),
          radius: (cellSize * 0.4) * (1.0 - t * 0.5),
          shape: TrailShape.ribbon,
          blurSigma: 1.5,
        );

      // ── SPARKLES (Golden) ────────────────────────────────────────
      case SnakeSkin.golden:
        return TrailVisuals(
          color: const Color(0xFFFFD700).withValues(alpha: fade * 0.9),
          radius: (cellSize * 0.2) * (1.0 - t),
          shape: TrailShape.star,
          blurSigma: 2.0,
        );

      // ── RAINBOW SMEARS ───────────────────────────────────────────
      case SnakeSkin.rainbow:
        final hue = (seg.angle / (2 * pi) * 360) % 360;
        return TrailVisuals(
          color: HSVColor.fromAHSV(fade * 0.75, hue, 1.0, 1.0).toColor(),
          radius: (cellSize * 0.35) * (1.0 - t * 0.6),
          shape: TrailShape.blob,
          blurSigma: 2.5,
        );

      // ── BLOOD DROPLETS (Vampire) ─────────────────────────────────
      case SnakeSkin.vampire:
        return TrailVisuals(
          color: const Color(0xFFCC0000).withValues(alpha: fade * 0.7),
          radius: (cellSize * 0.2) * (1.0 - t * 0.4),
          shape: TrailShape.blob,
          blurSigma: 1.0,
        );

      // ── ECTOPLASM (Ghost) ─────────────────────────────────────────
      case SnakeSkin.ghost:
        return TrailVisuals(
          color: Colors.white.withValues(alpha: fade * 0.3),
          radius: (cellSize * 0.4) * (1.0 - t * 0.5),
          shape: TrailShape.blob,
          blurSigma: 4.0,
        );

      // ── SLASH MARK (Ninja) ────────────────────────────────────────
      case SnakeSkin.ninja:
        return TrailVisuals(
          color: const Color(0xFF888888).withValues(alpha: fade * 0.4),
          radius: (cellSize * 0.3) * (1.0 - t),
          shape: TrailShape.slash,
          blurSigma: 0.5,
        );

      default:
        return TrailVisuals(
          color: Colors.white.withValues(alpha: fade * 0.15),
          radius: (cellSize * 0.3) * (1.0 - t),
          shape: TrailShape.blob,
          blurSigma: 1.0,
        );
    }
  }
}

enum TrailShape { ember, ribbon, blob, star, slash }

class TrailVisuals {
  final Color color;
  final double radius;
  final TrailShape shape;
  final double blurSigma;
  const TrailVisuals({
    required this.color,
    required this.radius,
    required this.shape,
    required this.blurSigma,
  });
}
