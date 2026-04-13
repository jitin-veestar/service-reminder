import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:service_reminder/app/router/route_names.dart';
import 'package:service_reminder/core/theme/app_colors.dart';
import 'package:service_reminder/core/theme/app_typography.dart';
import 'package:service_reminder/features/assigned_services/domain/assigned_service_status_rules.dart';
import 'package:service_reminder/features/assigned_services/domain/entities/assigned_service.dart';
import 'package:service_reminder/features/assigned_services/domain/entities/today_visit_summary.dart';
import 'package:service_reminder/features/assigned_services/presentation/providers/assigned_services_provider.dart';
import 'package:service_reminder/features/dashboard/presentation/widgets/dashboard_visit_card.dart';
import 'package:service_reminder/features/reminders/presentation/pages/reminders_page.dart';
import 'package:service_reminder/l10n/app_localizations.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardVisitsProvider);
    final l10n = AppLocalizations.of(context)!;
    final localeTag = Localizations.localeOf(context).toString();
    final todayLabel =
        DateFormat('EEEE, d MMM', localeTag).format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.dashboard, style: AppTypography.heading2),
            Text(
              todayLabel,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        automaticallyImplyLeading: false,
        toolbarHeight: 64,
        actions: [
          IconButton(
            tooltip: l10n.remindersTooltip,
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RemindersPage()),
            ),
          ),
          IconButton(
            tooltip: l10n.assignServiceTooltip,
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => context.push(RouteNames.assignService),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorView(
          message: err.toString(),
          onRetry: () => ref.read(dashboardVisitsProvider.notifier).refresh(),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.read(dashboardVisitsProvider.notifier).refresh(),
          child: _DashboardBody(
            visits: data.visits,
            todaySummary: data.todaySummary,
          ),
        ),
      ),
    );
  }
}

// ── Dashboard body ────────────────────────────────────────────────────────────

bool _visitMatchesSearch(AssignedService v, String rawQuery) {
  final q = rawQuery.trim().toLowerCase();
  if (q.isEmpty) return true;
  for (final s in [v.customerName, v.customerPhone, v.serviceOfferingName]) {
    if (s != null && s.toLowerCase().contains(q)) return true;
  }
  final qDigits = rawQuery.replaceAll(RegExp(r'\D'), '');
  if (qDigits.length >= 2) {
    final phoneDigits =
        v.customerPhone?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (phoneDigits.contains(qDigits)) return true;
  }
  return false;
}

List<AssignedService> _filterVisits(
  List<AssignedService> visits,
  String query,
) {
  final q = query.trim();
  if (q.isEmpty) return visits;
  return visits.where((v) => _visitMatchesSearch(v, q)).toList();
}

class _TodaySummaryStrip extends StatelessWidget {
  final TodayVisitSummary summary;
  final int overdueOpenCount;

  const _TodaySummaryStrip({
    required this.summary,
    required this.overdueOpenCount,
  });

