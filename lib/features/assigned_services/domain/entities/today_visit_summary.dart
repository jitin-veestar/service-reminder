/// Counts for assignments scheduled **today** (device-local calendar date),
/// including **completed** (which are omitted from [getDashboardVisits]).
class TodayVisitSummary {
  /// Non-cancelled rows with `scheduled_date` = today.
  final int scheduledTodayCount;

  /// Subset of those with `status` = completed.
  final int completedTodayCount;

  const TodayVisitSummary({
    required this.scheduledTodayCount,
    required this.completedTodayCount,
  });
}
