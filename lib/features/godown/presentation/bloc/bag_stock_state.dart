import 'package:equatable/equatable.dart';

import '../../data/models/bag_stock_draft_line.dart';
import '../../data/models/product_packaging.dart';
import '../../data/models/stock_position.dart';

enum BagStockStatus { initial, loading, loaded, failure }

class BagStockState extends Equatable {
  final BagStockStatus status;
  final List<GodownProductPackaging> packagings;
  final Map<String, int> draftCounts;

  /// Keyed by packaging public_id; absent for a packaging never counted.
  final Map<String, BagStockPosition> positions;
  final bool isComplete;
  final bool isSubmitting;
  final String? errorMessage;

  const BagStockState({
    this.status = BagStockStatus.initial,
    this.packagings = const [],
    this.draftCounts = const {},
    this.positions = const {},
    this.isComplete = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  List<BagStockDraftLine> get lines => [
    for (final GodownProductPackaging packaging in packagings)
      BagStockDraftLine(
        packaging: packaging,
        draftCount: draftCounts[packaging.publicId],
        position: positions[packaging.publicId],
      ),
  ];

  BagStockState copyWith({
    BagStockStatus? status,
    List<GodownProductPackaging>? packagings,
    Map<String, int>? draftCounts,
    Map<String, BagStockPosition>? positions,
    bool? isComplete,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BagStockState(
      status: status ?? this.status,
      packagings: packagings ?? this.packagings,
      draftCounts: draftCounts ?? this.draftCounts,
      positions: positions ?? this.positions,
      isComplete: isComplete ?? this.isComplete,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    packagings,
    draftCounts,
    positions,
    isComplete,
    isSubmitting,
    errorMessage,
  ];
}
