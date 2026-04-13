class ChartPoint {
  final String label;
  final double value;
  final bool isHighlighted;

  const ChartPoint({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });
}

/// A single completed service entry — merged from service_history and
/// assigned_services (status = completed).
class CompletedServiceRecord {
  final String id;
  final String customerId;
  final String? customerName;
  final DateTime serviceDate;

  /// Only populated from service_history rows (assigned_services have no amount).
  final double amount;
  final String? serviceName;

  const CompletedServiceRecord({
    required this.id,
    required this.customerId,
    this.customerName,
    required this.serviceDate,
    this.amount = 0,
    this.serviceName,
  });
}

class TopCustomer {
  final String customerId;
  final String? name;
  final int servicesCount;
  final double totalEarnings;

  const TopCustomer({
    required this.customerId,
    this.name,
    required this.servicesCount,
    required this.totalEarnings,
  });
}

class ReportStats {
  // ── Current period KPIs ──────────────────────────────────────────────────────
  final double totalEarnings;
  final int totalServices;
  final double avgEarningsPerVisit;

  /// Unique customers who had at least one service this period.
  final int customersServedThisPeriod;

  // ── Previous period KPIs (for comparison indicators) ─────────────────────────
  final double previousPeriodEarnings;
  final int previousPeriodServices;

  // ── All-time customer counts ──────────────────────────────────────────────────
  final int totalCustomers;
  final int amcCustomers;
  final int oneTimeCustomers;
  final int activeCustomers;
  final int inactiveCustomers;

  // ── Chart data (current period, bucketed by period granularity) ───────────────
  final List<ChartPoint> earningsChart;
  final List<ChartPoint> servicesChart;

  // ── Detailed lists ────────────────────────────────────────────────────────────
  final List<CompletedServiceRecord> completedServices;
  final List<TopCustomer> topCustomers;

  const ReportStats({
    required this.totalEarnings,
    required this.totalServices,
    required this.avgEarningsPerVisit,
    required this.customersServedThisPeriod,
    required this.previousPeriodEarnings,
    required this.previousPeriodServices,
    required this.totalCustomers,
    required this.amcCustomers,
    required this.oneTimeCustomers,
    required this.activeCustomers,
    required this.inactiveCustomers,
    required this.earningsChart,
    required this.servicesChart,
    required this.completedServices,
    required this.topCustomers,
  });

  // ── Computed comparison helpers ───────────────────────────────────────────────

  /// Percentage change in earnings vs previous period. Returns 0 if no prev data.
  double get earningsChangePct {
    if (previousPeriodEarnings <= 0) return 0;
    return (totalEarnings - previousPeriodEarnings) / previousPeriodEarnings * 100;
  }

  int get servicesChangeAbs => totalServices - previousPeriodServices;

  bool get earningsImproved => totalEarnings >= previousPeriodEarnings;
  bool get servicesImproved => totalServices >= previousPeriodServices;

  static ReportStats empty() => const ReportStats(
        totalEarnings: 0,
        totalServices: 0,
        avgEarningsPerVisit: 0,
        customersServedThisPeriod: 0,
        previousPeriodEarnings: 0,
        previousPeriodServices: 0,
        totalCustomers: 0,
        amcCustomers: 0,
        oneTimeCustomers: 0,
        activeCustomers: 0,
        inactiveCustomers: 0,
        earningsChart: [],
        servicesChart: [],
        completedServices: [],
        topCustomers: [],
      );
}
