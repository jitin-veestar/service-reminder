import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:service_reminder/core/theme/app_colors.dart';
import 'package:service_reminder/core/theme/app_typography.dart';
import 'package:service_reminder/features/reports/domain/entities/report_stats.dart';
import 'package:service_reminder/features/reports/presentation/providers/reports_provider.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(reportStatsProvider);
    final period = ref.watch(reportPeriodProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reports', style: AppTypography.heading2),
        backgroundColor: AppColors.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _PeriodSelector(
            selected: period,
            onChanged: (p) =>
                ref.read(reportPeriodProvider.notifier).state = p,
          ),
        ),
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(reportStatsProvider),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(reportStatsProvider),
          child: _ReportBody(stats: stats, period: period),
        ),
      ),
    );
  }
}

// ── Period selector ───────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final ReportPeriod selected;
  final ValueChanged<ReportPeriod> onChanged;

  const _PeriodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: ReportPeriod.values.map((p) {
          final isSelected = p == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p.label,
                  textAlign: TextAlign.center,
                  style: AppTypography.label.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Report body ───────────────────────────────────────────────────────────────

class _ReportBody extends StatelessWidget {
  final ReportStats stats;
  final ReportPeriod period;

  const _ReportBody({required this.stats, required this.period});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // ── KPI cards ──────────────────────────────────────────────────────
        _SectionLabel('Overview · ${period.label}'),
        const SizedBox(height: 10),
        _KpiRow(stats: stats, period: period),
        const SizedBox(height: 20),

        // ── Earnings chart ─────────────────────────────────────────────────
        _SectionLabel('Earnings · ${period.label}'),
        const SizedBox(height: 10),
        _ChartCard(
          height: 220,
          child: stats.earningsChart.every((p) => p.value == 0)
              ? const _NoData()
              : _EarningsBarChart(data: stats.earningsChart),
        ),
        const SizedBox(height: 20),

        // ── Services chart ─────────────────────────────────────────────────
        _SectionLabel('Services Done · ${period.label}'),
        const SizedBox(height: 10),
        _ChartCard(
          height: 200,
          child: stats.servicesChart.every((p) => p.value == 0)
              ? const _NoData()
              : _ServicesBarChart(data: stats.servicesChart),
        ),
        const SizedBox(height: 20),

        // ── Customer breakdown ─────────────────────────────────────────────
        const _SectionLabel('Customers'),
        const SizedBox(height: 10),
        _CustomerBreakdownRow(stats: stats),
        const SizedBox(height: 20),

        // ── Top customers ─────────────────────────────────────────────────
        if (stats.topCustomers.isNotEmpty) ...[
          const _SectionLabel('Top Customers · This Period'),
          const SizedBox(height: 10),
          _TopCustomersList(customers: stats.topCustomers),
          const SizedBox(height: 20),
        ],

        // ── Completed services list ────────────────────────────────────────
        _SectionLabel(
            'Services (${stats.completedServices.length}) · ${period.label}'),
        const SizedBox(height: 10),
        stats.completedServices.isEmpty
            ? _card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.construction_outlined,
                          size: 36, color: AppColors.textHint),
                      const SizedBox(height: 8),
                      Text(
                        'No services recorded this period',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            : _ServicesList(records: stats.completedServices),
      ],
    );
  }
}

