import 'package:flutter/material.dart';

class Difficulty {
  final String name;
  final Color color;
  final int visibleCellCount;

  Difficulty({
    required this.name,
    required this.color,
    required this.visibleCellCount,
  });

  static final List<Difficulty> levels = [
    Difficulty(name: '簡単', color: Colors.green, visibleCellCount: 40),
    Difficulty(name: '普通', color: Colors.orange, visibleCellCount: 30),
    Difficulty(name: '難しい', color: Colors.red, visibleCellCount: 25),
    Difficulty(name: '超難しい', color: Colors.purple, visibleCellCount: 17),
  ];
}