import 'package:equatable/equatable.dart';

/// One swipeable page in [FastModeScreen], generic over bag stock and packet
/// stock so the keypad screen is built once and shared. [key] is whatever the
/// owning cubit uses to look up/store the draft count (packaging public_id
/// for bag stock, the `product|packet_weight` pair for packet stock).
class FastModeRow extends Equatable {
  final String key;
  final String title;
  final String subtitle;
  final String imageUrl;
  final int? draftCount;

  const FastModeRow({
    required this.key,
    required this.title,
    this.subtitle = '',
    this.imageUrl = '',
    this.draftCount,
  });

  @override
  List<Object?> get props => [key, title, subtitle, imageUrl, draftCount];
}
