import 'dart:typed_data';

import 'package:JsxposedX/generated/memory_tool.g.dart';

class MemoryToolSavedItem {
  const MemoryToolSavedItem({
    required this.pid,
    required this.address,
    required this.regionStart,
    required this.regionTypeKey,
    required this.type,
    required this.rawBytes,
    required this.displayValue,
    required this.isFrozen,
    this.isInstructionPatch = false,
    this.instructionText,
  });

  final int pid;
  final int address;
  final int regionStart;
  final String regionTypeKey;
  final SearchValueType type;
  final Uint8List rawBytes;
  final String displayValue;
  final bool isFrozen;
  final bool isInstructionPatch;
  final String? instructionText;

  String get effectiveInstructionText {
    final value = instructionText?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return displayValue;
  }

  factory MemoryToolSavedItem.fromSearchResult({
    required int pid,
    required SearchResult result,
    MemoryValuePreview? preview,
    required bool isFrozen,
    bool isInstructionPatch = false,
    String? instructionText,
  }) {
    return MemoryToolSavedItem(
      pid: pid,
      address: result.address,
      regionStart: result.regionStart,
      regionTypeKey: result.regionTypeKey,
      type: preview?.type ?? result.type,
      rawBytes: preview?.rawBytes ?? result.rawBytes,
      displayValue:
          instructionText ??
          preview?.displayValue ??
          result.displayValue,
      isFrozen: isFrozen,
      isInstructionPatch: isInstructionPatch,
      instructionText: instructionText,
    );
  }

  MemoryToolSavedItem copyWith({
    int? pid,
    int? address,
    int? regionStart,
    String? regionTypeKey,
    SearchValueType? type,
    Uint8List? rawBytes,
    String? displayValue,
    bool? isFrozen,
    bool? isInstructionPatch,
    String? instructionText,
  }) {
    return MemoryToolSavedItem(
      pid: pid ?? this.pid,
      address: address ?? this.address,
      regionStart: regionStart ?? this.regionStart,
      regionTypeKey: regionTypeKey ?? this.regionTypeKey,
      type: type ?? this.type,
      rawBytes: rawBytes ?? this.rawBytes,
      displayValue: displayValue ?? this.displayValue,
      isFrozen: isFrozen ?? this.isFrozen,
      isInstructionPatch: isInstructionPatch ?? this.isInstructionPatch,
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
      displayValue: displayValue,
    );
  }
}
