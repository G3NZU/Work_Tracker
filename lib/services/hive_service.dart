import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/break_entry.dart';
import '../models/work_session.dart';

/// Manages Hive initialization and box access.
/// Call [init] once at app startup before accessing any boxes.
class HiveService {
  static const String _sessionsBoxName = 'work_sessions';

  /// Initialize Hive, register adapters, and open boxes.
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register manual TypeAdapters (no build_runner required)
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(WorkSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(BreakEntryAdapter());
    }

    try {
      await Hive.openBox<WorkSession>(_sessionsBoxName);
    } catch (_) {
      // Box is corrupted — manually delete the files and reopen fresh.
      final dir = await getApplicationDocumentsDirectory();
      for (final ext in ['.hive', '.lock']) {
        final file = File('${dir.path}/$_sessionsBoxName$ext');
        if (await file.exists()) await file.delete();
      }
      await Hive.openBox<WorkSession>(_sessionsBoxName);
    }
  }

  /// Returns the sessions box. Must be opened first via [init].
  static Box<WorkSession> get sessionsBox =>
      Hive.box<WorkSession>(_sessionsBoxName);

  /// Save or update a session in the box (uses session.id as key).
  static Future<void> saveSession(WorkSession session) async {
    await sessionsBox.put(session.id, session);
  }

  /// Delete a session by id.
  static Future<void> deleteSession(String id) async {
    await sessionsBox.delete(id);
  }

  /// Get all sessions sorted by start time descending.
  static List<WorkSession> getAllSessions() {
    final sessions = sessionsBox.values.toList();
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    return sessions;
  }

  /// Flush all open boxes to disk. Call this when the app is about to be
  /// backgrounded or closed to ensure no pending writes are lost.
  static Future<void> flushAll() async {
    if (Hive.isBoxOpen(_sessionsBoxName)) {
      await sessionsBox.flush();
    }
  }

  /// Get the active session (if any). At most one session should be active.
  static WorkSession? getActiveSession() {
    try {
      return sessionsBox.values.firstWhere((s) => s.isActive);
    } catch (_) {
      return null;
    }
  }
}
