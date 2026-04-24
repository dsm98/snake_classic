import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/enums/snake_skin.dart';
import '../core/enums/theme_type.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../core/models/expedition_gear.dart';
import '../providers/user_provider.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../widgets/ui/dynamic_background.dart';

class ShopScreen extends StatefulWidget {
  final ThemeType themeType;
  const ShopScreen({super.key, required this.themeType});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  AppThemeColors get colors {
    switch (widget.themeType) {
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

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final coins = userProvider.coins;
    final gems = userProvider.safariGems;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.hudBg.withOpacity(0.7),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colors.text, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '🛒 SHOP',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 16,
            color: colors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(children: [
                  const Text('💰', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 3),
                  Text('$coins',
                      style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 11,
                          color: Colors.amber,
                          fontWeight: FontWeight.bold)),
                ]),
                Row(children: [
                  const Text('💎', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 3),
                  Text('$gems',
                      style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 11,
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold)),
                ]),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.accent,
          unselectedLabelColor: colors.text.withOpacity(0.5),
          indicatorColor: colors.accent,
          tabs: const [
            Tab(text: '🐍 Skins'),
            Tab(text: '🎒 Gear'),
            Tab(text: '💎 Relics'),
          ],
        ),
      ),
      body: DynamicBackground(
        themeType: widget.themeType,
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _SkinsTab(
                  colors: colors,
                  onGacha: () => _showGachaDialog(context, userProvider)),
              _GearTab(colors: colors),
              _RelicsTab(colors: colors),
            ],
          ),
        ),
      ),
    );
  }

  void _showGachaDialog(BuildContext context, UserProvider userProvider) {
    bool spinning = false;
    SnakeSkin? wonSkin;
    const spinCost = AppConstants.gachaSpinCost;
    const minComp = AppConstants.gachaDuplicateCompensationCommon;
    const maxComp = AppConstants.gachaDuplicateCompensationLegendary;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) {
              return Dialog(
                backgroundColor: colors.hudBg,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: colors.buttonBorder, width: 2)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('MYSTERY BOX',
                          style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 18,
                              color: colors.text,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      if (spinning)
                        const CircularProgressIndicator(color: Colors.amber)
                      else if (wonSkin != null)
                        Builder(builder: (_) {
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.elasticOut,
                            builder: (context, value, _) {
                              return Transform.scale(
                                scale: value,
                                child: Column(children: [
                                  const Text('NEW SKIN UNLOCKED!',
                                      style: TextStyle(
                                          fontFamily: 'Orbitron',
                                          color: Colors.greenAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.amber.withOpacity(0.1),
                                        boxShadow: [
                                          BoxShadow(
                                              color: Colors.amber
                                                  .withOpacity(0.3 * value),
                                              blurRadius: 20 * value,
                                              spreadRadius: 5 * value)
                                        ]),
                                    child: Text(wonSkin!.emoji,
                                        style: const TextStyle(fontSize: 60)),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(wonSkin!.displayName,
                                      style: TextStyle(
                                          fontFamily: 'Orbitron',
                                          fontSize: 24,
                                          color: colors.accent,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(wonSkin!.rarity.name.toUpperCase(),
                                      style: TextStyle(
                                          fontFamily: 'Orbitron',
                                          fontSize: 10,
                                          color: colors.text.withOpacity(0.5))),
                                ]),
                              );
                            },
                          );
                        })
                      else
                        const Text('🎰', style: TextStyle(fontSize: 60)),
                      if (!spinning && wonSkin == null) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Drop Rates\nCommon 50%  •  Rare 30%\nEpic 15%  •  Legendary 5%',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 10,
                            color: colors.text.withOpacity(0.7),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Duplicate compensation: +$minComp to +$maxComp coins',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 9,
                            color: colors.text.withOpacity(0.5),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      if (!spinning && wonSkin == null)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black),
                          onPressed: () async {
                            if (userProvider.coins < spinCost) {
                              AudioService().play(SoundEffect.click);
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Not enough coins. You need $spinCost for a spin.'),
                                ),
                              );
                              return;
                            }
                            setDialogState(() => spinning = true);
                            AudioService().play(SoundEffect.powerUp);
                            await Future.delayed(const Duration(seconds: 2));
                            final skin = await userProvider.rollGacha();
                            setDialogState(() {
                              spinning = false;
                              wonSkin = skin;
                            });
                            AudioService().play(SoundEffect.highScore);
                          },
                          child: Text('SPIN ($spinCost 💰)',
                              style: const TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontWeight: FontWeight.bold)),
                        ),
                      if (!spinning)
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('CLOSE',
                              style: TextStyle(
                                  fontFamily: 'Orbitron', color: colors.text)),
                        ),
                    ],
                  ),
                ),
              );
            }));
  }
}

