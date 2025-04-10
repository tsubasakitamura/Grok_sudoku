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
      Map<String, List<List<int>>> puzzleData = generatePuzzleData(count);

      if (!_isValidPuzzle(puzzleData['initialGrid']!, puzzleData['fullGrid']!)) {
        print('エラー: 有効な盤面を生成できませんでした');
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('有効な問題の生成に失敗しました')),
          );
        }
        return;
      }

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
    List<List<int>> grid;
    do {
      grid = _generateFullGrid(rand);
    } while (!_isValidFullGrid(grid));
    List<List<int>> fullGrid = List.generate(9, (i) => List.from(grid[i]));
    List<List<int>> initialGrid = _createInitialGrid(fullGrid, visibleCellCount, rand);

    return {
      'grid': initialGrid,
      'initialGrid': initialGrid,
      'fullGrid': fullGrid,
    };
  }

  List<List<int>> _generateFullGrid(Random rand) {
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

    List<List<int>> baseGrid = List.generate(9, (i) => List.from(baseGrids[rand.nextInt(baseGrids.length)][i]));
    return _transformGrid(baseGrid, rand);
  }

  List<List<int>> _transformGrid(List<List<int>> grid, Random rand) {
    List<List<int>> transformed = List.generate(9, (i) => List.from(grid[i]));

    // 1. 行のシャッフル（3x3ブロック内）
    for (int block = 0; block < 3; block++) {
      List<int> rows = [block * 3, block * 3 + 1, block * 3 + 2]..shuffle(rand);
      List<List<int>> tempBlock = List.generate(3, (i) => List.from(transformed[rows[i]]));
      for (int i = 0; i < 3; i++) {
        transformed[block * 3 + i] = tempBlock[i];
      }
    }

    // 2. 列のシャッフル（3x3ブロック内）
    for (int block = 0; block < 3; block++) {
      List<int> cols = [block * 3, block * 3 + 1, block * 3 + 2]..shuffle(rand);
      List<List<int>> temp = List.generate(9, (i) => List.from(transformed[i]));
      for (int row = 0; row < 9; row++) {
        for (int i = 0; i < 3; i++) {
          temp[row][block * 3 + i] = transformed[row][cols[i]];
        }
      }
      transformed = temp;
    }

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
    List<List<int>> initialGrid = List.generate(9, (i) => List.filled(9, 0));
    List<int> positions = List.generate(81, (i) => i)..shuffle(rand);
    int cellsToFill = visibleCellCount;

    for (int i = 0; i < 81 && cellsToFill > 0; i++) {
      int idx = positions[i];
      int row = idx ~/ 9;
      int col = idx % 9;
      int value = grid[row][col];
      initialGrid[row][col] = value;
      if (_isValidInitialGrid(initialGrid)) {
        cellsToFill--;
      } else {
        initialGrid[row][col] = 0;
      }
    }

    return initialGrid;
  }

  bool _isValidPuzzle(List<List<int>> initialGrid, List<List<int>> fullGrid) {
    // 1. initialGridの重複チェック
    for (int i = 0; i < 9; i++) {
      Map<int, int> rowCount = {};
      for (int j = 0; j < 9; j++) {
        if (initialGrid[i][j] != 0) {
          if (rowCount[initialGrid[i][j]] != null) {
            print('行 $i で重複: ${initialGrid[i][j]}');
            return false;
          }
          rowCount[initialGrid[i][j]] = 1;
        }
      }
      Map<int, int> colCount = {};
      for (int j = 0; j < 9; j++) {
        if (initialGrid[j][i] != 0) {
          if (colCount[initialGrid[j][i]] != null) {
            print('列 $i で重複: ${initialGrid[j][i]}');
            return false;
          }
          colCount[initialGrid[j][i]] = 1;
        }
      }
    }

    for (int blockRow = 0; blockRow < 3; blockRow++) {
      for (int blockCol = 0; blockCol < 3; blockCol++) {
        Map<int, int> blockCount = {};
        for (int i = 0; i < 3; i++) {
          for (int j = 0; j < 3; j++) {
            int value = initialGrid[blockRow * 3 + i][blockCol * 3 + j];
            if (value != 0) {
              if (blockCount[value] != null) {
                print('3x3ブロック ($blockRow, $blockCol) で重複: $value');
                return false;
              }
              blockCount[value] = 1;
            }
          }
        }
      }
    }

    // 2. 表示セル数の確認
    int visibleCount = initialGrid.expand((row) => row).where((cell) => cell != 0).length;
    int expectedCount = visibleCount == 17 ? 17 : visibleCount == 25 ? 25 : 30;
    if (visibleCount != expectedCount) {
      print('表示セル数不一致: 期待値 $expectedCount, 実際 $visibleCount');
      return false;
    }

    // 3. fullGridが有効か確認
    if (!_isValidFullGrid(fullGrid)) {
      return false;
    }

    return true;
  }

  bool _isValidFullGrid(List<List<int>> grid) {
    for (int i = 0; i < 9; i++) {
      Map<int, int> rowCount = {};
      Map<int, int> colCount = {};
      for (int j = 0; j < 9; j++) {
        if (grid[i][j] == 0 || grid[i][j] < 1 || grid[i][j] > 9) {
          print('fullGridに無効な値: ($i, $j), 値: ${grid[i][j]}');
          return false;
        }
        if (rowCount[grid[i][j]] != null) {
          print('fullGrid 行 $i で重複: ${grid[i][j]}');
          return false;
        }
        rowCount[grid[i][j]] = 1;
        if (colCount[grid[j][i]] != null) {
          print('fullGrid 列 $i で重複: ${grid[j][i]}');
          return false;
        }
        colCount[grid[j][i]] = 1;
      }
    }

    for (int blockRow = 0; blockRow < 3; blockRow++) {
      for (int blockCol = 0; blockCol < 3; blockCol++) {
        Map<int, int> blockCount = {};
        for (int i = 0; i < 3; i++) {
          for (int j = 0; j < 3; j++) {
            int value = grid[blockRow * 3 + i][blockCol * 3 + j];
            if (blockCount[value] != null) {
              print('fullGrid 3x3ブロック ($blockRow, $blockCol) で重複: $value');
              return false;
            }
            blockCount[value] = 1;
          }
        }
      }
    }

    return true;
  }

  bool _isValidInitialGrid(List<List<int>> grid) {
    for (int i = 0; i < 9; i++) {
      Map<int, int> rowCount = {};
      for (int j = 0; j < 9; j++) {
        if (grid[i][j] != 0) {
          if (rowCount[grid[i][j]] != null) return false;
          rowCount[grid[i][j]] = 1;
        }
      }
      Map<int, int> colCount = {};
      for (int j = 0; j < 9; j++) {
        if (grid[j][i] != 0) {
          if (colCount[grid[j][i]] != null) return false;
          colCount[grid[j][i]] = 1;
        }
      }
    }

    for (int blockRow = 0; blockRow < 3; blockRow++) {
      for (int blockCol = 0; blockCol < 3; blockCol++) {
        Map<int, int> blockCount = {};
        for (int i = 0; i < 3; i++) {
          for (int j = 0; j < 3; j++) {
            int value = grid[blockRow * 3 + i][blockCol * 3 + j];
            if (value != 0) {
              if (blockCount[value] != null) return false;
              blockCount[value] = 1;
            }
          }
        }
      }
    }

    return true;
  }

  bool _isValidMove(List<List<int>> grid, int row, int col, int value) {
    for (int x = 0; x < 9; x++) {
      if (x != col && grid[row][x] == value) return false;
      if (x != row && grid[x][col] == value) return false;
    }
    int startRow = row - row % 3;
    int startCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if ((startRow + i != row || startCol + j != col) && grid[startRow + i][startCol + j] == value) return false;
      }
    }
    return true;
  }
}