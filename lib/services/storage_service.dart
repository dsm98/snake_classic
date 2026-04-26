import 'dart:convert';
import 'dart:math';
import '../core/models/position.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/enums/theme_type.dart';
import '../core/models/achievement.dart';
import '../core/models/quest_model.dart';
import '../core/models/social_challenge.dart';
import '../core/enums/snake_skin.dart';
import 'analytics_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._();
  factory StorageService() => _instance;
  StorageService._();

  // ── Keys ────────────────────────────────────────────────────────
  static const _keyTheme = 'theme';
  static const _keyDifficulty = 'difficulty';
  static const _keySoundEnabled = 'sound_enabled';
  static const _keyVibrationEnabled = 'vibration_enabled';
  static const _keyShowJoystick = 'show_joystick';
  static const _keyShowRunModifierPrompt = 'show_run_modifier_prompt';
  static const _keyTutorialCompleted = 'tutorial_completed';
  static const _keyFontScale = 'font_scale';
  static const _keyReducedMotion = 'reduced_motion';
  static const _keyHapticIntensity = 'haptic_intensity';
  static const _keyGamesPlayed = 'games_played';

  // XP / Rank
  static const _keyTotalXp = 'total_xp';

  // Stats
  static const _keyTotalFoodEaten = 'stat_food_total';
  static const _keyTotalPowerUps = 'stat_pu_total';
  static const _keyBestCombo = 'stat_best_combo';
  static const _keyTotalGoldenApples = 'stat_gold_total';
  static const _keyTotalPoisonApples = 'stat_poison_total';
  static const _keyShadowDefeats = 'stat_shadow_defeats';
  static const _keyQuestsCompleted = 'stat_quests_total';

  // Economy & Shop
  static const _keyCoins = 'coins_balance';
  static const _keyUnlockedSkins = 'unlocked_skins';
  static const _keyEquippedSkin = 'equipped_skin';

  // Achievements
  static const _keyAchievementsPrefix = 'ach_';

  // Daily streak & Quests
  static const _keyLastPlayedDate = 'last_played_date';
  static const _keyDailyStreak = 'daily_streak';
  static const _keyStreakRewardShownDate = 'streak_reward_shown_date';
  static const _keyQuestsDate = 'quests_date';
  static const _keyWeeklyQuestsDate = 'weekly_quests_date';
  static const _keyQuests = 'quests_data';
  static const _keySocialChallengeDate = 'social_challenge_date';
  static const _keySocialChallengeData = 'social_challenge_data';

  // ── A/B Experiment variants ────────────────────────────────────
  // Each flag is assigned once per install. 0 = control, 1 = variant.
  // Add new experiments here; remove after shipping the winner.
  static const _keyExpTutorialVariant =
      'exp_tutorial_v'; // 0=current, 1=shorter
  static const _keyExpStreakRewardSize =
      'exp_streak_reward_v'; // 0=current, 1=+20% coins
  static const _keyExpHudSimplified =
      'exp_hud_simplified_v'; // 0=current, 1=minimal HUD

  static const _keyCampaignLevel = 'highest_campaign_level';
  static const _keyCampaignStars = 'campaign_stars';
  static const _keyBestScore = 'best_score_all_time';
  static const _keyBestLength = 'best_length_all_time';
  static const _keyPrestigeLevel = 'prestige_level';
  static const _keyBestReplay = 'best_replay_data';

  // Safari Journal
  static const _keySafariCounts = 'safari_counts';
  static const _keySafariBiomes = 'safari_biomes_visited';
  static const _keySafariMissionDate = 'safari_mission_date';
  static const _keySafariMissionProgress = 'safari_mission_progress';

  // Safari Gems (second currency)
  static const _keySafariGems = 'safari_gems';

  // Expedition Gear owned counts (per GearType name)
  static const _keyGearCounts = 'gear_counts';

  // Equipped gear slots (up to 2, stored as list of GearType names)
  static const _keyEquippedGear = 'equipped_gear';

  // Relics
  static const _keyOwnedRelics = 'owned_relics';
  static const _keyEquippedRelic = 'equipped_relic';

  // Safari lifetime stats
  static const _keySafariTotalPrey = 'safari_total_prey';
  static const _keySafariRoomsVisited = 'safari_rooms_visited';
  static const _keySafariCrocKills = 'safari_croc_kills';
  static const _keySafariBestStreak = 'safari_best_streak';

  // Altar Skills
  static const _keySkillThickScales = 'skill_thick_scales';
  static const _keySkillGreed = 'skill_greed';
  static const _keySkillDashMastery = 'skill_dash_mastery';

  // Explore session resume
  static const _keyExploreSnakeX = 'explore_resume_x';
  static const _keyExploreSnakeY = 'explore_resume_y';
  static const _keyExploreFloor = 'explore_resume_floor';
  static const _keyExploreScore = 'explore_resume_score';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Settings ───────────────────────────────────────────────────
  ThemeType get theme =>
      ThemeType.values[_prefs.getInt(_keyTheme) ?? ThemeType.neon.index];
  Future<void> saveTheme(ThemeType t) => _prefs.setInt(_keyTheme, t.index);

  Difficulty get difficulty => Difficulty
      .values[_prefs.getInt(_keyDifficulty) ?? Difficulty.normal.index];
  Future<void> saveDifficulty(Difficulty d) =>
      _prefs.setInt(_keyDifficulty, d.index);

  bool get soundEnabled => _prefs.getBool(_keySoundEnabled) ?? true;
  Future<void> saveSoundEnabled(bool v) => _prefs.setBool(_keySoundEnabled, v);

  bool get vibrationEnabled => _prefs.getBool(_keyVibrationEnabled) ?? true;
  Future<void> saveVibrationEnabled(bool v) =>
      _prefs.setBool(_keyVibrationEnabled, v);

  bool get showJoystick => _prefs.getBool(_keyShowJoystick) ?? false;
  Future<void> saveShowJoystick(bool v) => _prefs.setBool(_keyShowJoystick, v);

  bool get showRunModifierPrompt =>
      _prefs.getBool(_keyShowRunModifierPrompt) ?? true;
  Future<void> saveShowRunModifierPrompt(bool v) =>
      _prefs.setBool(_keyShowRunModifierPrompt, v);

  bool get tutorialCompleted => _prefs.getBool(_keyTutorialCompleted) ?? false;
  Future<void> setTutorialCompleted(bool value) =>
      _prefs.setBool(_keyTutorialCompleted, value);

  double get fontScale => _prefs.getDouble(_keyFontScale) ?? 1.0;
  Future<void> saveFontScale(double value) =>
      _prefs.setDouble(_keyFontScale, value);

  bool get reducedMotion => _prefs.getBool(_keyReducedMotion) ?? false;
  Future<void> saveReducedMotion(bool value) =>
      _prefs.setBool(_keyReducedMotion, value);

  int get hapticIntensityIndex => _prefs.getInt(_keyHapticIntensity) ?? 1;
  Future<void> saveHapticIntensityIndex(int index) =>
      _prefs.setInt(_keyHapticIntensity, index);

  // ── Ads / games played ─────────────────────────────────────────
  int get gamesPlayed => _prefs.getInt(_keyGamesPlayed) ?? 0;
  Future<void> incrementGamesPlayed() =>
      _prefs.setInt(_keyGamesPlayed, gamesPlayed + 1);

  // ── Progressive unlock gates ───────────────────────────────────
  /// Returns true when [feature] has been unlocked.
  /// Feature keys: 'altar', 'quests', 'explore', 'multiplayer'
  bool isUnlocked(String feature) {
    final games = gamesPlayed;
    final campaign = highestCampaignLevel;
    return switch (feature) {
      'altar' => games >= 1,
      'quests' => games >= 2,
      'explore' => campaign >= 3,
      'multiplayer' => games >= 5,
      _ => true,
    };
  }

  // ── A/B Experiments ───────────────────────────────────────────
  /// Returns the variant index for an experiment, assigning it on first call.
  int _getOrAssignVariant(String key, int numVariants) {
    final stored = _prefs.getInt(key);
    if (stored != null) return stored;
    // Random assignment weighted 50/50 for 2-variant tests
    final assigned = DateTime.now().millisecondsSinceEpoch % numVariants;
    _prefs.setInt(key, assigned);
    return assigned;
  }

  int get expTutorialVariant => _getOrAssignVariant(_keyExpTutorialVariant, 2);
  int get expStreakRewardVariant =>
      _getOrAssignVariant(_keyExpStreakRewardSize, 2);
  int get expHudSimplifiedVariant =>
      _getOrAssignVariant(_keyExpHudSimplified, 2);

  /// Expose key names for analytics tagging
  String get expTutorialKey => _keyExpTutorialVariant;
  String get expStreakRewardKey => _keyExpStreakRewardSize;
  String get expHudKey => _keyExpHudSimplified;

  // ── Shop & Economy ──────────────────────────────────────────────
  int get coins => _prefs.getInt(_keyCoins) ?? 0;
  Future<void> addCoins(int amount) => _prefs.setInt(_keyCoins, coins + amount);
  Future<void> deductCoins(int amount) {
    int newval = coins - amount;
    return _prefs.setInt(_keyCoins, newval < 0 ? 0 : newval);
  }

  List<SnakeSkin> get unlockedSkins {
    final list = _prefs.getStringList(_keyUnlockedSkins) ?? [];
    if (list.isEmpty) return [SnakeSkin.classic];
    return list
        .map((e) => SnakeSkin.values
            .firstWhere((s) => s.name == e, orElse: () => SnakeSkin.classic))
        .toSet()
        .toList();
  }

  Future<void> unlockSkin(SnakeSkin skin) async {
    final list = unlockedSkins;
    if (!list.contains(skin)) {
      list.add(skin);
      await _prefs.setStringList(
          _keyUnlockedSkins, list.map((e) => e.name).toList());
    }
  }

  SnakeSkin get equippedSkin {
    final name = _prefs.getString(_keyEquippedSkin) ?? SnakeSkin.classic.name;
    return SnakeSkin.values
        .firstWhere((e) => e.name == name, orElse: () => SnakeSkin.classic);
  }

  Future<void> equipSkin(SnakeSkin skin) async {
    if (unlockedSkins.contains(skin)) {
      await _prefs.setString(_keyEquippedSkin, skin.name);
    }
  }

  // ── XP & Rank ──────────────────────────────────────────────────
  int get totalXp => _prefs.getInt(_keyTotalXp) ?? 0;

  Future<void> addXp(int xp) async {
    await _prefs.setInt(_keyTotalXp, totalXp + xp);
  }

  Future<void> setTotalXp(int xp) async {
    await _prefs.setInt(_keyTotalXp, xp);
  }

  Future<void> setDailyStreak(int streak) async {
    await _prefs.setInt(_keyDailyStreak, streak);
  }

  /// Rank title and level (0–9) based on XP thresholds
  static const List<int> _rankThresholds = [
    0,
    500,
    1500,
    3000,
    5500,
    9000,
    14000,
    21000,
    30000,
    45000,
  ];
  static const List<String> rankTitles = [
    'Hatchling',
    'Crawler',
    'Slitherer',
    'Viper',
    'Cobra',
    'Asp',
    'Python',
    'Anaconda',
    'King Cobra',
    'Serpent God',
  ];
  static const List<String> rankEmojis = [
    '🥚',
    '🐛',
    '🐍',
    '🦎',
    '🐍',
    '⚡',
    '🐉',
    '🔱',
    '👑',
    '🌟',
  ];

  int get rankLevel {
    final xp = totalXp;
    int level = 0;
    for (int i = _rankThresholds.length - 1; i >= 0; i--) {
      if (xp >= _rankThresholds[i]) {
        level = i;
        break;
      }
    }
    return level;
  }

  int get prestigeLevel => _prefs.getInt(_keyPrestigeLevel) ?? 0;
  Future<void> setPrestigeLevel(int lvl) =>
      _prefs.setInt(_keyPrestigeLevel, lvl);

  String get rankTitle {
    final base = rankTitles[rankLevel];
    if (prestigeLevel == 0) return base;
    return 'Legend $prestigeLevel $base';
  }

  String get rankEmoji {
    if (prestigeLevel == 0) return rankEmojis[rankLevel];
    return '⭐ $prestigeLevel';
  }

  /// Progress within current rank (0.0 – 1.0)
  double get rankProgress {
    final xp = totalXp;
    final level = rankLevel;
    if (level >= _rankThresholds.length - 1) return 1.0;
    final current = _rankThresholds[level];
    final next = _rankThresholds[level + 1];
    return ((xp - current) / (next - current)).clamp(0.0, 1.0);
  }

  int get xpToNextRank {
    final level = rankLevel;
    if (level >= _rankThresholds.length - 1) return 0;
    return _rankThresholds[level + 1] - totalXp;
  }

  // ── Lifetime stats ─────────────────────────────────────────────
  int get totalFoodEaten => _prefs.getInt(_keyTotalFoodEaten) ?? 0;
  Future<void> addFoodEaten(int n) =>
      _prefs.setInt(_keyTotalFoodEaten, totalFoodEaten + n);

  int get totalPowerUpsCollected => _prefs.getInt(_keyTotalPowerUps) ?? 0;
  Future<void> addPowerUpsCollected(int n) =>
      _prefs.setInt(_keyTotalPowerUps, totalPowerUpsCollected + n);

  int get totalGoldenApplesEaten => _prefs.getInt(_keyTotalGoldenApples) ?? 0;
  Future<void> addGoldenApplesEaten(int n) =>
      _prefs.setInt(_keyTotalGoldenApples, totalGoldenApplesEaten + n);

  int get totalPoisonApplesEaten => _prefs.getInt(_keyTotalPoisonApples) ?? 0;
  Future<void> addPoisonApplesEaten(int n) =>
      _prefs.setInt(_keyTotalPoisonApples, totalPoisonApplesEaten + n);

  int get shadowDefeats => _prefs.getInt(_keyShadowDefeats) ?? 0;
  Future<void> addShadowDefeats(int n) =>
      _prefs.setInt(_keyShadowDefeats, shadowDefeats + n);

  int get questsCompletedCount => _prefs.getInt(_keyQuestsCompleted) ?? 0;
  Future<void> addQuestsCompletedCount(int n) =>
      _prefs.setInt(_keyQuestsCompleted, questsCompletedCount + n);

  int get bestComboEver => _prefs.getInt(_keyBestCombo) ?? 0;
  Future<void> updateBestCombo(int combo) async {
    if (combo > bestComboEver) await _prefs.setInt(_keyBestCombo, combo);
  }

  int get bestScore => _prefs.getInt(_keyBestScore) ?? 0;
  Future<void> updateBestScore(int score) async {
    if (score > bestScore) await _prefs.setInt(_keyBestScore, score);
  }

  int get bestLength => _prefs.getInt(_keyBestLength) ?? 0;
  Future<void> updateBestLength(int length) async {
    if (length > bestLength) await _prefs.setInt(_keyBestLength, length);
  }

  List<Position> getBestReplay() {
    final raw = _prefs.getString(_keyBestReplay);
    if (raw == null) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => Position.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveBestReplay(List<Position> path) async {
    await _prefs.setString(
        _keyBestReplay, jsonEncode(path.map((e) => e.toJson()).toList()));
  }

  // ── Daily streak ───────────────────────────────────────────────
  int get dailyStreak => _prefs.getInt(_keyDailyStreak) ?? 0;

  String get streakRewardShownDate =>
      _prefs.getString(_keyStreakRewardShownDate) ?? '';

  Future<void> markStreakRewardShown() async {
    await _prefs.setString(_keyStreakRewardShownDate, todayString());
  }

  /// Call once per game session — updates streak and returns whether it was a new day
  Future<bool> checkAndUpdateStreak() async {
    final today = todayString();
    final last = _prefs.getString(_keyLastPlayedDate) ?? '';
    if (last == today) return false; // already played today

    final yesterday = yesterdayString();
    final newStreak = (last == yesterday) ? dailyStreak + 1 : 1;
    await _prefs.setInt(_keyDailyStreak, newStreak);
    await _prefs.setString(_keyLastPlayedDate, today);
    return true; // new day
  }

  String todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String yesterdayString() {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return '${y.year}-${y.month.toString().padLeft(2, '0')}-${y.day.toString().padLeft(2, '0')}';
  }

  // ── Achievements ───────────────────────────────────────────────
  AchievementProgress getAchievementProgress(String id) {
    final raw = _prefs.getString('$_keyAchievementsPrefix$id');
    if (raw == null) return AchievementProgress(id: id);
    try {
      return AchievementProgress.fromJson(jsonDecode(raw));
    } catch (_) {
      return AchievementProgress(id: id);
    }
  }

  List<AchievementProgress> getAllAchievementProgress() =>
      Achievements.all.map((a) => getAchievementProgress(a.id)).toList();

  Future<void> _saveAchievementProgress(AchievementProgress p) async {
    await _prefs.setString(
        '$_keyAchievementsPrefix${p.id}', jsonEncode(p.toJson()));
  }

  Future<void> forceSaveAchievements(List<AchievementProgress> updates) async {
    for (final p in updates) {
      await _saveAchievementProgress(p);
    }
  }

  /// Returns list of newly unlocked achievement IDs
  Future<List<String>> checkAchievements({
    required int score,
    required int snakeLength,
    required int combo,
    int? shadowDefeatsExtra,
    int? questsCompletedExtra,
  }) async {
    final unlocked = <String>[];
    final games = gamesPlayed;
    final food = totalFoodEaten;
    final pus = totalPowerUpsCollected;
    final gold = totalGoldenApplesEaten;
    final poison = totalPoisonApplesEaten;
    final shadow = shadowDefeats + (shadowDefeatsExtra ?? 0);
    final qTotal = questsCompletedCount + (questsCompletedExtra ?? 0);

    if (shadowDefeatsExtra != null && shadowDefeatsExtra > 0)
      await addShadowDefeats(shadowDefeatsExtra);
    if (questsCompletedExtra != null && questsCompletedExtra > 0)
      await addQuestsCompletedCount(questsCompletedExtra);

    for (final ach in Achievements.all) {
      final prog = getAchievementProgress(ach.id);
      if (prog.unlocked) continue;

      int currentValue = 0;
      switch (ach.type) {
        case AchievementType.score:
          currentValue = score;
          break;
        case AchievementType.length:
          currentValue = snakeLength;
          break;
        case AchievementType.gamesPlayed:
          currentValue = games;
          break;
        case AchievementType.foodEaten:
          currentValue = food;
          break;
        case AchievementType.combo:
          currentValue = combo;
          break;
        case AchievementType.powerUps:
          currentValue = pus;
          break;
        case AchievementType.modePlay:
          currentValue = 1;
          break;
        case AchievementType.survive:
          currentValue = 0;
          break;
        case AchievementType.goldenApple:
          currentValue = gold;
          break;
        case AchievementType.poisonApple:
          currentValue = poison;
          break;
        case AchievementType.shadowDefeat:
          currentValue = shadow;
          break;
        case AchievementType.questsCompleted:
          currentValue = qTotal;
          break;
        case AchievementType.completionist:
          currentValue = getAllAchievementProgress()
              .where((p) => p.unlocked && p.id != 'all_ach')
              .length;
          break;
        // Safari types handled by checkSafariAchievements
        case AchievementType.safariPreyCaught:
        case AchievementType.safariCreatureTypes:
        case AchievementType.safariAllCreatures:
        case AchievementType.safariHuntStreak:
        case AchievementType.safariRoomsExplored:
        case AchievementType.safariCrocKills:
          continue;
      }

      // Only update if we've made forward progress
      if (currentValue > prog.progress) {
        final newProg = prog.copyWith(progress: currentValue);
        if (currentValue >= ach.targetValue) {
          await _saveAchievementProgress(newProg.copyWith(
            unlocked: true,
            unlockedAt: DateTime.now(),
          ));
          await addXp(ach.xpReward);
          unlocked.add(ach.id);
          AnalyticsService().logAchievementUnlocked(ach.id);
        } else {
          await _saveAchievementProgress(newProg);
        }
      }
    }
    return unlocked;
  }

  Future<List<String>> checkSafariAchievements({
    required int totalPrey,
    required int uniqueTypes,
    required bool allTypes,
    required int bestStreak,
    required int totalRooms,
    required int totalCrocs,
  }) async {
    final unlocked = <String>[];
    for (final ach in Achievements.all) {
      final prog = getAchievementProgress(ach.id);
      if (prog.unlocked) continue;

      int currentValue = 0;
      switch (ach.type) {
        case AchievementType.safariPreyCaught:
          currentValue = totalPrey;
          break;
        case AchievementType.safariCreatureTypes:
          currentValue = uniqueTypes;
          break;
        case AchievementType.safariAllCreatures:
          currentValue = allTypes ? 5 : uniqueTypes;
          break;
        case AchievementType.safariHuntStreak:
          currentValue = bestStreak;
          break;
        case AchievementType.safariRoomsExplored:
          currentValue = totalRooms;
          break;
        case AchievementType.safariCrocKills:
          currentValue = totalCrocs;
          break;
        default:
          continue;
      }

      if (currentValue > prog.progress) {
        final newProg = prog.copyWith(progress: currentValue);
        if (currentValue >= ach.targetValue) {
          await _saveAchievementProgress(newProg.copyWith(
            unlocked: true,
            unlockedAt: DateTime.now(),
          ));
          await addXp(ach.xpReward);
          unlocked.add(ach.id);
          AnalyticsService().logAchievementUnlocked(ach.id);
        } else {
          await _saveAchievementProgress(newProg);
        }
      }
    }
    return unlocked;
  }

  // ── Daily Quests ───────────────────────────────────────────────
  String get questsDate => _prefs.getString(_keyQuestsDate) ?? '';
  Future<void> saveQuestsDate(String date) =>
      _prefs.setString(_keyQuestsDate, date);

  String get weeklyQuestsDate => _prefs.getString(_keyWeeklyQuestsDate) ?? '';
  Future<void> saveWeeklyQuestsDate(String date) =>
      _prefs.setString(_keyWeeklyQuestsDate, date);

  List<DailyQuest> get quests {
    final raw = _prefs.getString(_keyQuests);
    if (raw == null) return [];
    try {
      final List dec = jsonDecode(raw);
      return dec.map((e) => DailyQuest.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveQuests(List<DailyQuest> quests) async {
    final raw = jsonEncode(quests.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyQuests, raw);
  }

  SocialChallenge getTodaySocialChallenge() {
    final today = todayString();
    final savedDate = _prefs.getString(_keySocialChallengeDate) ?? '';
    final raw = _prefs.getString(_keySocialChallengeData);

    if (savedDate == today && raw != null) {
      try {
        return SocialChallenge.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // Fall through and regenerate if local data is corrupted.
      }
    }

    final generated = _generateSocialChallenge(today);
    _prefs.setString(_keySocialChallengeDate, today);
    _prefs.setString(_keySocialChallengeData, jsonEncode(generated.toJson()));
    return generated;
  }

  Future<void> markSocialChallengeClaimed() async {
    final challenge = getTodaySocialChallenge();
    final updated = challenge.copyWith(claimed: true);
    await _prefs.setString(
        _keySocialChallengeData, jsonEncode(updated.toJson()));
  }

  SocialChallenge _generateSocialChallenge(String today) {
    const rivals = [
      'Nova Viper',
      'Pixel Cobra',
      'Arcade Fang',
      'Turbo Serpent',
      'Shadow Coil',
      'Neon Scale',
    ];

    final now = DateTime.now();
    final dayOfYear =
        now.difference(DateTime(now.year, 1, 1)).inDays.clamp(0, 365);
    final rng = Random(now.year * 1000 + dayOfYear);
    final target =
        max(400, (bestScore * 0.65).round() + 350 + rng.nextInt(450));
    final rewardCoins = 120 + (target ~/ 180).clamp(0, 280);
    final rewardXp = 80 + (target ~/ 240).clamp(0, 220);

    return SocialChallenge(
      challengeDate: today,
      rivalName: rivals[rng.nextInt(rivals.length)],
      targetScore: target,
      rewardCoins: rewardCoins,
      rewardXp: rewardXp,
      claimed: false,
    );
  }

  // ── Snake Souls (formerly Safari Gems) ─────────────────────────────────────
  int get snakeSouls => _prefs.getInt(_keySafariGems) ?? 0;
  Future<void> addSnakeSouls(int amount) =>
      _prefs.setInt(_keySafariGems, snakeSouls + amount);
  Future<void> deductSnakeSouls(int amount) {
    final newVal = snakeSouls - amount;
    return _prefs.setInt(_keySafariGems, newVal < 0 ? 0 : newVal);
  }

  // ── Altar Skills ────────────────────────────────────────────────────────────
  int get skillThickScales => _prefs.getInt(_keySkillThickScales) ?? 0;
  Future<void> setSkillThickScales(int level) =>
      _prefs.setInt(_keySkillThickScales, level);

  int get skillGreed => _prefs.getInt(_keySkillGreed) ?? 0;
  Future<void> setSkillGreed(int level) => _prefs.setInt(_keySkillGreed, level);

  int get skillDashMastery => _prefs.getInt(_keySkillDashMastery) ?? 0;
  Future<void> setSkillDashMastery(int level) =>
      _prefs.setInt(_keySkillDashMastery, level);

  // ── Explore Session Resume ───────────────────────────────────────────────────

  /// Saves the last known snake head position and floor for Explore mode.
  Future<void> saveExploreResume({
    required int headX,
    required int headY,
    required int floor,
    required int score,
  }) async {
    await Future.wait([
      _prefs.setInt(_keyExploreSnakeX, headX),
      _prefs.setInt(_keyExploreSnakeY, headY),
      _prefs.setInt(_keyExploreFloor, floor),
      _prefs.setInt(_keyExploreScore, score),
    ]);
  }

  /// Clears the saved explore resume data (call on game-over or portal exit).
  Future<void> clearExploreResume() async {
    await Future.wait([
      _prefs.remove(_keyExploreSnakeX),
      _prefs.remove(_keyExploreSnakeY),
      _prefs.remove(_keyExploreFloor),
      _prefs.remove(_keyExploreScore),
    ]);
  }

  /// Returns the saved explore head position, or null if none exists.
  ({int x, int y, int floor, int score})? get exploreResume {
    final x = _prefs.getInt(_keyExploreSnakeX);
    final y = _prefs.getInt(_keyExploreSnakeY);
    if (x == null || y == null) return null;
    return (
      x: x,
      y: y,
      floor: _prefs.getInt(_keyExploreFloor) ?? 1,
      score: _prefs.getInt(_keyExploreScore) ?? 0,
    );
  }

  // ── Expedition Gear ──────────────────────────────────────────────────────────
  Map<String, int> get gearCounts {
    final raw = _prefs.getString(_keyGearCounts);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  int gearCount(String typeName) => gearCounts[typeName] ?? 0;

  Future<void> addGear(String typeName, int count) async {
    final g = gearCounts;
    g[typeName] = (g[typeName] ?? 0) + count;
    await _prefs.setString(_keyGearCounts, jsonEncode(g));
  }

  Future<void> useGear(String typeName) async {
    final g = gearCounts;
    final current = g[typeName] ?? 0;
    if (current > 0) {
      g[typeName] = current - 1;
      await _prefs.setString(_keyGearCounts, jsonEncode(g));
    }
  }

  List<String> get equippedGear => _prefs.getStringList(_keyEquippedGear) ?? [];

  Future<void> setEquippedGear(List<String> gear) =>
      _prefs.setStringList(_keyEquippedGear, gear.take(2).toList());

  Set<String> get ownedRelics {
    final list = _prefs.getStringList(_keyOwnedRelics) ?? const [];
    return list.toSet();
  }

  Future<void> unlockRelic(String relicId) async {
    final owned = ownedRelics;
    if (owned.add(relicId)) {
      await _prefs.setStringList(_keyOwnedRelics, owned.toList());
    }
  }

  bool hasRelic(String relicId) => ownedRelics.contains(relicId);

  String? get equippedRelicId => _prefs.getString(_keyEquippedRelic);

  Future<void> setEquippedRelic(String? relicId) async {
    if (relicId == null) {
      await _prefs.remove(_keyEquippedRelic);
      return;
    }
    if (!hasRelic(relicId)) return;
    await _prefs.setString(_keyEquippedRelic, relicId);
  }

  // ── Safari Lifetime Stats ─────────────────────────────────────────────────
  int get safariTotalPrey => _prefs.getInt(_keySafariTotalPrey) ?? 0;
  Future<void> addSafariTotalPrey(int n) =>
      _prefs.setInt(_keySafariTotalPrey, safariTotalPrey + n);

  int get safariRoomsVisited => _prefs.getInt(_keySafariRoomsVisited) ?? 0;
  Future<void> addSafariRoomsVisited(int n) =>
      _prefs.setInt(_keySafariRoomsVisited, safariRoomsVisited + n);

  int get safariBestStreak => _prefs.getInt(_keySafariBestStreak) ?? 0;
  Future<void> updateSafariBestStreak(int streak) async {
    if (streak > safariBestStreak) {
      await _prefs.setInt(_keySafariBestStreak, streak);
    }
  }

  int get safariCrocKills => _prefs.getInt(_keySafariCrocKills) ?? 0;
  Future<void> addSafariCrocKills(int n) =>
      _prefs.setInt(_keySafariCrocKills, safariCrocKills + n);

  // ── Campaign ───────────────────────────────────────────────────
  int get highestCampaignLevel => _prefs.getInt(_keyCampaignLevel) ?? 1;
  Future<void> setHighestCampaignLevel(int level) =>
      _prefs.setInt(_keyCampaignLevel, level);

  /// Returns the best star rating (0-3) earned for a given level index.
  int getLevelStars(int levelIndex) {
    final raw = _prefs.getString(_keyCampaignStars);
    if (raw == null) return 0;
    final map = (jsonDecode(raw) as Map<String, dynamic>);
    return (map['$levelIndex'] as num?)?.toInt() ?? 0;
  }

  /// Saves star rating only if the new value is better.
  Future<void> saveLevelStars(int levelIndex, int stars) async {
    final raw = _prefs.getString(_keyCampaignStars);
    final map = raw != null
        ? Map<String, dynamic>.from(jsonDecode(raw) as Map)
        : <String, dynamic>{};
    final current = (map['$levelIndex'] as num?)?.toInt() ?? 0;
    if (stars > current) {
      map['$levelIndex'] = stars;
      await _prefs.setString(_keyCampaignStars, jsonEncode(map));
    }
  }
  // ── Safari Journal ──────────────────────────────────────────────────────────

  /// Returns a map of preyType-name → total caught count
  Map<String, int> get safariCounts {
    final raw = _prefs.getString(_keySafariCounts);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toInt()),
    );
  }

  Future<void> incrementSafariCount(String preyType) async {
    final counts = safariCounts;
    counts[preyType] = (counts[preyType] ?? 0) + 1;
    await _prefs.setString(_keySafariCounts, jsonEncode(counts));
  }

  /// Returns set of visited biome names
  Set<String> get safariVisitedBiomes {
    final list = _prefs.getStringList(_keySafariBiomes) ?? [];
    return list.toSet();
  }

  Future<void> recordBiomeVisit(String biomeName) async {
    final visited = safariVisitedBiomes;
    if (visited.add(biomeName)) {
      await _prefs.setStringList(_keySafariBiomes, visited.toList());
    }
  }

  /// Daily safari mission: catch N of a type. Resets each day.
  /// Returns {type, target, progress, date}
  Map<String, dynamic> get safariMission {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final storedDate = _prefs.getString(_keySafariMissionDate) ?? '';
    if (storedDate != today) {
      // Generate new daily mission
      final rng = Random(DateTime.now().year * 1000 +
          DateTime.now()
              .difference(DateTime(DateTime.now().year, 1, 1))
              .inDays);
      const types = [
        'mouse',
        'rabbit',
        'lizard',
        'butterfly',
        'croc',
        'fruit',
        'elite',
        'biomeEvent'
      ];
      final targets = [5, 3, 2, 2, 1, 4, 1, 2];
      final idx = rng.nextInt(types.length);
      return {
        'type': types[idx],
        'target': targets[idx],
        'progress': 0,
        'date': today,
        'fresh': true,
      };
    }
    return {
      'type': _prefs.getString('${_keySafariMissionDate}_type') ?? 'mouse',
      'target': _prefs.getInt('${_keySafariMissionDate}_target') ?? 5,
      'progress': _prefs.getInt(_keySafariMissionProgress) ?? 0,
      'date': storedDate,
      'fresh': false,
    };
  }

  Future<void> saveSafariMission(
      {required String type, required int target}) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await _prefs.setString(_keySafariMissionDate, today);
    await _prefs.setString('${_keySafariMissionDate}_type', type);
    await _prefs.setInt('${_keySafariMissionDate}_target', target);
    await _prefs.setInt(_keySafariMissionProgress, 0);
  }

  Future<void> incrementSafariMissionProgress() async {
    final current = _prefs.getInt(_keySafariMissionProgress) ?? 0;
    await _prefs.setInt(_keySafariMissionProgress, current + 1);
  }
}
