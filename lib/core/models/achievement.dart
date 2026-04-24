/// Represents a single achievement definition
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int xpReward;
  final AchievementType type;
  final int targetValue; // target count/score to unlock

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.xpReward,
    required this.type,
    required this.targetValue,
  });
}

enum AchievementType {
  score, // reach a score
  length, // reach snake length
  gamesPlayed, // play N games
  foodEaten, // eat N foods total
  combo, // reach N combo
  powerUps, // collect N power-ups
  modePlay, // play a specific mode
  survive, // survive N seconds
  goldenApple, // eat N golden apples total
  poisonApple, // eat N poison apples total
  shadowDefeat, // defeat shadow snake rival N times
  questsCompleted, // complete N daily/weekly quests
  completionist, // unlock all other achievements
  // Safari types
  safariPreyCaught, // catch N total prey in explore
  safariCreatureTypes, // catch N different creature types
  safariHuntStreak, // reach hunt streak of N
  safariRoomsExplored, // visit N rooms total
  safariCrocKills, // catch N crocs
  safariAllCreatures, // catch all 5 creature types
}

/// All game achievements (static definitions)
class Achievements {
  static const List<Achievement> all = [
    // ── Score milestones ──────────────────────────────────────────
    Achievement(
        id: 'score_50',
        title: 'First Blood',
        description: 'Score 50 points in a single game',
        icon: '🩸',
        xpReward: 50,
        type: AchievementType.score,
        targetValue: 50),
    Achievement(
        id: 'score_100',
        title: 'Century',
        description: 'Score 100 points in a single game',
        icon: '💯',
        xpReward: 100,
        type: AchievementType.score,
        targetValue: 100),
    Achievement(
        id: 'score_300',
        title: 'Sharpshooter',
        description: 'Score 300 points in a single game',
        icon: '🎯',
        xpReward: 200,
        type: AchievementType.score,
        targetValue: 300),
    Achievement(
        id: 'score_500',
        title: 'High Roller',
        description: 'Score 500 points in a single game',
        icon: '🎰',
        xpReward: 300,
        type: AchievementType.score,
        targetValue: 500),
    Achievement(
        id: 'score_1000',
        title: 'Legend',
        description: 'Score 1000 points in a single game',
        icon: '⚡',
        xpReward: 500,
        type: AchievementType.score,
        targetValue: 1000),
    Achievement(
        id: 'score_2000',
        title: 'Serpent God',
        description: 'Score 2000 points in a single game',
        icon: '👑',
        xpReward: 1000,
        type: AchievementType.score,
        targetValue: 2000),
    Achievement(
        id: 'score_5000',
        title: 'Mythical',
        description: 'Score 5000 points in a single game',
        icon: '🌌',
        xpReward: 2500,
        type: AchievementType.score,
        targetValue: 5000),
    Achievement(
        id: 'score_10k',
        title: 'Unstoppable',
        description: 'Score 10000 points in a single game',
        icon: '💥',
        xpReward: 5000,
        type: AchievementType.score,
        targetValue: 10000),

    // ── Snake length ──────────────────────────────────────────────
    Achievement(
        id: 'len_10',
        title: 'Growing Up',
        description: 'Reach length 10',
        icon: '🐍',
        xpReward: 50,
        type: AchievementType.length,
        targetValue: 10),
    Achievement(
        id: 'len_20',
        title: 'Hoarder',
        description: 'Reach length 20',
        icon: '🐉',
        xpReward: 100,
        type: AchievementType.length,
        targetValue: 20),
    Achievement(
        id: 'len_40',
        title: 'Anaconda',
        description: 'Reach length 40',
        icon: '🔱',
        xpReward: 300,
        type: AchievementType.length,
        targetValue: 40),
    Achievement(
        id: 'len_80',
        title: 'Titanboa',
        description: 'Reach length 80',
        icon: '🦖',
        xpReward: 800,
        type: AchievementType.length,
        targetValue: 80),
    Achievement(
        id: 'len_150',
        title: 'World Eater',
        description: 'Reach length 150',
        icon: '🌍',
        xpReward: 2000,
        type: AchievementType.length,
        targetValue: 150),

    // ── Games played ──────────────────────────────────────────────
    Achievement(
        id: 'play_5',
        title: 'Warming Up',
        description: 'Play 5 games',
        icon: '🎮',
        xpReward: 50,
        type: AchievementType.gamesPlayed,
        targetValue: 5),
    Achievement(
        id: 'play_25',
        title: 'Addicted',
        description: 'Play 25 games',
        icon: '🔁',
        xpReward: 150,
        type: AchievementType.gamesPlayed,
        targetValue: 25),
    Achievement(
        id: 'play_100',
        title: 'Dedicated',
        description: 'Play 100 games',
        icon: '💎',
        xpReward: 500,
        type: AchievementType.gamesPlayed,
        targetValue: 100),
    Achievement(
        id: 'play_500',
        title: 'True Fan',
        description: 'Play 500 games',
        icon: '❤️',
        xpReward: 2000,
        type: AchievementType.gamesPlayed,
        targetValue: 500),
    Achievement(
        id: 'play_1000',
        title: 'No Life',
        description: 'Play 1000 games',
        icon: '💀',
        xpReward: 5000,
        type: AchievementType.gamesPlayed,
        targetValue: 1000),

    // ── Food eaten (lifetime) ─────────────────────────────────────
    Achievement(
        id: 'food_50',
        title: 'Hungry',
        description: 'Eat 50 foods total',
        icon: '🍎',
        xpReward: 100,
        type: AchievementType.foodEaten,
        targetValue: 50),
    Achievement(
        id: 'food_200',
        title: 'Insatiable',
        description: 'Eat 200 foods total',
        icon: '🍽️',
        xpReward: 300,
        type: AchievementType.foodEaten,
        targetValue: 200),
    Achievement(
        id: 'food_500',
        title: 'Black Hole',
        description: 'Eat 500 foods total',
        icon: '🌑',
        xpReward: 600,
        type: AchievementType.foodEaten,
        targetValue: 500),
    Achievement(
        id: 'food_2000',
        title: 'Devourer',
        description: 'Eat 2000 foods total',
        icon: '🪐',
        xpReward: 1500,
        type: AchievementType.foodEaten,
        targetValue: 2000),
    Achievement(
        id: 'food_10000',
        title: 'Gluttony Sin',
        description: 'Eat 10000 foods total',
        icon: '😈',
        xpReward: 5000,
        type: AchievementType.foodEaten,
        targetValue: 10000),

    // ── Combo ─────────────────────────────────────────────────────
    Achievement(
        id: 'combo_3',
        title: 'On Fire',
        description: 'Reach a 3x combo',
        icon: '🔥',
        xpReward: 75,
        type: AchievementType.combo,
        targetValue: 3),
    Achievement(
        id: 'combo_5',
        title: 'Combo King',
        description: 'Reach a 5x combo',
        icon: '⚡',
        xpReward: 200,
        type: AchievementType.combo,
        targetValue: 5),
    Achievement(
        id: 'combo_8',
        title: 'Frenzy',
        description: 'Reach an 8x combo',
        icon: '🌪️',
        xpReward: 500,
        type: AchievementType.combo,
        targetValue: 8),
    Achievement(
        id: 'combo_12',
        title: 'Godlike',
        description: 'Reach a 12x combo',
        icon: '✨',
        xpReward: 1000,
        type: AchievementType.combo,
        targetValue: 12),

    // ── Power-ups ─────────────────────────────────────────────────
    Achievement(
        id: 'pu_10',
        title: 'Power Hungry',
        description: 'Collect 10 power-ups',
        icon: '✨',
        xpReward: 100,
        type: AchievementType.powerUps,
        targetValue: 10),
    Achievement(
        id: 'pu_50',
        title: 'Power User',
        description: 'Collect 50 power-ups',
        icon: '🔮',
        xpReward: 300,
        type: AchievementType.powerUps,
        targetValue: 50),
    Achievement(
        id: 'pu_200',
        title: 'Addict',
        description: 'Collect 200 power-ups',
        icon: '💊',
        xpReward: 800,
        type: AchievementType.powerUps,
        targetValue: 200),
    Achievement(
        id: 'pu_1000',
        title: 'Ascended',
        description: 'Collect 1000 power-ups',
        icon: '🌌',
        xpReward: 3000,
        type: AchievementType.powerUps,
        targetValue: 1000),

    // ── Golden / Poison Apples ────────────────────────────────────
    Achievement(
        id: 'gold_5',
        title: 'Gold Digger',
        description: 'Eat 5 Golden Apples total',
        icon: '🍌',
        xpReward: 200,
        type: AchievementType.goldenApple,
        targetValue: 5),
    Achievement(
        id: 'gold_25',
        title: 'Midas Touch',
        description: 'Eat 25 Golden Apples total',
        icon: '🏆',
        xpReward: 1000,
        type: AchievementType.goldenApple,
        targetValue: 25),
    Achievement(
        id: 'poison_5',
        title: 'Risk Taker',
        description: 'Eat 5 Poison Apples total',
        icon: '🤢',
        xpReward: 200,
        type: AchievementType.poisonApple,
        targetValue: 5),
    Achievement(
        id: 'poison_25',
        title: 'Immunity',
        description: 'Eat 25 Poison Apples total',
        icon: '☠️',
        xpReward: 1000,
        type: AchievementType.poisonApple,
        targetValue: 25),

    // ── Special encounters ────────────────────────────────────────
    Achievement(
        id: 'shadow_1',
        title: 'Shadow Slayer',
        description: 'Defeat the Shadow Snake rival',
        icon: '👻',
        xpReward: 300,
        type: AchievementType.shadowDefeat,
        targetValue: 1),
    Achievement(
        id: 'shadow_5',
        title: 'Anti-Glitch',
        description: 'Defeat the rival 5 times',
        icon: '🛠️',
        xpReward: 1000,
        type: AchievementType.shadowDefeat,
        targetValue: 5),

    // ── Progression ───────────────────────────────────────────────
    Achievement(
        id: 'quests_5',
        title: 'Overachiever',
        description: 'Complete 5 Daily Quests',
        icon: '📜',
        xpReward: 300,
        type: AchievementType.questsCompleted,
        targetValue: 5),
    Achievement(
        id: 'quests_20',
        title: 'Quest Master',
        description: 'Complete 20 Daily Quests',
        icon: '👑',
        xpReward: 1500,
        type: AchievementType.questsCompleted,
        targetValue: 20),

    // ── Completionist ─────────────────────────────────────────────
    Achievement(
        id: 'all_ach',
        title: 'Ultimate Predator',
        description: 'Unlock all other achievements',
        icon: '🏆',
        xpReward: 10000,
        type: AchievementType.completionist,
        targetValue: 30),

    // ── Safari Explorer chapter ───────────────────────────────────
    Achievement(
        id: 'safari_first',
        title: 'First Hunt',
        description: 'Catch your first prey in Safari mode',
        icon: '🐭',
        xpReward: 50,
        type: AchievementType.safariPreyCaught,
        targetValue: 1),
    Achievement(
        id: 'safari_10',
        title: 'Tracker',
        description: 'Catch 10 prey in Safari mode',
        icon: '🗺️',
        xpReward: 100,
        type: AchievementType.safariPreyCaught,
        targetValue: 10),
    Achievement(
        id: 'safari_50',
        title: 'Hunter',
        description: 'Catch 50 prey in Safari mode',
        icon: '🎯',
        xpReward: 300,
        type: AchievementType.safariPreyCaught,
        targetValue: 50),
    Achievement(
        id: 'safari_200',
        title: 'Predator',
        description: 'Catch 200 prey in Safari mode',
        icon: '🔥',
        xpReward: 800,
        type: AchievementType.safariPreyCaught,
        targetValue: 200),
    Achievement(
        id: 'safari_500',
        title: 'Apex Hunter',
        description: 'Catch 500 prey in Safari mode',
        icon: '🦁',
        xpReward: 2000,
        type: AchievementType.safariPreyCaught,
        targetValue: 500),
    Achievement(
        id: 'safari_types3',
        title: 'Field Guide',
        description: 'Catch 3 different creature types',
        icon: '📖',
        xpReward: 200,
        type: AchievementType.safariCreatureTypes,
        targetValue: 3),
    Achievement(
        id: 'safari_types5',
        title: 'Naturalist',
        description: 'Catch all 5 creature types',
        icon: '🌍',
        xpReward: 500,
        type: AchievementType.safariAllCreatures,
        targetValue: 5),
    Achievement(
        id: 'safari_streak3',
        title: 'Combo Hunter',
        description: 'Reach Hunt Streak ×3',
        icon: '🔥',
        xpReward: 150,
        type: AchievementType.safariHuntStreak,
        targetValue: 3),
    Achievement(
        id: 'safari_streak7',
        title: 'Apex Predator',
        description: 'Reach Hunt Streak ×7',
        icon: '👑',
        xpReward: 1000,
        type: AchievementType.safariHuntStreak,
        targetValue: 7),
    Achievement(
        id: 'safari_rooms25',
        title: 'Cartographer',
        description: 'Visit 25 rooms in Safari mode',
        icon: '🗺️',
        xpReward: 200,
        type: AchievementType.safariRoomsExplored,
        targetValue: 25),
    Achievement(
        id: 'safari_rooms88',
        title: 'World Explorer',
        description: 'Visit all 88 rooms in Safari mode',
        icon: '🌎',
        xpReward: 2000,
        type: AchievementType.safariRoomsExplored,
        targetValue: 88),
    Achievement(
        id: 'safari_croc5',
        title: 'Croc Slayer',
        description: 'Catch 5 crocodiles',
        icon: '🐊',
        xpReward: 400,
        type: AchievementType.safariCrocKills,
        targetValue: 5),
    Achievement(
        id: 'safari_croc20',
        title: 'Croc Bane',
        description: 'Catch 20 crocodiles',
        icon: '⚔️',
        xpReward: 1500,
        type: AchievementType.safariCrocKills,
        targetValue: 20),
  ];

  static Achievement? findById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Runtime state of a single achievement for a player
class AchievementProgress {
  final String id;
  final int progress; // current progress toward targetValue
  final bool unlocked;
  final DateTime? unlockedAt;

  const AchievementProgress({
    required this.id,
    this.progress = 0,
    this.unlocked = false,
    this.unlockedAt,
  });

  AchievementProgress copyWith(
      {int? progress, bool? unlocked, DateTime? unlockedAt}) {
    return AchievementProgress(
      id: id,
      progress: progress ?? this.progress,
      unlocked: unlocked ?? this.unlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'progress': progress,
        'unlocked': unlocked,
        'unlockedAt': unlockedAt?.toIso8601String(),
      };

  factory AchievementProgress.fromJson(Map<String, dynamic> j) =>
      AchievementProgress(
        id: j['id'] as String,
        progress: j['progress'] as int? ?? 0,
        unlocked: j['unlocked'] as bool? ?? false,
        unlockedAt: j['unlockedAt'] != null
            ? DateTime.tryParse(j['unlockedAt'] as String)
            : null,
      );
}
