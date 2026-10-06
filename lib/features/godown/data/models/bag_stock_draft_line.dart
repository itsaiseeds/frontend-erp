import 'package:equatable/equatable.dart';

import 'product_packaging.dart';
import 'stock_position.dart';

/// One row the bag-stock screen shows: a packaging plus whatever count is
/// currently in the draft for it (or null when untouched this session), plus
/// its live position if it has ever been counted. The cubit drives the row
/// list straight off `GodownProductPackaging` and a `Map<String, int>` draft
/// keyed by packaging public_id -- this is just the pairing the UI iterates
/// over, not a response-parsing model.
class BagStockDraftLine extends Equatable {
  final GodownProductPackaging packaging;
  final int? draftCount;
  final BagStockPosition? position;

  const BagStockDraftLine({
    required this.packaging,
    this.draftCount,
    this.position,
  });

  String get packagingPublicId => packaging.publicId;

  bool get hasPosition => position != null;

  @override
  List<Object?> get props => [packaging, draftCount, position];
}
