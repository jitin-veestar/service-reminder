import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:service_reminder/core/constants/app_constants.dart';
import 'package:service_reminder/core/constants/db_tables.dart';
import 'package:service_reminder/core/services/supabase/supabase_client_provider.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final seedDataServiceProvider = Provider<SeedDataService>((ref) {
  return SeedDataService(ref.watch(supabaseClientProvider));
});

final seedDataControllerProvider =
    AsyncNotifierProvider.autoDispose<SeedDataController, void>(
  SeedDataController.new,
);

class SeedDataController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> seed() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(seedDataServiceProvider).seedAll(),
    );
  }
}

// ── Service ───────────────────────────────────────────────────────────────────

class SeedDataService {
  final SupabaseClient _client;
  const SeedDataService(this._client);

  String get _uid => _client.auth.currentUser!.id;

  /// Returns true if customers already exist for this technician.
  Future<bool> isAlreadySeeded() async {
    final res = await _client.from(DbTables.customers).select('id').limit(1);
    return res.isNotEmpty;
  }

  static Set<String> get _seedNameSet => {for (final s in _seeds) s.name};

  /// Removes any customers (and their services) that match this seed set so
  /// "Load Sample Data" can be run again without unique-constraint failures.
  Future<void> _clearPriorSeedRows(String uid) async {
    final rows = await _client
        .from(DbTables.customers)
        .select('id, name')
        .eq('technician_id', uid);

    final idsToRemove = <String>[];
    for (final row in rows) {
      final name = row['name'] as String?;
      if (name != null && _seedNameSet.contains(name)) {
        idsToRemove.add(row['id'] as String);
      }
    }
    if (idsToRemove.isEmpty) return;

    // Chunk IDs — long `in=(...)` query strings can hit URL limits.
    const chunk = 20;
    for (var i = 0; i < idsToRemove.length; i += chunk) {
      final end = (i + chunk > idsToRemove.length) ? idsToRemove.length : i + chunk;
      final slice = idsToRemove.sublist(i, end);
      await _client
          .from(DbTables.serviceHistory)
          .delete()
          .inFilter('customer_id', slice);
    }
    for (var i = 0; i < idsToRemove.length; i += chunk) {
      final end = (i + chunk > idsToRemove.length) ? idsToRemove.length : i + chunk;
      final slice = idsToRemove.sublist(i, end);
      await _client
          .from(DbTables.customers)
          .delete()
          .inFilter('id', slice);
    }
  }

