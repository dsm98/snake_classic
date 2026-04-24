enum QuestType {
  playGames,
  eatGoldenApples,
  eatPoisonApples,
  scoreTotal,
  timePlayed,
  collectPowerUps,
  reachLength,
  // Safari quest types
  catchPrey,
  discoverBiomes,
  huntStreak,
}

class DailyQuest {
  final String id;
  final QuestType type;
  final String title;
  final String description;
  final int goalAmount;
  final int coinReward;
  int currentAmount;

  DailyQuest({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.goalAmount,
    required this.coinReward,
    this.currentAmount = 0,
    this.isWeekly = false,
  });

  final bool isWeekly;

  bool get isCompleted => currentAmount >= goalAmount;
  double get progress => (currentAmount / goalAmount).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'description': description,
        'goalAmount': goalAmount,
        'coinReward': coinReward,
        'currentAmount': currentAmount,
        'isWeekly': isWeekly,
      };

  factory DailyQuest.fromJson(Map<String, dynamic> json) {
    return DailyQuest(
      id: json['id'] as String,
      type: QuestType.values.firstWhere((e) => e.name == json['type']),
      title: json['title'] as String,
      description: json['description'] as String,
      goalAmount: json['goalAmount'] as int,
      coinReward: json['coinReward'] as int,
      currentAmount: json['currentAmount'] as int,
      isWeekly: json['isWeekly'] as bool? ?? false,
    );
  }
}
