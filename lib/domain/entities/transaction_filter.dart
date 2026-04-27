class TransactionFilter {
  final String? type; // 'income', 'expense', null (all)
  final String? source; // 'personal', 'community', null (all)
  final DateTime? startDate;
  final DateTime? endDate;
  final String? categoryId;
  final FilterPeriod? period; // day, month, custom

  TransactionFilter({
    this.type,
    this.source,
    this.startDate,
    this.endDate,
    this.categoryId,
    this.period,
  });

  bool get hasFilter =>
      type != null ||
      source != null ||
      startDate != null ||
      endDate != null ||
      categoryId != null ||
      period != null;

  TransactionFilter copyWith({
    String? type,
    String? source,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    FilterPeriod? period,
  }) {
    return TransactionFilter(
      type: type ?? this.type,
      source: source ?? this.source,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categoryId: categoryId ?? this.categoryId,
      period: period ?? this.period,
    );
  }

  void clear() {}
}

enum FilterPeriod {
  today,
  yesterday,
  thisWeek,
  thisMonth,
  lastMonth,
  custom,
}
