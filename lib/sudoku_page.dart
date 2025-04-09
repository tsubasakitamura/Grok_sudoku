import 'package:flutter/material.dart';
import 'dart:async';

class SudokuPage extends StatefulWidget {
  final int visibleCellCount;
  final List<List<int>> grid;
  final List<List<int>> initialGrid;
  final List<List<int>>? fullGrid;
  final void Function(int)? onClear;

  SudokuPage({
    required this.visibleCellCount,
    required this.grid,
    required this.initialGrid,
    this.fullGrid,
    this.onClear,
  });

  @override
  State<SudokuPage> createState() => _SudokuPageState();
}

class _SudokuPageState extends State<SudokuPage> {
  late List<List<int>> grid, initialGrid, fullGrid;
  String message = '';
  int? selectedRow, selectedCol;
  int mistakeCount = 0;
  int score = 0;
  Timer? timer;
  int elapsedSeconds = 0;
  int _hintUsed = 0;

  @override
  void initState() {
    super.initState();
    _resetState(); // 初期化を関数に切り出し
    startTimer();
  }

  void _resetState() {
    grid = List.generate(9, (i) => List.from(widget.grid[i]));
    initialGrid = List.generate(9, (i) => List.from(widget.initialGrid[i]));
    fullGrid = widget.fullGrid != null
        ? List.generate(9, (i) => List.from(widget.fullGrid![i]))
        : List.generate(9, (_) => List.filled(9, 0));
    message = '';
    selectedRow = null;
    selectedCol = null;
    mistakeCount = 0;
    score = 0;
    elapsedSeconds = 0;
    _hintUsed = 0; // ヒント状態を確実にリセット
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        elapsedSeconds++;
      });
    });
  }

  Map<int, int> getNumberCounts() {
    final counts = List.filled(10, 0);
    for (var row in grid) for (var val in row) if (val != 0) counts[val]++;
    return Map.fromIterables(List.generate(10, (i) => i), counts);
  }

  void updateCell(int row, int col, int value) {
    if (initialGrid[row][col] != 0) return;
    setState(() {
      grid[row][col] = value;
      if (value != 0 && !isValidMove(grid, row, col, value)) {
        mistakeCount++;
        message = 'ルール違反です！';
        if (mistakeCount >= 3) _showGameOverDialog();
      } else {
        if (isPuzzleComplete()) {
          timer?.cancel();
          score = 10000 - (elapsedSeconds * 5) - (mistakeCount * 50);
          message = 'おめでとう！スコア: $score';
          if (widget.onClear != null) widget.onClear!(score);
        } else {
          message = '';
        }
      }
    });
  }

  bool isValidMove(List<List<int>> board, int row, int col, int value) {
    for (int x = 0; x < 9; x++) {
      if ((x != col && board[row][x] == value) || (x != row && board[x][col] == value)) return false;
    }
    int startRow = row - row % 3, startCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if ((startRow + i != row || startCol + j != col) && board[startRow + i][startCol + j] == value) return false;
      }
    }
    return true;
  }

  bool isPuzzleComplete() {
    return grid.asMap().entries.every((rowEntry) {
      final i = rowEntry.key;
      final row = rowEntry.value;
      return row.asMap().entries.every((colEntry) {
        final j = colEntry.key;
        final val = colEntry.value;
        return val != 0 && isValidMove(grid, i, j, val);
      });
    });
  }

  void _showGameOverDialog() => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: Text('ゲームオーバー'),
      content: Text('3回間違えました。どうしますか？'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
          child: Text('戻る'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              mistakeCount--;
              message = 'ミス回数が減りました';
            });
            Navigator.pop(context);
          },
          child: Text('動画を見てミスを1回減らす'),
        ),
      ],
    ),
  );

  void selectCell(int row, int col) => (initialGrid[row][col] == 0 || grid[row][col] != 0) ? setState(() { selectedRow = row; selectedCol = col; }) : null;

  String getDifficultyText() => {30: '簡単', 25: '普通', 17: '難しい'}[widget.visibleCellCount] ?? '不明';

  Future<bool> _handlePop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('本当にもどりますか？'),
        content: Text('現在の内容は破棄されます'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('いいえ')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('はい')),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  void _autoSolve() {
    setState(() {
      if (widget.fullGrid != null) {
        for (int i = 0; i < 9; i++) {
          for (int j = 0; j < 9; j++) {
            grid[i][j] = fullGrid[i][j];
          }
        }
        timer?.cancel();
        score = 10000 - (elapsedSeconds * 5) - (mistakeCount * 50);
        message = '自動解決！スコア: $score';
      } else {
        message = '完全な解がありません';
      }
    });
  }

  void _useHint() {
    setState(() {
      if (_hintUsed == 0) {
        if (selectedRow == null || selectedCol == null) {
          message = 'セルを選択してください';
          return;
        }
        if (widget.fullGrid == null) {
          message = 'ヒントが利用できません';
          return;
        }
        if (initialGrid[selectedRow!][selectedCol!] != 0) {
          message = 'このセルは変更できません';
          return;
        }

        grid[selectedRow!][selectedCol!] = fullGrid[selectedRow!][selectedCol!];
        _hintUsed = 1;
        message = 'ヒントを使用しました';

        if (isPuzzleComplete()) {
          timer?.cancel();
          score = 10000 - (elapsedSeconds * 5) - (mistakeCount * 50);
          message = 'おめでとう！スコア: $score';
          if (widget.onClear != null) widget.onClear!(score);
        }
      } else if (_hintUsed >= 1) {
        message = '広告を見てヒントを再利用します';
        Future.delayed(Duration(seconds: 2), () {
          setState(() {
            _hintUsed = 0;
            message = 'ヒントが再利用可能になりました';
          });
        });
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top;
    final buttonWidth = (screenWidth - 40) / 5;
    final gridSize = screenWidth * 0.9;
    final counts = getNumberCounts();
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handlePop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('ナンプレ（${getDifficultyText()}）', style: TextStyle(fontSize: 20)),
          centerTitle: true,
          actions: [
            GestureDetector(
              onTap: _useHint,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _hintUsed == 0 ? Icons.lightbulb : Icons.lightbulb_outline,
                      color: _hintUsed == 0 ? Colors.black : Colors.grey,
                      size: 20,
                    ),
                    SizedBox(width: 4),
                    Text(
                      _hintUsed == 0 ? 'Hint' : 'AD',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _hintUsed == 0 ? Colors.black : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.play_arrow),
              onPressed: _autoSolve,
              tooltip: 'Solve',
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              height: screenHeight * 0.05,
              color: Colors.blueGrey[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('ミス: $mistakeCount/3', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text('経過時間: $minutes:${seconds.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text('スコア: $score', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Container(
              height: gridSize,
              width: gridSize,
              child: GridView.builder(
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 9),
                itemCount: 81,
                itemBuilder: (_, index) {
                  final row = index ~/ 9, col = index % 9;
                  final isFixed = initialGrid[row][col] != 0;
                  final isSelected = selectedRow == row && selectedCol == col;
                  final isHighlighted = selectedRow != null && selectedCol != null && grid[row][col] != 0 && grid[row][col] == grid[selectedRow!][selectedCol!] && !isSelected;

                  return GestureDetector(
                    onTap: () => selectCell(row, col),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(right: BorderSide(width: col == 2 || col == 5 ? 2 : 1), bottom: BorderSide(width: row == 2 || row == 5 ? 2 : 1), left: BorderSide(width: col == 0 ? 2 : 1), top: BorderSide(width: row == 0 ? 2 : 1)),
                        color: isSelected ? Colors.yellow[200] : isHighlighted ? Colors.lightGreen[100] : isFixed ? Colors.grey[300] : Colors.white,
                      ),
                      child: Center(child: Text(grid[row][col] == 0 ? '' : '${grid[row][col]}', style: TextStyle(fontSize: gridSize / 20, fontWeight: isFixed ? FontWeight.bold : FontWeight.normal, color: isFixed ? Colors.black : Colors.blue))),
                    ),
                  );
                },
              ),
            ),
            Container(height: screenHeight * 0.05, child: Center(child: Text(message, style: TextStyle(fontSize: 14, color: message.contains('おめでとう') ? Colors.green : message.contains('ルール違反') ? Colors.red : Colors.black)))),
            Container(
              height: screenHeight * 0.20,
              color: Colors.blueGrey[50],
              padding: EdgeInsets.symmetric(vertical: 2),
              child: isPuzzleComplete()
                  ? Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                  child: Text('戻る', style: TextStyle(fontSize: 16)),
                ),
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => _buildNumberButton(i + 1, counts[i + 1]! >= 9, buttonWidth))),
                  SizedBox(height: 2),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i) => _buildNumberButton(i + 6, counts[i + 6]! >= 9, buttonWidth)) + [_buildEraseButton(buttonWidth)]),
                ],
              ),
            ),
            Container(height: 50, width: double.infinity, color: Colors.grey[300], child: Center(child: Text('ここにバナー広告が入ります', style: TextStyle(fontSize: 14, color: Colors.black54)))),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberButton(int value, bool isDisabled, double width) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 1),
    child: SizedBox(
      width: width,
      height: width * 0.6,
      child: ElevatedButton(
        onPressed: selectedRow != null && selectedCol != null && !isDisabled ? () => updateCell(selectedRow!, selectedCol!, value) : null,
        style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), backgroundColor: isDisabled ? Colors.grey[400] : null),
        child: Text('$value', style: TextStyle(fontSize: width * 0.35)),
      ),
    ),
  );

  Widget _buildEraseButton(double width) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 1),
    child: SizedBox(
      width: width,
      height: width * 0.6,
      child: ElevatedButton(
        onPressed: selectedRow != null && selectedCol != null ? () => updateCell(selectedRow!, selectedCol!, 0) : null,
        style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
        child: Text('消', style: TextStyle(fontSize: width * 0.3)),
      ),
    ),
  );
}