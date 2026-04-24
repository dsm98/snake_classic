import 'package:flutter/foundation.dart';
import '../core/models/position.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../core/models/achievement.dart';
import '../core/enums/snake_skin.dart';
import '../core/models/quest_model.dart';
import '../core/models/daily_event.dart';
import '../core/models/social_challenge.dart';
import '../core/models/seasonal_content.dart';
import '../services/analytics_service.dart';
import '../services/notification_service.dart';
import '../core/constants/app_constants.dart';
import 'dart:math';

class UserProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final AuthService _auth = AuthService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Set<String> _notifiedQuests = {};

  // Reactive state
  int _totalXp = 0;
  int _rankLevel = 0;
  double _rankProgress = 0.0;
  String _rankTitle = '';
  String _rankEmoji = '';
  int _dailyStreak = 0;
  int _coins = 0;
  int _safariGems = 0;
  List<String> _equippedGear = [];
  SnakeSkin _equippedSkin = SnakeSkin.classic;
  List<SnakeSkin> _unlockedSkins = [SnakeSkin.classic];
  List<DailyQuest> _quests = [];
  int _highestCampaignLevel = 1;
  DailyEvent? _currentDailyEvent;
  SocialChallenge? _socialChallenge;

  UserProvider() {
    _currentDailyEvent = DailyEvent.getEventForDay(DateTime.now());
    _loadFromStorage();
    // Listen to auth changes to sync cloud data
    _auth.authStateChanges.listen((user) async {
      if (user != null) {
        await _pullFromCloud();
      }
      _loadFromStorage();
    });
  }

  // Getters
  int get xp => _totalXp;
  int get bestScore => _storage.bestScore;
  int get bestLength => _storage.bestLength;
  int get rankLevel => _rankLevel;
  double get rankProgress => _rankProgress;
  String get rankTitle => _rankTitle;
  String get rankEmoji => _rankEmoji;
  int get dailyStreak => _dailyStreak;
  int get coins => _coins;
  int get safariGems => _safariGems;
  List<String> get equippedGear => _equippedGear;
  SnakeSkin get equippedSkin => _equippedSkin;
  List<SnakeSkin> get unlockedSkins => _unlockedSkins;
  List<DailyQuest> get quests => _quests;
  int get highestCampaignLevel => _highestCampaignLevel;
  DailyEvent? get currentDailyEvent => _currentDailyEvent;
  SocialChallenge? get socialChallenge => _socialChallenge;
  SeasonalContent get seasonalContent =>
      SeasonalContent.forDate(DateTime.now());
  int get prestigeLevel => _storage.prestigeLevel;

  bool get isMaxRank => _rankLevel >= 9;
  int get xpToNextRank => _storage.xpToNextRank;

  String get personalizedHint {
    final activeQuests = _quests.where((q) => !q.isCompleted).toList();
    if (activeQuests.isNotEmpty) {
      final quest = activeQuests.first;
      final remaining =
          (quest.goalAmount - quest.currentAmount).clamp(0, quest.goalAmount);
      if (remaining > 0) {
        return 'Finish quest: ${quest.title} (${remaining.toInt()} left) for ${quest.coinReward} coins';
      }
    }

    if (xpToNextRank > 0 && xpToNextRank <= 300) {
      return 'Only $xpToNextRank XP to your next rank. One strong run can do it.';
    }

    final lockedSkins = SnakeSkin.values
        .where((s) => !_unlockedSkins.contains(s))
        .toList()
      ..sort((a, b) => a.price.compareTo(b.price));
    if (lockedSkins.isNotEmpty) {
      final nextSkin = lockedSkins.first;
      final missingCoins = (nextSkin.price - _coins).clamp(0, nextSkin.price);
      return 'Next unlock: ${nextSkin.displayName} skin. ${missingCoins.toInt()} coins to go.';
    }

    return 'Try a different mode today to keep your streak and boost variety.';
  }

  /// Public method for external callers to re-sync state from storage.
  void reloadFromStorage() {
    _loadFromStorage();
    notifyListeners();
  }

  void _loadFromStorage() {
    _totalXp = _storage.totalXp;
    _rankLevel = _storage.rankLevel;
    _rankProgress = _storage.rankProgress;
    _rankTitle = _storage.rankTitle;
    _rankEmoji = _storage.rankEmoji;
    _dailyStreak = _storage.dailyStreak;
    _coins = _storage.coins;
    _safariGems = _storage.safariGems;
    _equippedGear = _storage.equippedGear;
    _equippedSkin = _storage.equippedSkin;
    _unlockedSkins = _storage.unlockedSkins;
    _highestCampaignLevel = _storage.highestCampaignLevel;
    _socialChallenge = _storage.getTodaySocialChallenge();
    _checkDailyQuests();
    notifyListeners();
  }

  double _streakCoinMultiplier(int streak) {
    if (streak >= 14) return 1.3;
    if (streak >= 7) return 1.2;
    if (streak >= 3) return 1.1;
    return 1.0;
  }

  int _streakMilestoneBonus(int streak, bool isNewDay) {
    if (!isNewDay) return 0;
    if (streak >= 14 && streak % 14 == 0) return 250;
    if (streak == 7) return 120;
    if (streak == 3) return 50;
    return 0;
  }

  Future<void> reborn() async {
    if (!isMaxRank) return;

    await _storage.setPrestigeLevel(prestigeLevel + 1);
    await _storage.setTotalXp(0);
    _loadFromStorage();
    notifyListeners();
  }

  Future<void> _pullFromCloud() async {
    if (!_auth.isSignedIn) return;
    try {
      final doc = await _db.collection('users').doc(_auth.userId).get();
      if (!doc.exists) return;

      final data = doc.data()!;

      // 1. Sync stats (take max for safety, or just cloud priority)
      final cloudXp = data['totalXp'] as int? ?? 0;
      if (cloudXp > _storage.totalXp) {
        await _storage.setTotalXp(cloudXp);
      }

      final cloudStreak = data['dailyStreak'] as int? ?? 0;
      if (cloudStreak > _storage.dailyStreak) {
        await _storage.setDailyStreak(cloudStreak);
      }

      // 2. Sync Achievements
      final cloudAchs =
          data['unlockedAchievements'] as Map<String, dynamic>? ?? {};
      final localAchs = _storage.getAllAchievementProgress();
      final List<AchievementProgress> updates = [];

      for (var entry in cloudAchs.entries) {
        final id = entry.key;
        final unlockTime = (entry.value as Timestamp).toDate();

        final local = localAchs.firstWhere((a) => a.id == id,
            orElse: () => AchievementProgress(id: id));

        if (!local.unlocked) {
          updates.add(local.copyWith(unlocked: true, unlockedAt: unlockTime));
        }
      }

      if (updates.isNotEmpty) {
        await _storage.forceSaveAchievements(updates);
      }
    } catch (e) {
      debugPrint('Cloud Pull Error: $e');
    }
  }

  Future<void> _syncToCloud() async {
    if (!_auth.isSignedIn) return;
    try {
      final unlocked = _storage
          .getAllAchievementProgress()
          .where((a) => a.unlocked)
          .fold<Map<String, dynamic>>({}, (map, a) {
        map[a.id] = Timestamp.fromDate(a.unlockedAt ?? DateTime.now());
        return map;
      });

      await _db.collection('users').doc(_auth.userId).set({
        'totalXp': _storage.totalXp,
        'dailyStreak': _storage.dailyStreak,
        'lastPlayed': FieldValue.serverTimestamp(),
        'unlockedAchievements': unlocked,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Cloud Sync Error: $e');
    }
  }

  /// Processes end-of-game data and updates all progression systems
  /// Returns a map with 'xpEarned' and 'newAchievements'
  Future<Map<String, dynamic>> completeGameSession({
    required int score,
    required int snakeLength,
    required int combo,
    required int foodEaten,
    required int powerUps,
    required int goldenApples,
    required int poisonApples,
    double coinMultiplier = 1.0,
    List<Position> path = const [],
    int bonusCoins = 0,
  }) async {
    // 1. Increment games played
    await _storage.incrementGamesPlayed();

    // 2. Update lifetime stats
    await _storage.addFoodEaten(foodEaten);
    await _storage.addPowerUpsCollected(powerUps);
    await _storage.addGoldenApplesEaten(goldenApples);
    await _storage.addPoisonApplesEaten(poisonApples);
    await _storage.updateBestCombo(combo);

    if (score > _storage.bestScore && path.isNotEmpty) {
      await _storage.saveBestReplay(path);
    }

    await _storage.updateBestScore(score);
    await _storage.updateBestLength(snakeLength);

    // 3. Calculate Base XP from performance
    double prestigeMultiplier = 1.0 + (prestigeLevel * 0.1);

    int xpEarned =
        (((score ~/ 5) + (foodEaten * 2) + (combo * 5)) * prestigeMultiplier)
            .round()
            .clamp(10, 5000);
    int coinsEarned = (((foodEaten * 3) + (goldenApples * 12) + (combo * 4)) *
            prestigeMultiplier)
        .round()
        .clamp(0, 600);

    final season = seasonalContent;
    xpEarned = (xpEarned * season.scoreMultiplier).round();
    coinsEarned = (coinsEarned * season.coinMultiplier).round();

    // 4. Process achievements
    final newAchievements = await _storage.checkAchievements(
      score: score,
      snakeLength: snakeLength,
      combo: combo,
      shadowDefeatsExtra:
          bonusCoins >= 50 ? 1 : 0, // 50 coins is the shadow reward
    );

    final oldRankLevel = _storage.rankLevel;
    await _storage.addXp(xpEarned);

    // 5. Update daily streak & Quests
    final isNewDay = await _storage.checkAndUpdateStreak();
    final streakAfterUpdate = _storage.dailyStreak;
    final streakMultiplier = _streakCoinMultiplier(streakAfterUpdate);
    final streakMilestoneBonus =
        _streakMilestoneBonus(streakAfterUpdate, isNewDay);

    // Schedule streak-at-risk reminder ~20 h from now so player keeps the streak alive.
    if (streakAfterUpdate > 0) {
      NotificationService().scheduleStreakReminder(streakAfterUpdate);
    }

    int questCoins = 0;
    int completedThisSession = 0;
    for (var q in _quests) {
      if (!q.isCompleted) {
        switch (q.type) {
          case QuestType.playGames:
            q.currentAmount++;
            break;
          case QuestType.eatGoldenApples:
            q.currentAmount += goldenApples;
            break;
          case QuestType.eatPoisonApples:
            q.currentAmount += poisonApples;
            break;
          case QuestType.scoreTotal:
            q.currentAmount += score;
            break;
          case QuestType.timePlayed:
            q.currentAmount += 1;
            break;
          case QuestType.collectPowerUps:
            q.currentAmount += powerUps;
            break;
          case QuestType.reachLength:
            if (snakeLength > q.currentAmount) q.currentAmount = snakeLength;
            break;
          // Safari types — not updated here; done via completeSafariSession
          case QuestType.catchPrey:
          case QuestType.discoverBiomes:
          case QuestType.huntStreak:
            break;
        }
        if (q.isCompleted) {
          questCoins += q.coinReward;
          completedThisSession++;
          AnalyticsService().logQuestCompleted(q.id, q.isWeekly);
        } else if (q.isWeekly &&
            q.currentAmount / q.goalAmount >= 0.8 &&
            !_notifiedQuests.contains(q.id)) {
          // Notify 80% completion
          _notifiedQuests.add(q.id);
          NotificationService().notifyQuestAlmostComplete(q.title);
        }
      }
    }

    if (completedThisSession > 0) {
      await _storage.checkAchievements(
        score: score,
        snakeLength: snakeLength,
        combo: combo,
        questsCompletedExtra: completedThisSession,
      );
    }

    if (questCoins > 0) {
      await _storage.addCoins(questCoins);
    }

    // Welcome bonus: 60% extra coins for first 3 games to hook new players
    final gamesPlayedCount = _storage.gamesPlayed;
    final welcomeMultiplier = gamesPlayedCount <= 3 ? 1.6 : 1.0;

    final sessionCoins = (((coinsEarned + bonusCoins) * coinMultiplier) *
            streakMultiplier *
            welcomeMultiplier)
        .round();
    final totalSessionCoins = sessionCoins + streakMilestoneBonus;
    await _storage.addCoins(totalSessionCoins);
    if (streakMultiplier > 1.0 || streakMilestoneBonus > 0) {
      AnalyticsService().logStreakReward(
        streak: streakAfterUpdate,
        coins: totalSessionCoins,
        multiplier: streakMultiplier,
      );
    }
    await _storage.saveQuests(_quests);

    // 6. Cloud Sync
    if (_auth.isSignedIn) {
      await _syncToCloud();
    }

    // 7. Reload and Notify
    _loadFromStorage();

    return {
      'xpEarned': xpEarned,
      'newAchievementIds': newAchievements,
      'coinsEarned': totalSessionCoins,
      'streakMultiplier': streakMultiplier,
      'streakBonusCoins': streakMilestoneBonus,
      'questCoins': questCoins,
      'rankLeveledUp': _storage.rankLevel > oldRankLevel,
      'newRankLevel': _storage.rankLevel,
    };
  }

  /// Manually add XP (e.g. from special events)
  Future<void> addXp(int amount) async {
    await _storage.addXp(amount);
    if (_auth.isSignedIn) await _syncToCloud();
    _loadFromStorage();
  }

  Future<bool> claimSocialChallengeReward() async {
    final challenge = _storage.getTodaySocialChallenge();
    if (challenge.claimed || bestScore < challenge.targetScore) {
      return false;
    }

    await _storage.addCoins(challenge.rewardCoins);
    await _storage.addXp(challenge.rewardXp);
    await _storage.markSocialChallengeClaimed();
    await AnalyticsService().logExperimentConversion(
      experimentKey: 'social_challenge_v1',
      variant: 1,
      event: 'claimed',
    );

    _loadFromStorage();
    return true;
  }

  Future<bool> buySkin(SnakeSkin skin) async {
    if (_unlockedSkins.contains(skin)) return false;
    if (_coins >= skin.price) {
      await _storage.deductCoins(skin.price);
      await _storage.unlockSkin(skin);
      await _storage.equipSkin(skin);
      _loadFromStorage();
      return true;
    }
    return false;
  }

  Future<void> equipSkin(SnakeSkin skin) async {
    if (_unlockedSkins.contains(skin)) {
      await _storage.equipSkin(skin);
      _loadFromStorage();
    }
  }

  // ── Expedition Gear ──────────────────────────────────────────────────────────
  int gearCount(String typeName) => _storage.gearCount(typeName);

  Future<bool> buyGear(String typeName, int gemCost) async {
    if (_safariGems < gemCost) return false;
    await _storage.deductSafariGems(gemCost);
    await _storage.addGear(typeName, 1);
    _loadFromStorage();
    return true;
  }

  Future<void> setEquippedGear(List<String> gear) async {
    await _storage.setEquippedGear(gear);
    _loadFromStorage();
  }

  // ── Safari session completion ─────────────────────────────────────────────────
  /// Call at end of an explore run to update safari stats, gems, quests, achievements.
  Future<List<String>> completeSafariSession({
    required int preyCaught,
    required int crocsCaught,
    required int roomsVisited,
    required int bestStreak,
    required int biomesDiscovered,
    required List<String> preyTypes,
  }) async {
    // Update lifetime stats
    await _storage.addSafariTotalPrey(preyCaught);
    await _storage.addSafariRoomsVisited(roomsVisited);
    await _storage.updateSafariBestStreak(bestStreak);
    await _storage.addSafariCrocKills(crocsCaught);

    // Earn gems
    int gemsEarned = 0;
    gemsEarned += crocsCaught * 3;
    gemsEarned += biomesDiscovered * 2;
    if (bestStreak >= 7) gemsEarned += 1;
    if (gemsEarned > 0) await _storage.addSafariGems(gemsEarned);

    // Check safari skin milestones
    final counts = _storage.safariCounts;
    for (final skin in [
      SnakeSkin.jadeSerpent,
      SnakeSkin.monarchWyrm,
      SnakeSkin.crocBane,
    ]) {
      if (!_unlockedSkins.contains(skin)) {
        final caught = counts[skin.safariUnlockPreyType] ?? 0;
        if (caught >= skin.safariUnlockTarget) {
          await _storage.unlockSkin(skin);
        }
      }
    }

    // Update safari quests
    int questCoins = 0;
    for (var q in _quests) {
      if (!q.isCompleted) {
        switch (q.type) {
          case QuestType.catchPrey:
            q.currentAmount += preyCaught;
            break;
          case QuestType.discoverBiomes:
            q.currentAmount += biomesDiscovered;
            break;
          case QuestType.huntStreak:
            if (bestStreak > q.currentAmount) q.currentAmount = bestStreak;
            break;
          default:
            break;
        }
        if (q.isCompleted) {
          questCoins += q.coinReward;
          AnalyticsService().logQuestCompleted(q.id, q.isWeekly);
        }
      }
    }
    if (questCoins > 0) await _storage.addCoins(questCoins);
    await _storage.saveQuests(_quests);

    // Check safari achievements
    final totalPrey = _storage.safariTotalPrey;
    final totalRooms = _storage.safariRoomsVisited;
    final totalCrocs = _storage.safariCrocKills;
    final uniqueTypes = preyTypes.toSet().length;
    final allTypes = preyTypes.toSet().length >= 5;

    final newAchs = await _storage.checkSafariAchievements(
      totalPrey: totalPrey,
      uniqueTypes: uniqueTypes,
      allTypes: allTypes,
      bestStreak: _storage.safariBestStreak,
      totalRooms: totalRooms,
      totalCrocs: totalCrocs,
    );

    _loadFromStorage();
    return newAchs;
  }

  Future<SnakeSkin?> rollGacha() async {
    const int spinCost = AppConstants.gachaSpinCost;
    if (_coins < spinCost) return null;

    await _storage.deductCoins(spinCost);

    // Determine random skin based on rarity weights
    List<SnakeSkin> pool = [];
    for (var skin in SnakeSkin.values) {
      int weight = 0;
      switch (skin.rarity) {
        case SkinRarity.common:
          weight = 50;
          break;
        case SkinRarity.rare:
          weight = 30;
          break;
        case SkinRarity.epic:
          weight = 15;
          break;
        case SkinRarity.legendary:
          weight = 5;
          break;
        case SkinRarity.safari:
          weight = 0; // safari skins not in gacha pool
          break;
      }
      for (int i = 0; i < weight; i++) {
        pool.add(skin);
      }
    }
    pool.shuffle();
    SnakeSkin wonSkin = pool.first;

    if (!_unlockedSkins.contains(wonSkin)) {
      await _storage.unlockSkin(wonSkin);
    } else {
      // Compensation for duplicate
      await _storage.addCoins(_duplicateCompensationForSkin(wonSkin));
    }

    _loadFromStorage();
    return wonSkin;
  }

  int _duplicateCompensationForSkin(SnakeSkin skin) {
    switch (skin.rarity) {
      case SkinRarity.common:
        return AppConstants.gachaDuplicateCompensationCommon;
      case SkinRarity.rare:
        return AppConstants.gachaDuplicateCompensationRare;
      case SkinRarity.epic:
        return AppConstants.gachaDuplicateCompensationEpic;
      case SkinRarity.legendary:
        return AppConstants.gachaDuplicateCompensationLegendary;
      case SkinRarity.safari:
        return 0;
    }
  }

  void _checkDailyQuests() {
    final now = DateTime.now();
    final today = _storage.todayString();
    final savedDailyDate = _storage.questsDate;
    final savedWeeklyDate = _storage.weeklyQuestsDate;

    List<DailyQuest> currentQuests = _storage.quests;
    bool needsDailyReset = savedDailyDate != today;

    // Check if weekly needs reset (e.g. 7 days passed)
    bool needsWeeklyReset = false;
    if (savedWeeklyDate.isEmpty) {
      needsWeeklyReset = true;
    } else {
      final lastWeekly = DateTime.parse(savedWeeklyDate);
      if (now.difference(lastWeekly).inDays >= 7) {
        needsWeeklyReset = true;
      }
    }

    if (needsDailyReset || needsWeeklyReset || currentQuests.isEmpty) {
      List<DailyQuest> newQuests = [];

      // If daily reset, generate new dailies.
      // If not, keep the existing dailies that aren't weekly.
      if (needsDailyReset || currentQuests.isEmpty) {
        newQuests.addAll(_getNewDailyQuests());
        _storage.saveQuestsDate(today);
      } else {
        newQuests.addAll(currentQuests.where((q) => !q.isWeekly));
      }

      // If weekly reset, generate new weekly.
      // If not, keep existing weekly quests.
      if (needsWeeklyReset || currentQuests.isEmpty) {
        newQuests.add(_getNewWeeklyQuest());
        _storage.saveWeeklyQuestsDate(now.toIso8601String());
      } else {
        newQuests.addAll(currentQuests.where((q) => q.isWeekly));
      }

      _quests = newQuests;
      _storage.saveQuests(_quests);
    } else {
      _quests = currentQuests;
    }
  }

  double _questDifficultyFactor() {
    final scoreFactor = (_storage.bestScore / 900).clamp(0.0, 1.2);
    final rankFactor = (_storage.rankLevel / 9).clamp(0.0, 1.0);
    return 0.85 + (scoreFactor * 0.45) + (rankFactor * 0.35);
  }

  int _scaledGoal(int base, double factor) {
    final scaled = (base * factor).round();
    return scaled < 1 ? 1 : scaled;
  }

  int _scaledReward(int base, double factor) {
    final rewardFactor = (0.85 + (factor - 0.85) * 0.7).clamp(0.85, 1.8);
    return (base * rewardFactor).round();
  }

  String _questId(String prefix, int index) {
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}_$index';
  }

  List<DailyQuest> _getNewDailyQuests() {
    final factor = _questDifficultyFactor();
    final rng = Random(DateTime.now().millisecondsSinceEpoch ~/ 1000);

    final fixedWarmup = DailyQuest(
      id: _questId('q_warmup', 0),
      type: QuestType.playGames,
      title: 'Warm Up',
      description: 'Play 1 game',
      goalAmount: 1,
      coinReward: 50,
    );

    final pool = <DailyQuest>[
      DailyQuest(
        id: _questId('q_play', 1),
        type: QuestType.playGames,
        title: 'Steady Player',
        description: 'Play ${_scaledGoal(4, factor)} games',
        goalAmount: _scaledGoal(4, factor),
        coinReward: _scaledReward(90, factor),
      ),
      DailyQuest(
        id: _questId('q_gold', 2),
        type: QuestType.eatGoldenApples,
        title: 'Gold Rush',
        description: 'Eat ${_scaledGoal(3, factor)} Golden Apples',
        goalAmount: _scaledGoal(3, factor),
        coinReward: _scaledReward(180, factor),
      ),
      DailyQuest(
        id: _questId('q_score', 3),
        type: QuestType.scoreTotal,
        title: 'High Scorer',
        description: 'Score ${_scaledGoal(450, factor)} points across games',
        goalAmount: _scaledGoal(450, factor),
        coinReward: _scaledReward(140, factor),
      ),
      DailyQuest(
        id: _questId('q_power', 4),
        type: QuestType.collectPowerUps,
        title: 'Power Hunt',
        description: 'Collect ${_scaledGoal(6, factor)} power-ups',
        goalAmount: _scaledGoal(6, factor),
        coinReward: _scaledReward(130, factor),
      ),
      DailyQuest(
        id: _questId('q_length', 5),
        type: QuestType.reachLength,
        title: 'Long Run',
        description: 'Reach snake length ${_scaledGoal(15, factor)}',
        goalAmount: _scaledGoal(15, factor),
        coinReward: _scaledReward(160, factor),
      ),
      DailyQuest(
        id: _questId('q_poison', 6),
        type: QuestType.eatPoisonApples,
        title: 'Risk Taker',
        description: 'Eat ${_scaledGoal(2, factor)} poison apples',
        goalAmount: _scaledGoal(2, factor),
        coinReward: _scaledReward(120, factor),
      ),
    ];

    pool.shuffle(rng);
    return [
      fixedWarmup,
      ...pool.take(3),
    ];
  }

  DailyQuest _getNewWeeklyQuest() {
    final factor = _questDifficultyFactor() + 0.2;
    final options = <DailyQuest>[
      DailyQuest(
        id: _questId('q_week_power', 0),
        type: QuestType.collectPowerUps,
        title: 'Power Week',
        description: 'Collect ${_scaledGoal(40, factor)} power-ups this week',
        goalAmount: _scaledGoal(40, factor),
        coinReward: _scaledReward(900, factor),
        isWeekly: true,
      ),
      DailyQuest(
        id: _questId('q_week_score', 1),
        type: QuestType.scoreTotal,
        title: 'Weekly Grinder',
        description: 'Score ${_scaledGoal(5000, factor)} points this week',
        goalAmount: _scaledGoal(5000, factor),
        coinReward: _scaledReward(1100, factor),
        isWeekly: true,
      ),
      DailyQuest(
        id: _questId('q_week_games', 2),
        type: QuestType.playGames,
        title: 'Consistency Challenge',
        description: 'Play ${_scaledGoal(20, factor)} games this week',
        goalAmount: _scaledGoal(20, factor),
        coinReward: _scaledReward(1000, factor),
        isWeekly: true,
      ),
    ];

    final rng = Random(DateTime.now().millisecondsSinceEpoch ~/ 1000);
    return options[rng.nextInt(options.length)];
  }

  Future<void> unlockCampaignLevel(int levelIndex) async {
    if (levelIndex > _highestCampaignLevel) {
      await _storage.setHighestCampaignLevel(levelIndex);
      _loadFromStorage();
    }
  }
}