  Future<void> seedAll() async {
    final today = DateTime.now();
    final uid = _uid;

    await _clearPriorSeedRows(uid);

    // ── 1. Build customer insert payloads ─────────────────────────────────
    final customerInserts = _seeds.map((s) {
      return {
        'technician_id': uid,
        'name': s.name,
        'phone': s.phone,
        'address': s.address,
        if (AppConstants.customersHasCustomerTypeColumn) 'customer_type': s.type,
        if (AppConstants.customersHasServiceFrequencyDaysColumn)
          'service_frequency_days': s.freq,
      };
    }).toList();

    // Insert customers, then fetch IDs in a separate query
    // (avoids PGRST 204 when RLS SELECT policy blocks the inline .select())
    await _client.from(DbTables.customers).insert(customerInserts);

    // Resolve IDs from all rows for this technician (avoids long `in` URLs and
    // matches how the list screen loads data).
    final allRows = await _client
        .from(DbTables.customers)
        .select('id, name')
        .eq('technician_id', uid);

    final nameSet = _seedNameSet;
    final nameToId = <String, String>{};
    for (final row in allRows) {
      final name = row['name'] as String;
      if (nameSet.contains(name)) {
        nameToId[name] = row['id'] as String;
      }
    }

    if (nameToId.length != _seeds.length) {
      throw Exception(
        'After inserting sample customers, expected ${_seeds.length} rows but '
        'could resolve ${nameToId.length} by name. Check Supabase RLS: '
        'technicians need SELECT (and INSERT) on `customers` and INSERT on `service_history`.',
      );
    }

    // ── 2. Build service record payloads ──────────────────────────────────
    final serviceInserts = <Map<String, dynamic>>[];

    for (int i = 0; i < _seeds.length; i++) {
      final seed = _seeds[i];
      final customerId = nameToId[seed.name];
      if (customerId == null) continue; // shouldn't happen

      if (seed.offset == null) continue; // never serviced customers

      final nextService = _addDays(today, seed.offset!);
      final mostRecentServiced = _addDays(nextService, -seed.freq);

      // Most recent service record
      serviceInserts.add(_serviceRow(
        customerId: customerId,
        uid: uid,
        servicedAt: mostRecentServiced,
        nextServiceAt: nextService,
        amount: _amount(i, seed.type),
        checklist: _checklist(i, 0),
      ));

      // Add 1–3 prior visits spread backwards (for bar-chart data)
      final priorCount = (i % 3) + 1;
      for (int p = 1; p <= priorCount; p++) {
        final priorServiced = _addDays(mostRecentServiced, -(seed.freq * p));
        // Only include if within the last 13 months
        if (priorServiced
            .isAfter(today.subtract(const Duration(days: 395)))) {
          serviceInserts.add(_serviceRow(
            customerId: customerId,
            uid: uid,
            servicedAt: priorServiced,
            nextServiceAt: _addDays(priorServiced, seed.freq),
            amount: _amount(i + p * 7, seed.type),
            checklist: _checklist(i, p),
          ));
        }
      }
    }

    if (serviceInserts.isNotEmpty) {
      // Insert in batches of 50 to avoid payload limits
      for (int start = 0; start < serviceInserts.length; start += 50) {
        final batch = serviceInserts.sublist(
          start,
          (start + 50).clamp(0, serviceInserts.length),
        );
        await _client.from(DbTables.serviceHistory).insert(batch);
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static DateTime _addDays(DateTime base, int days) =>
      DateTime(base.year, base.month, base.day + days);

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static double _amount(int i, String type) {
    final amcAmounts = [150.0, 175.0, 200.0, 200.0, 225.0, 250.0, 175.0];
    final oneTimeAmounts = [250.0, 300.0, 350.0, 300.0, 400.0, 450.0, 350.0, 500.0];
    return type == 'amc'
        ? amcAmounts[i.abs() % amcAmounts.length]
        : oneTimeAmounts[i.abs() % oneTimeAmounts.length];
  }

  static Map<String, dynamic> _serviceRow({
    required String customerId,
    required String uid,
    required DateTime servicedAt,
    required DateTime nextServiceAt,
    required double amount,
    required ({bool filter, bool membrane, bool cleaning, bool leakage})
        checklist,
  }) {
    return {
      'customer_id': customerId,
      'technician_id': uid,
      'serviced_at': _fmt(servicedAt),
      'next_service_at': _fmt(nextServiceAt),
      if (AppConstants.servicesHasAmountChargedColumn) 'amount_charged': amount,
      'filter_changed': checklist.filter,
      'membrane_checked': checklist.membrane,
      'cleaning_done': checklist.cleaning,
      'leakage_fixed': checklist.leakage,
    };
  }

  static ({bool filter, bool membrane, bool cleaning, bool leakage}) _checklist(
      int i, int p) {
    return (
      filter: true,
      membrane: (i + p) % 3 != 0,
      cleaning: true,
      leakage: (i + p) % 7 == 0,
    );
  }

  // ── Seed data ─────────────────────────────────────────────────────────────
  // offset = days from today for next_service_at (null = no service ever)
  // Positive = future (active/upcoming), 0 = today, negative = overdue

  static const _seeds = [
    // ── Today's visits (5) ────────────────────────────────────────────────
    _S('Arjun Sharma',      '9876543210', '12 Anna Nagar, Chennai',           'amc',      90,  0),
    _S('Priya Patel',       '9867453201', '45 Koramangala, Bangalore',        'one_time', 90,  0),
    _S('Ravi Kumar',        '9856234109', '7 Banjara Hills, Hyderabad',       'amc',      120, 0),
    _S('Anjali Singh',      '9834512907', '23 Salt Lake, Kolkata',            'one_time', 90,  0),
    _S('Vikram Gupta',      '9823401896', '89 Janakpuri, Delhi',              'amc',      120, 0),

    // ── Upcoming 1–7 days (8) ─────────────────────────────────────────────
    _S('Sunita Rao',        '9812390785', '34 Aundh, Pune',                   'one_time', 90,  1),
    _S('Manoj Nair',        '9801279674', '56 Vashi, Mumbai',                 'amc',      90,  2),
    _S('Kavitha Reddy',     '9790168563', '12 Whitefield, Bangalore',         'one_time', 120, 3),
    _S('Suresh Mishra',     '9779057452', '78 Gomti Nagar, Lucknow',          'amc',      90,  4),
    _S('Deepa Iyer',        '9767946341', '90 RA Puram, Chennai',             'one_time', 90,  5),
    _S('Ramesh Khanna',     '9756835230', '23 Model Town, Delhi',             'amc',      120, 6),
    _S('Pooja Verma',       '9745724119', '45 Civil Lines, Prayagraj',        'one_time', 90,  7),
    _S('Kiran Bose',        '9734613008', '67 Ballygunge, Kolkata',           'amc',      90,  7),

    // ── Future active >7 days (12) ────────────────────────────────────────
    _S('Meena Pillai',      '9723501897', '89 Kakkanad, Kochi',               'one_time', 120, 15),
    _S('Ajay Joshi',        '9712390786', '12 Pimple Saudagar, Pune',         'one_time', 90,  20),
    _S('Latha Srinivasan',  '9701279675', '34 T Nagar, Chennai',              'amc',      120, 25),
    _S('Sunil Mehta',       '9690168564', '56 Navrangpura, Ahmedabad',        'amc',      90,  30),
    _S('Uma Krishnan',      '9679057453', '78 Indira Nagar, Bangalore',       'amc',      120, 35),
    _S('Prakash Desai',     '9667946342', '90 Baner, Pune',                   'one_time', 90,  40),
    _S('Nisha Pandey',      '9656835231', '12 Hazratganj, Lucknow',           'one_time', 90,  45),
    _S('Arun Chakraborty',  '9645724120', '34 Lake Gardens, Kolkata',         'amc',      120, 50),
    _S('Geetha Nambiar',    '9634613009', '56 Ernakulam, Kochi',              'amc',      90,  55),
    _S('Vinod Agrawal',     '9623501898', '78 Sikandra, Agra',                'one_time', 120, 60),
    _S('Radha Menon',       '9612390787', '90 Palarivattom, Kochi',           'one_time', 90,  65),
    _S('Ashok Tiwari',      '9601279676', '23 Shastri Nagar, Jaipur',         'amc',      120, 70),

    // ── Overdue 1–30 days (10) ────────────────────────────────────────────
    _S('Saranya Devi',      '9590168565', '45 Chromepet, Chennai',            'one_time', 90,  -1),
    _S('Mohit Banerjee',    '9579057454', '67 South Kolkata, Kolkata',        'amc',      90,  -3),
    _S('Bhavna Parekh',     '9567946343', '89 Navrangpura, Ahmedabad',        'one_time', 120, -5),
    _S('Sriram Swamy',      '9556835232', '12 Malleshwaram, Bangalore',       'amc',      90,  -7),
    _S('Rekha Choudhury',   '9545724121', '34 Mansarovar, Jaipur',            'one_time', 90,  -10),
    _S('Dinesh Hegde',      '9534613010', '56 Mangalore, Karnataka',          'amc',      120, -13),
    _S('Padma Subramanian', '9523501899', '78 Adyar, Chennai',                'one_time', 90,  -16),
    _S('Naresh Vyas',       '9512390788', '90 Surat Centre, Surat',           'amc',      90,  -20),
    _S('Shobha Iyengar',    '9501279677', '23 Mysore Road, Bangalore',        'one_time', 120, -25),
    _S('Balaji Murugan',    '9490168566', '45 Coimbatore South, Coimbatore',  'amc',      90,  -28),

    // ── Long overdue / inactive (10) ─────────────────────────────────────
    _S('Jyoti Bhaduri',     '9479057455', '67 Dhakuria, Kolkata',             'one_time', 90,  -35),
    _S('Ramakrishna Patil', '9467946344', '89 Dharwad, Karnataka',            'amc',      120, -50),
    _S('Anitha Nayak',      '9456835233', '12 Mangalore, Karnataka',          'one_time', 90,  -60),
    _S('Sanjay Kulkarni',   '9445724122', '34 Sadashiv Peth, Pune',           'amc',      90,  -75),
    _S('Lalitha Venkat',    '9434613011', '56 Thiruvanmiyur, Chennai',        'one_time', 120, -80),
    _S('Harish Dubey',      '9423501900', '78 Govind Nagar, Kanpur',          'amc',      90,  -95),
    _S('Kamala Raghunathan','9412390789', '90 Nungambakkam, Chennai',         'one_time', 90,  -105),
    _S('Praveen Kumar',     '9401279678', '23 Rajajinagar, Bangalore',        'amc',      120, -115),
    _S('Usha Natarajan',    '9390168567', '45 Velachery, Chennai',            'one_time', 90,  -125),
    _S('Gopal Yadav',       '9379057456', '67 Vaishali, Ghaziabad',           'amc',      90,  -140),

    // ── Never serviced (5) ────────────────────────────────────────────────
    _S('Mythili Subramaniam',  '9367946345', '89 Porur, Chennai',              'one_time', 90,  null),
    _S('Suresh Chandrasekhar', '9356835234', '12 Electronic City, Bangalore',  'amc',      120, null),
    _S('Veena Gopinath',       '9345724123', '34 Perumbavoor, Kochi',          'one_time', 90,  null),
    _S('Rajesh Pillai',        '9334613012', '56 Thampanoor, Trivandrum',      'amc',      90,  null),
    _S('Amita Bhatia',         '9323501901', '78 Sector 17, Chandigarh',       'one_time', 120, null),
  ];
}

// ── Seed record helper ────────────────────────────────────────────────────────

class _S {
  final String name;
  final String phone;
  final String address;
  final String type;
  final int freq;
  final int? offset;

  const _S(this.name, this.phone, this.address, this.type, this.freq,
      this.offset);
}
