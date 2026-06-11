import 'package:financial_tracker/src/core/goal_funding.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('goalFundingKey', () {
    test('joins type and id', () {
      expect(goalFundingKey('savings', 'a1'), 'savings:a1');
      expect(goalFundingKey('investment', 'x9'), 'investment:x9');
    });
  });

  group('allocateLinkedGoals', () {
    test('manual goals (null fundingKey) are skipped', () {
      final out = allocateLinkedGoals(
        goals: [(id: 'g1', target: 1000, fundingKey: null)],
        assetValues: {'savings:a': 500},
      );
      expect(out, isEmpty);
    });

    test('single goal on one asset gets full asset value capped at target',
        () {
      final out = allocateLinkedGoals(
        goals: [(id: 'g1', target: 10_000_000, fundingKey: 'savings:a')],
        assetValues: {'savings:a': 4_000_000},
      );
      expect(out['g1'], 4_000_000);

      final capped = allocateLinkedGoals(
        goals: [(id: 'g1', target: 10_000_000, fundingKey: 'savings:a')],
        assetValues: {'savings:a': 15_000_000},
      );
      expect(capped['g1'], 10_000_000);
    });

    test('two goals share one asset proportionally by target', () {
      // Aset 10jt; A target 20jt, B target 30jt → A 4jt, B 6jt.
      final out = allocateLinkedGoals(
        goals: [
          (id: 'a', target: 20_000_000, fundingKey: 'investment:i1'),
          (id: 'b', target: 30_000_000, fundingKey: 'investment:i1'),
        ],
        assetValues: {'investment:i1': 10_000_000},
      );
      expect(out['a'], 4_000_000);
      expect(out['b'], 6_000_000);
    });

    test('shares are capped at each target when asset exceeds total', () {
      final out = allocateLinkedGoals(
        goals: [
          (id: 'a', target: 20_000_000, fundingKey: 'savings:s1'),
          (id: 'b', target: 30_000_000, fundingKey: 'savings:s1'),
        ],
        assetValues: {'savings:s1': 100_000_000},
      );
      expect(out['a'], 20_000_000);
      expect(out['b'], 30_000_000);
    });

    test('missing asset yields 0 for its goals', () {
      final out = allocateLinkedGoals(
        goals: [(id: 'a', target: 5_000_000, fundingKey: 'savings:gone')],
        assetValues: {},
      );
      expect(out['a'], 0);
    });

    test('zero-target goal yields 0 without dividing by zero', () {
      final out = allocateLinkedGoals(
        goals: [
          (id: 'a', target: 0, fundingKey: 'savings:s1'),
          (id: 'b', target: 1_000_000, fundingKey: 'savings:s1'),
        ],
        assetValues: {'savings:s1': 500_000},
      );
      expect(out['a'], 0);
      expect(out['b'], 500_000);
    });

    test('goals on different assets are independent', () {
      final out = allocateLinkedGoals(
        goals: [
          (id: 'a', target: 10_000_000, fundingKey: 'savings:s1'),
          (id: 'b', target: 10_000_000, fundingKey: 'investment:i1'),
        ],
        assetValues: {'savings:s1': 2_000_000, 'investment:i1': 7_000_000},
      );
      expect(out['a'], 2_000_000);
      expect(out['b'], 7_000_000);
    });

    test('large rupiah values do not overflow', () {
      final out = allocateLinkedGoals(
        goals: [
          (id: 'a', target: 3_000_000_000, fundingKey: 'savings:s1'),
          (id: 'b', target: 2_000_000_000, fundingKey: 'savings:s1'),
        ],
        assetValues: {'savings:s1': 4_000_000_000},
      );
      expect(out['a'], 2_400_000_000);
      expect(out['b'], 1_600_000_000);
    });
  });
}
