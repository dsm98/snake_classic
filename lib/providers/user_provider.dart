import 'package:flutter/foundation.dart';
import '../core/models/position.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../core/models/achievement.dart';
import '../core/enums/snake_skin.dart';
import '../core/models/quest_model.dart';
import '../core/models/daily_event.dart';
import '../services/analytics_service.dart';
import '../services/notification_service.dart';
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
  SnakeSkin _equippedSkin = SnakeSkin.classic;
  List<SnakeSkin> _unlockedSkins = [SnakeSkin.classic];
  List<DailyQuest> _quests = [];
  int _highestCampaignLevel = 1;
  DailyEvent? _currentDailyEvent;

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
  SnakeSkin get equippedSkin => _equippedSkin;
  List<SnakeSkin> get unlockedSkins => _unlockedSkins;
  List<DailyQuest> get quests => _quests;
  int get highestCampaignLevel => _highestCampaignLevel;
  DailyEvent? get currentDailyEvent => _currentDailyEvent;
  int get prestigeLevel => _storage.prestigeLevel;
  
  bool get isMaxRank => _rankLevel >= 9;
  int get xpToNextRank => _storage.xpToNextRank;

  void _loadFromStorage() {
    _totalXp = _storage.totalXp;
    _rankLevel = _storage.rankLevel;
    _rankProgress = _storage.rankProgress;
    _rankTitle = _storage.rankTitle;
    _rankEmoji = _storage.rankEmoji;
    _dailyStreak = _storage.dailyStreak;
    _coins = _storage.coins;
    _equippedSkin = _storage.equippedSkin;
    _unlockedSkins = _storage.unlockedSkins;
    _highestCampaignLevel = _storage.highestCampaignLevel;
    _checkDailyQuests();
    notifyListeners();
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
      final cloudAchs = data['unlockedAchievements'] as Map<String, dynamic>? ?? {};
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
      final unlocked = _storage.getAllAchievementProgress()
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
    
    int xpEarned = (((score ~/ 5) + (foodEaten * 2) + (combo * 5)) * prestigeMultiplier).round().clamp(10, 5000);
    int coinsEarned = (((foodEaten * 2) + (goldenApples * 10) + (combo * 3)) * prestigeMultiplier).round().clamp(0, 500);

    // 4. Process achievements
    int shadowDefeatsThisSession = 0; // We might need to track this in GameEngine if not already
    // For now, I'll check if coinsEarnedSession includes the shadow bonus
    
    final newAchievements = await _storage.checkAchievements(
      score: score,
      snakeLength: snakeLength,
      combo: combo,
      shadowDefeatsExtra: bonusCoins >= 50 ? 1 : 0, // 50 coins is the shadow reward
    );

    await _storage.addXp(xpEarned);
    await _storage.addCoins(((coinsEarned + bonusCoins) * coinMultiplier).round());

    // 5. Update daily streak & Quests
    await _storage.checkAndUpdateStreak();
    
    int questCoins = 0;
    int completedThisSession = 0;
    for (var q in _quests) {
      if (!q.isCompleted) {
        switch (q.type) {
          case QuestType.playGames: q.currentAmount++; break;
          case QuestType.eatGoldenApples: q.currentAmount += goldenApples; break;
          case QuestType.eatPoisonApples: q.currentAmount += poisonApples; break;
          case QuestType.scoreTotal: q.currentAmount += score; break;
          case QuestType.timePlayed: q.currentAmount += 1; break;
          case QuestType.collectPowerUps: q.currentAmount += powerUps; break;
          case QuestType.reachLength: if (snakeLength > q.currentAmount) q.currentAmount = snakeLength; break;
        }
        if (q.isCompleted) {
           questCoins += q.coinReward;
           completedThisSession++;
           AnalyticsService().logQuestCompleted(q.id, q.isWeekly);
        } else if (q.isWeekly && q.currentAmount / q.goalAmount >= 0.8 && !_notifiedQuests.contains(q.id)) {
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
    };
  }

  /// Manually add XP (e.g. from special events)
  Future<void> addXp(int amount) async {
    await _storage.addXp(amount);
    if (_auth.isSignedIn) await _syncToCloud();
    _loadFromStorage();
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

  Future<SnakeSkin?> rollGacha() async {
    const int spinCost = 1000;
    if (_coins < spinCost) return null;
    
    await _storage.deductCoins(spinCost);
    
    // Determine random skin based on rarity weights
    List<SnakeSkin> pool = [];
    for (var skin in SnakeSkin.values) {
       int weight = 0;
       switch (skin.rarity) {
          case SkinRarity.common: weight = 50; break;
          case SkinRarity.rare: weight = 30; break;
          case SkinRarity.epic: weight = 15; break;
          case SkinRarity.legendary: weight = 5; break;
       }
       for (int i=0; i<weight; i++) {
          pool.add(skin);
       }
    }
    pool.shuffle();
    SnakeSkin wonSkin = pool.first;
    
    if (!_unlockedSkins.contains(wonSkin)) {
       await _storage.unlockSkin(wonSkin);
    } else {
       // Compensation for duplicate
       await _storage.addCoins(200); 
    }
    
    _loadFromStorage();
    return wonSkin;
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

  List<DailyQuest> _getNewDailyQuests() {
    return [
        DailyQuest(
          id: 'q_easy_${DateTime.now().millisecondsSinceEpoch}',
          type: QuestType.playGames,
          title: 'Warm Up',
          description: 'Play 1 game',
          goalAmount: 1,
          coinReward: 50,
        ),
        DailyQuest(
          id: 'q1_${DateTime.now().millisecondsSinceEpoch}',
          type: QuestType.playGames,
          title: 'Steady Player',
          description: 'Play 5 games',
          goalAmount: 5,
          coinReward: 100,
        ),
        DailyQuest(
          id: 'q2_${DateTime.now().millisecondsSinceEpoch}',
          type: QuestType.eatGoldenApples,
          title: 'Gold Rush',
          description: 'Eat 3 Golden Apples',
          goalAmount: 3,
          coinReward: 200,
        ),
        DailyQuest(
          id: 'q3_${DateTime.now().millisecondsSinceEpoch}',
          type: QuestType.scoreTotal,
          title: 'High Scorer',
          description: 'Score 500 points across games',
          goalAmount: 500,
          coinReward: 150,
        ),
    ];
  }

  DailyQuest _getNewWeeklyQuest() {
    return DailyQuest(
      id: 'q_weekly_${DateTime.now().millisecondsSinceEpoch}',
      type: QuestType.collectPowerUps,
      title: 'Power Week',
      description: 'Collect 50 power-ups this week',
      goalAmount: 50,
      coinReward: 1000,
      isWeekly: true,
    );
  }

  Future<void> unlockCampaignLevel(int levelIndex) async {
    if (levelIndex > _highestCampaignLevel) {
      await _storage.setHighestCampaignLevel(levelIndex);
      _loadFromStorage();
    }
  }
}
