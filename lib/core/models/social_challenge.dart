class SocialChallenge {
  final String challengeDate;
  final String rivalName;
  final int targetScore;
  final int rewardCoins;
  final int rewardXp;
  final bool claimed;

  const SocialChallenge({
    required this.challengeDate,
    required this.rivalName,
    required this.targetScore,
    required this.rewardCoins,
    required this.rewardXp,
    this.claimed = false,
  });

  bool isCompleted(int bestScore) => bestScore >= targetScore;

  SocialChallenge copyWith({
    String? challengeDate,
    String? rivalName,
    int? targetScore,
    int? rewardCoins,
    int? rewardXp,
    bool? claimed,
  }) {
    return SocialChallenge(
      challengeDate: challengeDate ?? this.challengeDate,
      rivalName: rivalName ?? this.rivalName,
      targetScore: targetScore ?? this.targetScore,
      rewardCoins: rewardCoins ?? this.rewardCoins,
      rewardXp: rewardXp ?? this.rewardXp,
      claimed: claimed ?? this.claimed,
    );
  }

  Map<String, dynamic> toJson() => {
        'challengeDate': challengeDate,
        'rivalName': rivalName,
        'targetScore': targetScore,
        'rewardCoins': rewardCoins,
        'rewardXp': rewardXp,
        'claimed': claimed,
      };

  factory SocialChallenge.fromJson(Map<String, dynamic> json) {
    return SocialChallenge(
      challengeDate: json['challengeDate'] as String,
      rivalName: json['rivalName'] as String,
      targetScore: json['targetScore'] as int,
      rewardCoins: json['rewardCoins'] as int,
      rewardXp: json['rewardXp'] as int,
      claimed: json['claimed'] as bool? ?? false,
    );
  }
}
