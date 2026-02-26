import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State provider to manage the grouping preference in PO Item summary list
/// Default: not grouped (flat list)
final poItemSummaryGroupedProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});
