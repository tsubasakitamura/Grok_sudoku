class PlayerProgress {
  int level;
  int experience;
  DateTime? lastFirstClearDate;

  PlayerProgress({
    this.level = 1,
    this.experience = 0,
    this.lastFirstClearDate,
  });

  // 経験値を追加し、レベルアップを処理
  void addExperience(int exp, bool isFirstClearToday) {
    experience += exp;
    while (experience >= 1000 && level < 999) {
      experience -= 1000;
      level++;
    }
    if (isFirstClearToday) {
      lastFirstClearDate = DateTime.now();
    }
  }

  // 今日が初回クリアか判定
  bool isFirstClearToday() {
    if (lastFirstClearDate == null) return true;
    final now = DateTime.now();
    return lastFirstClearDate!.year != now.year ||
        lastFirstClearDate!.month != now.month ||
        lastFirstClearDate!.day != now.day;
  }
}