  @override
  Widget build(BuildContext context) {
    final v = summary.scheduledTodayCount;
    final d = summary.completedTodayCount;
    final o = overdueOpenCount;
    final visitPart = v == 1 ? '1 visit today' : '$v visits today';
    final donePart = d == 1 ? '1 done' : '$d done';
    final overduePart = o == 1 ? '1 overdue' : '$o overdue';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.insights_outlined,
                size: 22,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$visitPart · $donePart · $overduePart',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatefulWidget {
  final List<AssignedService> visits;
  final TodayVisitSummary todaySummary;

  const _DashboardBody({
    required this.visits,
    required this.todaySummary,
  });

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static DateTime _sortKey(AssignedService v) {
    final t = v.scheduledTime?.trim();
    if (t == null || t.isEmpty) {
      return DateTime(
        v.scheduledDate.year,
        v.scheduledDate.month,
        v.scheduledDate.day,
      );
    }
    return AssignedServiceStatusRules.scheduledDateTime(v.scheduledDate, t);
  }

  Widget _searchBar() {
    final hasText = _searchController.text.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: (_) => setState(() {}),
        style: AppTypography.body,
        decoration: InputDecoration(
          hintText: 'Search customer, phone, or service',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: hasText
              ? IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _summaryStrip() {
    final overdueOpen = widget.visits
        .where(
          (v) =>
              AssignedServiceStatusRules.derive(v) ==
              AssignedServiceStatus.overdue,
        )
        .length;
    return _TodaySummaryStrip(
      summary: widget.todaySummary,
      overdueOpenCount: overdueOpen,
    );
  }

  @override
  Widget build(BuildContext context) {
    final visits = widget.visits;
    if (visits.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 16),
        children: [
          _summaryStrip(),
          const SizedBox(height: 8),
          const _EmptyState(embedded: true),
        ],
      );
    }

    final filtered = _filterVisits(visits, _searchController.text);
    final qTrim = _searchController.text.trim();

    if (filtered.isEmpty && qTrim.isNotEmpty) {
      return ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        children: [
          _summaryStrip(),
          _searchBar(),
          const SizedBox(height: 48),
          const Icon(
            Icons.search_off_rounded,
            size: 56,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            'No visits match your search',
            textAlign: TextAlign.center,
            style: AppTypography.heading3.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Try another name, phone number, or service.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      );
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final overdue = filtered
        .where((v) =>
            AssignedServiceStatusRules.derive(v) ==
            AssignedServiceStatus.overdue)
        .toList()
      ..sort((a, b) => _sortKey(a).compareTo(_sortKey(b)));

    final todayVisits = filtered.where((v) {
      if (AssignedServiceStatusRules.derive(v) ==
          AssignedServiceStatus.overdue) {
        return false;
      }
      final d = v.scheduledDate;
      return DateTime(d.year, d.month, d.day) == todayDate;
    }).toList()
      ..sort((a, b) => _sortKey(a).compareTo(_sortKey(b)));

    final upcomingVisits = filtered.where((v) {
      if (AssignedServiceStatusRules.derive(v) ==
          AssignedServiceStatus.overdue) {
        return false;
      }
      final d = v.scheduledDate;
      return DateTime(d.year, d.month, d.day).isAfter(todayDate);
    }).toList()
      ..sort((a, b) => _sortKey(a).compareTo(_sortKey(b)));

    if (overdue.isEmpty && todayVisits.isEmpty && upcomingVisits.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        children: [
          _summaryStrip(),
          _searchBar(),
          const SizedBox(height: 32),
          const _EmptyState(embedded: true),
        ],
      );
    }

    final children = <Widget>[_summaryStrip(), _searchBar()];
    void append(Widget w) {
      if (children.length > 2) {
        children.add(const SizedBox(height: 8));
      }
      children.add(w);
    }

    if (overdue.isNotEmpty) {
      append(
        _AccordionSection(
          title: 'Overdue',
          count: overdue.length,
          accentColor: AppColors.overdue,
          icon: Icons.warning_amber_rounded,
          initiallyExpanded: true,
          visits: overdue,
          emptyMessage: 'No overdue visits.',
        ),
      );
    }
    if (todayVisits.isNotEmpty) {
      append(
        _AccordionSection(
          title: "Today's visits",
          count: todayVisits.length,
          accentColor: AppColors.primary,
          icon: Icons.today_rounded,
          initiallyExpanded: true,
          visits: todayVisits,
          emptyMessage: 'Nothing scheduled for today.',
        ),
      );
    }
    if (upcomingVisits.isNotEmpty) {
      append(
        _AccordionSection(
          title: 'Upcoming',
          count: upcomingVisits.length,
          accentColor: AppColors.dueSoon,
          icon: Icons.calendar_month_rounded,
          initiallyExpanded: true,
          visits: upcomingVisits,
          emptyMessage: 'No upcoming visits in the loaded window.',
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: children,
    );
  }
}

// ── Accordion section ─────────────────────────────────────────────────────────

class _AccordionSection extends StatefulWidget {
  final String title;
  final int count;
  final Color accentColor;
  final IconData icon;
  final bool initiallyExpanded;
  final List<AssignedService> visits;
  final String emptyMessage;

  const _AccordionSection({
    required this.title,
    required this.count,
    required this.accentColor,
    required this.icon,
    required this.initiallyExpanded,
    required this.visits,
    required this.emptyMessage,
  });

  @override
  State<_AccordionSection> createState() => _AccordionSectionState();
}

class _AccordionSectionState extends State<_AccordionSection>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _iconTurn;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: _expanded ? 1.0 : 0.0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _iconTurn = Tween<double>(begin: 0.0, end: 0.5).animate(_expandAnimation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _toggle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            widget.icon,
                            size: 20,
                            color: widget.accentColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: AppTypography.heading3,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: widget.accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${widget.count}',
                            style: AppTypography.caption.copyWith(
                              color: widget.accentColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        RotationTransition(
                          turns: _iconTurn,
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // ── Content ──────────────────────────────────────────────────
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(height: 1, color: AppColors.divider),
                    if (widget.visits.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 16,
                        ),
                        child: Text(
                          widget.emptyMessage,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: widget.visits
                              .map((v) => DashboardVisitCard(visit: v))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  /// When true, renders a [Column] for use inside another scroll view (e.g. with search).
  final bool embedded;

  const _EmptyState({this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      SizedBox(height: embedded ? 24 : 80),
      Icon(
        Icons.check_circle_outline_rounded,
        size: 72,
        color: AppColors.success.withValues(alpha: 0.7),
      ),
      const SizedBox(height: 20),
      Text(
        'All clear!',
        textAlign: TextAlign.center,
        style: AppTypography.heading2.copyWith(color: AppColors.textPrimary),
      ),
      const SizedBox(height: 8),
      Text(
        'No open assignments in the\ncurrent dashboard window.',
        textAlign: TextAlign.center,
        style: AppTypography.body.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    ];
    if (embedded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      );
    }
    return ListView(children: children);
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

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
            Text(
              'Failed to load visits',
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
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
