/// One checkpoint in a service visit.
class ChecklistItem {
  final String key;
  final String label;
  final bool isChecked;

  const ChecklistItem({
    required this.key,
    required this.label,
    required this.isChecked,
  });

  ChecklistItem copyWith({bool? isChecked}) => ChecklistItem(
        key: key,
        label: label,
        isChecked: isChecked ?? this.isChecked,
      );
}

/// The 4 fixed checkpoints for every RO service visit.
abstract final class Checklist {
  static const filterChanged = 'filter_changed';
  static const membraneChecked = 'membrane_checked';
  static const cleaningDone = 'cleaning_done';
  static const leakageFixed = 'leakage_fixed';

  static List<ChecklistItem> defaults() => const [
        ChecklistItem(key: filterChanged, label: 'Filter Changed', isChecked: false),
        ChecklistItem(key: membraneChecked, label: 'Membrane Checked', isChecked: false),
        ChecklistItem(key: cleaningDone, label: 'Cleaning Done', isChecked: false),
        ChecklistItem(key: leakageFixed, label: 'Leakage Fixed', isChecked: false),
      ];

  static List<ChecklistItem> fromBooleans({
    required bool filterChanged,
    required bool membraneChecked,
    required bool cleaningDone,
    required bool leakageFixed,
  }) =>
      [
        ChecklistItem(key: Checklist.filterChanged, label: 'Filter Changed', isChecked: filterChanged),
        ChecklistItem(key: Checklist.membraneChecked, label: 'Membrane Checked', isChecked: membraneChecked),
        ChecklistItem(key: Checklist.cleaningDone, label: 'Cleaning Done', isChecked: cleaningDone),
        ChecklistItem(key: Checklist.leakageFixed, label: 'Leakage Fixed', isChecked: leakageFixed),
      ];
}
