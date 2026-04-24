import 'package:flutter/material.dart';

// ── Retro (Nokia 3310 LCD) palette ────────────────────────────
// Authentic 4-shade Nokia green palette: #0F380F / #306230 / #8BAC0F / #9BBC0F
class RetroColors {
  static const background = Color(0xFFC7D081); // Bright Nokia LCD (active)
  static const grid = Color(0xFFB9C46D); // Darker LCD panel
  static const gridLine = Color(0xFFB1BB63); // Grid texture
  static const snakeHead = Color(0xFF2B3306); // Darkest pixel (nearly black)
  static const snakeBody = Color(0xFF434D10); // Standard dark pixel
  static const snakeTail = Color(0xFF434D10); // Standard dark pixel
  static const food = Color(0xFF2B3306); // Dark pixel food
  static const powerUp = Color(0xFF434D10); // Mid-shade for power-ups
  static const text = Color(0xFF2B3306); // Authentic dark grey text
  static const accent = Color(0xFF5A6615); // Slightly lighter contrast
  static const hudBg = Color(0xFFB9C46D); // Matches LCD panel
  static const buttonBg = Color(0xFFD9D9D9); // Plastic grey buttons
  static const buttonBorder = Color(0xFF707070); // Button shadow/border
}

// ── Neon (Synthwave) palette ───────────────────────────────────
class NeonColors {
  static const background = Color(0xFF0F0B29); // Deep space purple
  static const grid = Color(0xFF1B143F); // slightly lighter purple tile
  static const gridLine = Color(0xFF281E57); // grid borders
  static const snakeHead = Color(0xFF00E5FF); // Blinding Cyan
  static const snakeBody = Color(0xFF007A99); // Darker cyan
  static const snakeTail = Color(0xFF003E4C); // Fades into dark cyan
  static const food = Color(0xFFFF0066); // Hot Pink
  static const powerUp = Color(0xFFFFD700); // Glowing Yellow
  static const text = Color(0xFFE0E0FF); // Cool white text
  static const accent = Color(0xFFFF0066); // Pink accents
  static const hudBg = Color(0xFF0D0922); // Very dark purple
  static const buttonBg = Color(0xFF171033); // Dark purple button
  static const buttonBorder = Color(0xFF00E5FF); // Cyan border
}

// ── Nature (Zen Garden) palette ───────────────────────────────
class NatureColors {
  static const background = Color(0xFF16251C); // Deep moss
  static const grid = Color(0xFF1F3528); // Rich green
  static const gridLine = Color(0xFF182D20); // Border
  static const snakeHead = Color(0xFF66FF99); // Bright bamboo leaf
  static const snakeBody = Color(0xFF28B463); // Grass green
  static const snakeTail = Color(0xFF1D8348); // Dark grass
  static const food = Color(0xFFFF9933); // Sunset orange/mandarin
  static const powerUp = Color(0xFFFFD54F); // Warm sun yellow
  static const text = Color(0xFFD5F5E3); // Mint white text
  static const accent = Color(0xFFFF9933); // Orange accents
  static const hudBg = Color(0xFF121E16); // Very dark moss
  static const buttonBg = Color(0xFF1B2E23); // Dark button
  static const buttonBorder = Color(0xFF66FF99); // Bright green border
}

// ── Arcade (80s Coin-op) palette ───────────────────────────────
class ArcadeColors {
  static const background = Color(0xFF000000); // True black
  static const grid = Color(0xFF111111); // Very dark grey
  static const gridLine = Color(0xFF222222); // Dark grey border
  static const snakeHead = Color(0xFFFFD700); // Pacman yellow
  static const snakeBody = Color(0xFFE6B800); // Darker yellow
  static const snakeTail = Color(0xFFB38F00); // Even darker yellow
  static const food = Color(0xFFFF0000); // Arcade red
  static const powerUp = Color(0xFF00FFFF); // Arcade blue
  static const text = Color(0xFFFFFFFF); // Pure white
  static const accent = Color(0xFFFF0000); // Red accents
  static const hudBg = Color(0xFF080808); // Near black
  static const buttonBg = Color(0xFF1A1A1A); // Dark grey button
  static const buttonBorder = Color(0xFFFFD700); // Yellow border
}

