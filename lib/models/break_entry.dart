import 'package:hive/hive.dart';

/// Represents a single break interval within a work session.
/// Stores start and optional end time (null = break still active).
class BreakEntry extends HiveObject {
  DateTime startTime;
  DateTime? endTime;

  BreakEntry({required this.startTime, this.endTime});

  /// Duration of this break. Returns Duration.zero if break is ongoing.
  Duration get duration {
    if (endTime == null) return Duration.zero;
    return endTime!.difference(startTime);
  }

  /// Whether this break is currently active (not yet ended).
  bool get isActive => endTime == null;
}

/// Manual Hive TypeAdapter for BreakEntry (typeId = 1).
/// Avoids the need for build_runner code generation.
class BreakEntryAdapter extends TypeAdapter<BreakEntry> {
  @override
  final int typeId = 1;

  @override
  BreakEntry read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numFields; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return BreakEntry(
      startTime: DateTime.fromMillisecondsSinceEpoch(fields[0] as int),
      endTime: fields[1] != null
          ? DateTime.fromMillisecondsSinceEpoch(fields[1] as int)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, BreakEntry obj) {
    writer.writeByte(2); // 2 fields
    writer.writeByte(0);
    writer.writeInt(obj.startTime.millisecondsSinceEpoch);
    writer.writeByte(1);
    // Use write(null) for nullable fields – Hive encodes null as a typed null value
    writer.write(
        obj.endTime != null ? obj.endTime!.millisecondsSinceEpoch : null);
  }
}
