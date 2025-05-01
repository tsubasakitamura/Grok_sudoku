import 'dart:math';
import 'package:flutter/foundation.dart';

class SudokuGenerator {
  static final List<List<List<int>>> _fullGridCache = [];
  static const int maxCacheSize = 10;

  // generatePuzzleData をそのままにする
  static Map<String, List<List<int>>> generatePuzzleData(int visibleCellCount) {

    final rand = Random();
    try {
      List<List<int>> fullGrid;
      if (_fullGridCache.isNotEmpty && rand.nextDouble() < 0.7) {
        fullGrid = List.generate(
            9, (i) => List.from(_fullGridCache[rand.nextInt(_fullGridCache.length)][i]));
      } else {
        fullGrid = _generateFullGrid(rand);
        if (_fullGridCache.length < maxCacheSize) {
          _fullGridCache.add(List.generate(9, (i) => List.from(fullGrid[i])));
        }
      }

      List<List<int>> initialGrid = _createInitialGrid(fullGrid, visibleCellCount, rand);
      List<List<int>> grid = List.generate(9, (i) => List.from(initialGrid[i]));

      return {
        'grid': grid,
        'initialGrid': initialGrid,
        'fullGrid': fullGrid,
      };
    } catch (e, stackTrace) {
      print('PuzzleData生成エラー: $e\nスタックトレース: $stackTrace');
      rethrow;
    }
  }

  static List<List<int>> _generateFullGrid(Random rand) {
    List<List<int>> grid = List.generate(9, (_) => List.filled(9, 0));
    try {
      _fillGrid(grid, rand);
      _shuffleRows(grid, rand);
      _shuffleCols(grid, rand);
      _swapNumbers(grid, rand);
      print('フルグリッド生成成功');
      return grid;
    } catch (e, stackTrace) {
      print('フルグリッド生成エラー: $e\nスタックトレース: $stackTrace');
      throw Exception('フルグリッド生成に失敗しました');
    }
  }

