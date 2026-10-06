import '../../../../core/bloc/safe_cubit.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/godown_repository.dart';
import '../../data/models/product_packaging.dart';
import '../../data/models/stock_position.dart';
import 'bag_stock_state.dart';

/// Draft-then-submit sealed-bag counting, mirroring the admin's
/// `BagStockCubit`: typing updates [draftCounts] only; [submitDraft] decides
/// POST (today not yet complete) vs PATCH (already started) from the live
/// `check-todays-inventory` signal, then refreshes.
class BagStockCubit extends SafeCubit<BagStockState> {
  final GodownRepository _repository;

  BagStockCubit({required GodownRepository repository})
    : _repository = repository,
      super(const BagStockState());

  Future<void> load() async {
    emit(state.copyWith(status: BagStockStatus.loading, clearError: true));
    try {
      final List<GodownProductPackaging> packagings = await _repository
          .fetchProductPackagings();
      final bool isComplete = await _repository.fetchTodaysInventoryStatus();
      final Map<String, BagStockPosition> positions = await _fetchPositions();
      emit(
        state.copyWith(
          status: BagStockStatus.loaded,
          packagings: packagings,
          isComplete: isComplete,
          positions: positions,
          draftCounts: const {},
          clearError: true,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: BagStockStatus.failure,
          errorMessage: error.message,
        ),
      );
    }
  }

  /// The position read is supplementary -- a packaging not yet counted has
  /// none, and a failure here should not block the counting screen itself.
  Future<Map<String, BagStockPosition>> _fetchPositions() async {
    try {
      final List<BagStockPosition> positions = await _repository
          .fetchBagStockPositions();
      return {
        for (final BagStockPosition position in positions)
          position.packagingPublicId: position,
      };
    } on ApiException {
      return const {};
    }
  }

  void setDraftCount(String packagingPublicId, int? count) {
    if (packagingPublicId.isEmpty) return;
    final Map<String, int> draft = Map<String, int>.from(state.draftCounts);
    if (count == null) {
      draft.remove(packagingPublicId);
    } else {
      draft[packagingPublicId] = count;
    }
    emit(state.copyWith(draftCounts: draft));
  }

  Future<bool> submitDraft() async {
    final Map<String, int> draft = Map<String, int>.from(state.draftCounts);
    if (draft.isEmpty) return false;

    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      if (state.isComplete) {
        await _repository.patchBagStock(draft);
      } else {
        await _repository.replaceBagStock(draft);
      }
      emit(
        state.copyWith(
          isSubmitting: false,
          isComplete: true,
          draftCounts: const {},
        ),
      );
      await load();
      return true;
    } on ApiException catch (error) {
      emit(state.copyWith(isSubmitting: false, errorMessage: error.message));
      return false;
    }
  }
}
