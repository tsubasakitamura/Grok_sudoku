import 'package:flutter/material.dart';
import 'home_page.dart';

void main() => runApp(SudokuApp());

class SudokuApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ナンプレアプリ',
    theme: ThemeData(primarySwatch: Colors.blue, scaffoldBackgroundColor: Colors.grey[100]),
    home: HomePage(),
  );
}