import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../services/vibration_service.dart';

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

  Widget _buildSkillCard(String title, String desc, String icon, int currentLvl,
      int maxLvl, Future<void> Function(int) saveFunc) {
    bool isMax = currentLvl >= maxLvl;
    int cost = _costForLevel(currentLvl);
    bool canAfford = !isMax && gems >= cost;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        border: Border.all(
            color: Colors.redAccent.withValues(alpha: 0.5), width: 1.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withValues(alpha: 0.1),
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
                  style: const TextStyle(
                      fontFamily: 'Orbitron',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  'Lvl $currentLvl / $maxLvl',
                  style: const TextStyle(
                      color: Colors.redAccent, fontFamily: 'Orbitron'),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isMax
                  ? Colors.grey[800]
                  : (canAfford ? Colors.red[900] : Colors.grey[900]),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: isMax
                ? null
                : () => _upgradeSkill(title, currentLvl, maxLvl, saveFunc),
            child: isMax
                ? const Text('MAX',
                    style: TextStyle(
                        fontFamily: 'Orbitron', fontWeight: FontWeight.bold))
                : Text('💎 $cost',
                    style: const TextStyle(
                        fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0205),
      appBar: AppBar(
        title: const Text(
          'ALTAR OF SERPENTS',
          style: TextStyle(
              fontFamily: 'Orbitron',
              color: Colors.redAccent,
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.redAccent),
      ),
      body: Stack(
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
                        Colors.red.withValues(
                            alpha: 0.15 + (_pulseController.value * 0.1)),
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
              const Text(
                'Offer Snake Souls to gain permanent power.',
                style: TextStyle(
                    color: Colors.white54, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red[900]!.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Text(
                  '💎 $gems Souls Available',
                  style: const TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 20,
                      color: Colors.white,
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
    );
  }
}
