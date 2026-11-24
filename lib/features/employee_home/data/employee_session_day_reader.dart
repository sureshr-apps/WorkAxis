import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workaxis/core/time/business_time.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/features/attendance/data/attendance_entry_mapper.dart';
import 'package:workaxis/features/attendance/domain/models/attendance_entry.dart';

/// One of the signed-in user's own `attendance_entries` documents.
class SessionDayEntry {
  const SessionDayEntry(this.id, this.data);

  final String id;
  final Map<String, dynamic> data;

  DateTime? get checkInAt => AttendanceEntryMapper.instant(data['checkInAt']);
  DateTime? get checkOutAt => AttendanceEntryMapper.instant(data['checkOutAt']);

  /// The shift date the server filed the session under.
  String? get workDateKey {
    final key = data['workDateString'];
    return key is String ? key : null;
  }

  /// The system closed the session at its maximum length; no check-out was
  /// recorded (and none is invented).
  bool get closedWithoutCheckOut =>
      data['sessionClosure'] is Map && checkOutAt == null;

  /// Whether the session is still open. The server's `open` flag wins; older
  /// documents without it count as open while checked in and not closed.
  bool get isOpen {
    if (checkInAt == null || checkOutAt != null) return false;
    final flag = data['open'];
    if (flag is bool) return flag;
    return data['sessionClosure'] == null;
  }

  AttendanceEntry toAttendanceEntry() =>
      AttendanceEntryMapper.fromData(id, data);
}

/// The sessions of the shift day Employee Home describes, oldest first.
///
/// While a session is open this is the day that session belongs to: a night
/// shift started yesterday stays on yesterday after midnight. Otherwise it
/// is today's business day.
class SessionDay {
  const SessionDay({required this.dayKey, required this.entries});

  /// `yyyy-MM-dd` shift date of [entries].
  final String dayKey;
  final List<SessionDayEntry> entries;

  /// The open session, if any.
  SessionDayEntry? get openEntry {
    for (final entry in entries.reversed) {
      if (entry.isOpen) return entry;
    }
    return null;
  }

  /// The session shown in the hero card: the open one, else the latest.
  SessionDayEntry? get current =>
      openEntry ?? (entries.isEmpty ? null : entries.last);
}

/// Reads the signed-in user's [SessionDay]. The open session is looked up on
/// any date (`employeeId == uid` and `open == true`, allowed by the rules and
/// served by single-field indexes), so check-out after midnight finds it.
class EmployeeSessionDayReader {
  EmployeeSessionDayReader({required this._firestore, required this._now});

  final FirebaseFirestore Function() _firestore;
  final Now _now;

  CollectionReference<Map<String, dynamic>> get _entries =>
      _firestore().collection('attendance_entries');

  Future<SessionDay> read(String uid) async {
    final todayKey = BusinessTime.keyOfInstant(_now());
    final openFuture = _openEntry(uid);
    final todayFuture = _entriesOn(uid, todayKey);
    final open = await openFuture;
    final today = await todayFuture;

    final openKey = open?.workDateKey;
    if (open == null || openKey == null || openKey == todayKey) {
      return SessionDay(dayKey: todayKey, entries: _including(today, open));
    }
    final shiftDay = await _entriesOn(uid, openKey);
    return SessionDay(dayKey: openKey, entries: _including(shiftDay, open));
  }

  /// The open session on any date. A failed lookup is logged and falls back
  /// to today's entries, which still detect a same-day open session.
  Future<SessionDayEntry?> _openEntry(String uid) async {
    try {
      final snapshot = await _entries
          .where('employeeId', isEqualTo: uid)
          .where('open', isEqualTo: true)
          .get();
      final open = [
        for (final doc in snapshot.docs) SessionDayEntry(doc.id, doc.data()),
      ].where((entry) => entry.isOpen).toList()..sort(_byCheckIn);
      return open.isEmpty ? null : open.last;
    } catch (error, stackTrace) {
      developer.log(
        'Unable to look up the open attendance session for Employee Home.',
        name: 'workaxis.employee_home',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<List<SessionDayEntry>> _entriesOn(String uid, String dayKey) async {
    final snapshot = await _entries
        .where('employeeId', isEqualTo: uid)
        .where('workDateString', isEqualTo: dayKey)
        .get();
    return [
      for (final doc in snapshot.docs) SessionDayEntry(doc.id, doc.data()),
    ]..sort(_byCheckIn);
  }

  /// [entries] with [open] added when a concurrent write left it out.
  static List<SessionDayEntry> _including(
    List<SessionDayEntry> entries,
    SessionDayEntry? open,
  ) {
    if (open == null || entries.any((entry) => entry.id == open.id)) {
      return List.unmodifiable(entries);
    }
    return List<SessionDayEntry>.unmodifiable(
      <SessionDayEntry>[...entries, open]..sort(_byCheckIn),
    );
  }

  static int _byCheckIn(SessionDayEntry a, SessionDayEntry b) =>
      (a.checkInAt ?? DateTime(1970)).compareTo(b.checkInAt ?? DateTime(1970));
}
