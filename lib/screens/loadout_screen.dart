import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/enums/theme_type.dart';
import '../core/models/expedition_gear.dart';
import '../core/theme/app_typography.dart';
import '../providers/settings_provider.dart';
import '../providers/user_provider.dart';
import '../services/storage_service.dart';
import '../widgets/ui/dynamic_background.dart';

class LoadoutResult {
  final List<String> gear; // up to 2 GearType names

  const LoadoutResult({required this.gear});
}

class LoadoutScreen extends StatefulWidget {
  const LoadoutScreen({super.key});

  @override
  State<LoadoutScreen> createState() => _LoadoutScreenState();
}

class _LoadoutScreenState extends State<LoadoutScreen> {
  final List<String?> _slots = [null, null]; // 2 gear slots

  @override
  void initState() {
    super.initState();
    final equipped = StorageService().equippedGear;
    for (int i = 0; i < equipped.length && i < 2; i++) {
      _slots[i] = equipped[i];
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

  void _pickGear(int slot) {
    final colors = _colors(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.hudBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final userProvider = context.read<UserProvider>();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Gear',
                  style: TextStyle(
                    fontFamily: AppTypography.modernFont,
                    color: colors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Text('❌', style: TextStyle(fontSize: 24)),
                  title: Text('None',
                      style:
                          TextStyle(color: colors.text.withValues(alpha: 0.6))),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _slots[slot] = null);
                  },
                ),
                ...ExpeditionGear.all.map((def) {
                  final count = userProvider.gearCount(def.type.name);
                  final inOtherSlot = _slots[1 - slot] == def.type.name;
                  final unavailable = count == 0 || inOtherSlot;
                  return ListTile(
                    leading:
                        Text(def.emoji, style: const TextStyle(fontSize: 24)),
                    title: Text(
                      def.name,
                      style: TextStyle(
                        color: unavailable
                            ? colors.text.withValues(alpha: 0.3)
                            : colors.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      unavailable && count == 0
                          ? 'Not owned'
                          : inOtherSlot
                              ? 'Already in other slot'
                              : 'Owned: $count',
                      style: TextStyle(
                        color: unavailable
                            ? colors.accent.withValues(alpha: 0.4)
                            : colors.accent,
                        fontSize: 12,
                      ),
                    ),
                    enabled: !unavailable,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _slots[slot] = def.type.name);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final settings = context.watch<SettingsProvider>();
    final colors = _colors(context);
    final font = settings.theme == ThemeType.retro
        ? AppTypography.retroFont
        : AppTypography.modernFont;
    final gems = userProvider.snakeSouls;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.hudBg.withValues(alpha: 0.9),
        elevation: 0,
        iconTheme: IconThemeData(color: colors.text),
        title: Text(
          'EXPLORE LOADOUT',
          style: TextStyle(
            fontFamily: font,
            color: colors.text,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Text('💎', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '$gems',
                  style: TextStyle(
                    fontFamily: font,
                    color: colors.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: DynamicBackground(
        themeType: settings.theme,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'EXPEDITION GEAR',
                style: TextStyle(
                  fontFamily: font,
                  color: colors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Equip up to 2 one-use items for this run.',
                style: TextStyle(
                    color: colors.text.withValues(alpha: 0.6), fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildSlotCard(0)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSlotCard(1)),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.buttonBorder,
                  foregroundColor: colors.background,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  final gear = _slots.whereType<String>().toList();
                  await userProvider.setEquippedGear(gear);
                  for (final typeName in gear) {
                    await StorageService().useGear(typeName);
                  }
                  if (mounted) {
                    Navigator.pop(context, LoadoutResult(gear: gear));
                  }
                },
                child: Text(
                  '🌍 START EXPLORE',
                  style: TextStyle(
                    fontFamily: font,
                    color: colors.background,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotCard(int slot) {
    final colors = _colors(context);
    final typeName = _slots[slot];
    GearDef? def;
    if (typeName != null) {
      try {
        def = ExpeditionGear.all.firstWhere(
          (g) => g.type.name == typeName,
        );
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () => _pickGear(slot),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: def != null
              ? colors.buttonBorder.withValues(alpha: 0.12)
              : colors.hudBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: def != null
                ? colors.buttonBorder.withValues(alpha: 0.7)
                : colors.buttonBorder.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: def == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add,
                      color: colors.text.withValues(alpha: 0.35), size: 36),
                  const SizedBox(height: 6),
                  Text(
                    'Slot ${slot + 1}',
                    style: TextStyle(
                      color: colors.text.withValues(alpha: 0.35),
                      fontSize: 13,
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(def.emoji, style: const TextStyle(fontSize: 36)),
                    const SizedBox(height: 8),
                    Text(
                      def.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      def.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.text.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
