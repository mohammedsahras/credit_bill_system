import 'package:flutter/material.dart';

import '../../domain/entities/card_entity.dart';
import '../widgets/card_item_widget.dart';

class CardDetailPage extends StatelessWidget {
  final CardEntity card;

  const CardDetailPage({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Card Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: CardItemWidget(
          card: card,
          height: 240,
          faceKey: const Key('cardDetailFace'),
        ),
      ),
    );
  }
}
