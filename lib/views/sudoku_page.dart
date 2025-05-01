import 'dart:async';
import 'package:flutter/material.dart';
import '../viewmodels/sudoku_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../models/sudoku_grid.dart';
import '../services/ad_service.dart';

class SudokuPage extends StatefulWidget {
  final SudokuGrid grid;
  final bool isChallengeMode;
  final Function(int) onClear;
  final HomeViewModel homeViewModel;

  SudokuPage({
    required this.grid,
    required this.isChallengeMode,
    required this.onClear,
    required this.homeViewModel,
  });

  @override
  _SudokuPageState createState() => _SudokuPageState();
}

class _SudokuPageState extends State<SudokuPage> {
  late SudokuViewModel _viewModel;
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();
    _viewModel = SudokuViewModel(
      sudokuGrid: widget.grid,
      isChallengeMode: widget.isChallengeMode,
      onClear: widget.onClear,
      adService: AdService(),
      homeViewModel: widget.homeViewModel,
    );
    if (widget.isChallengeMode) {
      _uiTimer = Timer.periodic(Duration(seconds: 1), (_) {
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safeAreaPadding = MediaQuery.of(context).padding;
    final availableHeight = screenSize.height - 40 - safeAreaPadding.top - safeAreaPadding.bottom;
    final isLargeDevice = screenSize.height >= 800 || screenSize.width >= 600;
    final gridRatio = isLargeDevice ? 0.7 : 0.6;
    final minButtonHeight = isLargeDevice ? 80.0 : 60.0;
    final maxGridSize = (availableHeight - 28 - minButtonHeight) * gridRatio;
    final gridSize = (screenSize.width < maxGridSize ? screenSize.width : maxGridSize) * 0.9;

    _viewModel.updateGridSize(gridSize);

    return Scaffold(
      backgroundColor: Colors.blue[300],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(40),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
          child: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white, size: 20),
              padding: EdgeInsets.all(4),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(
                      '本当に戻ってもよろしいですか？',
                      style: TextStyle(
                        fontFamily: 'NotoSansJP',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: Text(
                      '現在の内容は破棄されます',
                      style: TextStyle(
                        fontFamily: 'NotoSansJP',
                        fontSize: 20,
                        height: 1.3,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'やめる',
                          style: TextStyle(
                            fontFamily: 'NotoSansJP',
                            fontSize: 18,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: Text(
                          'OK',
                          style: TextStyle(
                            fontFamily: 'NotoSansJP',
                            fontSize: 18,
                            color: Colors.red[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                widget.isChallengeMode
                    ? Text('時間: ${_viewModel.formatTime(_viewModel.secondsElapsed)}',
                    style: TextStyle(fontSize: 18, color: Colors.white))
                    : SizedBox(width: 0),
                Text('ミス: ${_viewModel.missCount}/3', style: TextStyle(fontSize: 18, color: Colors.white)),
              ],
            ),
            centerTitle: false,
            backgroundColor: Colors.blue[900],
            elevation: 6,
            surfaceTintColor: Colors.transparent,
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[200]!, Colors.blue[600]!],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(height: gridSize * 0.015),
              Stack(
                children: [
                  SizedBox(
                    width: gridSize,
                    height: gridSize,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: GestureDetector(
                        child: Stack(
                          children: [
                            RepaintBoundary(
                              child: Container(
                                margin: EdgeInsets.all(gridSize * 0.02),
                                color: Colors.white,
                                child: GridView.builder(
                                  physics: NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 9,
                                    childAspectRatio: 1,
                                  ),
                                  itemCount: 81,
                                  itemBuilder: (context, index) {
                                    int row = index ~/ 9, col = index % 9;
                                    bool isSelected = row == _viewModel.selectedRow && col == _viewModel.selectedCol;
                                    bool isSameNumber = _viewModel.selectedRow != -1 &&
                                        _viewModel.selectedCol != -1 &&
                                        _viewModel.grid[row][col] != 0 &&
                                        _viewModel.grid[row][col] == _viewModel.grid[_viewModel.selectedRow][_viewModel.selectedCol];
                                    bool isMiss = _viewModel.isMiss[row][col];
                                    bool isHighlighted = false;

                                    if (_viewModel.selectedRow != -1 && _viewModel.selectedCol != -1 && !isSelected && !isSameNumber) {
                                      bool isSameRowOrCol = row == _viewModel.selectedRow || col == _viewModel.selectedCol;
                                      int startRow = (_viewModel.selectedRow ~/ 3) * 3;
                                      int startCol = (_viewModel.selectedCol ~/ 3) * 3;
                                      bool isInSameBlock = row >= startRow &&
                                          row < startRow + 3 &&
                                          col >= startCol &&
                                          col < startCol + 3;
                                      isHighlighted = isSameRowOrCol || isInSameBlock;
                                    }

                                    Color? cellColor = isMiss
                                        ? Colors.red[300]
                                        : isSelected
                                        ? Colors.yellow[300]
                                        : isSameNumber
                                        ? Colors.orange[200]
                                        : isHighlighted
                                        ? Colors.blue[100]
                                        : (row ~/ 3 + col ~/ 3) % 2 == 0
                                        ? Colors.grey[200]
                                        : Colors.white;

                                    return GestureDetector(
                                      onTap: () => setState(() => _viewModel.selectCell(row, col)),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            top: BorderSide(
                                              color: row % 3 == 0 ? Colors.black : Colors.grey[400]!,
                                              width: row % 3 == 0 ? 2 : 1,
                                            ),
                                            left: BorderSide(
                                              color: col % 3 == 0 ? Colors.black : Colors.grey[400]!,
                                              width: col % 3 == 0 ? 2 : 1,
                                            ),
                                            bottom: BorderSide(
                                              color: row == 8 ? Colors.black : Colors.grey[400]!,
                                              width: row == 8 ? 2 : 1,
                                            ),
                                            right: BorderSide(
                                              color: col == 8 ? Colors.black : Colors.grey[400]!,
                                              width: col == 8 ? 2 : 1,
                                            ),
                                          ),
                                          color: cellColor,
                                        ),
                                        child: Center(
                                          child: Text(
                                            _viewModel.grid[row][col] == 0 ? '' : _viewModel.grid[row][col].toString(),
                                            style: TextStyle(
                                              fontSize: gridSize / 18,
                                              fontWeight: _viewModel.isInitial[row][col] ? FontWeight.bold : FontWeight.normal,
                                              color: _viewModel.isInitial[row][col] ? Colors.black : Colors.blue[800],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            if (_viewModel.showMagnifier)
                              Positioned(
                                left: _viewModel.magnifierPosition.dx - gridSize * 0.35,
                                top: _viewModel.magnifierPosition.dy - gridSize * 0.5,
                                child: AnimatedOpacity(
                                  opacity: _viewModel.showMagnifier ? 1.0 : 0.0,
                                  duration: Duration(milliseconds: 100),
                                  curve: Curves.easeInOut,
                                  child: RawMagnifier(
                                    size: Size(gridSize * 0.7, gridSize * 0.7),
                                    focalPointOffset: Offset(0, 0),
                                    magnificationScale: _viewModel.magnificationScale,
                                    decoration: MagnifierDecoration(
                                      shape: CircleBorder(side: BorderSide(color: Colors.grey[400]!, width: 2)),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -gridSize * 0.01,
                    right: -gridSize * 0.01,
                    child: _buildMagnifierButton(gridSize),
                  ),
                ],
              ),
              SizedBox(height: gridSize * 0.015),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: gridSize * 0.01),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      constraints: BoxConstraints(maxWidth: gridSize * 0.95),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          mainAxisSpacing: gridSize * 0.005,
                          crossAxisSpacing: gridSize * 0.005,
                          children: List.generate(9, (index) {
                            int number = index + 1;
                            return _buildNumberButton(number, _viewModel.numberCounts[number] ?? 0);
                          }),
                        ),
                      ),
                    ),
                    SizedBox(height: gridSize * 0.015),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton('消す', () => setState(() => _viewModel.inputNumber(0, context))),
                        _buildHintButton(),
                        _buildActionButton('自動', () => setState(() => _viewModel.autoComplete(context))),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: gridSize * 0.015),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberButton(int number, int count) {
    bool isDisabled = count >= 9;
    bool isInitialSelected =
        _viewModel.selectedRow != -1 && _viewModel.selectedCol != -1 && _viewModel.isInitial[_viewModel.selectedRow][_viewModel.selectedCol];
    bool isPossible = !isInitialSelected && _viewModel.possibleNumbers[number] && !isDisabled;

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: ElevatedButton(
        onPressed: isDisabled ? null : () => setState(() => _viewModel.inputNumber(number, context)),
        style: ButtonStyle(
          padding: WidgetStateProperty.all(EdgeInsets.all(_viewModel.gridSize! * 0.015)),
          shape: WidgetStateProperty.all(CircleBorder()),
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
                (states) {
              if (isDisabled) return Colors.grey[400]!;
              if (isPossible) return Colors.yellow[200]!;
              return Colors.white;
            },
          ),
          elevation: WidgetStateProperty.all(4),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        ),
        child: Text(
          number.toString(),
          style: TextStyle(
            fontSize: _viewModel.gridSize! / 10,
            color: isDisabled ? Colors.grey[800] : Colors.blue[800],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2),
        height: _viewModel.gridSize! * 0.16,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ButtonStyle(
            padding: WidgetStateProperty.all(
                EdgeInsets.symmetric(horizontal: 4, vertical: _viewModel.gridSize! * 0.015)),
            shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            backgroundColor: WidgetStateProperty.all(Colors.white),
            elevation: WidgetStateProperty.all(4),
            surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: _viewModel.gridSize! / 16,
              color: Colors.blue[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMagnifierButton(double gridSize) {
    return Tooltip(
      message: _viewModel.showMagnifier ? '縮小' : '拡大',
      child: SizedBox(
        width: gridSize * 0.09,
        height: gridSize * 0.09,
        child: ElevatedButton(
          onPressed: () => setState(() => _viewModel.toggleMagnifier(gridSize)),
          style: ButtonStyle(
            padding: WidgetStateProperty.all(EdgeInsets.all(gridSize * 0.015)),
            shape: WidgetStateProperty.all(
              CircleBorder(side: BorderSide(color: Colors.grey[400]!, width: 1)),
            ),
            backgroundColor: WidgetStateProperty.all(
              _viewModel.showMagnifier ? Colors.yellow[200] : Colors.white,
            ),
            elevation: WidgetStateProperty.all(5),
            surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          ),
          child: Icon(
            _viewModel.showMagnifier ? Icons.zoom_out : Icons.zoom_in,
            size: gridSize / 18,
            color: Colors.blue[800],
          ),
        ),
      ),
    );
  }

  Widget _buildHintButton() {
    bool isHintEnabled = _viewModel.selectedRow != -1 &&
        _viewModel.selectedCol != -1 &&
        !_viewModel.isInitial[_viewModel.selectedRow][_viewModel.selectedCol];
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2),
        height: _viewModel.gridSize! * 0.16,
        child: ElevatedButton(
          onPressed: isHintEnabled ? () => setState(() => _viewModel.useHint(context)) : null,
          style: ButtonStyle(
            padding: WidgetStateProperty.all(
                EdgeInsets.symmetric(horizontal: 4, vertical: _viewModel.gridSize! * 0.015)),
            shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            backgroundColor: WidgetStateProperty.resolveWith<Color>(
                  (states) => isHintEnabled ? Colors.white : Colors.grey[300]!,
            ),
            elevation: WidgetStateProperty.all(4),
            surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          ),
          child: Text(
            _viewModel.hintUsed ? '広告で\nヒント' : 'ヒント',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: _viewModel.hintUsed ? _viewModel.gridSize! / 20 : _viewModel.gridSize! / 16,
              color: isHintEnabled ? Colors.blue[800] : Colors.grey[600],
              fontWeight: FontWeight.bold,
              height: _viewModel.hintUsed ? 1.2 : 1.0,
            ),
          ),
        ),
      ),
    );
  }
}