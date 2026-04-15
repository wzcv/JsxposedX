import 'package:JsxposedX/core/extensions/context_extensions.dart';
import 'package:JsxposedX/generated/memory_tool.g.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

String resolveMemoryToolSearchResultDisplayValue({
  required SearchResult result,
  required AsyncValue<Map<int, MemoryValuePreview>> livePreviewsAsync,
}) {
  return livePreviewsAsync.when(
    data: (previews) => previews[result.address]?.displayValue ?? '--',
    error: (_, _) => '--',
    loading: () => '...',
  );
}

String formatMemoryToolSearchResultAddress(int value) {
  return value.toRadixString(16).toUpperCase();
}

String mapMemoryToolSearchResultTypeLabel({
  required SearchValueType type,
  required String displayValue,
}) {
  return switch (type) {
    SearchValueType.i8 => 'I8',
    SearchValueType.i16 => 'I16',
    SearchValueType.i32 => 'I32',
    SearchValueType.i64 => 'I64',
    SearchValueType.f32 => 'F32',
    SearchValueType.f64 => 'F64',
    SearchValueType.bytes => _looksLikeHexByteSequence(displayValue)
        ? 'AOB'
        : 'TEXT',
  };
}

String mapMemoryToolSearchResultRegionTypeLabel(
  BuildContext context,
  String regionTypeKey,
) {
  return switch (regionTypeKey) {
    'anonymous' => context.l10n.memoryToolRangeSectionAnonymous,
    'java' => context.l10n.memoryToolRangeSectionJava,
    'javaHeap' => context.l10n.memoryToolRangeSectionJavaHeap,
    'cAlloc' => context.l10n.memoryToolRangeSectionCAlloc,
    'cHeap' => context.l10n.memoryToolRangeSectionCHeap,
    'cData' => context.l10n.memoryToolRangeSectionCData,
    'cBss' => context.l10n.memoryToolRangeSectionCBss,
    'codeApp' => context.l10n.memoryToolRangeSectionCodeApp,
    'codeSys' => context.l10n.memoryToolRangeSectionCodeSys,
    'stack' => context.l10n.memoryToolRangeSectionStack,
    'ashmem' => context.l10n.memoryToolRangeSectionAshmem,
    'bad' => context.l10n.memoryToolRangeSectionBad,
    'other' => context.l10n.memoryToolRangeSectionOther,
    _ => context.l10n.memoryToolRangeSectionOther,
  };
}

Color mapMemoryToolSearchResultTypeBadgeBackground(SearchValueType type) {
  return switch (type) {
    SearchValueType.i8 ||
    SearchValueType.i16 ||
    SearchValueType.i32 => const Color(0xFFE8F4FF),
    SearchValueType.i64 => const Color(0xFFEAF2FF),
    SearchValueType.f32 || SearchValueType.f64 => const Color(0xFFEAFBF1),
    SearchValueType.bytes => const Color(0xFFFFF1E4),
  };
}

Color mapMemoryToolSearchResultTypeBadgeForeground(SearchValueType type) {
  return switch (type) {
    SearchValueType.i8 ||
    SearchValueType.i16 ||
    SearchValueType.i32 => const Color(0xFF1E6FD9),
    SearchValueType.i64 => const Color(0xFF3157C8),
    SearchValueType.f32 || SearchValueType.f64 => const Color(0xFF1F8A4D),
    SearchValueType.bytes => const Color(0xFFB56816),
  };
}

Color mapMemoryToolSearchResultRegionBadgeBackground(String regionTypeKey) {
  return switch (regionTypeKey) {
    'anonymous' => const Color(0xFFF2F3F7),
    'java' || 'javaHeap' => const Color(0xFFFFF3D9),
    'cAlloc' || 'cHeap' || 'cData' || 'cBss' => const Color(0xFFE9F7EC),
    'codeApp' || 'codeSys' => const Color(0xFFECEBFF),
    'stack' => const Color(0xFFFFE9EE),
    'ashmem' => const Color(0xFFE9F8F7),
    'bad' => const Color(0xFFFFE5E5),
    'other' => const Color(0xFFF4F1FF),
    _ => const Color(0xFFF4F1FF),
  };
}

Color mapMemoryToolSearchResultRegionBadgeForeground(String regionTypeKey) {
  return switch (regionTypeKey) {
    'anonymous' => const Color(0xFF5F6675),
    'java' || 'javaHeap' => const Color(0xFF9A6A00),
    'cAlloc' || 'cHeap' || 'cData' || 'cBss' => const Color(0xFF2C8A52),
    'codeApp' || 'codeSys' => const Color(0xFF5A46CC),
    'stack' => const Color(0xFFC14568),
    'ashmem' => const Color(0xFF1E8C84),
    'bad' => const Color(0xFFC13F3F),
    'other' => const Color(0xFF6E56CF),
    _ => const Color(0xFF6E56CF),
  };
}

bool _looksLikeHexByteSequence(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return false;
  }
  return RegExp(r'^[0-9A-F]{2}( [0-9A-F]{2})*$').hasMatch(normalized);
}
