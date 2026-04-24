import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models/expedition_gear.dart';
import '../providers/user_provider.dart';
import '../services/storage_service.dart';

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

  void _pickGear(int slot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2A1C),
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
                const Text(
                  'Choose Gear',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Text('❌', style: TextStyle(fontSize: 24)),
                  title: const Text('None',
                      style: TextStyle(color: Colors.white70)),
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
                        color: unavailable ? Colors.white30 : Colors.white,
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
                        color:
                            unavailable ? Colors.red[300] : Colors.green[300],
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
    final gems = userProvider.safariGems;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C2A1C),
        title: const Text(
          '🌿 SAFARI EXPEDITION',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Text('💎', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 4),
                Text(
                  '$gems',
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'EXPEDITION GEAR',
              style: TextStyle(
                color: Colors.green,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Equip up to 2 one-use items for this run.',
              style: TextStyle(color: Colors.white60, fontSize: 13),
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
                backgroundColor: Colors.green[700],
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                final gear = _slots.whereType<String>().toList();
                await userProvider.setEquippedGear(gear);
                // Consume gear items used
                for (final typeName in gear) {
                  await StorageService().useGear(typeName);
                }
                if (mounted) {
                  Navigator.pop(context, LoadoutResult(gear: gear));
                }
              },
              child: const Text(
                '🌿 START HUNT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotCard(int slot) {
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
          color:
              def != null ? const Color(0xFF1A3A1A) : const Color(0xFF151F15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: def != null ? Colors.green.withOpacity(0.6) : Colors.white24,
            width: 1.5,
          ),
        ),
        child: def == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, color: Colors.white38, size: 36),
                  const SizedBox(height: 6),
                  Text(
                    'Slot ${slot + 1}',
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      def.description,
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
