import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'views/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontFamily: 'NotoSansJP'),
          titleLarge: TextStyle(fontFamily: 'NotoSansJP'),
          labelLarge: TextStyle(fontFamily: 'NotoSansJP'),
        ),
        appBarTheme: AppBarTheme(
          titleTextStyle: TextStyle(fontFamily: 'NotoSansJP', fontSize: 24, color: Colors.white),
        ),
      ),
      home: HomePage(),
    );
  }
}

// lib/
// ├── main.dart
// ├── models/
// │   ├── sudoku_grid.dart       # ナンプレ盤面のデータ構造
// │   ├── game_stats.dart        # クリア回数やハイスコアのデータ
// │   ├── difficulty.dart        # 難易度設定
// ├── viewmodels/
// │   ├── home_viewmodel.dart    # ホーム画面のロジック
// │   ├── sudoku_viewmodel.dart  # ゲーム画面のロジック
// ├── views/
// │   ├── home_page.dart         # ホーム画面のUI
// │   ├── sudoku_page.dart       # ゲーム画面のUI
// ├── services/
// │   ├── ad_service.dart        # 広告管理
// │   ├── storage_service.dart   # データ永続化（SharedPreferences）
// ├── utils/
// │   ├── sudoku_generator.dart  # ナンプレ盤面生成ロジック
// │   ├── constants.dart         # 定数（広告ID、キャッシュサイズなど）