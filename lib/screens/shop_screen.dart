import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/enums/snake_skin.dart';
import '../core/enums/theme_type.dart';
import '../core/constants/app_colors.dart';
import '../providers/user_provider.dart';
import '../services/audio_service.dart';

class ShopScreen extends StatelessWidget {
  final ThemeType themeType;
  const ShopScreen({super.key, required this.themeType});

  AppThemeColors get colors {
    switch (themeType) {
      case ThemeType.retro: return AppThemeColors.retro;
      case ThemeType.neon: return AppThemeColors.neon;
      case ThemeType.nature: return AppThemeColors.nature;
      case ThemeType.arcade: return AppThemeColors.arcade;
      case ThemeType.cyber: return AppThemeColors.cyber;
      case ThemeType.volcano: return AppThemeColors.volcano;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final availableCoins = userProvider.coins;
    
    return Scaffold(
      backgroundColor: colors.background,
       appBar: AppBar(
         backgroundColor: colors.hudBg.withOpacity(0.7),
         elevation: 0,
         leading: IconButton(
           icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.text, size: 20),
           onPressed: () => Navigator.of(context).pop(),
         ),
         title: Row(
           mainAxisAlignment: MainAxisAlignment.center,
           mainAxisSize: MainAxisSize.min,
           children: [
             const Text('🐍', style: TextStyle(fontSize: 20)),
             const SizedBox(width: 8),
             Text('SNAKE SKINS', style: TextStyle(fontFamily: 'Orbitron', fontSize: 13, color: colors.text, fontWeight: FontWeight.bold)),
           ],
         ),
         centerTitle: true,
         actions: [
           Padding(
             padding: const EdgeInsets.only(right: 16),
             child: Center(
               child: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                 decoration: BoxDecoration(
                   color: Colors.amber.withOpacity(0.15),
                   borderRadius: BorderRadius.circular(10),
                   border: Border.all(color: Colors.amber.withOpacity(0.4)),
                 ),
                 child: Row(
                   children: [
                     const Text('💰', style: TextStyle(fontSize: 12)),
                     const SizedBox(width: 4),
                     Text(
                       '$availableCoins',
                       style: const TextStyle(fontFamily: 'Orbitron', fontSize: 12, color: Colors.amber, fontWeight: FontWeight.bold),
                     ),
                   ],
                 ),
               ),
             ),
           ),
         ],
       ),
       body: SafeArea(
         child: GridView.builder(
           padding: const EdgeInsets.all(20),
           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
             crossAxisCount: 2,
             childAspectRatio: 0.8,
             crossAxisSpacing: 16,
             mainAxisSpacing: 16,
           ),
           itemCount: SnakeSkin.values.length,
           itemBuilder: (ctx, i) {
             final skin = SnakeSkin.values[i];
             final isUnlocked = userProvider.unlockedSkins.contains(skin);
             final isEquipped = userProvider.equippedSkin == skin;
             
             return _SkinCard(
                skin: skin, 
                colors: colors, 
                isUnlocked: isUnlocked, 
                isEquipped: isEquipped, 
                onTap: () async {
                  if (isEquipped) return;
                  if (isUnlocked) {
                     AudioService().play(SoundEffect.click);
                     await userProvider.equipSkin(skin);
                  } else {
                     if (availableCoins >= skin.price) {
                        AudioService().play(SoundEffect.highScore);
                        await userProvider.buySkin(skin);
                     } else {
                        // Not enough coins error sound
                        AudioService().play(SoundEffect.click); 
                     }
                  }
                }
             );
           },
         ),
       ),
       floatingActionButton: FloatingActionButton.extended(
         onPressed: () => _showGachaDialog(context, userProvider),
         backgroundColor: Colors.amber,
         icon: const Text('🎰', style: TextStyle(fontSize: 20)),
         label: const Text('LUCKY SPIN\n1000 💰', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black)),
       ),
    );
  }

  void _showGachaDialog(BuildContext context, UserProvider userProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          bool spinning = false;
          SnakeSkin? wonSkin;
          return Dialog(
            backgroundColor: colors.hudBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: colors.buttonBorder, width: 2)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('MYSTERY BOX', style: TextStyle(fontFamily: 'Orbitron', fontSize: 18, color: colors.text, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  if (spinning)
                    const CircularProgressIndicator(color: Colors.amber)
                  else if (wonSkin != null)
                     TweenAnimationBuilder<double>(
                       tween: Tween(begin: 0.0, end: 1.0),
                       duration: const Duration(milliseconds: 600),
                       curve: Curves.elasticOut,
                       builder: (context, value, child) {
                         return Transform.scale(
                           scale: value,
                           child: Column(
                             children: [
                                const Text('NEW SKIN UNLOCKED!', style: TextStyle(fontFamily: 'Orbitron', color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.amber.withOpacity(0.1),
                                    boxShadow: [
                                      BoxShadow(color: Colors.amber.withOpacity(0.3 * value), blurRadius: 20 * value, spreadRadius: 5 * value)
                                    ]
                                  ),
                                  child: Text(
                                     wonSkin == SnakeSkin.ghost ? '👻' 
                                     : wonSkin == SnakeSkin.skeleton ? '💀' 
                                     : wonSkin == SnakeSkin.robot ? '🤖' 
                                     : wonSkin == SnakeSkin.rainbow ? '🌈' 
                                     : wonSkin == SnakeSkin.ninja ? '🥷'
                                     : wonSkin == SnakeSkin.dragon ? '🐉'
                                     : wonSkin == SnakeSkin.vampire ? '🧛'
                                     : wonSkin == SnakeSkin.golden ? '✨'
                                     : '🐍',
                                     style: const TextStyle(fontSize: 60),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(wonSkin!.displayName, style: TextStyle(fontFamily: 'Orbitron', fontSize: 24, color: colors.accent, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(wonSkin!.rarity.name.toUpperCase(), style: TextStyle(fontFamily: 'Orbitron', fontSize: 10, color: colors.text.withOpacity(0.5))),
                             ]
                           ),
                         );
                       }
                     )
                  else
                    const Text('🎰', style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 20),
                  if (!spinning && wonSkin == null)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                      onPressed: () async {
                        if (userProvider.coins < 1000) {
                          AudioService().play(SoundEffect.click);
                          return;
                        }
                        setState(() => spinning = true);
                        AudioService().play(SoundEffect.powerUp);
                        await Future.delayed(const Duration(seconds: 2));
                        final skin = await userProvider.rollGacha();
                        setState(() { 
                           spinning = false; 
                           wonSkin = skin; 
                        });
                        AudioService().play(SoundEffect.highScore);
                      },
                      child: const Text('SPIN (1000 💰)', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
                    ),
                  if (!spinning)
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('CLOSE', style: TextStyle(fontFamily: 'Orbitron', color: colors.text)),
                    ),
                ],
              ),
            ),
          );
        }
      )
    );
  }
}