// ── Cyber (Digital Rain) palette ──────────────────────────────
class CyberColors {
  static const background = Color(0xFF000500); // Pitch black-green
  static const grid = Color(0xFF000F00); // Matrix green tile
  static const gridLine = Color(0xFF001A00); // Darker border
  static const snakeHead = Color(0xFF00FF41); // Pure Matrix green
  static const snakeBody = Color(0xFF008F11); // Standard terminal green
  static const snakeTail = Color(0xFF003B00); // Fading green
  static const food = Color(0xFFFFFFFF); // White cursor food
  static const powerUp = Color(0xFF00FF41); // Matrix green
  static const text = Color(0xFF00FF41); // Terminal text
  static const accent = Color(0xFF00FF41);
  static const hudBg = Color(0xFF000500);
  static const buttonBg = Color(0xFF000A00);
  static const buttonBorder = Color(0xFF00FF41);
}

// ── Ice (Arctic Frost) palette ─────────────────────────────────
class IceColors {
  static const background = Color(0xFF050E1A); // Midnight arctic sky
  static const grid = Color(0xFF0B1829); // Deep frost tile
  static const gridLine = Color(0xFF0E2038); // Ice border
  static const snakeHead = Color(0xFF7FEFFF); // Bright glacial cyan
  static const snakeBody = Color(0xFF3BCDE0); // Ice blue
  static const snakeTail = Color(0xFF1C7A8A); // Deep teal
  static const food = Color(0xFFFF7EBA); // Frosty pink berry
  static const powerUp = Color(0xFFB3F3FF); // Ice crystal
  static const text = Color(0xFFDFF6FF); // Frost white text
  static const accent = Color(0xFF7FEFFF); // Cyan accent
  static const hudBg = Color(0xFF030B14); // Near-black arctic
  static const buttonBg = Color(0xFF0A1520); // Dark button
  static const buttonBorder = Color(0xFF7FEFFF); // Cyan border
}

// ── Volcano (Inferno) palette ──────────────────────────────────
class VolcanoColors {
  static const background = Color(0xFF1A0505); // Dark obsidian
  static const grid = Color(0xFF2A0A0A); // Lava glow tile
  static const gridLine = Color(0xFF3A0F0F); // Cinders
  static const snakeHead = Color(0xFFFF4500); // Orange-red lava
  static const snakeBody = Color(0xFFE25822); // Flame orange
  static const snakeTail = Color(0xFFB22222); // Firebrick red
  static const food = Color(0xFFFFD700); // Molten gold
  static const powerUp = Color(0xFFFF8C00); // Bright orange
  static const text = Color(0xFFFFE4E1); // Smoky white
  static const accent = Color(0xFFFF4500);
  static const hudBg = Color(0xFF150303);
  static const buttonBg = Color(0xFF200808);
  static const buttonBorder = Color(0xFFFF4500);
}

// Generic theme accessor
class AppThemeColors {
  final Color background;
  final Color grid;
  final Color gridLine;
  final Color snakeHead;
  final Color snakeBody;
  final Color snakeTail;
  final Color food;
  final Color powerUp;
  final Color text;
  final Color accent;
  final Color hudBg;
  final Color buttonBg;
  final Color buttonBorder;

  const AppThemeColors({
    required this.background,
    required this.grid,
    required this.gridLine,
    required this.snakeHead,
    required this.snakeBody,
    required this.snakeTail,
    required this.food,
    required this.powerUp,
    required this.text,
    required this.accent,
    required this.hudBg,
    required this.buttonBg,
    required this.buttonBorder,
  });

