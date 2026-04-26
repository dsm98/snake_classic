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
import '../core/theme/app_typography.dart';
import '../widgets/ui/dynamic_background.dart';

class ShopScreen extends StatefulWidget {
  final ThemeType themeType;
  final bool isEmbedded;
  const ShopScreen(
      {super.key, required this.themeType, this.isEmbedded = false});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
    final gems = userProvider.snakeSouls;

    final bodyContent = Column(
      children: [
        if (widget.isEmbedded)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            color: colors.hudBg.withValues(alpha: 0.4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🛒 SHOP',
                  style: TextStyle(
                    fontFamily: AppTypography.modernFont,
                    fontSize: 16,
                    color: colors.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Row(children: [
                      const Text('💰', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text('$coins',
                          style: const TextStyle(
                              fontFamily: AppTypography.modernFont,
                              fontSize: 11,
                              color: Colors.amber,
                              fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(width: 16),
                    Row(children: [
                      const Text('💎', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text('$gems',
                          style: const TextStyle(
                              fontFamily: AppTypography.modernFont,
                              fontSize: 11,
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold)),
                    ]),
                  ],
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: _buildStoreHero(colors, coins, gems),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            decoration: BoxDecoration(
              color: colors.hudBg.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: colors.buttonBorder.withValues(alpha: 0.2)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: colors.background,
              unselectedLabelColor: colors.text.withValues(alpha: 0.58),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colors.accent.withValues(alpha: 0.22),
                    blurRadius: 10,
                  ),
                ],
              ),
              labelStyle: const TextStyle(
                fontFamily: AppTypography.modernFont,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: AppTypography.modernFont,
                fontSize: 11,
              ),
              tabs: const [
                Tab(text: '🐍 Skins'),
                Tab(text: '🎒 Gear'),
                Tab(text: '💎 Relics'),
                Tab(text: '🛕 Altar'),
              ],
              isScrollable: true,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _SkinsTab(
                  colors: colors,
                  onGacha: () => _showGachaDialog(context, userProvider)),
              _GearTab(colors: colors),
              _RelicsTab(colors: colors),
              _AltarTab(colors: colors),
            ],
          ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.hudBg.withValues(alpha: 0.7),
        elevation: 0,
        automaticallyImplyLeading: !widget.isEmbedded,
        leading: widget.isEmbedded
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: colors.text, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: Text(
          '🛒 SHOP',
          style: TextStyle(
            fontFamily: AppTypography.modernFont,
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
                          fontFamily: AppTypography.modernFont,
                          fontSize: 11,
                          color: Colors.amber,
                          fontWeight: FontWeight.bold)),
                ]),
                Row(children: [
                  const Text('💎', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 3),
                  Text('$gems',
                      style: const TextStyle(
                          fontFamily: AppTypography.modernFont,
                          fontSize: 11,
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold)),
                ]),
              ],
            ),
          ),
        ],
      ),
      body: DynamicBackground(
        themeType: widget.themeType,
        child: SafeArea(
          child: bodyContent,
        ),
      ),
    );
  }

  Widget _buildStoreHero(AppThemeColors colors, int coins, int gems) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.buttonBorder.withValues(alpha: 0.26),
            colors.accent.withValues(alpha: 0.14),
            colors.hudBg.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.buttonBorder.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: colors.buttonBorder.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
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
              color: colors.hudBg.withValues(alpha: 0.75),
              border: Border.all(
                  color: colors.buttonBorder.withValues(alpha: 0.45)),
            ),
            child: const Center(
              child: Text('🛍️', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BLACK MARKET BAZAAR',
                  style: TextStyle(
                    fontFamily: AppTypography.modernFont,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Spend coins and souls on style, power, and permanent upgrades.',
                  style: TextStyle(
                    fontFamily: AppTypography.modernFont,
                    fontSize: 9,
                    color: colors.text.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '💰 $coins',
                style: const TextStyle(
                  fontFamily: AppTypography.modernFont,
                  fontSize: 10,
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '💎 $gems',
                style: const TextStyle(
                  fontFamily: AppTypography.modernFont,
                  fontSize: 10,
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
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
                              fontFamily: AppTypography.modernFont,
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
                                          fontFamily: AppTypography.modernFont,
                                          color: Colors.greenAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            Colors.amber.withValues(alpha: 0.1),
                                        boxShadow: [
                                          BoxShadow(
                                              color: Colors.amber.withValues(
                                                  alpha: 0.3 * value),
                                              blurRadius: 20 * value,
                                              spreadRadius: 5 * value)
                                        ]),
                                    child: Text(wonSkin!.emoji,
                                        style: const TextStyle(fontSize: 60)),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(wonSkin!.displayName,
                                      style: TextStyle(
                                          fontFamily: AppTypography.modernFont,
                                          fontSize: 24,
                                          color: colors.accent,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(wonSkin!.rarity.name.toUpperCase(),
                                      style: TextStyle(
                                          fontFamily: AppTypography.modernFont,
                                          fontSize: 10,
                                          color: colors.text
                                              .withValues(alpha: 0.5))),
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
                            fontFamily: AppTypography.modernFont,
                            fontSize: 10,
                            color: colors.text.withValues(alpha: 0.7),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Duplicate compensation: +$minComp to +$maxComp coins',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTypography.modernFont,
                            fontSize: 9,
                            color: colors.text.withValues(alpha: 0.5),
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
                                  fontFamily: AppTypography.modernFont,
                                  fontWeight: FontWeight.bold)),
                        ),
                      if (!spinning)
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('CLOSE',
                              style: TextStyle(
                                  fontFamily: AppTypography.modernFont,
                                  color: colors.text)),
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
                    fontFamily: AppTypography.modernFont,
                    fontSize: 11,
                    color: colors.text.withValues(alpha: 0.6),
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
                  fontFamily: AppTypography.modernFont,
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
    final gems = userProvider.snakeSouls;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.cyan.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Text('🎒', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Expedition Gear is consumed on use. Equip before a Safari run from the Loadout screen.',
                  style: TextStyle(
                      color: colors.text.withValues(alpha: 0.7), fontSize: 12),
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
              border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
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
                          ? Colors.cyanAccent.withValues(alpha: 0.15)
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
    final ownedRelics = userProvider.ownedRelics;
    final equippedRelic = userProvider.equippedRelicId;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Text('💎', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Relics grant passive bonuses to every run. Own one at a time — only the latest purchased applies.',
                  style: TextStyle(
                      color: colors.text.withValues(alpha: 0.7), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ..._relics.map((relic) {
          final owned = ownedRelics.contains(relic.id);
          final equipped = equippedRelic == relic.id;
          final canAfford = coins >= relic.coinPrice;
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: equipped
                  ? Colors.deepPurple.withValues(alpha: 0.20)
                  : owned
                      ? Colors.purple.withValues(alpha: 0.12)
                      : const Color(0xFF141418),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: equipped
                    ? Colors.deepPurpleAccent.withValues(alpha: 0.7)
                    : owned
                        ? Colors.purple.withValues(alpha: 0.6)
                        : Colors.white24,
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
                      if (equipped)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            '✅ EQUIPPED',
                            style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      else if (owned)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'OWNED',
                            style: TextStyle(
                                color: Colors.purpleAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () async {
                    if (owned) {
                      await userProvider.equipRelic(relic.id);
                      return;
                    }
                    if (!canAfford) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Not enough coins!')),
                      );
                      return;
                    }
                    await userProvider.buyRelic(relic.id, relic.coinPrice);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: equipped
                          ? Colors.green.withValues(alpha: 0.16)
                          : owned
                              ? Colors.purple.withValues(alpha: 0.15)
                              : canAfford
                                  ? Colors.amber.withValues(alpha: 0.15)
                                  : Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: equipped
                            ? Colors.greenAccent
                            : owned
                                ? Colors.purpleAccent
                                : canAfford
                                    ? Colors.amber
                                    : Colors.white24,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          equipped
                              ? '✓'
                              : owned
                                  ? 'E'
                                  : '💰',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          equipped
                              ? 'ON'
                              : owned
                                  ? 'USE'
                                  : '${relic.coinPrice}',
                          style: TextStyle(
                            color: equipped
                                ? Colors.greenAccent
                                : owned
                                    ? Colors.purpleAccent
                                    : canAfford
                                        ? Colors.amber
                                        : Colors.white38,
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
            colors.buttonBorder.withValues(alpha: 0.25),
            colors.accent.withValues(alpha: 0.12),
            colors.hudBg.withValues(alpha: 0.65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.buttonBorder.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.hudBg.withValues(alpha: 0.7),
              border: Border.all(
                  color: colors.buttonBorder.withValues(alpha: 0.35)),
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
                    fontFamily: AppTypography.modernFont,
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
                    fontFamily: AppTypography.modernFont,
                    fontSize: 9,
                    color: colors.text.withValues(alpha: 0.72),
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
    final safariCount =
        StorageService().safariCounts[skin.safariUnlockPreyType] ?? 0;
    final safariTarget = skin.safariUnlockTarget;
    final safariProgress =
        safariTarget > 0 ? (safariCount / safariTarget).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isEquipped
                  ? colors.buttonBorder.withValues(alpha: 0.15)
                  : colors.hudBg.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isEquipped
                    ? colors.buttonBorder
                    : (isUnlocked
                        ? colors.buttonBorder.withValues(alpha: 0.3)
                        : colors.buttonBorder.withValues(alpha: 0.1)),
                width: isEquipped ? 2 : 1,
              ),
              boxShadow: isEquipped
                  ? [
                      BoxShadow(
                          color: colors.buttonBorder.withValues(alpha: 0.2),
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
                          color: colors.buttonBorder.withValues(alpha: 0.3))),
                  child: Center(
                      child: Text(skin.emoji,
                          style: const TextStyle(fontSize: 30)))),
              Text(skin.displayName,
                  style: TextStyle(
                      fontFamily: AppTypography.modernFont,
                      fontSize: 13,
                      color: colors.text,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(skin.advantageDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: AppTypography.modernFont,
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
                            fontFamily: AppTypography.modernFont,
                            fontSize: 9,
                            color: Colors.black,
                            fontWeight: FontWeight.bold)))
              else if (isUnlocked)
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: colors.buttonBorder.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('USE',
                        style: TextStyle(
                            fontFamily: AppTypography.modernFont,
                            fontSize: 9,
                            color: colors.buttonBorder,
                            fontWeight: FontWeight.bold)))
              else if (skin.isSafariExclusive)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'MILESTONE',
                        style: TextStyle(
                          fontFamily: AppTypography.modernFont,
                          fontSize: 9,
                          color: Colors.cyanAccent.withValues(alpha: 0.9),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${skin.safariUnlockPreyType.toUpperCase()}  $safariCount/$safariTarget',
                        style: TextStyle(
                          fontFamily: AppTypography.modernFont,
                          fontSize: 8,
                          color: colors.text.withValues(alpha: 0.8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: safariProgress,
                          minHeight: 4,
                          backgroundColor:
                              colors.background.withValues(alpha: 0.5),
                          color: Colors.cyanAccent.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        skin.safariUnlockHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTypography.modernFont,
                          fontSize: 7,
                          color: colors.text.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                )
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
                                fontFamily: AppTypography.modernFont,
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
                                  colors.background.withValues(alpha: 0.5),
                              color: Colors.amber.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            availableCoins >= skin.price
                                ? 'Tap to unlock!'
                                : '${(skin.price - availableCoins).clamp(0, skin.price)} more',
                            style: TextStyle(
                              fontFamily: AppTypography.modernFont,
                              fontSize: 7,
                              color: availableCoins >= skin.price
                                  ? Colors.greenAccent
                                  : colors.text.withValues(alpha: 0.4),
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

// ── Altar Tab ─────────────────────────────────────────────────────────────────
class _AltarTab extends StatefulWidget {
  final AppThemeColors colors;
  const _AltarTab({required this.colors});

  @override
  State<_AltarTab> createState() => _AltarTabState();
}

class _AltarTabState extends State<_AltarTab> {
  final StorageService _storage = StorageService();

  int get gems => _storage.snakeSouls;
  int get thickScales => _storage.skillThickScales;
  int get greed => _storage.skillGreed;
  int get dashMastery => _storage.skillDashMastery;

  int _costForLevel(int level) => (level + 1) * 150;

  Future<void> _upgradeSkill(String title, int currentLvl, int maxLvl,
      Future<void> Function(int) saveFunc) async {
    if (currentLvl >= maxLvl) return;
    final cost = _costForLevel(currentLvl);
    if (gems >= cost) {
      AudioService().play(SoundEffect.powerUp);
      await _storage.deductSnakeSouls(cost);
      await saveFunc(currentLvl + 1);
      setState(() {});
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not enough Snake Souls!',
                style: TextStyle(fontFamily: AppTypography.modernFont)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSkillCard(String title, String desc, String icon, int currentLvl,
      int maxLvl, Future<void> Function(int) saveFunc) {
    final colors = widget.colors;
    final bool isMax = currentLvl >= maxLvl;
    final int cost = _costForLevel(currentLvl);
    final bool canAfford = !isMax && gems >= cost;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.hudBg.withValues(alpha: 0.6),
        border: Border.all(
            color: colors.buttonBorder.withValues(alpha: 0.5), width: 1.5),
        borderRadius: BorderRadius.circular(12),
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
                      fontFamily: AppTypography.modernFont,
                      color: colors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  'Lvl $currentLvl / $maxLvl',
                  style: TextStyle(
                      color: colors.accent,
                      fontFamily: AppTypography.modernFont,
                      fontSize: 10),
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
          const SizedBox(width: 10),
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
                        fontFamily: AppTypography.modernFont,
                        fontWeight: FontWeight.bold))
                : Text('💎 $cost',
                    style: TextStyle(
                        fontFamily: AppTypography.modernFont,
                        fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.buttonBorder.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: colors.buttonBorder.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              const Text('🛕', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Offer Snake Souls to gain permanent power across all game modes.',
                  style: TextStyle(
                      fontFamily: AppTypography.modernFont,
                      color: colors.text.withValues(alpha: 0.7),
                      fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: colors.buttonBorder.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: colors.buttonBorder.withValues(alpha: 0.6)),
            ),
            child: Text(
              '💎 $gems Souls Available',
              style: TextStyle(
                  fontFamily: AppTypography.modernFont,
                  fontSize: 14,
                  color: colors.accent,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildSkillCard(
          'Thick Scales',
          'Absorb wall hits in Explore Mode without dying.',
          '🛡️',
          thickScales,
          3,
          _storage.setSkillThickScales,
        ),
        _buildSkillCard(
          'Greed',
          'Earn bonus coins from Prey and Bosses.',
          '💰',
          greed,
          5,
          _storage.setSkillGreed,
        ),
        _buildSkillCard(
          'Dash Mastery',
          'Start Explore Mode with instant dash charges.',
          '⚡',
          dashMastery,
          2,
          _storage.setSkillDashMastery,
        ),
      ],
    );
  }
}
