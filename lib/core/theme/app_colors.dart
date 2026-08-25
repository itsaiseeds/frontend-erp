import 'package:flutter/material.dart';

/// Core brand and semantic colors.
class AppColors {
  AppColors._();

  // ── Brand Primary ────────────────────────────────────────────────────────
  static const Color PRIMARY = Color(0xFF16A34A);
  static const Color PRIMARY_LIGHT = Color(
    0xFF22C55E,
  ); // Lighter tint for hover states (non-visual)
  static const Color PRIMARY_DARK = Color(
    0xFF15803D,
  ); // Darker shade for active states

  // ── Neutral ──────────────────────────────────────────────────────────────
  static const Color WHITE = Color(0xFFFFFFFF);
  static const Color BLACK = Color(0xFF000000);

  // ── Backgrounds (derived from white/black) ────────────────────────────────
  static const Color BACKGROUND = Color(
    0xFFF5F5F5,
  ); // Off-white page background
  static const Color SURFACE = Color(0xFFFFFFFF); // Card / panel background
  static const Color SURFACE_VARIANT = Color(
    0xFFF0F0F0,
  ); // Subtle alternate surface
  static const Color DIVIDER = Color(0xFFE0E0E0); // Borders and separators

  // ── Sidebar (Light Modern Theme) ───────────────────────────────────────────
  static const Color SIDEBAR_BG = Color(0xFFF9FAFB); // Very light grey/white
  static const Color SIDEBAR_ACTIVE_BG = Color(0xFFF3F4F6); // Active item bg
  static const Color SIDEBAR_ITEM_HOVER = Color(0xFFF9FAFB);
  static const Color SIDEBAR_BORDER = Color(0xFFF3F4F6);
  static const Color SIDEBAR_DIVIDER = Color(0xFFE5E7EB);
  static const Color SIDEBAR_TEXT = Color(0xFF6B7280);
  static const Color SIDEBAR_TEXT_ACTIVE = Color(0xFF111827);
  static const Color SIDEBAR_ICON = Color(0xFF9CA3AF);
  static const Color SIDEBAR_ICON_ACTIVE = Color(
    0xFF16A34A,
  ); // Using Primary Green

  // ── Upgrade Card ──────────────────────────────────────────────────────────
  static const Color UPGRADE_CARD_BG = Color(
    0xFFEEF2FF,
  ); // Light Indigo/Lavender
  static const Color UPGRADE_TEXT_PRIMARY = Color(0xFF111827);
  static const Color UPGRADE_TEXT_SECONDARY = Color(0xFF6B7280);
  static const Color UPGRADE_BTN_BG = Color(0xFF16A34A); // Using Primary Green

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color TEXT_PRIMARY = Color(
    0xFF111111,
  ); // Near-black for headings/body
  static const Color TEXT_SECONDARY = Color(
    0xFF555555,
  ); // Mid-grey for sub-text
  static const Color TEXT_MUTED = Color(
    0xFF999999,
  ); // Light-grey for hints/captions
  static const Color TEXT_ON_PRIMARY = Color(
    0xFFFFFFFF,
  ); // White text on primary button
  static const Color TEXT_DISABLED = Color(0xFFBBBBBB);
  static const Color TEXT_DARK = Color(0xFF1F2937); // Strong emphasis text

  // ── Semantic: Error ───────────────────────────────────────────────────────
  static const Color ERROR = Color(0xFFD32F2F); // Material Red 700
  static const Color ERROR_LIGHT = Color(0xFFFFEBEE); // Error background tint
  static const Color ERROR_BORDER = Color(0xFFD32F2F);
  static const Color ERROR_BRIGHT = Color(0xFFEF4444); // Bright red for badges/icons

  // ── Semantic: Warning ─────────────────────────────────────────────────────
  static const Color WARNING = Color(0xFFF9A825); // Amber/Yellow shade
  static const Color WARNING_LIGHT = Color(
    0xFFFFFDE7,
  ); // Warning background tint
  static const Color WARNING_BORDER = Color(0xFFF9A825);
  static const Color WARNING_BRIGHT = Color(0xFFF59E0B); // Bright amber for badges

  // ── Semantic: Success ─────────────────────────────────────────────────────
  static const Color SUCCESS = Color(0xFF2E7D32); // Material Green 800
  static const Color SUCCESS_LIGHT = Color(
    0xFFE8F5E9,
  ); // Success background tint
  static const Color SUCCESS_BORDER = Color(0xFF2E7D32);
  static const Color SUCCESS_BRIGHT = Color(0xFF10B981); // Bright green for badges

  // ── Semantic: Info ────────────────────────────────────────────────────────
  static const Color INFO = Color(0xFF1565C0); // Blue (neutral info only)
  static const Color INFO_LIGHT = Color(0xFFE3F2FD);

  // ── Border ───────────────────────────────────────────────────────────────
  static const Color BORDER = Color(0xFFE0E0E0);
  static const Color BORDER_FOCUSED = Color(
    0xFF16A34A,
  ); // Primary color on focus

  // ── Shimmer ───────────────────────────────────────────────────────────────
  static const Color SHIMMER_BASE = Color(0xFFF0F0F0);
  static const Color SHIMMER_HIGHLIGHT = Color(0xFFF9F9F9);

  // ── Overlay ───────────────────────────────────────────────────────────────
  static const Color OVERLAY = Color(0x80000000); // Semi-transparent black
}
