import 'package:flutter/material.dart';

class CardGradientPalette {
  static const List<LinearGradient> gradients = [
    // 0: Deep Navy / Midnight Blue
    LinearGradient(
      colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // 1: Obsidian Gold / Charcoal Gold
    LinearGradient(
      colors: [Color(0xFF1F1C2C), Color(0xFF928DAB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // 2: Royal Purple
    LinearGradient(
      colors: [Color(0xFF3A1C71), Color(0xFFD76D77), Color(0xFFFFAF7B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // 3: Emerald Jade
    LinearGradient(
      colors: [Color(0xFF134E5E), Color(0xFF71B280)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // 4: Sunset Crimson
    LinearGradient(
      colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  static LinearGradient getGradient(int index) {
    if (index >= 0 && index < gradients.length) {
      return gradients[index];
    }
    return gradients[0];
  }
}
