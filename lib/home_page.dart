import 'package:flutter/material.dart';
import 'sudoku_page.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<int, int> clearCounts = {30: 0, 25: 0, 17: 0};
  Map<int, int> highScores = {30: 0, 25: 0, 17: 0};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      clearCounts[30] = prefs.getInt('clear_30') ?? 0;
      clearCounts[25] = prefs.getInt('clear_25') ?? 0;
      clearCounts[17] = prefs.getInt('clear_17') ?? 0;
      highScores[30] = prefs.getInt('highscore_30') ?? 0;
      highScores[25] = prefs.getInt('highscore_25') ?? 0;
      highScores[17] = prefs.getInt('highscore_17') ?? 0;
    });
  }

  Future<void> _saveStats(int visibleCellCount, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final newClearCount = (clearCounts[visibleCellCount] ?? 0) + 1;
    final newHighScore = (highScores[visibleCellCount] ?? 0) > score ? highScores[visibleCellCount]! : score;

    await prefs.setInt('clear_$visibleCellCount', newClearCount);
    await prefs.setInt('highscore_$visibleCellCount', newHighScore);

    setState(() {
      clearCounts[visibleCellCount] = newClearCount;
      highScores[visibleCellCount] = newHighScore;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[300]!, Colors.blue[800]!],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ナンプレ',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 10, color: Colors.black45, offset: Offset(2, 2))],
              ),
            ),
            SizedBox(height: 10),
            Text(
              '難易度を選択してください',
              style: TextStyle(fontSize: 20, color: Colors.white70, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 40),
            _buildDifficultyCard(context, '簡単', Colors.green, 30),
            SizedBox(height: 20),
            _buildDifficultyCard(context, '普通', Colors.orange, 25),
            SizedBox(height: 20),
            _buildDifficultyCard(context, '難しい', Colors.red, 17),
          ],
        ),
      ),
    ),
  );

  Widget _buildDifficultyCard(BuildContext context, String title, Color color, int count) => GestureDetector(
    onTap: () async {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('問題を生成しています...'),
            ],
          ),
        ),
      );

      print('パズル生成開始: $count');
      try {
        final puzzleData = await _generatePuzzleWithRetry(count);
        print('パズル生成完了: $count');

        if (context.mounted) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SudokuPage(
                visibleCellCount: count,
                initialGrid: puzzleData['initialGrid']!,
                grid: puzzleData['grid']!,
                fullGrid: puzzleData['fullGrid'],
                onClear: (score) => _saveStats(count, score),
              ),
            ),
          );
        }
      } catch (e) {
        print('エラー: $e');
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('問題の生成に失敗しました: $e')),
          );
        }
      }
    },
    child: Container(
      width: MediaQuery.of(context).size.width * 0.8,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color.fromRGBO(255, 255, 255, 0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: color, size: 28),
              SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('クリア: ${clearCounts[count]}回', style: TextStyle(fontSize: 16, color: Colors.black87)),
              Text('ハイスコア: ${highScores[count]}', style: TextStyle(fontSize: 16, color: Colors.black87)),
            ],
          ),
        ],
      ),
    ),
  );

  Future<Map<String, List<List<int>>>> _generatePuzzleWithRetry(int visibleCellCount) async {
    const maxRetries = 3;
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await flutterCompute<Map<String, List<List<int>>>, int>(generatePuzzleData, visibleCellCount)
            .timeout(Duration(seconds: 3), onTimeout: () {
          print('タイムアウト (試行 $attempt): $visibleCellCount');
          throw Exception('タイムアウト');
        });
      } catch (e) {
        if (attempt == maxRetries - 1) rethrow; // 最後の試行で失敗したらエラー
      }
    }
    throw Exception('予期せぬエラー'); // ここには到達しないはず
  }

  static Map<String, List<List<int>>> generatePuzzleData(int visibleCellCount) {
    final rand = Random();
    List<List<int>> grid = _generateFullGrid(rand);
    List<List<int>> fullGrid = List.generate(9, (i) => List.from(grid[i]));
    List<List<int>> initialGrid = _createInitialGrid(grid, visibleCellCount, rand);

    return {
      'grid': initialGrid,
      'initialGrid': initialGrid,
      'fullGrid': fullGrid,
    };
  }

  static List<List<int>> _generateFullGrid(Random rand) {
    List<List<int>> grid = List.generate(9, (_) => List<int>.filled(9, 0));

    // 最初の行にランダムな数字を配置して高速化
    List<int> firstRow = List.generate(9, (i) => i + 1)..shuffle(rand);
    for (int col = 0; col < 9; col++) {
      grid[0][col] = firstRow[col];
    }

    _fillGrid(grid, rand, 1, 0); // 2行目から埋める
    return grid;
  }

  static bool _fillGrid(List<List<int>> grid, Random rand, int row, int col) {
    if (row >= 9) return true;

    int nextRow = col == 8 ? row + 1 : row;
    int nextCol = col == 8 ? 0 : col + 1;

    if (grid[row][col] != 0) return _fillGrid(grid, rand, nextRow, nextCol);

    List<int> numbers = List.generate(9, (i) => i + 1);
    int attempts = 0;
    const maxAttempts = 10; // 試行回数を制限して高速化

    while (attempts < maxAttempts && numbers.isNotEmpty) {
      int idx = rand.nextInt(numbers.length);
      int num = numbers[idx];
      if (_isValid(grid, row, col, num)) {
        grid[row][col] = num;
        if (_fillGrid(grid, rand, nextRow, nextCol)) return true;
        grid[row][col] = 0;
      }
      numbers.removeAt(idx);
      attempts++;
    }
    return false;
  }

  static List<List<int>> _createInitialGrid(List<List<int>> grid, int visibleCellCount, Random rand) {
    List<List<int>> initialGrid = List.generate(9, (i) => List.from(grid[i]));
    List<int> positions = List.generate(81, (i) => i)..shuffle(rand);
    int cellsToRemove = 81 - visibleCellCount;

    for (int i = 0; i < cellsToRemove; i++) {
      int idx = positions[i];
      int row = idx ~/ 9;
      int col = idx % 9;
      initialGrid[row][col] = 0;
    }

    return initialGrid;
  }

  static bool _isValid(List<List<int>> grid, int row, int col, int num) {
    for (int x = 0; x < 9; x++) {
      if (grid[row][x] == num || grid[x][col] == num) return false;
    }
    int startRow = row - row % 3;
    int startCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (grid[startRow + i][startCol + j] == num) return false;
      }
    }
    return true;
  }
}