// ── Skins Tab ────────────────────────────────────────────────────────────────
class _SkinsTab extends StatelessWidget {
  final AppThemeColors colors;
  final VoidCallback onGacha;
  const _SkinsTab({required this.colors, required this.onGacha});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final coins = userProvider.coins;
    final allSkins = SnakeSkin.values;

    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: _ShopHero(colors: colors),
              ),
            ),
            // Regular skins
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'ALL SKINS',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 11,
                    color: colors.text.withOpacity(0.6),
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final skin = allSkins[i];
                    final isUnlocked =
                        userProvider.unlockedSkins.contains(skin);
                    final isEquipped = userProvider.equippedSkin == skin;

                    return _SkinCard(
                      skin: skin,
                      colors: colors,
                      isUnlocked: isUnlocked,
                      isEquipped: isEquipped,
                      availableCoins: coins,
                      onTap: () async {
                        if (isEquipped) return;
                        if (isUnlocked) {
                          AudioService().play(SoundEffect.click);
                          await userProvider.equipSkin(skin);
                        } else if (!skin.isSafariExclusive) {
                          if (coins >= skin.price) {
                            AudioService().play(SoundEffect.highScore);
                            await userProvider.buySkin(skin);
                          } else {
                            AudioService().play(SoundEffect.click);
                          }
                        }
                      },
                    );
                  },
                  childCount: allSkins.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: onGacha,
            backgroundColor: Colors.amber,
            icon: const Text('🎰', style: TextStyle(fontSize: 20)),
            label: Text(
              'LUCKY SPIN\n${AppConstants.gachaSpinCost} 💰',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Gear Tab ─────────────────────────────────────────────────────────────────
class _GearTab extends StatelessWidget {
  final AppThemeColors colors;
  const _GearTab({required this.colors});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final gems = userProvider.safariGems;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.cyan.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Text('🎒', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Expedition Gear is consumed on use. Equip before a Safari run from the Loadout screen.',
                  style: TextStyle(
                      color: colors.text.withOpacity(0.7), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...ExpeditionGear.all.map((def) {
          final count = userProvider.gearCount(def.type.name);
          final canAfford = gems >= def.gemPrice;
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141F14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Text(def.emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        def.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        def.description,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Owned: $count',
                        style: TextStyle(
                          color: count > 0 ? Colors.green : Colors.white38,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: canAfford
                      ? () async {
                          final ok = await userProvider.buyGear(
                              def.type.name, def.gemPrice);
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Not enough Safari Gems!')),
                            );
                          }
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: canAfford
                          ? Colors.cyanAccent.withOpacity(0.15)
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              canAfford ? Colors.cyanAccent : Colors.white24),
                    ),
                    child: Column(
                      children: [
                        const Text('💎', style: TextStyle(fontSize: 16)),
                        Text(
                          '${def.gemPrice}',
                          style: TextStyle(
                            color:
                                canAfford ? Colors.cyanAccent : Colors.white38,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ── Relics Tab ───────────────────────────────────────────────────────────────
class _RelicDef {
  final String id, name, emoji, description;
  final int coinPrice;
  const _RelicDef(
      {required this.id,
      required this.name,
      required this.emoji,
      required this.description,
      required this.coinPrice});
}

const _relics = [
  _RelicDef(
    id: 'serrated_fangs',
    name: 'Serrated Fangs',
    emoji: '🗡️',
    description: 'All food worth +15% score',
    coinPrice: 2000,
  ),
  _RelicDef(
    id: 'hunters_luck',
    name: "Hunter's Luck",
    emoji: '🍀',
    description: 'Golden apples spawn 25% more often',
    coinPrice: 2500,
  ),
  _RelicDef(
    id: 'fever_heart',
    name: 'Fever Heart',
    emoji: '❤️‍🔥',
    description: 'Fever mode lasts 50% longer',
    coinPrice: 3000,
  ),
  _RelicDef(
    id: 'swamp_walker',
    name: 'Swamp Walker',
    emoji: '🌿',
    description: 'Start every run 30% slower — never hit walls accidentally',
    coinPrice: 2000,
  ),
  _RelicDef(
    id: 'eagle_eye',
    name: 'Eagle Eye',
    emoji: '🦅',
    description: 'Food compass range doubled',
    coinPrice: 1500,
  ),
];

class _RelicsTab extends StatelessWidget {
  final AppThemeColors colors;
  const _RelicsTab({required this.colors});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final coins = userProvider.coins;
    // Owned relics stored as list of ids
    final ownedRelics =
        StorageService().equippedGear; // reuse storage for now (placeholder)

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.purple.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Text('💎', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Relics grant passive bonuses to every run. Own one at a time — only the latest purchased applies.',
                  style: TextStyle(
                      color: colors.text.withOpacity(0.7), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ..._relics.map((relic) {
          final owned = ownedRelics.contains(relic.id);
          final canAfford = coins >= relic.coinPrice;
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: owned
                  ? Colors.purple.withOpacity(0.12)
                  : const Color(0xFF141418),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: owned ? Colors.purple.withOpacity(0.6) : Colors.white24,
              ),
            ),
            child: Row(
              children: [
                Text(relic.emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        relic.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        relic.description,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12),
                      ),
                      if (owned)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            '✅ OWNED',
                            style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!owned) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: canAfford
                        ? () async {
                            await StorageService().deductCoins(relic.coinPrice);
                            final existing = StorageService().equippedGear;
                            await StorageService()
                                .setEquippedGear([...existing, relic.id]);
                            (context as Element).markNeedsBuild();
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: canAfford
                            ? Colors.amber.withOpacity(0.15)
                            : Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: canAfford ? Colors.amber : Colors.white24),
                      ),
                      child: Column(
                        children: [
                          const Text('💰', style: TextStyle(fontSize: 16)),
                          Text(
                            '${relic.coinPrice}',
                            style: TextStyle(
                              color: canAfford ? Colors.amber : Colors.white38,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _ShopHero extends StatelessWidget {
  final AppThemeColors colors;
  const _ShopHero({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.buttonBorder.withOpacity(0.25),
            colors.accent.withOpacity(0.12),
            colors.hudBg.withOpacity(0.65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.buttonBorder.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.hudBg.withOpacity(0.7),
              border: Border.all(color: colors.buttonBorder.withOpacity(0.35)),
            ),
            child: const Center(
              child: Text('✨', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PREMIUM SKIN COLLECTION',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 10,
                    color: colors.accent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Unlock looks, perks, and progression style.',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 9,
                    color: colors.text.withOpacity(0.72),
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

class _SkinCard extends StatelessWidget {
  final SnakeSkin skin;
  final AppThemeColors colors;
  final bool isUnlocked;
  final bool isEquipped;
  final int availableCoins;
  final VoidCallback onTap;

  const _SkinCard({
    required this.skin,
    required this.colors,
    required this.isUnlocked,
    required this.isEquipped,
    required this.availableCoins,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isEquipped
                  ? colors.buttonBorder.withOpacity(0.15)
                  : colors.hudBg.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isEquipped
                    ? colors.buttonBorder
                    : (isUnlocked
                        ? colors.buttonBorder.withOpacity(0.3)
                        : colors.buttonBorder.withOpacity(0.1)),
                width: isEquipped ? 2 : 1,
              ),
              boxShadow: isEquipped
                  ? [
                      BoxShadow(
                          color: colors.buttonBorder.withOpacity(0.2),
                          blurRadius: 15)
                    ]
                  : [],
            ),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.background,
                      border: Border.all(
                          color: colors.buttonBorder.withOpacity(0.3))),
                  child: Center(
                      child: Text(
                          skin == SnakeSkin.ghost
                              ? '👻'
                              : skin == SnakeSkin.skeleton
                                  ? '💀'
                                  : skin == SnakeSkin.robot
                                      ? '🤖'
                                      : skin == SnakeSkin.rainbow
                                          ? '🌈'
                                          : skin == SnakeSkin.ninja
                                              ? '🥷'
                                              : skin == SnakeSkin.dragon
                                                  ? '🐉'
                                                  : skin == SnakeSkin.vampire
                                                      ? '🧛'
                                                      : skin == SnakeSkin.golden
                                                          ? '✨'
                                                          : '🐍',
                          style: const TextStyle(fontSize: 30)))),
              Text(skin.displayName,
                  style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 13,
                      color: colors.text,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(skin.advantageDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 8,
                      color: colors.accent,
                      fontWeight: FontWeight.normal)),
              const SizedBox(height: 8),
              if (isEquipped)
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: colors.buttonBorder,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Text('EQUIPPED',
                        style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 9,
                            color: Colors.black,
                            fontWeight: FontWeight.bold)))
              else if (isUnlocked)
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: colors.buttonBorder.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('USE',
                        style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 9,
                            color: colors.buttonBorder,
                            fontWeight: FontWeight.bold)))
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('💰', style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 4),
                        Text('${skin.price}',
                            style: const TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 11,
                                color: Colors.amber,
                                fontWeight: FontWeight.bold))
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value:
                                  (availableCoins / skin.price).clamp(0.0, 1.0),
                              minHeight: 4,
                              backgroundColor:
                                  colors.background.withOpacity(0.5),
                              color: Colors.amber.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            availableCoins >= skin.price
                                ? 'Tap to unlock!'
                                : '${(skin.price - availableCoins).clamp(0, skin.price)} more',
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 7,
                              color: availableCoins >= skin.price
                                  ? Colors.greenAccent
                                  : colors.text.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
            ])));
  }
}
