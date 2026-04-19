import 'dart:typed_data';

import 'package:JsxposedX/generated/memory_tool.g.dart';

enum MemoryToolDisplayItemKind {
  value,
  instruction,
}

class MemoryToolDisplayItem {
  const MemoryToolDisplayItem({
    required this.address,
    required this.regionStart,
    required this.regionTypeKey,
    required this.type,
    required this.rawBytes,
    required this.displayValue,
    this.kind = MemoryToolDisplayItemKind.value,
    this.instructionText,
  });

  final int address;
  final int regionStart;
  final String regionTypeKey;
  final SearchValueType type;
  final Uint8List rawBytes;
  final String displayValue;
  final MemoryToolDisplayItemKind kind;
  final String? instructionText;

  bool get isInstruction => kind == MemoryToolDisplayItemKind.instruction;

  String get effectiveDisplayValue {
    final resolvedInstruction = instructionText?.trim();
    if (isInstruction && resolvedInstruction != null && resolvedInstruction.isNotEmpty) {
      return resolvedInstruction;
    }
    return displayValue;
  }

  factory MemoryToolDisplayItem.fromSearchResult({
    required SearchResult result,
    MemoryToolDisplayItemKind kind = MemoryToolDisplayItemKind.value,
    String? instructionText,
  }) {
    return MemoryToolDisplayItem(
      address: result.address,
      regionStart: result.regionStart,
      regionTypeKey: result.regionTypeKey,
      type: result.type,
      rawBytes: result.rawBytes,
      displayValue: instructionText ?? result.displayValue,
      kind: kind,
      instructionText: instructionText,
    );
  }

  MemoryToolDisplayItem copyWith({
    int? address,
    int? regionStart,
    String? regionTypeKey,
    SearchValueType? type,
    Uint8List? rawBytes,
    String? displayValue,
    MemoryToolDisplayItemKind? kind,
    String? instructionText,
  }) {
    return MemoryToolDisplayItem(
      address: address ?? this.address,
      regionStart: regionStart ?? this.regionStart,
      regionTypeKey: regionTypeKey ?? this.regionTypeKey,
      type: type ?? this.type,
      rawBytes: rawBytes ?? this.rawBytes,
      displayValue: displayValue ?? this.displayValue,
      kind: kind ?? this.kind,
      instructionText: instructionText ?? this.instructionText,
    );
  }

  SearchResult toSearchResult() {
    return SearchResult(
      address: address,
      regionStart: regionStart,
      regionTypeKey: regionTypeKey,
      type: type,
      rawBytes: rawBytes,
      displayValue: effectiveDisplayValue,
    );
  }
}
