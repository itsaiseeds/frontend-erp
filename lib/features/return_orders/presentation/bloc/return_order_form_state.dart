import 'package:equatable/equatable.dart';

import '../../data/models/return_order.dart';
import '../../data/models/return_order_draft_item.dart';
import '../../data/models/return_order_prefill.dart';

enum ReturnOrderFormStatus { initial, loading, ready, submitting, success, failure }

class ReturnOrderFormState extends Equatable {
  final ReturnOrderFormStatus status;
  final ReturnOrderPrefill? prefill;
  final DateTime returnDate;
  final List<ReturnOrderDraftItem> items;
  final String? errorMessage;

  /// Set once the API accepts the return, so the screen can report the id it
  /// was given.
  final ReturnOrder? created;

  const ReturnOrderFormState({
    this.status = ReturnOrderFormStatus.initial,
    this.prefill,
    required this.returnDate,
    this.items = const [],
    this.errorMessage,
    this.created,
  });

  ReturnOrderFormState copyWith({
    ReturnOrderFormStatus? status,
    ReturnOrderPrefill? prefill,
    DateTime? returnDate,
    List<ReturnOrderDraftItem>? items,
    String? errorMessage,
    bool clearError = false,
    ReturnOrder? created,
  }) {
    return ReturnOrderFormState(
      status: status ?? this.status,
      prefill: prefill ?? this.prefill,
      returnDate: returnDate ?? this.returnDate,
      items: items ?? this.items,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      created: created ?? this.created,
    );
  }

  bool get isLoading => status == ReturnOrderFormStatus.loading;

  bool get isSubmitting => status == ReturnOrderFormStatus.submitting;

  bool get isBusy => isLoading || isSubmitting;

  bool get isReady => status == ReturnOrderFormStatus.ready;

  bool get hasError => status == ReturnOrderFormStatus.failure;

  /// The order must be dispatched or delivered, must not already carry a live
  /// return, and must actually have challan lines to return.
  bool get canCreate => prefill?.canCreate ?? false;

  /// Why the screen is read-only, when it is. Null when a return can be raised.
  String? get blockedReason {
    final ReturnOrderPrefill? data = prefill;
    if (data == null) return null;
    if (data.lines.isEmpty) return ReturnOrderFormBlockX.noLines;
    if (!data.isReturnableOrder) return ReturnOrderFormBlockX.notReturnable;
    if (data.hasLiveReturn) return ReturnOrderFormBlockX.liveReturn;
    return null;
  }

  bool get hasItems => items.isNotEmpty;

  bool get canSubmit =>
      canCreate &&
      items.isNotEmpty &&
      items.every((item) => item.canSubmit) &&
      !isSubmitting;

  int get totalPackets => items.fold(0, (total, item) => total + item.packets);

  num get totalKg => items.fold(0, (total, item) => total + item.kg);

  num get totalAmount => items.fold(0, (total, item) => total + item.lineTotal);

  @override
  List<Object?> get props => [
    status,
    prefill,
    returnDate,
    items,
    errorMessage,
    created,
  ];
}

class ReturnOrderFormBlockX {
  ReturnOrderFormBlockX._();

  static const String noLines = 'block_no_lines';
  static const String notReturnable = 'block_not_returnable';
  static const String liveReturn = 'block_live_return';
}