  static const retro = AppThemeColors(
    background: RetroColors.background,
    grid: RetroColors.grid,
    gridLine: RetroColors.gridLine,
    snakeHead: RetroColors.snakeHead,
    snakeBody: RetroColors.snakeBody,
    snakeTail: RetroColors.snakeTail,
    food: RetroColors.food,
    powerUp: RetroColors.powerUp,
    text: RetroColors.text,
    accent: RetroColors.accent,
    hudBg: RetroColors.hudBg,
    buttonBg: RetroColors.buttonBg,
    buttonBorder: RetroColors.buttonBorder,
  );

  static const neon = AppThemeColors(
    background: NeonColors.background,
    grid: NeonColors.grid,
    gridLine: NeonColors.gridLine,
    snakeHead: NeonColors.snakeHead,
    snakeBody: NeonColors.snakeBody,
    snakeTail: NeonColors.snakeTail,
    food: NeonColors.food,
    powerUp: NeonColors.powerUp,
    text: NeonColors.text,
    accent: NeonColors.accent,
    hudBg: NeonColors.hudBg,
    buttonBg: NeonColors.buttonBg,
    buttonBorder: NeonColors.buttonBorder,
  );

  static const nature = AppThemeColors(
    background: NatureColors.background,
    grid: NatureColors.grid,
    gridLine: NatureColors.gridLine,
    snakeHead: NatureColors.snakeHead,
    snakeBody: NatureColors.snakeBody,
    snakeTail: NatureColors.snakeTail,
    food: NatureColors.food,
    powerUp: NatureColors.powerUp,
    text: NatureColors.text,
    accent: NatureColors.accent,
    hudBg: NatureColors.hudBg,
    buttonBg: NatureColors.buttonBg,
    buttonBorder: NatureColors.buttonBorder,
  );

  static const arcade = AppThemeColors(
    background: ArcadeColors.background,
    grid: ArcadeColors.grid,
    gridLine: ArcadeColors.gridLine,
    snakeHead: ArcadeColors.snakeHead,
    snakeBody: ArcadeColors.snakeBody,
    snakeTail: ArcadeColors.snakeTail,
    food: ArcadeColors.food,
    powerUp: ArcadeColors.powerUp,
    text: ArcadeColors.text,
    accent: ArcadeColors.accent,
    hudBg: ArcadeColors.hudBg,
    buttonBg: ArcadeColors.buttonBg,
    buttonBorder: ArcadeColors.buttonBorder,
  );

  static const cyber = AppThemeColors(
    background: CyberColors.background,
    grid: CyberColors.grid,
    gridLine: CyberColors.gridLine,
    snakeHead: CyberColors.snakeHead,
    snakeBody: CyberColors.snakeBody,
    snakeTail: CyberColors.snakeTail,
    food: CyberColors.food,
    powerUp: CyberColors.powerUp,
    text: CyberColors.text,
    accent: CyberColors.accent,
    hudBg: CyberColors.hudBg,
    buttonBg: CyberColors.buttonBg,
    buttonBorder: CyberColors.buttonBorder,
  );

  static const volcano = AppThemeColors(
    background: VolcanoColors.background,
    grid: VolcanoColors.grid,
    gridLine: VolcanoColors.gridLine,
    snakeHead: VolcanoColors.snakeHead,
    snakeBody: VolcanoColors.snakeBody,
    snakeTail: VolcanoColors.snakeTail,
    food: VolcanoColors.food,
    powerUp: VolcanoColors.powerUp,
    text: VolcanoColors.text,
    accent: VolcanoColors.accent,
    hudBg: VolcanoColors.hudBg,
    buttonBg: VolcanoColors.buttonBg,
    buttonBorder: VolcanoColors.buttonBorder,
  );

  static const ice = AppThemeColors(
    background: IceColors.background,
    grid: IceColors.grid,
    gridLine: IceColors.gridLine,
    snakeHead: IceColors.snakeHead,
    snakeBody: IceColors.snakeBody,
    snakeTail: IceColors.snakeTail,
    food: IceColors.food,
    powerUp: IceColors.powerUp,
    text: IceColors.text,
    accent: IceColors.accent,
    hudBg: IceColors.hudBg,
    buttonBg: IceColors.buttonBg,
    buttonBorder: IceColors.buttonBorder,
  );
}
