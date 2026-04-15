import 'package:hive/hive.dart';
import 'break_entry.dart';

/// Represents a single work session.
/// Uses timestamp-based calculation: total = (endTime - startTime) - totalBreakTime
/// This means the timer works correctly even if the app is killed and restarted.
class WorkSession extends HiveObject {
  String id;
  DateTime startTime;
  DateTime? endTime;
  List<BreakEntry> breaks;

  WorkSession({
    required this.id,
    required this.startTime,
    this.endTime,
    List<BreakEntry>? breaks,
  }) : breaks = breaks ?? [];

  /// Whether this session is still running (not yet stopped).
  bool get isActive => endTime == null;

  /// Whether the user is currently on a break.
  bool get isOnBreak {
    if (breaks.isEmpty) return false;
    return breaks.last.isActive;
  }

  /// Total break time accumulated in this session.
  Duration get totalBreakDuration {
    Duration total = Duration.zero;
    for (final b in breaks) {
      if (b.endTime != null) {
        total += b.endTime!.difference(b.startTime);
      } else {
        // Active break: count from break start to now
        total += DateTime.now().difference(b.startTime);
      }
    }
    return total;
  }

  /// Total worked time = elapsed - breaks.
  /// For active sessions, uses current time as end time.
  Duration get workedDuration {
    final end = endTime ?? DateTime.now();
    final elapsed = end.difference(startTime);
    // Clamp to avoid negative durations from clock drift
    final worked = elapsed - totalBreakDuration;
    return worked.isNegative ? Duration.zero : worked;
  }
}

/// Manual Hive TypeAdapter for WorkSession (typeId = 0).
class WorkSessionAdapter extends TypeAdapter<WorkSession> {
  @override
  final int typeId = 0;

  @override
  WorkSession read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numFields; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return WorkSession(
      id: fields[0] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(fields[1] as int),
      endTime: fields[2] != null
          ? DateTime.fromMillisecondsSinceEpoch(fields[2] as int)
          : null,
      breaks: (fields[3] as List?)
              ?.whereType<BreakEntry>()
              .toList() ??
          [],
    );
  }

  @override
  void write(BinaryWriter writer, WorkSession obj) {
    writer.writeByte(4); // 4 fields
    writer.writeByte(0);
    writer.writeString(obj.id);
    writer.writeByte(1);
    writer.writeInt(obj.startTime.millisecondsSinceEpoch);
    writer.writeByte(2);
    // Use write(null) for nullable fields – Hive encodes null as a typed null value
    writer.write(
        obj.endTime != null ? obj.endTime!.millisecondsSinceEpoch : null);
    writer.writeByte(3);
    writer.writeList(obj.breaks);
  }
}
