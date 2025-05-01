import 'dart:async';
import 'package:flutter/material.dart';
import '../models/sudoku_grid.dart';
import '../services/ad_service.dart';
import 'home_viewmodel.dart';

class SudokuViewModel {
  final SudokuGrid _sudokuGrid;
  final bool _isChallengeMode;
  final Function(int) _onClear;
  final AdService _adService;
  final HomeViewModel _homeViewModel;
  late List<List<int>> _currentGrid;
  late List<List<int>> _fullGrid;
  List<List<int>> _grid;
  List<List<bool>> _isInitial;
  List<List<bool>> _isMiss;
  Map<int, int> _numberCounts;
  List<bool> _possibleNumbers;
  Map<String, bool> _ruleViolationCache;
  bool _hintUsed;
  int _selectedRow = -1;
  int _selectedCol = -1;
  bool _showMagnifier = false;
  double? _gridSize;
  int _score = 0;
  int _missCount = 0;
  int _secondsElapsed = 0;
  Timer? _timer;
  Offset _magnifierPosition = Offset.zero;
  double _magnificationScale = 1.0;
  final double _minMagnification = 1.0;
  final double _fixedMagnification = 1.5;

  SudokuViewModel({
    required SudokuGrid sudokuGrid,
    required bool isChallengeMode,
    required Function(int) onClear,
    required AdService adService,
    required HomeViewModel homeViewModel,
  })  : _sudokuGrid = sudokuGrid,
        _isChallengeMode = isChallengeMode,
        _onClear = onClear,
        _adService = adService,
        _homeViewModel = homeViewModel,
        _grid = List.generate(9, (i) => List.from(sudokuGrid.currentGrid[i])),
        _isInitial = List.generate(9,
            (i) => List.generate(9, (j) => sudokuGrid.initialGrid[i][j] != 0)),
        _isMiss = List.generate(9, (i) => List.generate(9, (j) => false)),
        _numberCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0, 8: 0, 9: 0},
        _possibleNumbers = List.filled(10, false),
        _ruleViolationCache = {},
        _hintUsed = false {
    _currentGrid =
        sudokuGrid.currentGrid.map((row) => List<int>.from(row)).toList();
    _fullGrid = sudokuGrid.fullGrid.map((row) => List<int>.from(row)).toList();
    _updateNumberCounts();
    _validateFullGrid();
    _adService.loadRewardedAd();
    if (_isChallengeMode) {
      _startTimer();
    }
  }

  // ゲッター（変更なし）
  List<List<int>> get grid => _grid;

  List<List<bool>> get isInitial => _isInitial;

  List<List<bool>> get isMiss => _isMiss;

  int get selectedRow => _selectedRow;

  int get selectedCol => _selectedCol;

  int get score => _score;

  int get missCount => _missCount;

  int get secondsElapsed => _secondsElapsed;

  bool get hintUsed => _hintUsed;

  Map<int, int> get numberCounts => _numberCounts;

  List<bool> get possibleNumbers => _possibleNumbers;

  bool get showMagnifier => _showMagnifier;

  Offset get magnifierPosition => _magnifierPosition;

  double get magnificationScale => _magnificationScale;

  double? get gridSize => _gridSize;

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      _secondsElapsed++;
    });
  }

  void _validateFullGrid() {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        int num = _fullGrid[row][col];
        if (num == 0) continue;
        _fullGrid[row][col] = 0;
        if (_isRuleViolation(row, col, num, _fullGrid)) {
          print('fullGridがルール違反: pos=($row, $col), num=$num');
        }
        _fullGrid[row][col] = num;
      }
    }
  }

  void updateGridSize(double gridSize) {
    _gridSize = gridSize;
  }

  void selectCell(int row, int col) {
    if (_selectedRow == row && _selectedCol == col) return;
    _selectedRow = row;
    _selectedCol = col;
    _updatePossibleNumbers();
    if (_showMagnifier && _gridSize != null) {
      _updateMagnifierPosition(_gridSize!);
    }
  }

  void _updatePossibleNumbers() {
    if (_selectedRow == -1 || _selectedCol == -1) return;
    if (_isInitial[_selectedRow][_selectedCol]) {
      _possibleNumbers = List.filled(10, false);
      return;
    }

    _possibleNumbers = List.filled(10, false);
    int currentNum = _grid[_selectedRow][_selectedCol];
    _grid[_selectedRow][_selectedCol] = 0;
    for (int num = 1; num <= 9; num++) {
      if (!_isRuleViolation(_selectedRow, _selectedCol, num, _grid)) {
        _possibleNumbers[num] = true;
      }
    }
    _grid[_selectedRow][_selectedCol] = currentNum;
  }

  bool _isRuleViolation(int row, int col, int num, List<List<int>> grid) {
    if (num == 0) return false;

    String cacheKey = '$row-$col-$num';
    if (_ruleViolationCache.containsKey(cacheKey)) {
      return _ruleViolationCache[cacheKey]!;
    }

    bool hasConflict = false;
    for (int j = 0; j < 9; j++) {
      if (j != col && grid[row][j] == num) {
        hasConflict = true;
        break;
      }
    }
    if (!hasConflict) {
      for (int i = 0; i < 9; i++) {
        if (i != row && grid[i][col] == num) {
          hasConflict = true;
          break;
        }
      }
    }
    if (!hasConflict) {
      int startRow = (row ~/ 3) * 3, startCol = (col ~/ 3) * 3;
      for (int i = startRow; i < startRow + 3; i++) {
        for (int j = startCol; j < startCol + 3; j++) {
          if ((i != row || j != col) && grid[i][j] == num) {
            hasConflict = true;
            break;
          }
        }
        if (hasConflict) break;
      }
    }

    _ruleViolationCache[cacheKey] = hasConflict;
    return hasConflict;
  }

  int _getClearBonus() {
    switch (_sudokuGrid.visibleCellCount) {
      case 40:
        return 100;
      case 30:
        return 200;
      case 25:
        return 300;
      case 17:
        return 500;
      default:
        return 200;
    }
  }

  void inputNumber(int number, BuildContext context) {
    if (_selectedRow == -1 ||
        _selectedCol == -1 ||
        _isInitial[_selectedRow][_selectedCol]) return;

    int oldNumber = _grid[_selectedRow][_selectedCol];
    _grid[_selectedRow][_selectedCol] = number;
    _updateNumberCountsSingle(oldNumber, number);

    _ruleViolationCache.clear();

    if (number != 0) {
      bool isCorrect = _grid[_selectedRow][_selectedCol] ==
          _fullGrid[_selectedRow][_selectedCol];
      bool isViolation =
          _isRuleViolation(_selectedRow, _selectedCol, number, _grid);

      if (isCorrect) {
        _score += 20;
        _isMiss[_selectedRow][_selectedCol] = false;
      }
      if (isViolation) {
        _score -= 2;
        _missCount++;
        _isMiss[_selectedRow][_selectedCol] = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ルール違反です！'), duration: Duration(seconds: 3)),
        );
        if (_missCount >= 3) {
          _timer?.cancel();
          _showGameOverDialog(context);
          return;
        }
      } else {
        _isMiss[_selectedRow][_selectedCol] = false;
      }

      if (_isGridFilled()) {
        if (_isComplete()) {
          _score += _getClearBonus();
          _timer?.cancel();
          _showClearDialog(context);
        } else {
          String errorMessage = _getCompletionErrors();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('クリア条件を満たしていません：$errorMessage'),
                duration: Duration(seconds: 5)),
          );
        }
      }
    } else {
      _isMiss[_selectedRow][_selectedCol] = false;
    }
    _updatePossibleNumbers();
  }

  void useHint(BuildContext context) {
    if (_selectedRow == -1 ||
        _selectedCol == -1 ||
        _isInitial[_selectedRow][_selectedCol]) return;

    if (_hintUsed) {
      _adService.showRewardedAd(
        onReward: () {
          _hintUsed = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('ヒントが再び使えるようになりました！'),
                duration: Duration(seconds: 3)),
          );
        },
        onError: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('広告を読み込み中です。しばらくお待ちください。'),
                duration: Duration(seconds: 3)),
          );
        },
      );
    } else {
      int correctNumber = _fullGrid[_selectedRow][_selectedCol];
      int oldNumber = _grid[_selectedRow][_selectedCol];
      _grid[_selectedRow][_selectedCol] = correctNumber;
      _updateNumberCountsSingle(oldNumber, correctNumber);
      _hintUsed = true;

      if (oldNumber != 0)
        _score -= 10;
      else
        _score += 10;

      _isMiss[_selectedRow][_selectedCol] = false;
      _ruleViolationCache.clear();

      if (_isGridFilled()) {
        if (_isComplete()) {
          _score += _getClearBonus();
          _timer?.cancel();
          _showClearDialog(context);
        } else {
          String errorMessage = _getCompletionErrors();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('クリア条件を満たしていません：$errorMessage'),
                duration: Duration(seconds: 5)),
          );
        }
      }
      _updatePossibleNumbers();
    }
  }

  void autoComplete(BuildContext context) {
    if (_selectedRow == -1 ||
        _selectedCol == -1 ||
        _isInitial[_selectedRow][_selectedCol]) return;

    int correctNumber = _fullGrid[_selectedRow][_selectedCol];
    int oldNumber = _grid[_selectedRow][_selectedCol];
    _grid[_selectedRow][_selectedCol] = correctNumber;
    _updateNumberCountsSingle(oldNumber, correctNumber);

    if (oldNumber != 0)
      _score -= 10;
    else
      _score += 10;

    _isMiss[_selectedRow][_selectedCol] = false;
    _ruleViolationCache.clear();

    if (_isGridFilled()) {
      if (_isComplete()) {
        _score += _getClearBonus();
        _timer?.cancel();
        _showClearDialog(context);
      } else {
        String errorMessage = _getCompletionErrors();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('クリア条件を満たしていません：$errorMessage'),
              duration: Duration(seconds: 5)),
        );
      }
    }
    _updatePossibleNumbers();
  }

  bool _isComplete() {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (_grid[i][j] == 0) {
          print('Incomplete: Empty cell at ($i, $j)');
          return false;
        }
      }
    }

    _ruleViolationCache.clear();

    for (int i = 0; i < 9; i++) {
      Map<int, int> rowCount = {}, colCount = {};
      for (int j = 0; j < 9; j++) {
        int rowNum = _grid[i][j], colNum = _grid[j][i];
        if (rowNum != 0) {
          rowCount[rowNum] = (rowCount[rowNum] ?? 0) + 1;
          if (rowCount[rowNum]! > 1) {
            print('Rule violation: Duplicate $rowNum in row $i');
            return false;
          }
        }
        if (colNum != 0) {
          colCount[colNum] = (colCount[colNum] ?? 0) + 1;
          if (colCount[colNum]! > 1) {
            print('Rule violation: Duplicate $colNum in column $i');
            return false;
          }
        }
      }
    }

    for (int blockRow = 0; blockRow < 3; blockRow++) {
      for (int blockCol = 0; blockCol < 3; blockCol++) {
        Map<int, int> blockCount = {};
        for (int i = 0; i < 3; i++) {
          for (int j = 0; j < 3; j++) {
            int num = _grid[blockRow * 3 + i][blockCol * 3 + j];
            if (num != 0) {
              blockCount[num] = (blockCount[num] ?? 0) + 1;
              if (blockCount[num]! > 1) {
                print(
                    'Rule violation: Duplicate $num in block ($blockRow, $blockCol)');
                return false;
              }
            }
          }
        }
      }
    }

    print('Grid is complete and valid');
    return true;
  }

  String _getCompletionErrors() {
    List<String> errors = [];

    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (_grid[i][j] == 0) {
          errors.add('(${i + 1}, ${j + 1}) が未入力です');
        }
      }
    }

    for (int i = 0; i < 9; i++) {
      Map<int, int> rowCount = {}, colCount = {};
      for (int j = 0; j < 9; j++) {
        int rowNum = _grid[i][j], colNum = _grid[j][i];
        if (rowNum != 0) {
          rowCount[rowNum] = (rowCount[rowNum] ?? 0) + 1;
          if (rowCount[rowNum]! > 1) {
            errors.add('${i + 1}行目に数字 $rowNum が重複しています');
          }
        }
        if (colNum != 0) {
          colCount[colNum] = (colCount[colNum] ?? 0) + 1;
          if (colCount[colNum]! > 1) {
            errors.add('${j + 1}列目に数字 $colNum が重複しています');
          }
        }
      }
    }

    for (int blockRow = 0; blockRow < 3; blockRow++) {
      for (int blockCol = 0; blockCol < 3; blockCol++) {
        Map<int, int> blockCount = {};
        for (int i = 0; i < 3; i++) {
          for (int j = 0; j < 3; j++) {
            int num = _grid[blockRow * 3 + i][blockCol * 3 + j];
            if (num != 0) {
              blockCount[num] = (blockCount[num] ?? 0) + 1;
              if (blockCount[num]! > 1) {
                String blockName = _getBlockName(blockRow, blockCol);
                errors.add('$blockNameのブロックに数字 $num が重複しています');
              }
            }
          }
        }
      }
    }

    errors = errors.toSet().toList();
    return errors.isEmpty
        ? 'すべてのセルが正しいですが、クリア条件を確認してください'
        : errors.take(3).join('、');
  }

  String _getBlockName(int blockRow, int blockCol) {
    if (blockRow == 0 && blockCol == 0) return '左上';
    if (blockRow == 0 && blockCol == 1) return '上中央';
    if (blockRow == 0 && blockCol == 2) return '右上';
    if (blockRow == 1 && blockCol == 0) return '左中央';
    if (blockRow == 1 && blockCol == 1) return '中央';
    if (blockRow == 1 && blockCol == 2) return '右中央';
    if (blockRow == 2 && blockCol == 0) return '左下';
    if (blockRow == 2 && blockCol == 1) return '下中央';
    if (blockRow == 2 && blockCol == 2) return '右下';
    return 'ブロック';
  }

  void _updateNumberCounts() {
    _numberCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0, 8: 0, 9: 0};
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (_grid[i][j] != 0) {
          _numberCounts[_grid[i][j]] = (_numberCounts[_grid[i][j]] ?? 0) + 1;
        }
      }
    }
  }

  void _updateNumberCountsSingle(int oldNumber, int newNumber) {
    if (oldNumber != 0) {
      _numberCounts[oldNumber] = (_numberCounts[oldNumber] ?? 0) - 1;
    }
    if (newNumber != 0) {
      _numberCounts[newNumber] = (_numberCounts[newNumber] ?? 0) + 1;
    }
  }

  void _showClearDialog(BuildContext context) {
    int baseBrainAge = 40;
    int timePenalty = (_secondsElapsed ~/ 120) * 2;
    int missPenalty = _missCount * 3;
    int brainAge = baseBrainAge + timePenalty + missPenalty - (_score ~/ 30);
    brainAge = brainAge.clamp(15, 60);

    String brainAgeMessage;
    if (brainAge <= 19) brainAgeMessage = '驚異的！天才的なひらめき！';
    else if (brainAge <= 25) brainAgeMessage = '素晴らしい！超鋭い脳！';
    else if (brainAge <= 35) brainAgeMessage = 'すごい！若々しい思考力！';
    else if (brainAge <= 50) brainAgeMessage = 'いいね！バランスの取れた脳！';
    else brainAgeMessage = '立派！経験豊かな知恵！';

    _homeViewModel.saveStats(_sudokuGrid.visibleCellCount, _score).then((result) {
      if (!context.mounted) return;

      print('Clear dialog: score=${result['score']}, expGained=${result['expGained']}, isDailyBonus=${result['isDailyBonus']}, isChallengeMode=$_isChallengeMode');

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white, // 背景色を白色に変更
          title: Text(
            'クリア！',
            style: TextStyle(
              fontFamily: 'NotoSansJP',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'スコア: ${result['score']}',
                style: TextStyle(
                  fontFamily: 'NotoSansJP',
                  fontSize: 24,
                  height: 1.3,
                ),
              ),
              Text(
                result['isDailyBonus']
                    ? 'デイリーボーナス\n+${result['expGained']} EXP'
                    : '+${result['expGained']} EXP',
                style: TextStyle(
                  fontFamily: 'NotoSansJP',
                  fontSize: 24,
                  height: 1.3,
                  color: Colors.green[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isChallengeMode) ...[
                Text(
                  '時間: ${formatTime(_secondsElapsed)}',
                  style: TextStyle(
                    fontFamily: 'NotoSansJP',
                    fontSize: 24,
                    height: 1.3,
                  ),
                ),
                Text(
                  '脳年齢: $brainAge歳',
                  style: TextStyle(
                    fontFamily: 'NotoSansJP',
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                Text(
                  brainAgeMessage,
                  style: TextStyle(
                    fontFamily: 'NotoSansJP',
                    fontSize: 24,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // ダイアログを閉じる
                // _onClear(_score) を削除（saveStats の重複呼び出し防止）
              },
              child: Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'NotoSansJP',
                  fontSize: 22,
                  color: Colors.green[800],
                ),
              ),
            ),
          ],
        ),
      );
    }).catchError((e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    });
  }

  void _showGameOverDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.red[100],
        title: Text(
          'ゲームオーバー',
          style: TextStyle(
            fontFamily: 'NotoSansJP',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.red[800],
          ),
        ),
        content: Text(
          '3回ミスしました。\nスコア: $_score\n時間: ${formatTime(_secondsElapsed)}',
          style: TextStyle(
            fontFamily: 'NotoSansJP',
            fontSize: 24,
            height: 1.3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              '戻る',
              style: TextStyle(
                fontFamily: 'NotoSansJP',
                fontSize: 22,
                color: Colors.red[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _adService.showRewardedAd(
                onReward: () {
                  _missCount--;
                  _timer = Timer.periodic(Duration(seconds: 1), (_) {
                    _secondsElapsed++;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ゲームを続行します！ミス回数: $_missCount'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
                onError: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('広告を読み込み中です。しばらくお待ちください。'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
              );
            },
            child: Text(
              '動画を見て続行',
              style: TextStyle(
                fontFamily: 'NotoSansJP',
                fontSize: 22,
                color: Colors.blue[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60, remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  bool _isGridFilled() {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (_grid[i][j] == 0) return false;
      }
    }
    return true;
  }

  void _updateMagnifierPosition(double gridSize) {
    _gridSize = gridSize;
    double cellSize = _gridSize! / 9;
    double offsetX, offsetY;
    if (_selectedRow == -1 || _selectedCol == -1) {
      offsetX = (4 + 0.5) * cellSize;
      offsetY = (4 + 0.5) * cellSize;
    } else {
      offsetX = (_selectedCol + 0.5) * cellSize;
      offsetY = (_selectedRow + 0.5) * cellSize;
    }
    _magnifierPosition = Offset(
      offsetX + (_gridSize! * 0.02),
      offsetY + (_gridSize! * 0.02),
    );
  }

  void toggleMagnifier(double gridSize) {
    if (_showMagnifier) {
      _showMagnifier = false;
      _magnificationScale = _minMagnification;
    } else {
      _showMagnifier = true;
      _magnificationScale = _fixedMagnification;
      _updateMagnifierPosition(gridSize);
    }
  }

  void dispose() {
    _timer?.cancel();
    _adService.disposeRewardedAd();
  }
}
