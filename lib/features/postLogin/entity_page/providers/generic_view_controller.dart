import 'package:flutter_riverpod/flutter_riverpod.dart';

class GenericViewState {
  final bool isLoading;
  final String? error;
  final bool isDeleted;

  const GenericViewState({
    this.isLoading = false,
    this.error,
    this.isDeleted = false,
  });

  GenericViewState copyWith({bool? isLoading, String? error, bool? isDeleted}) {
    return GenericViewState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // Nullable update
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

class GenericViewController
    extends AutoDisposeFamilyNotifier<GenericViewState, String> {
  @override
  GenericViewState build(String arg) {
    return const GenericViewState();
  }

  Future<void> deleteEntity({
    required Future<bool> Function(WidgetRef, String) deleteFunction,
    required String entityId,
    required WidgetRef ref,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await deleteFunction(ref, entityId);
      if (success) {
        state = state.copyWith(isLoading: false, isDeleted: true);
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to delete');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final genericViewControllerProvider = NotifierProvider.autoDispose
    .family<GenericViewController, GenericViewState, String>(
      () => GenericViewController(),
    );
