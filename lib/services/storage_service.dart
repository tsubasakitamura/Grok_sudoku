import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_stats.dart';
import '../models/player_progress.dart';

class StorageService {
  Future<GameStats> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final stats = GameStats();
    stats.clearCounts[40] = prefs.getInt('clear_40') ?? 0;
    stats.clearCounts[30] = prefs.getInt('clear_30') ?? 0;
    stats.clearCounts[25] = prefs.getInt('clear_25') ?? 0;
    stats.clearCounts[17] = prefs.getInt('clear_17') ?? 0;
    stats.highScores[40] = prefs.getInt('highscore_40') ?? 0;
    stats.highScores[30] = prefs.getInt('highscore_30') ?? 0;
    stats.highScores[25] = prefs.getInt('highscore_25') ?? 0;
    stats.highScores[17] = prefs.getInt('highscore_17') ?? 0;
    return stats;
  }

  Future<void> saveStats(GameStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('clear_40', stats.clearCounts[40]!);
    await prefs.setInt('clear_30', stats.clearCounts[30]!);
    await prefs.setInt('clear_25', stats.clearCounts[25]!);
    await prefs.setInt('clear_17', stats.clearCounts[17]!);
    await prefs.setInt('highscore_40', stats.highScores[40]!);
    await prefs.setInt('highscore_30', stats.highScores[30]!);
    await prefs.setInt('highscore_25', stats.highScores[25]!);
    await prefs.setInt('highscore_17', stats.highScores[17]!);
  }

  Future<PlayerProgress> loadPlayerProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final level = prefs.getInt('player_level') ?? 1;
    final experience = prefs.getInt('player_experience') ?? 0;
    final lastClearTimestamp = prefs.getString('last_first_clear_date');
    DateTime? lastClearDate;
    if (lastClearTimestamp != null) {
      lastClearDate = DateTime.tryParse(lastClearTimestamp);
    }
    return PlayerProgress(
      level: level,
      experience: experience,
      lastFirstClearDate: lastClearDate,
    );
  }

  Future<void> savePlayerProgress(PlayerProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('player_level', progress.level);
    await prefs.setInt('player_experience', progress.experience);
    if (progress.lastFirstClearDate != null) {
      await prefs.setString('last_first_clear_date', progress.lastFirstClearDate!.toIso8601String());
    }
  }
}