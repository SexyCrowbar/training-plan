import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/features/templates/templates_screen.dart';

void main() {
  group('uniqueCopyName', () {
    test('returns "<base> copy" when no collision', () {
      expect(uniqueCopyName('Push A', {}), 'Push A copy');
    });

    test('returns "<base> copy 2" when "<base> copy" already exists', () {
      expect(uniqueCopyName('Push A', {'Push A copy'}), 'Push A copy 2');
    });

    test('increments suffix until unique', () {
      expect(
        uniqueCopyName('Push A', {'Push A copy', 'Push A copy 2'}),
        'Push A copy 3',
      );
    });

    test('returns "<base> copy" when only unrelated names exist', () {
      expect(uniqueCopyName('Push A', {'Push B copy', 'Other'}), 'Push A copy');
    });

    test('handles gap in numbering — picks the next unused number', () {
      // "Push A copy 2" is missing: still picks "Push A copy 2"
      expect(
        uniqueCopyName('Push A', {'Push A copy', 'Push A copy 3'}),
        'Push A copy 2',
      );
    });

    test('works with empty base name', () {
      expect(uniqueCopyName('', {}), ' copy');
    });
  });
}
