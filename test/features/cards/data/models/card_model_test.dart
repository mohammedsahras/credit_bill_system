import 'package:flutter_test/flutter_test.dart';
import 'package:credit_bill_system/features/cards/data/models/card_model.dart';
import 'package:credit_bill_system/features/cards/domain/entities/card_entity.dart';

void main() {
  final testDate = DateTime.parse('2026-10-13T10:00:00Z');

  final testCardModel = CardModel(
    id: 'test-uuid-1',
    bankName: 'HDFC Bank',
    nickname: 'Millennia',
    lastFour: '4821',
    network: 'Visa',
    totalLimit: 150000.0,
    billingDay: 12,
    dueDay: 2,
    colorGradientIdx: 1,
    isArchived: false,
    createdAt: testDate,
  );

  final testCardMap = {
    'id': 'test-uuid-1',
    'bank_name': 'HDFC Bank',
    'nickname': 'Millennia',
    'last_four': '4821',
    'network': 'Visa',
    'total_limit': 150000.0,
    'billing_day': 12,
    'due_day': 2,
    'color_gradient_idx': 1,
    'is_archived': 0,
    'created_at': '2026-10-13T10:00:00.000Z',
  };

  group('CardModel', () {
    test('is a subclass of CardEntity', () {
      expect(testCardModel, isA<CardEntity>());
    });

    test('fromMap returns valid model', () {
      final result = CardModel.fromMap(testCardMap);
      expect(result.id, 'test-uuid-1');
      expect(result.bankName, 'HDFC Bank');
      expect(result.lastFour, '4821');
      expect(result.totalLimit, 150000.0);
      expect(result.isArchived, false);
    });

    test('toMap converts model to Map with correct keys and zero CVV/PAN', () {
      final map = testCardModel.toMap();
      expect(map['id'], 'test-uuid-1');
      expect(map['bank_name'], 'HDFC Bank');
      expect(map['last_four'], '4821');
      expect(map['is_archived'], 0);
      expect(map.containsKey('cvv'), false);
      expect(map.containsKey('pan'), false);
      expect(map.containsKey('card_number'), false);
    });

    test('fromEntity converts entity to model', () {
      final result = CardModel.fromEntity(testCardModel);
      expect(result, equals(testCardModel));
    });
  });
}
