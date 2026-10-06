import 'package:equatable/equatable.dart';

import '../../data/models/packet_stock_draft_line.dart';
import '../../data/models/product_packaging.dart';
import '../../data/models/stock_position.dart';

enum PacketStockStatus { initial, loading, loaded, failure }

class PacketStockState extends Equatable {
  final PacketStockStatus status;
  final List<GodownProductPackaging> packagings;
  final Map<String, int> draftCounts;

  /// Keyed by `(product, packet_weight)` pair; absent for a pool never
  /// counted.
  final Map<String, PacketStockPosition> positions;
  final bool isSubmitting;
  final String? errorMessage;

  const PacketStockState({
    this.status = PacketStockStatus.initial,
    this.packagings = const [],
    this.draftCounts = const {},
    this.positions = const {},
    this.isSubmitting = false,
    this.errorMessage,
  });

  List<PacketStockDraftLine> get lines => [
    for (final GodownProductPackaging packaging in packagings)
      PacketStockDraftLine(
        packaging: packaging,
        draftCount:
            draftCounts[PacketStockDraftLine(packaging: packaging).draftKey],
        position:
            positions[PacketStockDraftLine(packaging: packaging).draftKey],
      ),
  ];

  /// Packet stock has no server completeness signal (unlike bag stock's
  /// `is_complete`), so it is derived locally: today's count is complete once
  /// every pool carries a position. A pool appears in [positions] only once it
  /// has actually been counted today.
  bool get isComplete =>
      packagings.isNotEmpty && lines.every((line) => line.position != null);

  PacketStockState copyWith({
    PacketStockStatus? status,
    List<GodownProductPackaging>? packagings,
    Map<String, int>? draftCounts,
    Map<String, PacketStockPosition>? positions,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PacketStockState(
      status: status ?? this.status,
      packagings: packagings ?? this.packagings,
      draftCounts: draftCounts ?? this.draftCounts,
      positions: positions ?? this.positions,
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
    isSubmitting,
    errorMessage,
  ];
}