// ── KPI row ───────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final ReportStats stats;
  final ReportPeriod period;

  const _KpiRow({required this.stats, required this.period});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    final fmtDec = NumberFormat('#,##0.00', 'en_IN');

    final earningsDelta = stats.earningsChangePct;
    final servicesAbsDelta = stats.servicesChangeAbs;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.currency_rupee_rounded,
                iconColor: AppColors.success,
                label: 'Total Earned',
                value: '₹${fmt.format(stats.totalEarnings)}',
                subLabel: earningsDelta == 0
                    ? null
                    : '${earningsDelta >= 0 ? '+' : ''}${earningsDelta.toStringAsFixed(1)}% vs ${period.comparisonLabel}',
                subLabelPositive: stats.earningsImproved,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                icon: Icons.build_circle_outlined,
                iconColor: AppColors.primary,
                label: 'Services Done',
                value: fmt.format(stats.totalServices),
                subLabel: servicesAbsDelta == 0
                    ? null
                    : '${servicesAbsDelta >= 0 ? '+' : ''}$servicesAbsDelta vs ${period.comparisonLabel}',
                subLabelPositive: stats.servicesImproved,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.trending_up_rounded,
                iconColor: AppColors.dueSoon,
                label: 'Avg per Visit',
                value: stats.totalServices > 0
                    ? '₹${fmtDec.format(stats.avgEarningsPerVisit)}'
                    : '—',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                icon: Icons.people_alt_outlined,
                iconColor: AppColors.primaryDark,
                label: 'Customers Served',
                value: fmt.format(stats.customersServedThisPeriod),
                subLabel: 'of ${fmt.format(stats.totalCustomers)} total',
                subLabelPositive: null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? subLabel;

  /// null = neutral (grey), true = green, false = red
  final bool? subLabelPositive;

  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.subLabel,
    this.subLabelPositive,
  });

  @override
  Widget build(BuildContext context) {
    final subColor = subLabelPositive == null
        ? AppColors.textSecondary
        : subLabelPositive!
            ? AppColors.success
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: AppTypography.heading2.copyWith(fontSize: 17)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTypography.caption
                  .copyWith(color: AppColors.textSecondary)),
          if (subLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              subLabel!,
              style: AppTypography.caption
                  .copyWith(color: subColor, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Earnings bar chart ────────────────────────────────────────────────────────

class _EarningsBarChart extends StatefulWidget {
  final List<ChartPoint> data;
  const _EarningsBarChart({required this.data});

  @override
  State<_EarningsBarChart> createState() => _EarningsBarChartState();
}

class _EarningsBarChartState extends State<_EarningsBarChart> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final maxY = widget.data.map((e) => e.value).fold<double>(0, (a, b) => a > b ? a : b);
    final fmt = NumberFormat.compact(locale: 'en_IN');

    return BarChart(
      BarChartData(
        maxY: maxY < 1 ? 500 : maxY * 1.3,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final val = rod.toY;
              return BarTooltipItem(
                '₹${NumberFormat('#,##0', 'en_IN').format(val)}',
                AppTypography.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
          touchCallback: (evt, resp) {
            setState(() {
              _touched = (resp?.spot?.touchedBarGroupIndex);
            });
          },
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppColors.divider,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, _) => Text(
                '₹${fmt.format(v)}',
                style: AppTypography.caption
                    .copyWith(color: AppColors.textSecondary, fontSize: 9),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= widget.data.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    widget.data[i].label,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: widget.data.asMap().entries.map((entry) {
          final isHighlighted = entry.value.isHighlighted;
          final isTouched = _touched == entry.key;
          final barColor = isHighlighted || isTouched
              ? AppColors.success
              : AppColors.primary.withValues(alpha: 0.6);

          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value,
                color: barColor,
                width: 18,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(5),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY < 1 ? 500 : maxY * 1.3,
                  color: AppColors.surfaceVariant,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Services bar chart ────────────────────────────────────────────────────────

class _ServicesBarChart extends StatefulWidget {
  final List<ChartPoint> data;
  const _ServicesBarChart({required this.data});

  @override
  State<_ServicesBarChart> createState() => _ServicesBarChartState();
}

class _ServicesBarChartState extends State<_ServicesBarChart> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final maxY = widget.data.map((e) => e.value).fold<double>(0, (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: maxY < 1 ? 5 : maxY * 1.4,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              '${rod.toY.toInt()} services',
              AppTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          touchCallback: (evt, resp) =>
              setState(() => _touched = resp?.spot?.touchedBarGroupIndex),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppColors.divider,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: AppTypography.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= widget.data.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    widget.data[i].label,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: widget.data.asMap().entries.map((entry) {
          final isHighlighted =
              entry.value.isHighlighted || _touched == entry.key;
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value,
                color: isHighlighted
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.5),
                width: 18,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(5),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY < 1 ? 5 : maxY * 1.4,
                  color: AppColors.surfaceVariant,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Customer breakdown row ────────────────────────────────────────────────────

class _CustomerBreakdownRow extends StatelessWidget {
  final ReportStats stats;
  const _CustomerBreakdownRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BreakdownChip(
            label: 'Total',
            count: stats.totalCustomers,
            color: AppColors.primary,
            icon: Icons.people_alt_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _BreakdownChip(
            label: 'Active',
            count: stats.activeCustomers,
            color: AppColors.success,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _BreakdownChip(
            label: 'AMC',
            count: stats.amcCustomers,
            color: AppColors.primaryDark,
            icon: Icons.verified_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _BreakdownChip(
            label: 'Overdue',
            count: stats.inactiveCustomers,
            color: AppColors.error,
            icon: Icons.warning_amber_outlined,
          ),
        ),
      ],
    );
  }
}

class _BreakdownChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _BreakdownChip({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 5),
          Text(
            '$count',
            style: AppTypography.heading3
                .copyWith(color: color, fontSize: 15),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Top customers list ────────────────────────────────────────────────────────

class _TopCustomersList extends StatelessWidget {
  final List<TopCustomer> customers;
  const _TopCustomersList({required this.customers});

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        children: customers.asMap().entries.map((entry) {
          final idx = entry.key;
          final c = entry.value;
          final fmt = NumberFormat('#,##0', 'en_IN');
          final isLast = idx == customers.length - 1;

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    // rank badge
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: idx == 0
                            ? AppColors.dueSoon.withValues(alpha: 0.15)
                            : AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${idx + 1}',
                        style: AppTypography.caption.copyWith(
                          color: idx == 0
                              ? AppColors.dueSoon
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name ?? 'Unknown',
                            style: AppTypography.body
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${c.servicesCount} service${c.servicesCount == 1 ? '' : 's'}',
                            style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (c.totalEarnings > 0)
                      Text(
                        '₹${fmt.format(c.totalEarnings)}',
                        style: AppTypography.body.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(height: 1, indent: 56, color: AppColors.divider),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Completed services list ───────────────────────────────────────────────────

class _ServicesList extends StatefulWidget {
  final List<CompletedServiceRecord> records;
  const _ServicesList({required this.records});

  @override
  State<_ServicesList> createState() => _ServicesListState();
}

class _ServicesListState extends State<_ServicesList> {
  static const _pageSize = 10;
  int _shown = _pageSize;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    final dateFmt = DateFormat('d MMM, hh:mm a');
    final visible = widget.records.take(_shown).toList();

    return Column(
      children: [
        _card(
          child: Column(
            children: visible.asMap().entries.map((entry) {
              final idx = entry.key;
              final r = entry.value;
              final isLast = idx == visible.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor:
                              AppColors.primaryLight.withValues(alpha: 0.2),
                          child: Text(
                            (r.customerName?.isNotEmpty == true)
                                ? r.customerName![0].toUpperCase()
                                : '?',
                            style: AppTypography.label.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.customerName ?? 'Unknown Customer',
                                style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.w600),
                              ),
                              Text(
                                [
                                  if (r.serviceName != null) r.serviceName!,
                                  dateFmt.format(r.serviceDate),
                                ].join(' · '),
                                style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (r.amount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '₹${fmt.format(r.amount)}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                        height: 1, indent: 56, color: AppColors.divider),
                ],
              );
            }).toList(),
          ),
        ),
        if (_shown < widget.records.length) ...[
          const SizedBox(height: 10),
          TextButton(
            onPressed: () =>
                setState(() => _shown += _pageSize),
            child: Text(
              'Show more (${widget.records.length - _shown} remaining)',
              style: AppTypography.label
                  .copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final Widget child;
  final double height;

  const _ChartCard({required this.child, this.height = 200});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(8, 14, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

Widget _card({required Widget child}) {
  return Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

class _NoData extends StatelessWidget {
  const _NoData();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bar_chart_outlined,
              size: 34, color: AppColors.textHint),
          const SizedBox(height: 8),
          Text(
            'No data for this period',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Failed to load reports',
                style:
                    AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
