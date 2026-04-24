import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/app_colors.dart';
import '../core/enums/haptic_intensity.dart';
import '../core/enums/theme_type.dart';
import '../providers/settings_provider.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  AppThemeColors _colors(ThemeType t) {
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

  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colors = _colors(settings.theme);
    final font =
        settings.theme == ThemeType.retro ? 'PressStart2P' : 'Orbitron';

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────
            _PremiumAppBar(title: 'SETTINGS', colors: colors, font: font),

            // ── Content ───────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Account section
                  _SectionLabel(title: 'ACCOUNT', colors: colors, font: font),
                  const SizedBox(height: 10),
                  _SettingsHero(colors: colors, font: font)
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.08, end: 0),
                  const SizedBox(height: 10),
                  Consumer<AuthService>(
                    builder: (context, auth, _) {
                      return _AccountCard(
                        auth: auth,
                        colors: colors,
                        font: font,
                      ).animate().fadeIn().slideY(begin: 0.1, end: 0);
                    },
                  ),

                  const SizedBox(height: 28),

                  // Theme section
                  _SectionLabel(title: 'THEME', colors: colors, font: font),
                  const SizedBox(height: 10),
                  _ThemeSelector(settings: settings, colors: colors)
                      .animate(delay: 50.ms)
                      .fadeIn()
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 28),

                  // Difficulty section
                  _SectionLabel(
                      title: 'DIFFICULTY', colors: colors, font: font),
                  const SizedBox(height: 10),
                  ...Difficulty.values.asMap().entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DifficultyTile(
                        d: e.value,
                        selected: settings.difficulty,
                        colors: colors,
                        font: font,
                        onTap: () => settings.setDifficulty(e.value),
                      )
                          .animate(
                              delay: Duration(milliseconds: 80 + e.key * 40))
                          .fadeIn()
                          .slideX(begin: 0.05, end: 0),
                    );
                  }),

                  const SizedBox(height: 28),

                  // Options section
                  _SectionLabel(title: 'OPTIONS', colors: colors, font: font),
                  const SizedBox(height: 10),
                  _OptionsCard(settings: settings, colors: colors)
                      .animate(delay: 200.ms)
                      .fadeIn()
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 32),

                  // Version footer
                  Center(
                    child: Text(
                      'Snake Classic Reborn  •  v1.0',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 9,
                        color: colors.text.withOpacity(0.2),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PremiumAppBar extends StatelessWidget {
  final String title;
  final AppThemeColors colors;
  final String font;
  const _PremiumAppBar(
      {required this.title, required this.colors, required this.font});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: colors.hudBg.withOpacity(0.7),
        border: Border(
          bottom: BorderSide(color: colors.buttonBorder.withOpacity(0.15)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: colors.text, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: font,
                fontSize: 13,
                color: colors.text,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final AppThemeColors colors;
  final String font;
  const _SectionLabel(
      {required this.title, required this.colors, required this.font});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.buttonBorder.withOpacity(0.9),
            boxShadow: [
              BoxShadow(
                color: colors.buttonBorder.withOpacity(0.35),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: font,
            fontSize: 9,
            color: colors.text.withOpacity(0.4),
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.buttonBorder.withOpacity(0.3),
                  colors.buttonBorder.withOpacity(0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsHero extends StatelessWidget {
  final AppThemeColors colors;
  final String font;
  const _SettingsHero({required this.colors, required this.font});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.buttonBorder.withOpacity(0.28),
            colors.accent.withOpacity(0.14),
            colors.hudBg.withOpacity(0.65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.buttonBorder.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: colors.buttonBorder.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.hudBg.withOpacity(0.8),
              border: Border.all(color: colors.buttonBorder.withOpacity(0.45)),
            ),
            child: const Center(
              child: Text('🎮', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONTROL YOUR EXPERIENCE',
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tune visuals, difficulty, and controls for your perfect run.',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 10,
                    color: colors.text.withOpacity(0.75),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final AuthService auth;
  final AppThemeColors colors;
  final String font;
  const _AccountCard(
      {required this.auth, required this.colors, required this.font});

  @override
  Widget build(BuildContext context) {
    final isSignedIn = auth.isSignedIn;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.hudBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.buttonBorder.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: colors.buttonBorder.withOpacity(0.06),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  colors.buttonBorder.withOpacity(0.5),
                  colors.buttonBorder.withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: colors.buttonBorder.withOpacity(0.4)),
            ),
            clipBehavior: Clip.antiAlias,
            child: auth.currentUser?.photoURL != null
                ? Image.network(auth.currentUser!.photoURL!, fit: BoxFit.cover)
                : const Center(
                    child: Text('👤', style: TextStyle(fontSize: 26))),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSignedIn ? 'SIGNED IN AS' : 'GUEST MODE',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 8,
                    color: colors.text.withOpacity(0.45),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSignedIn ? auth.playerName : 'Login to save scores',
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 12,
                    color: colors.text,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          if (isSignedIn)
            _IconBtn(
              icon: Icons.logout_rounded,
              color: Colors.red.withOpacity(0.7),
              onTap: () => auth.signOut(),
            )
          else
            _TextBtn(
              label: 'SIGN IN',
              colors: colors,
              onTap: () => auth.signInWithGoogle(),
            ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _TextBtn extends StatelessWidget {
  final String label;
  final AppThemeColors colors;
  final VoidCallback onTap;
  const _TextBtn(
      {required this.label, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.buttonBorder,
              Color.lerp(colors.buttonBorder, colors.accent, 0.4)!,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colors.buttonBorder.withOpacity(0.3),
              blurRadius: 12,
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  final SettingsProvider settings;
  final AppThemeColors colors;
  const _ThemeSelector({required this.settings, required this.colors});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final itemWidth = (constraints.maxWidth - spacing * 2) / 3;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: ThemeType.values.map((t) {
            final sel = t == settings.theme;
            final themeColors = _themeColors(t);
            return SizedBox(
              width: itemWidth,
              child: GestureDetector(
                onTap: () => settings.setTheme(t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: sel
                        ? LinearGradient(
                            colors: [
                              themeColors.withOpacity(0.3),
                              themeColors.withOpacity(0.1),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          )
                        : null,
                    color: sel ? null : colors.hudBg.withOpacity(0.42),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: sel
                          ? themeColors.withOpacity(0.9)
                          : colors.buttonBorder.withOpacity(0.15),
                      width: sel ? 2 : 1,
                    ),
                    boxShadow: sel
                        ? [
                            BoxShadow(
                              color: themeColors.withOpacity(0.25),
                              blurRadius: 14,
                            )
                          ]
                        : [],
                  ),
                  child: Column(
                    children: [
                      Text(t.icon, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 6),
                      Text(
                        t.displayName,
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 8,
                          color:
                              sel ? colors.text : colors.text.withOpacity(0.42),
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Color _themeColors(ThemeType t) {
    switch (t) {
      case ThemeType.retro:
        return const Color(0xFF8BAC0F);
      case ThemeType.neon:
        return const Color(0xFF00E5FF);
      case ThemeType.nature:
        return const Color(0xFF66FF99);
      case ThemeType.arcade:
        return const Color(0xFFFFD700);
      case ThemeType.cyber:
        return const Color(0xFF00FF41);
      case ThemeType.volcano:
        return const Color(0xFFFF4500);
      case ThemeType.ice:
        return const Color(0xFF7FEFFF);
    }
  }
}

class _DifficultyTile extends StatelessWidget {
  final Difficulty d;
  final Difficulty selected;
  final AppThemeColors colors;
  final String font;
  final VoidCallback onTap;
  const _DifficultyTile({
    required this.d,
    required this.selected,
    required this.colors,
    required this.font,
    required this.onTap,
  });

  Color get _diffColor {
    switch (d) {
      case Difficulty.easy:
        return const Color(0xFF66BB6A);
      case Difficulty.normal:
        return const Color(0xFFFFA726);
      case Difficulty.hard:
        return const Color(0xFFEF5350);
      case Difficulty.insane:
        return const Color(0xFFAB47BC);
    }
  }

  String get _diffIcon {
    switch (d) {
      case Difficulty.easy:
        return '🟢';
      case Difficulty.normal:
        return '🟡';
      case Difficulty.hard:
        return '🔴';
      case Difficulty.insane:
        return '💀';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sel = d == selected;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: sel
              ? LinearGradient(
                  colors: [
                    _diffColor.withOpacity(0.2),
                    _diffColor.withOpacity(0.05),
                  ],
                )
              : null,
          color: sel ? null : colors.hudBg.withOpacity(0.4),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: sel
                ? _diffColor.withOpacity(0.6)
                : colors.buttonBorder.withOpacity(0.15),
            width: sel ? 2 : 1,
          ),
          boxShadow: sel
              ? [
                  BoxShadow(
                    color: _diffColor.withOpacity(0.2),
                    blurRadius: 16,
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Text(_diffIcon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.displayName.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      color: sel ? colors.text : colors.text.withOpacity(0.4),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: sel
                    ? _diffColor.withOpacity(0.2)
                    : colors.background.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: sel
                      ? _diffColor.withOpacity(0.5)
                      : colors.buttonBorder.withOpacity(0.15),
                ),
              ),
              child: Text(
                '${d.scoreMultiplier}x',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 12,
                  color: sel ? _diffColor : colors.text.withOpacity(0.3),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (sel) ...[
              const SizedBox(width: 10),
              Icon(Icons.check_circle_rounded, color: _diffColor, size: 22),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionsCard extends StatelessWidget {
  final SettingsProvider settings;
  final AppThemeColors colors;
  const _OptionsCard({required this.settings, required this.colors});

  String _hapticLabel(HapticIntensity intensity) {
    switch (intensity) {
      case HapticIntensity.light:
        return 'Light';
      case HapticIntensity.medium:
        return 'Medium';
      case HapticIntensity.strong:
        return 'Strong';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.hudBg.withOpacity(0.55),
            colors.hudBg.withOpacity(0.38),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.buttonBorder.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: colors.buttonBorder.withOpacity(0.08),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        children: [
          _ToggleTile(
            label: 'Sound Effects',
            subtitle: settings.soundEnabled ? 'On' : 'Off',
            icon: settings.soundEnabled ? '🔊' : '🔇',
            value: settings.soundEnabled,
            colors: colors,
            onChanged: (_) => settings.toggleSound(),
            isFirst: true,
            isLast: false,
          ),
          _Divider(colors: colors),
          _ToggleTile(
            label: 'Haptic Feedback',
            subtitle: 'Vibration on tap',
            icon: '📳',
            value: settings.vibrationEnabled,
            colors: colors,
            onChanged: (_) => settings.toggleVibration(),
            isFirst: false,
            isLast: false,
          ),
          _Divider(colors: colors),
          _ToggleTile(
            label: 'Show D-Pad',
            subtitle: 'On-screen joystick',
            icon: '🕹️',
            value: settings.showJoystick,
            colors: colors,
            onChanged: (_) => settings.toggleJoystick(),
            isFirst: false,
            isLast: false,
          ),
          _Divider(colors: colors),
          _ToggleTile(
            label: 'Reduced Motion',
            subtitle: settings.reducedMotion
                ? 'Minimize transitions and effects'
                : 'Use full motion effects',
            icon: '🎞️',
            value: settings.reducedMotion,
            colors: colors,
            onChanged: (_) => settings.toggleReducedMotion(),
            isFirst: false,
            isLast: false,
          ),
          _Divider(colors: colors),
          _ToggleTile(
            label: 'Pre-Run Twist Prompt',
            subtitle: settings.showRunModifierPrompt
                ? 'Show random modifier before each run'
                : 'Start runs instantly without the prompt',
            icon: '🎲',
            value: settings.showRunModifierPrompt,
            colors: colors,
            onChanged: (_) => settings.toggleRunModifierPrompt(),
            isFirst: false,
            isLast: false,
          ),
          _Divider(colors: colors),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Font Scale',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 12,
                    color: colors.text.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Slider(
                  value: settings.fontScale,
                  min: 0.9,
                  max: 1.35,
                  divisions: 9,
                  activeColor: colors.buttonBorder,
                  inactiveColor: colors.background.withOpacity(0.5),
                  label: '${(settings.fontScale * 100).round()}%',
                  onChanged: settings.setFontScale,
                ),
              ],
            ),
          ),
          _Divider(colors: colors),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Text(
                  'Haptics',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 12,
                    color: colors.text.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Wrap(
                  spacing: 6,
                  children: HapticIntensity.values.map((intensity) {
                    final selected = settings.hapticIntensity == intensity;
                    return ChoiceChip(
                      label: Text(_hapticLabel(intensity)),
                      selected: selected,
                      onSelected: (_) => settings.setHapticIntensity(intensity),
                      selectedColor: colors.buttonBorder.withOpacity(0.25),
                      backgroundColor: colors.background.withOpacity(0.4),
                      labelStyle: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 10,
                        color: selected
                            ? colors.text
                            : colors.text.withOpacity(0.5),
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final AppThemeColors colors;
  const _Divider({required this.colors});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 56),
      color: colors.buttonBorder.withOpacity(0.1),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final String icon;
  final bool value;
  final void Function(bool) onChanged;
  final AppThemeColors colors;
  final bool isFirst;
  final bool isLast;

  const _ToggleTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.colors,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.buttonBorder.withOpacity(0.16),
                  colors.buttonBorder.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.buttonBorder.withOpacity(0.2)),
            ),
            child:
                Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 12,
                    color: colors.text.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 9,
                    color: colors.text.withOpacity(0.35),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: colors.buttonBorder,
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return colors.buttonBorder.withOpacity(0.3);
              }
              return colors.background.withOpacity(0.5);
            }),
          ),
        ],
      ),
    );
  }
}
