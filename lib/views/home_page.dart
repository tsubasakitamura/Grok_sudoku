import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../viewmodels/home_viewmodel.dart';
import '../models/difficulty.dart';
import '../services/ad_service.dart';
import '../services/storage_service.dart';
import 'sudoku_page.dart';

// DifficultyCard widget for animated difficulty selection
class DifficultyCard extends StatefulWidget {
  final Difficulty difficulty;
  final HomeViewModel viewModel;
  final BuildContext parentContext;

  DifficultyCard({
    required this.difficulty,
    required this.viewModel,
    required this.parentContext,
  });

  @override
  _DifficultyCardState createState() => _DifficultyCardState();
}

class _DifficultyCardState extends State<DifficultyCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150), // Short and natural animation
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward(); // Scale down
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse(); // Scale up
  }

  void _onTapCancel() {
    _controller.reverse(); // Scale up on cancel
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () async {
        showDialog(
          context: widget.parentContext,
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

        try {
          final grid = await widget.viewModel.generatePuzzle(widget.difficulty.visibleCellCount);
          if (!grid.isValidPuzzle()) {
            if (Navigator.of(widget.parentContext).canPop()) {
              Navigator.pop(widget.parentContext);
            }
            ScaffoldMessenger.of(widget.parentContext).showSnackBar(
              SnackBar(content: Text('有効な問題の生成に失敗しました')),
            );
            return;
          }
          if (Navigator.of(widget.parentContext).canPop()) {
            Navigator.pop(widget.parentContext);
          }
          Navigator.push(
            widget.parentContext,
            MaterialPageRoute(
              builder: (_) => SudokuPage(
                grid: grid,
                isChallengeMode: widget.viewModel.isChallengeMode,
                onClear: (score) => widget.viewModel.saveStats(widget.difficulty.visibleCellCount, score),
                homeViewModel: widget.viewModel,
              ),
            ),
          );
        } catch (e) {
          if (Navigator.of(widget.parentContext).canPop()) {
            Navigator.pop(widget.parentContext);
          }
          ScaffoldMessenger.of(widget.parentContext).showSnackBar(
            SnackBar(content: Text('問題生成に失敗しました: $e')),
          );
        }
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color.fromRGBO(255, 255, 255, 0.9),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: widget.difficulty.color, size: 28),
                  SizedBox(width: 10),
                  Text(
                    widget.difficulty.name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: widget.difficulty.color,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'クリア: ${widget.viewModel.gameStats.clearCounts[widget.difficulty.visibleCellCount]}回',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  Text(
                    'ハイスコア: ${widget.viewModel.gameStats.highScores[widget.difficulty.visibleCellCount]}',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late HomeViewModel _viewModel;
  late int _previousLevel;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _initAsync();
  }

  Future<void> _initAsync() async {
    _viewModel = HomeViewModel(StorageService(), AdService());
    await _viewModel.loadPlayerProgress();
    if (!_isMounted) return;

    _previousLevel = _viewModel.playerProgress.level;
    print('Initial level: ${_viewModel.playerProgress.level}, Previous level: $_previousLevel');

    _viewModel.setStateCallback((data) {
      if (_isMounted) {
        setState(() {
          if (data.containsKey('newLevel') && data['newLevel'] > _previousLevel) {
            _showLevelUpDialog(newLevel: data['newLevel']);
            _previousLevel = data['newLevel'];
            print('Level up detected: ${data['newLevel']}');
          }
        });
      }
    });

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  void _showLevelUpDialog({required int newLevel}) {
    _animationController.forward(from: 0.0);
    showDialog(
      context: context,
      builder: (_) => ScaleTransition(
        scale: _scaleAnimation,
        child: AlertDialog(
          backgroundColor: Colors.blue[100],
          title: Text(
            'レベルアップ！',
            style: TextStyle(
              fontFamily: 'NotoSansJP',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, color: Colors.yellow[600], size: 50),
              SizedBox(height: 10),
              Text(
                'レベル $newLevel に到達！',
                style: TextStyle(
                  fontFamily: 'NotoSansJP',
                  fontSize: 24,
                  color: Colors.blue[800],
                ),
              ),
              SizedBox(height: 10),
              Text(
                '次のレベルまであと ${1000 - _viewModel.playerProgress.experience} EXP',
                style: TextStyle(
                  fontFamily: 'NotoSansJP',
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'NotoSansJP',
                  fontSize: 22,
                  color: Colors.blue[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isMounted = false;
    _animationController.dispose();
    _viewModel.dispose();
    super.dispose();
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
            SizedBox(height: 40),
            Text(
              'ナンプレ',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'NotoSansJP',
                shadows: [
                  Shadow(blurRadius: 10, color: Colors.black45, offset: Offset(2, 2)),
                ],
              ),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Text(
                    'レベル: ${_viewModel.playerProgress.level}',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontFamily: 'NotoSansJP',
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(blurRadius: 2, color: Colors.black54, offset: Offset(1, 1)),
                      ],
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '経験値: ${_viewModel.playerProgress.experience}/1000',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      fontFamily: 'NotoSansJP',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 5),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.6,
                    child: LinearProgressIndicator(
                      value: _viewModel.playerProgress.experience / 1000,
                      backgroundColor: Colors.white30,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green[400]!),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Text(
              '難易度を選択してください',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
                fontFamily: 'NotoSansJP',
              ),
            ),
            SizedBox(height: 40),
            ...Difficulty.levels.map((difficulty) => Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: DifficultyCard(
                difficulty: difficulty,
                viewModel: _viewModel,
                parentContext: context,
              ),
            )),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'チャレンジモード：',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontFamily: 'NotoSansJP',
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(blurRadius: 2, color: Colors.black54, offset: Offset(1, 1)),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  Switch(
                    value: _viewModel.isChallengeMode,
                    onChanged: (value) {
                      _viewModel.toggleChallengeMode(value);
                    },
                    activeColor: Colors.green[400],
                    activeTrackColor: Colors.green[100],
                    inactiveThumbColor: Colors.grey[500],
                    inactiveTrackColor: Colors.grey[300],
                  ),
                  SizedBox(width: 10),
                  Text(
                    _viewModel.isChallengeMode ? 'オン' : 'オフ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'NotoSansJP',
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(blurRadius: 2, color: Colors.black54, offset: Offset(1, 1)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),
            if (_viewModel.isAdLoaded && _viewModel.bannerAd != null)
              Container(
                alignment: Alignment.center,
                width: _viewModel.bannerAd!.size.width.toDouble(),
                height: _viewModel.bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _viewModel.bannerAd!),
              ),
            SizedBox(height: 10),
          ],
        ),
      ),
    ),
  );
}