  static bool _fillGrid(List<List<int>> grid, Random rand) {
    List<int> numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (grid[row][col] != 0) continue;
        numbers.shuffle(rand);
        for (int num in numbers) {
          if (_canPlaceNumber(grid, row, col, num)) {
            grid[row][col] = num;
            if (_fillGrid(grid, rand)) return true;
            grid[row][col] = 0;
          }
        }
        return false;
      }
    }
    return true;
  }

  static void _shuffleRows(List<List<int>> grid, Random rand) {
    for (int block = 0; block < 3; block++) {
      List<int> indices = [block * 3, block * 3 + 1, block * 3 + 2];
      indices.shuffle(rand);
      List<List<int>> temp = List.generate(3, (_) => List.filled(9, 0));
      for (int i = 0; i < 3; i++) temp[i] = grid[block * 3 + i];
      for (int i = 0; i < 3; i++) grid[block * 3 + i] = temp[indices[i] - block * 3];
    }
  }

  static void _shuffleCols(List<List<int>> grid, Random rand) {
    for (int block = 0; block < 3; block++) {
      List<int> indices = [block * 3, block * 3 + 1, block * 3 + 2];
      indices.shuffle(rand);
      for (int i = 0; i < 9; i++) {
        List<int> temp = List.filled(3, 0);
        for (int j = 0; j < 3; j++) temp[j] = grid[i][block * 3 + j];
        for (int j = 0; j < 3; j++) grid[i][block * 3 + j] = temp[indices[j] - block * 3];
      }
    }
  }

  static void _swapNumbers(List<List<int>> grid, Random rand) {
    int num1 = rand.nextInt(9) + 1;
    int num2 = rand.nextInt(9) + 1;
    while (num1 == num2) num2 = rand.nextInt(9) + 1;
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (grid[i][j] == num1) grid[i][j] = num2;
        else if (grid[i][j] == num2) grid[i][j] = num1;
      }
    }
  }

  static bool _canPlaceNumber(List<List<int>> grid, int row, int col, int num) {
    for (int x = 0; x < 9; x++) if (grid[row][x] == num) return false;
    for (int x = 0; x < 9; x++) if (grid[x][col] == num) return false;
    int startRow = row - row % 3, startCol = col - col % 3;
    for (int i = 0; i < 3; i++)
      for (int j = 0; j < 3; j++)
        if (grid[i + startRow][j + startCol] == num) return false;
    return true;
  }

  static List<List<int>> _createInitialGrid(List<List<int>> fullGrid, int visibleCellCount, Random rand) {
    const int minCellsPerBlock = 1;
    const int maxCellsPerBlock = 7;
    final stopwatch = Stopwatch()..start();

    try {
      List<List<int>> initialGrid = List.generate(9, (_) => List.filled(9, 0));
      List<int> positions = List.generate(81, (i) => i);
      positions.shuffle(rand);

      List<bool> canPlaceCache = List.filled(81, true);
      for (int pos = 0; pos < 81; pos++) {
        int row = pos ~/ 9, col = pos % 9;
        if (initialGrid[row][col] != 0) {
          canPlaceCache[pos] = false;
          continue;
        }
        int num = fullGrid[row][col];
        initialGrid[row][col] = num;
        if (_hasConflict(initialGrid, row, col, num)) {
          canPlaceCache[pos] = false;
        }
        initialGrid[row][col] = 0;
      }

      List<int> selectedPositions = [];
      List<int> blockCells = List.filled(9, 0);

      for (int block = 0; block < 9; block++) {
        int blockRow = (block ~/ 3) * 3, blockCol = (block % 3) * 3;
        List<int> blockPositions = [];
        for (int i = 0; i < 3; i++)
          for (int j = 0; j < 3; j++) blockPositions.add((blockRow + i) * 9 + (blockCol + j));
        blockPositions.shuffle(rand);

        int placedInBlock = 0;
        for (int pos in blockPositions) {
          if (placedInBlock >= minCellsPerBlock) break;
          if (!canPlaceCache[pos]) continue;
          int row = pos ~/ 9, col = pos % 9;
          initialGrid[row][col] = fullGrid[row][col];
          selectedPositions.add(pos);
          blockCells[block]++;
          placedInBlock++;
          canPlaceCache[pos] = false;
        }
      }

      int cellsToPlace = visibleCellCount - selectedPositions.length;
      positions.removeWhere((pos) => selectedPositions.contains(pos));
      positions.shuffle(rand);

      for (int pos in positions) {
        if (cellsToPlace <= 0) break;
        if (!canPlaceCache[pos]) continue;
        int row = pos ~/ 9, col = pos % 9;
        int block = (row ~/ 3) * 3 + (col ~/ 3);
        if (blockCells[block] >= maxCellsPerBlock) continue;

        initialGrid[row][col] = fullGrid[row][col];
        selectedPositions.add(pos);
        blockCells[block]++;
        cellsToPlace--;
        canPlaceCache[pos] = false;
      }

      int currentVisibleCount = selectedPositions.length;
      if (currentVisibleCount < visibleCellCount) {
        positions.removeWhere((pos) => selectedPositions.contains(pos));
        positions.shuffle(rand);
        while (currentVisibleCount < visibleCellCount && positions.isNotEmpty) {
          int pos = positions.removeAt(0);
          if (!canPlaceCache[pos]) continue;
          int row = pos ~/ 9, col = pos % 9;
          int block = (row ~/ 3) * 3 + (col ~/ 3);
          if (blockCells[block] >= maxCellsPerBlock) continue;

          initialGrid[row][col] = fullGrid[row][col];
          selectedPositions.add(pos);
          blockCells[block]++;
          currentVisibleCount++;
          canPlaceCache[pos] = false;
        }
      } else if (currentVisibleCount > visibleCellCount) {
        selectedPositions.shuffle(rand);
        while (currentVisibleCount > visibleCellCount) {
          int pos = selectedPositions.removeLast();
          int row = pos ~/ 9, col = pos % 9;
          int block = (row ~/ 3) * 3 + (col ~/ 3);
          if (blockCells[block] <= minCellsPerBlock) {
            selectedPositions.add(pos);
            continue;
          }
          initialGrid[row][col] = 0;
          blockCells[block]--;
          currentVisibleCount--;
        }
      }

      print(
          '初期グリッド生成成功: visibleCellCount=$visibleCellCount, 時間=${stopwatch.elapsedMilliseconds}ms, ブロック表示セル数=$blockCells');
      return initialGrid;
    } catch (e, stackTrace) {
      print('InitialGrid生成エラー: $e\nスタックトレース: $stackTrace');
      throw Exception('初期グリッド生成に失敗しました: visibleCellCount=$visibleCellCount');
    }
  }

  static bool _hasConflict(List<List<int>> grid, int row, int col, int num) {
    for (int x = 0; x < 9; x++) if (x != col && grid[row][x] == num) return true;
    for (int x = 0; x < 9; x++) if (x != row && grid[x][col] == num) return true;
    int startRow = row - row % 3, startCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if ((i + startRow != row || j + startCol != col) && grid[i + startRow][j + startCol] == num) {
          return true;
        }
      }
    }
    return false;
  }
}