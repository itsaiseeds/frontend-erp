import '../../../../core/bloc/safe_cubit.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/godown_repository.dart';
import '../../data/models/packet_stock_draft_line.dart';
import '../../data/models/product_packaging.dart';
import '../../data/models/stock_position.dart';
import 'packet_stock_state.dart';

/// Draft-then-submit loose-packet counting, keyed by the `(product,
/// packet_weight)` pair rather than packaging public_id -- that is the write
/// endpoint's real identity. There is no server completeness signal for
/// packet stock (unlike bag stock's `is_complete`), so this cubit tracks
/// "have I written today" locally for the session: POST on the first
/// successful submit, PATCH after that -- an accepted simplification per the
/// feature spec, since the flag resets if the screen/cubit is recreated.
class PacketStockCubit extends SafeCubit<PacketStockState> {
  final GodownRepository _repository;
  bool _hasSubmittedToday = false;

  PacketStockCubit({required GodownRepository repository})
    : _repository = repository,
      super(const PacketStockState());

  Future<void> load() async {
    emit(state.copyWith(status: PacketStockStatus.loading, clearError: true));
    try {
      final List<GodownProductPackaging> packagings = await _repository
          .fetchProductPackagings();
      final Map<String, PacketStockPosition> positions =
          await _fetchPositions();
      emit(
        state.copyWith(
          status: PacketStockStatus.loaded,
          packagings: _dedupedByPair(packagings),
          positions: positions,
          draftCounts: const {},
          clearError: true,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: PacketStockStatus.failure,
          errorMessage: error.message,
        ),
      );
    }
  }

  /// The position read is supplementary -- a pool not yet counted has none,
  /// and a failure here should not block the counting screen itself.
  Future<Map<String, PacketStockPosition>> _fetchPositions() async {
    try {
      final List<PacketStockPosition> positions = await _repository
          .fetchPacketStockPositions();
      return {
        for (final PacketStockPosition position in positions)
          position.draftKey: position,
      };
    } on ApiException {
      return const {};
    }
  }

  /// Several packagings can share a `(product, packet_weight)` pair (e.g. two
  /// bag sizes built from the same 1.1kg packet); the loose count only cares
  /// about the pair, so collapse to one row per pair, first-seen wins.
  List<GodownProductPackaging> _dedupedByPair(
    List<GodownProductPackaging> packagings,
  ) {
    final Map<String, GodownProductPackaging> byPair = {};
    for (final GodownProductPackaging packaging in packagings) {
      final String key = PacketStockDraftLine.draftKeyOf(
        packaging.product.publicId,
        packaging.packetWeight,
      );
      byPair.putIfAbsent(key, () => packaging);
    }
    return byPair.values.toList();
  }

  void setDraftCount(String draftKey, int? count) {
    if (draftKey.isEmpty) return;
    final Map<String, int> draft = Map<String, int>.from(state.draftCounts);
    if (count == null) {
      draft.remove(draftKey);
    } else {
      draft[draftKey] = count;
    }
    emit(state.copyWith(draftCounts: draft));
  }

  Future<bool> submitDraft() async {
    final List<PacketStockDraftLine> toSubmit = [
      for (final PacketStockDraftLine line in state.lines)
        if (line.draftCount != null) line,
    ];
    if (toSubmit.isEmpty) return false;

    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      final List<Map<String, dynamic>> lines = [
        for (final PacketStockDraftLine line in toSubmit)
          {
            'product': line.productPublicId,
            'packet_weight': line.packetWeight,
            'packets': line.draftCount,
          },
      ];

      if (_hasSubmittedToday) {
        await _repository.patchPacketStock(lines);
      } else {
        await _repository.replacePacketStock(lines);
        _hasSubmittedToday = true;
      }
      emit(state.copyWith(isSubmitting: false, draftCounts: const {}));
      await load();
      return true;
    } on ApiException catch (error) {
      emit(state.copyWith(isSubmitting: false, errorMessage: error.message));
      return false;
    }
  }
}
