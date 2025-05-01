class SudokuGrid {
  final List<List<int>> initialGrid;
  final List<List<int>> currentGrid;
  final List<List<int>> fullGrid;
  final int visibleCellCount;

  SudokuGrid({
    required this.initialGrid,
    required this.currentGrid,
    required this.fullGrid,
    required this.visibleCellCount,
  });

  bool isValidPuzzle() {
    int visibleCount = initialGrid.expand((row) => row).where((cell) => cell != 0).length;
    if (visibleCount != visibleCellCount) {
      print('表示セル数不一致: 期待値 $visibleCellCount, 実際 $visibleCount');
      return false;
    }

    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        int num = fullGrid[row][col];
        if (num == 0) continue;
        fullGrid[row][col] = 0;
        if (hasConflict(row, col, num, fullGrid)) {
          print('fullGridがルール違反: pos=($row, $col), num=$num');
          fullGrid[row][col] = num;
          return false;
        }
        fullGrid[row][col] = num;
      }
    }

    for (int i = 0; i < 9; i++) {
      Set<int> rowSet = {}, colSet = {};
      for (int j = 0; j < 9; j++) {
        if (initialGrid[i][j] != 0 && !rowSet.add(initialGrid[i][j])) {
          print('行 $i で重複: ${initialGrid[i][j]}');
          return false;
        }
        if (initialGrid[j][i] != 0 && !colSet.add(initialGrid[j][i])) {
          print('列 $i で重複: ${initialGrid[j][i]}');
          return false;
        }
      }
    }

    for (int blockRow = 0; blockRow < 3; blockRow++) {
      for (int blockCol = 0; blockCol < 3; blockCol++) {
        Set<int> blockSet = {};
        for (int i = 0; i < 3; i++) {
          for (int j = 0; j < 3; j++) {
            int value = initialGrid[blockRow * 3 + i][blockCol * 3 + j];
            if (value != 0 && !blockSet.add(value)) {
              print('3x3ブロック ($blockRow, $blockCol) で重複: $value');
              return false;
            }
          }
        }
      }
    }

    return true;
  }

  bool hasConflict(int row, int col, int num, List<List<int>> grid) {
    for (int x = 0; x < 9; x++) {
      if (x != col && grid[row][x] == num) return true;
    }
    for (int x = 0; x < 9; x++) {
      if (x != row && grid[x][col] == num) return true;
    }
    int startRow = row - row % 3, startCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if ((i + startRow != row || j + startCol != col) &&
            grid[i + startRow][j + startCol] == num) {
          return true;
        }
      }
    }
    return false;
  }
}