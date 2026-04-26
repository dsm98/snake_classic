import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/enums/theme_type.dart';
import '../core/theme/app_typography.dart';
import '../providers/settings_provider.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../services/vibration_service.dart';
import '../widgets/ui/dynamic_background.dart';

class AltarScreen extends StatefulWidget {
  const AltarScreen({Key? key}) : super(key: key);

  @override
  _AltarScreenState createState() => _AltarScreenState();
}

class _AltarScreenState extends State<AltarScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();
  late AnimationController _pulseController;

  int get gems => _storage.snakeSouls;
  int get thickScales => _storage.skillThickScales;
  int get greed => _storage.skillGreed;
  int get dashMastery => _storage.skillDashMastery;

  final int maxThickScales = 3;
  final int maxGreed = 5;
  final int maxDashMastery = 2;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  int _costForLevel(int level) => (level + 1) * 150;

  Future<void> _upgradeSkill(String name, int currentLvl, int maxLvl,
      Future<void> Function(int) saveFunc) async {
    if (currentLvl >= maxLvl) return;
    int cost = _costForLevel(currentLvl);
    if (gems >= cost) {
      AudioService().play(SoundEffect.powerUp);
      VibrationService().vibrate(duration: 200, amplitude: 200);
      await _storage.deductSnakeSouls(cost);
      await saveFunc(currentLvl + 1);
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough Snake Souls!',
              style: TextStyle(fontFamily: 'Orbitron')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  AppThemeColors _colors(BuildContext context) {
    final t = context.read<SettingsProvider>().theme;
    switch (t) {
      case ThemeType.retro:
        return AppThemeColors.retro;
      case ThemeType.neon:
        return AppThemeColors.neon;
      case ThemeType.nature:
        return AppThemeColors.nature;
      case ThemeType.arcade:
        return AppThemeColors.arcade;
      case ThemeType.cyber:
        return AppThemeColors.cyber;
      case ThemeType.volcano:
        return AppThemeColors.volcano;
      case ThemeType.ice:
        return AppThemeColors.ice;
    }
  }

  Widget _buildSkillCard(String title, String desc, String icon, int currentLvl,
      int maxLvl, Future<void> Function(int) saveFunc) {
    final colors = _colors(context);
    final font = context.read<SettingsProvider>().theme == ThemeType.retro
        ? AppTypography.retroFont
        : AppTypography.modernFont;
    final bool isMax = currentLvl >= maxLvl;
    final int cost = _costForLevel(currentLvl);
    final bool canAfford = !isMax && gems >= cost;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.hudBg.withValues(alpha: 0.6),
        border: Border.all(
            color: colors.buttonBorder.withValues(alpha: 0.5), width: 1.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors.buttonBorder.withValues(alpha: 0.08),
            blurRadius: 8,
            spreadRadius: 2,
          )
        ],
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontFamily: font,
                      color: colors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  'Lvl $currentLvl / $maxLvl',
                  style: TextStyle(
                      color: colors.accent, fontFamily: font, fontSize: 10),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                      color: colors.text.withValues(alpha: 0.6), fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isMax
                  ? colors.hudBg
                  : (canAfford
                      ? colors.buttonBorder
                      : colors.hudBg.withValues(alpha: 0.8)),
              foregroundColor: isMax
                  ? colors.text.withValues(alpha: 0.4)
                  : colors.background,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: isMax
                ? null
                : () => _upgradeSkill(title, currentLvl, maxLvl, saveFunc),
            child: isMax
                ? Text('MAX',
                    style: TextStyle(
                        fontFamily: font, fontWeight: FontWeight.bold))
                : Text('💎 $cost',
                    style: TextStyle(
                        fontFamily: font, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colors = _colors(context);
    final font = settings.theme == ThemeType.retro
        ? AppTypography.retroFont
        : AppTypography.modernFont;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'ALTAR OF SERPENTS',
          style: TextStyle(
              fontFamily: font,
              color: colors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 14),
        ),
        backgroundColor: colors.hudBg.withValues(alpha: 0.9),
        elevation: 0,
        iconTheme: IconThemeData(color: colors.text),
      ),
      body: DynamicBackground(
        themeType: settings.theme,
        child: Stack(
          children: [
            // Background Glow
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Positioned(
                  top: -100,
                  left: MediaQuery.of(context).size.width / 2 - 200,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          colors.buttonBorder.withValues(
                              alpha: 0.12 + (_pulseController.value * 0.08)),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  'Offer Snake Souls to gain permanent power.',
                  style: TextStyle(
                      color: colors.text.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                      fontSize: 12),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.buttonBorder.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: colors.buttonBorder.withValues(alpha: 0.6)),
                  ),
                  child: Text(
                    '💎 $gems Souls Available',
                    style: TextStyle(
                        fontFamily: font,
                        fontSize: 16,
                        color: colors.accent,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView(
                    children: [
                      _buildSkillCard(
                        'Thick Scales',
                        'Absorb wall hits in Explore Mode without dying.',
                        '🛡️',
                        thickScales,
                        maxThickScales,
                        _storage.setSkillThickScales,
                      ),
                      _buildSkillCard(
                        'Greed',
                        'Earn bonus coins from Prey and Bosses.',
                        '💰',
                        greed,
                        maxGreed,
                        _storage.setSkillGreed,
                      ),
                      _buildSkillCard(
                        'Dash Mastery',
                        'Start Explore Mode with instant dash charges.',
                        '⚡',
                        dashMastery,
                        maxDashMastery,
                        _storage.setSkillDashMastery,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
