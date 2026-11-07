import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workaxis/core/time/business_time.dart';
import 'package:workaxis/core/time/clock.dart';

/// Number of check-ins recorded for one business day.
class DailyCheckInCounts {
  const DailyCheckInCounts({required this.checkedIn, required this.late});

  /// Every entry for the day (entries are created at check-in).
  final int checkedIn;

  /// Entries whose status is `late` (a subset of [checkedIn]).
  final int late;
}

/// Aggregates today's `attendance_entries` with Firestore count queries, so
/// dashboards never download documents just to count them.
///
/// Queries are always constrained by organization (and branch when given) to
/// satisfy `firestore.rules`.
class AttendanceDayCounter {
  AttendanceDayCounter({FirebaseFirestore? firestore, Now? now})
    : _customFirestore = firestore,
      _now = now ?? systemNow;

  final FirebaseFirestore? _customFirestore;
  final Now _now;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  /// Counts for the whole organization (Org Admin scope).
  Future<DailyCheckInCounts> forOrganization(String organizationId) =>
      _count(organizationId: organizationId);

  /// Counts for a single branch of the organization.
  Future<DailyCheckInCounts> forBranch({
    required String organizationId,
    required String branchId,
  }) => _count(organizationId: organizationId, branchId: branchId);

  Future<DailyCheckInCounts> _count({
    required String organizationId,
    String? branchId,
  }) async {
    final dayKey = BusinessTime.keyOfInstant(_now());
    Query<Map<String, dynamic>> base = _firestore
        .collection('attendance_entries')
        .where('organizationId', isEqualTo: organizationId)
        .where('workDateString', isEqualTo: dayKey);
    if (branchId != null) {
      base = base.where('branchId', isEqualTo: branchId);
    }
    final results = await Future.wait([
      base.count().get(),
      base.where('status', isEqualTo: 'late').count().get(),
    ]);
    return DailyCheckInCounts(
      checkedIn: results[0].count ?? 0,
      late: results[1].count ?? 0,
    );
  }
}