class _SkinCard extends StatelessWidget {
  final SnakeSkin skin;
  final AppThemeColors colors;
  final bool isUnlocked;
  final bool isEquipped;
  final VoidCallback onTap;

  const _SkinCard({
    required this.skin,
    required this.colors,
    required this.isUnlocked,
    required this.isEquipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isEquipped ? colors.buttonBorder.withOpacity(0.15) : colors.hudBg.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
             color: isEquipped 
                 ? colors.buttonBorder 
                 : (isUnlocked ? colors.buttonBorder.withOpacity(0.3) : colors.buttonBorder.withOpacity(0.1)),
             width: isEquipped ? 2 : 1,
          ),
          boxShadow: isEquipped ? [
             BoxShadow(color: colors.buttonBorder.withOpacity(0.2), blurRadius: 15)
          ] : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
               width: 60, height: 60,
               decoration: BoxDecoration(
                 shape: BoxShape.circle,
                 color: colors.background,
                 border: Border.all(color: colors.buttonBorder.withOpacity(0.3))
               ),
               child: Center(
                  child: Text(
                     skin == SnakeSkin.ghost ? '👻' 
                     : skin == SnakeSkin.skeleton ? '💀' 
                     : skin == SnakeSkin.robot ? '🤖' 
                     : skin == SnakeSkin.rainbow ? '🌈' 
                     : skin == SnakeSkin.ninja ? '🥷'
                     : skin == SnakeSkin.dragon ? '🐉'
                     : skin == SnakeSkin.vampire ? '🧛'
                     : skin == SnakeSkin.golden ? '✨'
                     : '🐍',
                     style: const TextStyle(fontSize: 30)
                  )
               )
            ),
            Text(
               skin.displayName,
               style: TextStyle(fontFamily: 'Orbitron', fontSize: 13, color: colors.text, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 2),
            Text(
               skin.advantageDescription,
               textAlign: TextAlign.center,
               style: TextStyle(fontFamily: 'Orbitron', fontSize: 8, color: colors.accent, fontWeight: FontWeight.normal)
            ),
            const SizedBox(height: 8),
            if (isEquipped)
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                 decoration: BoxDecoration(color: colors.buttonBorder, borderRadius: BorderRadius.circular(10)),
                 child: const Text('EQUIPPED', style: TextStyle(fontFamily: 'Orbitron', fontSize: 9, color: Colors.black, fontWeight: FontWeight.bold))
               )
            else if (isUnlocked)
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                 decoration: BoxDecoration(color: colors.buttonBorder.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                 child: Text('USE', style: TextStyle(fontFamily: 'Orbitron', fontSize: 9, color: colors.buttonBorder, fontWeight: FontWeight.bold))
               )
            else
               Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                    const Text('💰', style: TextStyle(fontSize: 10)),
                    const SizedBox(width: 4),
                    Text('${skin.price}', style: const TextStyle(fontFamily: 'Orbitron', fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold))
                 ]
               )
          ]
        )
      )
    );
  }
}
