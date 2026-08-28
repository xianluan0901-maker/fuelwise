String getRewardTier(int totalPoints) {
  if (totalPoints >= 300) {
    return 'gold';
  }

  if (totalPoints >= 100) {
    return 'silver';
  }

  return 'blue';
}

int rewardTierRank(String tier) {
  switch (tier.toLowerCase()) {
    case 'gold':
      return 3;
    case 'silver':
      return 2;
    default:
      return 1;
  }
}

String formatRewardTier(String tier) {
  if (tier.isEmpty) return 'Blue';

  return '${tier[0].toUpperCase()}'
      '${tier.substring(1).toLowerCase()}';
}

int? getNextTierThreshold(int totalPoints) {
  if (totalPoints < 100) {
    return 100;
  }

  if (totalPoints < 300) {
    return 300;
  }

  return null;
}

String? getNextTierName(int totalPoints) {
  if (totalPoints < 100) {
    return 'Silver';
  }

  if (totalPoints < 300) {
    return 'Gold';
  }

  return null;
}