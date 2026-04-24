import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/enums/theme_type.dart';
import '../providers/user_provider.dart';
import '../core/models/quest_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class QuestsScreen extends StatelessWidget {
  final ThemeType themeType;
  const QuestsScreen({super.key, required this.themeType});

  AppThemeColors get colors {
    switch (themeType) {
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
    final quests = userProvider.quests;

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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📅', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text('DAILY QUESTS',
                style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 13,
                    color: colors.text,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: quests.isEmpty
            ? Center(
                child: Text(
                  'No quests today. Check back soon!',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 11,
                    color: colors.text.withOpacity(0.45),
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: quests.length,
                itemBuilder: (context, index) {
                  final q = quests[index];
                  return _QuestCard(quest: q, colors: colors)
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 100 * index))
                      .slideX();
                },
              ),
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final DailyQuest quest;
  final AppThemeColors colors;

  const _QuestCard({required this.quest, required this.colors});

  @override
  Widget build(BuildContext context) {
    final isDone = quest.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDone
            ? colors.buttonBorder.withOpacity(0.15)
            : colors.hudBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDone
              ? colors.buttonBorder
              : colors.buttonBorder.withOpacity(0.2),
          width: isDone ? 2 : 1,
        ),
        boxShadow: isDone
            ? [
                BoxShadow(
                    color: colors.buttonBorder.withOpacity(0.2), blurRadius: 15)
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(
                quest.title.toUpperCase(),
                style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 12,
                    color: colors.text,
                    fontWeight: FontWeight.bold),
              )),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Text('💰', style: TextStyle(fontSize: 10)),
                    const SizedBox(width: 4),
                    Text(
                      '+${quest.coinReward}',
                      style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 11,
                          color: Colors.amber,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            quest.description,
            style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 10,
                color: colors.text.withOpacity(0.7)),
          ),
          const SizedBox(height: 16),
          // Progress bar
          Semantics(
            label:
                '${quest.title}: ${quest.currentAmount} of ${quest.goalAmount} complete${isDone ? ", quest finished" : ""}',
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: quest.progress,
                      minHeight: 8,
                      backgroundColor: colors.background.withOpacity(0.5),
                      color: isDone ? Colors.greenAccent : colors.buttonBorder,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${quest.currentAmount} / ${quest.goalAmount}',
                  style: TextStyle(
                      fontFamily: 'Orbitron', fontSize: 10, color: colors.text),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
