import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/game_stats.dart';
import '../models/player_progress.dart';
import '../services/ad_service.dart';
import '../services/storage_service.dart';
import '../utils/sudoku_generator.dart';
import '../models/sudoku_grid.dart';

class HomeViewModel {
  final StorageService _storageService;
  final AdService _adService;
  GameStats _gameStats = GameStats();
  PlayerProgress _playerProgress = PlayerProgress();
  bool _isChallengeMode = true;
  bool _isAdLoaded = false;
  Function(Map<String, dynamic>)? _onStateChanged;

  HomeViewModel(this._storageService, this._adService) {
    _loadStats();
    _initBannerAd();
  }

  GameStats get gameStats => _gameStats;
  PlayerProgress get playerProgress => _playerProgress;
  bool get isChallengeMode => _isChallengeMode;
  bool get isAdLoaded => _isAdLoaded;
  BannerAd? get bannerAd => _adService.bannerAd;

  void setStateCallback(Function(Map<String, dynamic>) callback) {
    _onStateChanged = callback;
  }

  Future<void> _loadStats() async {
    _gameStats = await _storageService.loadStats();
  }

  Future<void> loadPlayerProgress() async {
    _playerProgress = await _storageService.loadPlayerProgress();
  }

  void _initBannerAd() {
    _adService.loadBannerAd(onAdLoaded: () {
      _isAdLoaded = true;
      _onStateChanged?.call({'isAdLoaded': true});
    });
  }

  Future<SudokuGrid> generatePuzzle(int visibleCellCount) async {
    try {
      final puzzleData = await compute(SudokuGenerator.generatePuzzleData, visibleCellCount)
          .timeout(Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('パズル生成がタイムアウトしました: visibleCellCount=$visibleCellCount');
      });
      return SudokuGrid(
        initialGrid: puzzleData['initialGrid']!,
        currentGrid: puzzleData['grid']!,
        fullGrid: puzzleData['fullGrid']!,
        visibleCellCount: visibleCellCount,
      );
    } catch (e, stackTrace) {
      print('生成エラー: $e\nスタックトレース: $stackTrace');
      rethrow;
    }
  }

  void toggleChallengeMode(bool value) {
    _isChallengeMode = value;
    _onStateChanged?.call({'isChallengeMode': value});
  }

  Future<Map<String, dynamic>> saveStats(int visibleCellCount, int score) async {
    _gameStats.updateStats(visibleCellCount, score);
    await _storageService.saveStats(_gameStats);
    final isFirstClear = _playerProgress.isFirstClearToday();
    final expGained = isFirstClear ? 300 : 100;
    final oldLevel = _playerProgress.level;
    _playerProgress.addExperience(expGained, isFirstClear);
    await _storageService.savePlayerProgress(_playerProgress);
    _onStateChanged?.call({
      'newLevel': _playerProgress.level,
      'oldLevel': oldLevel,
    });
    print('saveStats called: expGained=$expGained, isDailyBonus=$isFirstClear, level=${_playerProgress.level}, totalExperience=${_playerProgress.experience}');
    return {
      'score': score,
      'expGained': expGained,
      'isDailyBonus': isFirstClear,
    };
  }


  void dispose() {
    _adService.disposeBannerAd();
    _onStateChanged = null;
  }
}