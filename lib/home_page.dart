import 'package:flutter/material.dart';
import 'sudoku_page.dart';
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
      final puzzleData = generatePuzzleData(count); // メインスレッドで即時生成
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

  Map<String, List<List<int>>> generatePuzzleData(int visibleCellCount) {
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

  List<List<int>> _generateFullGrid(Random rand) {
    // 複数のベースグリッドを用意（有効なナンプレ）
    final List<List<List<int>>> baseGrids = [
      [
        [5, 3, 4, 6, 7, 8, 9, 1, 2],
        [6, 7, 2, 1, 9, 5, 3, 4, 8],
        [1, 9, 8, 3, 4, 2, 5, 6, 7],
        [8, 5, 9, 7, 6, 1, 4, 2, 3],
        [4, 2, 6, 8, 5, 3, 7, 9, 1],
        [7, 1, 3, 9, 2, 4, 8, 5, 6],
        [9, 6, 1, 5, 3, 7, 2, 8, 4],
        [2, 8, 7, 4, 1, 9, 6, 3, 5],
        [3, 4, 5, 2, 8, 6, 1, 7, 9],
      ],
      [
        [8, 3, 4, 1, 5, 9, 6, 7, 2],
        [5, 6, 7, 8, 2, 4, 9, 1, 3],
        [9, 1, 2, 6, 7, 3, 5, 4, 8],
        [4, 5, 8, 9, 6, 1, 7, 2, 3],
        [7, 2, 1, 5, 8, 4, 3, 9, 6],
        [6, 9, 3, 7, 4, 2, 8, 5, 1],
        [1, 7, 6, 4, 9, 8, 2, 3, 5],
        [3, 8, 5, 2, 1, 7, 4, 6, 9],
        [2, 4, 9, 3, 6, 5, 1, 8, 7],
      ],
    ];

    // ランダムにベースを選択
    List<List<int>> baseGrid = List.generate(9, (i) => List.from(baseGrids[rand.nextInt(baseGrids.length)][i]));
    return _transformGrid(baseGrid, rand);
  }

  List<List<int>> _transformGrid(List<List<int>> grid, Random rand) {
    List<List<int>> transformed = List.generate(9, (i) => List.from(grid[i]));

    // 1. 行のシャッフル（3x3ブロック内）
    for (int block = 0; block < 3; block++) {
      List<int> rows = [block * 3, block * 3 + 1, block * 3 + 2]..shuffle(rand);
      for (int i = 0; i < 3; i++) {
        transformed[block * 3 + i] = List.from(grid[rows[i]]);
      }
    }

    // 2. 列のシャッフル（3x3ブロック内）
    List<List<int>> temp = List.generate(9, (_) => List<int>.filled(9, 0));
    for (int block = 0; block < 3; block++) {
      List<int> cols = [block * 3, block * 3 + 1, block * 3 + 2]..shuffle(rand);
      for (int j = 0; j < 9; j++) {
        for (int i = 0; i < 3; i++) {
          temp[j][block * 3 + i] = transformed[j][cols[i]];
        }
      }
    }
    transformed = temp;

    // 3. 数字の置換
    List<int> numbers = List.generate(9, (i) => i + 1)..shuffle(rand);
    Map<int, int> mapping = Map.fromIterables(List.generate(9, (i) => i + 1), numbers);
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        transformed[i][j] = mapping[transformed[i][j]]!;
      }
    }

    return transformed;
  }

  List<List<int>> _createInitialGrid(List<List<int>> grid, int visibleCellCount, Random rand) {
    List<List<int>> initialGrid = List.generate(9, (i) => List.from(grid[i]));
    List<int> positions = List.generate(81, (i) => i)..shuffle(rand);
    int cellsToRemove = 81 - visibleCellCount;

    for (int i = 0; i < cellsToRemove; i++) {
      int idx = positions[i];
      int row = idx ~/ 9;
      int col = idx % 9;
      initialGrid[row][col] = 0;
    }

    // visibleCellCountが17の場合、厳密に17を保証
    if (visibleCellCount == 17) {
      int currentVisible = initialGrid.expand((row) => row).where((cell) => cell != 0).length;
      print('表示セル数調整: 現在 $currentVisible, 目標 17');
      while (currentVisible < 17) {
        int idx = positions[currentVisible + cellsToRemove];
        int row = idx ~/ 9;
        int col = idx % 9;
        if (initialGrid[row][col] == 0) {
          initialGrid[row][col] = grid[row][col];
          currentVisible++;
        }
      }
      while (currentVisible > 17) {
        int idx = positions[currentVisible - 1];
        int row = idx ~/ 9;
        int col = idx % 9;
        if (initialGrid[row][col] != 0) {
          initialGrid[row][col] = 0;
          currentVisible--;
        }
      }
    }

    return initialGrid;
  }
}