import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/providers/user_profile_state_provider.dart';
import '../../../../core/services/entity_service.dart';
import '../model/po_collection_model.dart';
import '../service/po_collection_service_impl.dart';
import '../adapter/po_collection_adapter.dart';

/// Mapper provider
final poCollectionMapperProvider = Provider<EntityMapper<ModelPoCollection>>((
  ref,
) {
  return ModelPoCollectionMapper();
});

/// Service provider
final poCollectionServiceProvider = Provider<PoCollectionServiceImpl>((ref) {
  return PoCollectionServiceImpl(
    ref.watch(poCollectionMapperProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(loggerServiceProvider),
  );
});

/// Adapter provider
final poCollectionAdapterProvider = Provider<PoCollectionAdapter>((ref) {
  return PoCollectionAdapter();
});

/// State provider for a collection associated with a PO
final poCollectionByPoIdProvider = FutureProvider.family
    .autoDispose<ModelPoCollection?, String>((ref, poId) async {
      final service = ref.read(poCollectionServiceProvider);
      return await service.fetchByPoId(poId);
    });

/// Fetches a single collection by its own ID
final poCollectionByIdProvider = FutureProvider.autoDispose
    .family<ModelPoCollection?, String>((ref, collectionId) async {
      final service = ref.read(poCollectionServiceProvider);
      return await service.fetchById(collectionId);
    });

/// Real-time stream of all collections
final poCollectionsStreamProvider =
    StreamProvider.autoDispose<List<ModelPoCollection>>((ref) {
      final service = ref.read(poCollectionServiceProvider);
      return service.streamEntities();
    });

/// Form state for PO Collection
class PoCollectionFormState {
  final double collectedAmount;
  final bool isCash;
  final bool isOnline;
  final bool isCheque;
  final String? chequeNo;
  final bool isSign;
  final double? signAmount;
  final String? comments;
  final bool isLoading;
  final String? error;

  PoCollectionFormState({
    this.collectedAmount = 0.0,
    this.isCash = false,
    this.isOnline = false,
    this.isCheque = false,
    this.chequeNo,
    this.isSign = false,
    this.signAmount = 0.0,
    this.comments,
    this.isLoading = false,
    this.error,
  });

  PoCollectionFormState copyWith({
    double? collectedAmount,
    bool? isCash,
    bool? isOnline,
    bool? isCheque,
    String? chequeNo,
    bool? isSign,
    double? signAmount,
    String? comments,
    bool? isLoading,
    String? error,
  }) {
    return PoCollectionFormState(
      collectedAmount: collectedAmount ?? this.collectedAmount,
      isCash: isCash ?? this.isCash,
      isOnline: isOnline ?? this.isOnline,
      isCheque: isCheque ?? this.isCheque,
      chequeNo: chequeNo ?? this.chequeNo,
      isSign: isSign ?? this.isSign,
      signAmount: signAmount ?? this.signAmount,
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing PO Collection form state
class PoCollectionFormNotifier extends StateNotifier<PoCollectionFormState> {
  final Ref ref;

  PoCollectionFormNotifier(this.ref) : super(PoCollectionFormState());

  void updateCollectedAmount(double value) {
    state = state.copyWith(collectedAmount: value);
  }

  void toggleCash(bool value) => state = state.copyWith(isCash: value);
  void toggleOnline(bool value) => state = state.copyWith(isOnline: value);
  void toggleCheque(bool value) {
    state = state.copyWith(
      isCheque: value,
      chequeNo: value ? state.chequeNo : null, // Clear if unchecked
    );
  }

  void updateChequeNo(String value) => state = state.copyWith(chequeNo: value);

  void toggleSign(bool value) {
    state = state.copyWith(
      isSign: value,
      signAmount: value ? state.signAmount : 0.0, // Reset if unchecked
    );
  }

  void updateSignAmount(double value) =>
      state = state.copyWith(signAmount: value);
  void updateComments(String value) => state = state.copyWith(comments: value);

  Future<bool> save({String? entityId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = ref.read(poCollectionServiceProvider);
      final userId = ref.read(userProfileStateProvider).profile?.userId;

      if (userId == null) throw Exception('User not logged in');

      // For generic form, we need to know poId. If it's not in state,
      // we might need to handle it. Actually poId is a required field.
      // In generic form, it should be passed via initialValues or updated via updateField.

      final entity = ModelPoCollection(
        collectionId: entityId,
        poId: _currentPoId ?? '', // Fallback if not set
        collectedAmount: state.collectedAmount,
        isCash: state.isCash,
        isOnline: state.isOnline,
        isCheque: state.isCheque,
        chequeNo: state.chequeNo,
        isSign: state.isSign,
        signAmount: state.signAmount,
        comments: state.comments,
        createdBy: userId,
        updatedBy: userId,
      );

      if (entityId == null) {
        await service.create(entity);
      } else {
        await service.update(entityId, entity);
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  String? _currentPoId;

  /// Generic update method for ModuleRouteGenerator
  void updateField(String field, dynamic value) {
    if (field == ModelPoCollectionFields.collectedAmount) {
      updateCollectedAmount(
        value is double ? value : double.tryParse(value.toString()) ?? 0.0,
      );
    } else if (field == ModelPoCollectionFields.isCash) {
      toggleCash(value as bool);
    } else if (field == ModelPoCollectionFields.isOnline) {
      toggleOnline(value as bool);
    } else if (field == ModelPoCollectionFields.isCheque) {
      toggleCheque(value as bool);
    } else if (field == ModelPoCollectionFields.chequeNo) {
      updateChequeNo(value as String);
    } else if (field == ModelPoCollectionFields.isSign) {
      toggleSign(value as bool);
    } else if (field == ModelPoCollectionFields.signAmount) {
      updateSignAmount(
        value is double ? value : double.tryParse(value.toString()) ?? 0.0,
      );
    } else if (field == ModelPoCollectionFields.comments) {
      updateComments(value as String);
    } else if (field == ModelPoCollectionFields.poId) {
      _currentPoId = value as String;
    }
  }

  /// Generic delete method for ModuleRouteGenerator
  Future<bool> delete(String id) async {
    try {
      final service = ref.read(poCollectionServiceProvider);
      await service.deleteEntityById(id);
      return true;
    } catch (e) {
      return false;
    }
  }

  void resetWith(ModelPoCollection entity) {
    state = PoCollectionFormState(
      collectedAmount: entity.collectedAmount,
      isCash: entity.isCash,
      isOnline: entity.isOnline,
      isCheque: entity.isCheque,
      chequeNo: entity.chequeNo,
      isSign: entity.isSign,
      signAmount: entity.signAmount,
      comments: entity.comments,
    );
  }
}

final poCollectionFormProvider =
    StateNotifierProvider.autoDispose<
      PoCollectionFormNotifier,
      PoCollectionFormState
    >((ref) {
      return PoCollectionFormNotifier(ref);
    });
