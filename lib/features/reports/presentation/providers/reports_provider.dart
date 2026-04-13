import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:service_reminder/core/services/supabase/supabase_client_provider.dart';
import 'package:service_reminder/features/reports/data/datasources/reports_remote_datasource.dart';
import 'package:service_reminder/features/reports/domain/entities/report_stats.dart';

// ── Period enum ───────────────────────────────────────────────────────────────

enum ReportPeriod { today, week, month, year }

extension ReportPeriodX on ReportPeriod {
  String get label => switch (this) {
        ReportPeriod.today => 'Today',
        ReportPeriod.week => 'Week',
        ReportPeriod.month => 'Month',
        ReportPeriod.year => 'Year',
      };

  String get comparisonLabel => switch (this) {
        ReportPeriod.today => 'yesterday',
        ReportPeriod.week => 'last week',
        ReportPeriod.month => 'last month',
        ReportPeriod.year => 'last year',
      };

  /// Returns {from, to, prevFrom, prevTo} — all date-only (time is handled in queries).
  ({DateTime from, DateTime to, DateTime prevFrom, DateTime prevTo})
      get dateRange {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (this) {
      case ReportPeriod.today:
        final yesterday = today.subtract(const Duration(days: 1));
        return (
          from: today,
          to: today,
          prevFrom: yesterday,
          prevTo: yesterday,
        );

      case ReportPeriod.week:
        // Monday as week start
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        final prevWeekStart = weekStart.subtract(const Duration(days: 7));
        return (
          from: weekStart,
          to: today,
          prevFrom: prevWeekStart,
          prevTo: weekStart.subtract(const Duration(days: 1)),
        );

      case ReportPeriod.month:
        final monthStart = DateTime(now.year, now.month, 1);
        // Handle January → previous December
        final prevMonthStart = now.month == 1
            ? DateTime(now.year - 1, 12, 1)
            : DateTime(now.year, now.month - 1, 1);
        final prevMonthEnd = monthStart.subtract(const Duration(days: 1));
        return (
          from: monthStart,
          to: today,
          prevFrom: prevMonthStart,
          prevTo: prevMonthEnd,
        );

      case ReportPeriod.year:
        return (
          from: DateTime(now.year, 1, 1),
          to: today,
          prevFrom: DateTime(now.year - 1, 1, 1),
          prevTo: DateTime(now.year - 1, 12, 31),
        );
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final reportPeriodProvider =
    StateProvider<ReportPeriod>((ref) => ReportPeriod.month);

final _reportsDataSourceProvider = Provider<ReportsRemoteDataSource>((ref) {
  return ReportsRemoteDataSource(ref.watch(supabaseClientProvider));
});

final reportStatsProvider =
    FutureProvider.autoDispose<ReportStats>((ref) async {
  final period = ref.watch(reportPeriodProvider);
  final ds = ref.watch(_reportsDataSourceProvider);
  final r = period.dateRange;
  final raw = await ds.fetch(
    from: r.from,
    to: r.to,
    prevFrom: r.prevFrom,
    prevTo: r.prevTo,
  );
  return _compute(raw, period);
});

// ── Computation ───────────────────────────────────────────────────────────────

ReportStats _compute(ReportsRawData raw, ReportPeriod period) {
  final now = DateTime.now();

  // ── Customer name lookup map ────────────────────────────────────────────────
  final customerNames = <String, String>{
    for (final c in raw.customers)
      c['id'] as String: (c['name'] as String?) ?? 'Unknown',
  };

  // ── Build unified CompletedServiceRecord list (current period) ──────────────
  final completed = <CompletedServiceRecord>[];

  for (final s in raw.serviceHistory) {
    final ts = DateTime.parse(s['serviced_at'] as String).toLocal();
    completed.add(CompletedServiceRecord(
      id: s['id'] as String,
      customerId: s['customer_id'] as String,
      customerName: customerNames[s['customer_id'] as String],
      serviceDate: ts,
      amount: (s['amount_charged'] as num?)?.toDouble() ?? 0,
      serviceName: null, // catalog name lookup is out of scope for reports
    ));
  }

  for (final a in raw.assignedCompleted) {
    final dateStr = a['scheduled_date'] as String;
    final timeStr = (a['scheduled_time'] as String?)?.trim();
    DateTime serviceDate;
    if (timeStr != null && timeStr.length >= 5) {
      final parts = timeStr.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final d = DateTime.parse(dateStr);
      serviceDate = DateTime(d.year, d.month, d.day, h, m);
    } else {
      serviceDate = DateTime.parse(dateStr);
    }
    completed.add(CompletedServiceRecord(
      id: 'as_${a['id'] as String}',
      customerId: a['customer_id'] as String,
      customerName: customerNames[a['customer_id'] as String],
      serviceDate: serviceDate,
      amount: 0,
      serviceName: a['service_offering_name'] as String?,
    ));
  }

  // Sort newest first
  completed.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));

  // ── Current period KPIs ─────────────────────────────────────────────────────
  final totalServices = completed.length;
  final totalEarnings =
      completed.fold<double>(0, (s, r) => s + r.amount);
  final avgEarnings =
      totalServices > 0 ? totalEarnings / totalServices : 0.0;

  final servedCustomerIds = completed.map((r) => r.customerId).toSet();
  final customersServedThisPeriod = servedCustomerIds.length;

  // ── Previous period KPIs ────────────────────────────────────────────────────
  final prevServices =
      raw.prevServiceHistory.length + raw.prevAssigned.length;
  final prevEarnings = raw.prevServiceHistory
      .fold<double>(0, (s, r) => s + ((r['amount_charged'] as num?)?.toDouble() ?? 0));

  // ── All-time customer breakdown ─────────────────────────────────────────────
  final totalCustomers = raw.customers.length;
  final amcCustomers =
      raw.customers.where((c) => c['customer_type'] == 'amc').length;
  final oneTimeCustomers = totalCustomers - amcCustomers;

  // Active = customer whose most recent next_service_at is in the future
  final latestNext = <String, DateTime>{};
  for (final s in raw.allServiceHistory) {
    if (s['next_service_at'] == null) continue;
    final cid = s['customer_id'] as String;
    final next = DateTime.parse(s['next_service_at'] as String);
    final ex = latestNext[cid];
    if (ex == null || next.isAfter(ex)) latestNext[cid] = next;
  }
  int activeCustomers = 0, inactiveCustomers = 0;
  for (final c in raw.customers) {
    final next = latestNext[c['id'] as String];
    (next != null && next.isAfter(now) ? activeCustomers++ : inactiveCustomers++);
  }

  // ── Top customers this period ───────────────────────────────────────────────
  final grouped = <String, List<CompletedServiceRecord>>{};
  for (final r in completed) {
    grouped.putIfAbsent(r.customerId, () => []).add(r);
  }
  final topCustomers = grouped.entries
      .map((e) => TopCustomer(
            customerId: e.key,
            name: e.value.first.customerName,
            servicesCount: e.value.length,
            totalEarnings: e.value.fold(0, (s, r) => s + r.amount),
          ))
      .toList()
    ..sort((a, b) => b.servicesCount.compareTo(a.servicesCount));

  // ── Chart data ──────────────────────────────────────────────────────────────
  final earningsChart = _buildChart(completed, period, isEarnings: true);
  final servicesChart = _buildChart(completed, period, isEarnings: false);

  return ReportStats(
    totalEarnings: totalEarnings,
    totalServices: totalServices,
    avgEarningsPerVisit: avgEarnings,
    customersServedThisPeriod: customersServedThisPeriod,
    previousPeriodEarnings: prevEarnings,
    previousPeriodServices: prevServices,
    totalCustomers: totalCustomers,
    amcCustomers: amcCustomers,
    oneTimeCustomers: oneTimeCustomers,
    activeCustomers: activeCustomers,
    inactiveCustomers: inactiveCustomers,
    earningsChart: earningsChart,
    servicesChart: servicesChart,
    completedServices: completed,
    topCustomers: topCustomers.take(5).toList(),
  );
}

// ── Chart builder ─────────────────────────────────────────────────────────────

List<ChartPoint> _buildChart(
  List<CompletedServiceRecord> records,
  ReportPeriod period, {
  required bool isEarnings,
}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  double valueOf(List<CompletedServiceRecord> recs) => isEarnings
      ? recs.fold(0.0, (s, r) => s + r.amount)
      : recs.length.toDouble();

  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  switch (period) {
    // Today → 4 time slots, current-hour slot highlighted
    case ReportPeriod.today:
      const slots = [
        ('Night', 0, 6),
        ('Morning', 6, 12),
        ('Afternoon', 12, 17),
        ('Evening', 17, 24),
      ];
      final currentHour = now.hour;
      return slots.map((slot) {
        final slotLabel = slot.$1;
        final start = slot.$2;
        final end = slot.$3;
        final inSlot = records
            .where((r) =>
                sameDay(r.serviceDate, today) &&
                r.serviceDate.hour >= start &&
                r.serviceDate.hour < end)
            .toList();
        final highlighted = currentHour >= start && currentHour < end;
        return ChartPoint(
            label: slotLabel,
            value: valueOf(inSlot),
            isHighlighted: highlighted);
      }).toList();

    // Week → Mon–Sun, today highlighted
    case ReportPeriod.week:
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      return List.generate(7, (i) {
        final day = weekStart.add(Duration(days: i));
        final inDay = records.where((r) => sameDay(r.serviceDate, day)).toList();
        return ChartPoint(
          label: DateFormat('E').format(day),
          value: valueOf(inDay),
          isHighlighted: sameDay(day, today),
        );
      });

    // Month → W1–W4, current week highlighted
    case ReportPeriod.month:
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      return List.generate(4, (i) {
        final start = i * 7 + 1;
        final end = (i == 3) ? daysInMonth : (i + 1) * 7;
        final inWeek = records
            .where((r) =>
                r.serviceDate.year == now.year &&
                r.serviceDate.month == now.month &&
                r.serviceDate.day >= start &&
                r.serviceDate.day <= end)
            .toList();
        final isCurrentWeek = now.day >= start && now.day <= end;
        return ChartPoint(
          label: 'W${i + 1}',
          value: valueOf(inWeek),
          isHighlighted: isCurrentWeek,
        );
      });

    // Year → Jan–Dec, current month highlighted
    case ReportPeriod.year:
      return List.generate(12, (i) {
        final month = i + 1;
        final inMonth = records
            .where((r) =>
                r.serviceDate.year == now.year &&
                r.serviceDate.month == month)
            .toList();
        return ChartPoint(
          label: DateFormat('MMM').format(DateTime(now.year, month)),
          value: valueOf(inMonth),
          isHighlighted: month == now.month,
        );
      });
  }
}
