import 'package:JsxposedX/core/extensions/context_extensions.dart';
import 'package:JsxposedX/features/memory_tool_overlay/presentation/states/memory_tool_search_state.dart';
import 'package:JsxposedX/generated/memory_tool.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MemoryToolSearchFormCard extends StatelessWidget {
  const MemoryToolSearchFormCard({
    super.key,
    required this.valueController,
    required this.state,
    required this.actionState,
    required this.hasRunningTask,
    required this.canRunNextScan,
    required this.onValueChanged,
    required this.onTypeChanged,
    required this.onEndianChanged,
    required this.onFirstScan,
    required this.onNextScan,
    required this.onReset,
    this.taskStatus,
  });

  final TextEditingController valueController;
  final MemoryToolSearchState state;
  final AsyncValue<void> actionState;
  final bool hasRunningTask;
  final bool canRunNextScan;
  final ValueChanged<String> onValueChanged;
  final ValueChanged<SearchValueType> onTypeChanged;
  final ValueChanged<bool> onEndianChanged;
  final Future<void> Function() onFirstScan;
  final Future<void> Function() onNextScan;
  final Future<void> Function() onReset;
  final Widget? taskStatus;

  @override
  Widget build(BuildContext context) {
    final isRunning = actionState.isLoading || hasRunningTask;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _FieldLabel(label: context.l10n.memoryToolFieldValue),
        SizedBox(height: 6.r),
        _MemoryToolSearchValueField(
          controller: valueController,
          selectedType: state.selectedType,
          onChanged: onValueChanged,
        ),
        SizedBox(height: 12.r),
        _FieldLabel(label: context.l10n.memoryToolFieldType),
        SizedBox(height: 6.r),
        _MemoryToolSearchTypeField(
          selectedType: state.selectedType,
          onChanged: onTypeChanged,
        ),
        SizedBox(height: 12.r),
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.52,
            ),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: context.colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 8.r),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    context.l10n.memoryToolEndianLabel,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: state.isLittleEndian,
                  onChanged: isRunning ? null : onEndianChanged,
                ),
              ],
            ),
          ),
        ),
        if (state.validationError != null) ...<Widget>[
          SizedBox(height: 10.r),
          Text(
            _validationMessage(context, state.validationError!),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (taskStatus != null) ...<Widget>[
          SizedBox(height: 10.r),
          taskStatus!,
        ],
        if (actionState.hasError) ...<Widget>[
          SizedBox(height: 10.r),
          Text(
            actionState.error.toString(),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.error,
            ),
          ),
        ],
        SizedBox(height: 12.r),
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton(
                onPressed: isRunning
                    ? null
                    : () async {
                        await onFirstScan();
                      },
                child: Text(context.l10n.memoryToolActionFirstScan),
              ),
            ),
            SizedBox(width: 10.r),
            Expanded(
              child: FilledButton.tonal(
                onPressed: isRunning || !canRunNextScan
                    ? null
                    : () async {
                        await onNextScan();
                      },
                child: Text(context.l10n.memoryToolActionNextScan),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.r),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: isRunning
                ? null
                : () async {
                    await onReset();
                  },
            child: Text(context.l10n.memoryToolActionReset),
          ),
        ),
      ],
    );
  }

  String _validationMessage(
    BuildContext context,
    MemoryToolSearchValidationError validationError,
  ) {
    return switch (validationError) {
      MemoryToolSearchValidationError.valueRequired =>
        context.l10n.memoryToolValidationValueRequired,
      MemoryToolSearchValidationError.invalidBytes =>
        context.l10n.memoryToolValidationBytesInvalid,
    };
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: context.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: context.colorScheme.onSurface.withValues(alpha: 0.82),
      ),
    );
  }
}

class _MemoryToolSearchValueField extends StatelessWidget {
  const _MemoryToolSearchValueField({
    required this.controller,
    required this.selectedType,
    required this.onChanged,
  });

  final TextEditingController controller;
  final SearchValueType selectedType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isBytes = selectedType == SearchValueType.bytes;
    final isFloatType =
        selectedType == SearchValueType.f32 || selectedType == SearchValueType.f64;
    final keyboardType = isBytes
        ? TextInputType.visiblePassword
        : TextInputType.numberWithOptions(decimal: isFloatType, signed: true);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: isBytes
          ? <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-FxX ]')),
            ]
          : null,
      style: context.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: isBytes
            ? context.l10n.memoryToolSearchBytesHint
            : context.l10n.memoryToolFieldValueHint,
        filled: true,
        fillColor: context.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.42,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(
            color: context.colorScheme.primary.withValues(alpha: 0.9),
            width: 1.4,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 14.r),
      ),
    );
  }
}

class _MemoryToolSearchTypeField extends StatelessWidget {
  const _MemoryToolSearchTypeField({
    required this.selectedType,
    required this.onChanged,
  });

  final SearchValueType selectedType;
  final ValueChanged<SearchValueType> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<SearchValueType>(
      value: selectedType,
      items: SearchValueType.values
          .map(
            (type) => DropdownMenuItem<SearchValueType>(
              value: type,
              child: Text(_typeLabel(type)),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) {
          return;
        }
        onChanged(value);
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: context.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.42,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(
            color: context.colorScheme.primary.withValues(alpha: 0.9),
            width: 1.4,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 14.r),
      ),
    );
  }

  String _typeLabel(SearchValueType type) {
    return switch (type) {
      SearchValueType.i8 => 'I8',
      SearchValueType.i16 => 'I16',
      SearchValueType.i32 => 'I32',
      SearchValueType.i64 => 'I64',
      SearchValueType.f32 => 'F32',
      SearchValueType.f64 => 'F64',
      SearchValueType.bytes => 'AOB',
    };
  }
}
