class GameStats {
  Map<int, int> clearCounts = {40: 0, 30: 0, 25: 0, 17: 0};
  Map<int, int> highScores = {40: 0, 30: 0, 25: 0, 17: 0};

  void updateStats(int visibleCellCount, int score) {
    clearCounts[visibleCellCount] = (clearCounts[visibleCellCount] ?? 0) + 1;
    highScores[visibleCellCount] = (highScores[visibleCellCount] ?? 0) > score
        ? highScores[visibleCellCount]!
        : score;
  }
}