import 'package:flutter_test/flutter_test.dart';

import 'package:scheduler/models/work_session.dart';
import 'package:scheduler/models/break_entry.dart';

void main() {
  group('WorkSession model', () {
    test('workedDuration calculates correctly', () {
      final start = DateTime(2024, 1, 1, 9, 0, 0);
      final end = DateTime(2024, 1, 1, 17, 0, 0); // 8 hours elapsed

      final breakStart = DateTime(2024, 1, 1, 12, 0, 0);
      final breakEnd = DateTime(2024, 1, 1, 12, 30, 0); // 30 min break

      final session = WorkSession(
        id: 'test-1',
        startTime: start,
        endTime: end,
        breaks: [
          BreakEntry(startTime: breakStart, endTime: breakEnd),
        ],
      );

      // Expected: 8h - 30min = 7h30m
      expect(session.workedDuration, const Duration(hours: 7, minutes: 30));
    });

    test('isOnBreak returns true when last break has no endTime', () {
      final session = WorkSession(
        id: 'test-2',
        startTime: DateTime.now(),
        breaks: [
          BreakEntry(startTime: DateTime.now()),
        ],
      );
      expect(session.isOnBreak, isTrue);
    });

    test('isOnBreak returns false when all breaks are ended', () {
      final session = WorkSession(
        id: 'test-3',
        startTime: DateTime.now(),
        breaks: [
          BreakEntry(
            startTime: DateTime.now().subtract(const Duration(minutes: 10)),
            endTime: DateTime.now(),
          ),
        ],
      );
      expect(session.isOnBreak, isFalse);
    });

    test('workedDuration is zero or positive', () {
      final session = WorkSession(
        id: 'test-4',
        startTime: DateTime.now(),
      );
      expect(session.workedDuration.isNegative, isFalse);
    });
  });

  group('BreakEntry model', () {
    test('duration returns correct duration', () {
      final start = DateTime(2024, 1, 1, 12, 0, 0);
      final end = DateTime(2024, 1, 1, 12, 15, 0);
      final b = BreakEntry(startTime: start, endTime: end);
      expect(b.duration, const Duration(minutes: 15));
    });

    test('duration returns zero for active break', () {
      final b = BreakEntry(startTime: DateTime.now());
      expect(b.duration, Duration.zero);
    });

    test('isActive returns true when endTime is null', () {
      final b = BreakEntry(startTime: DateTime.now());
      expect(b.isActive, isTrue);
    });
  });
}
