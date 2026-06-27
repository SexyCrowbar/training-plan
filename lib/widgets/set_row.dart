import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';

class SetRowData {
  final bool done;
  final String weightText;
  final String repsText;

  const SetRowData({required this.done, required this.weightText, required this.repsText});

  SetRowData copyWith({bool? done, String? weightText, String? repsText}) => SetRowData(
        done: done ?? this.done,
        weightText: weightText ?? this.weightText,
        repsText: repsText ?? this.repsText,
      );

  double? get weightKg => double.tryParse(weightText);
  int? get reps => int.tryParse(repsText);
}

class SetRow extends StatefulWidget {
  final int setNumber;
  final SetRowData data;
  final String? suggestedTarget;
  final double? suggestedWeight;
  final void Function(SetRowData next, {required bool triggeredByCheckbox}) onChanged;

  const SetRow({
    super.key,
    required this.setNumber,
    required this.data,
    required this.onChanged,
    this.suggestedTarget,
    this.suggestedWeight,
  });

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;
  late final FocusNode _repsFocusNode;

  @override
  void initState() {
    super.initState();
    _repsFocusNode = FocusNode();

    // Prefill weight from suggestedWeight only when the row is empty (user has
    // not yet typed anything). Fire onChanged once so the committed SetRowData
    // reflects the prefilled value even if the user taps the checkbox without
    // editing the field.
    String initialWeight = widget.data.weightText;
    if (initialWeight.isEmpty && widget.suggestedWeight != null) {
      initialWeight = _formatKgLocal(widget.suggestedWeight!);
      // Schedule the onChanged callback for after the first frame so the widget
      // tree is fully built before we mutate parent state.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onChanged(
            widget.data.copyWith(weightText: initialWeight),
            triggeredByCheckbox: false,
          );
        }
      });
    }

    _weightCtrl = TextEditingController(text: initialWeight);
    _repsCtrl = TextEditingController(text: widget.data.repsText);
  }

  @override
  void didUpdateWidget(covariant SetRow old) {
    super.didUpdateWidget(old);
    if (old.data.weightText != widget.data.weightText &&
        widget.data.weightText != _weightCtrl.text) {
      _weightCtrl.text = widget.data.weightText;
    }
    if (old.data.repsText != widget.data.repsText &&
        widget.data.repsText != _repsCtrl.text) {
      _repsCtrl.text = widget.data.repsText;
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _repsFocusNode.dispose();
    super.dispose();
  }

  String _formatKgLocal(double kg) {
    if (kg == kg.roundToDouble()) return kg.toInt().toString();
    return kg.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${widget.setNumber}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.textMid,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: const InputDecoration(hintText: 'kg'),
              onChanged: (v) => widget.onChanged(
                widget.data.copyWith(weightText: v),
                triggeredByCheckbox: false,
              ),
              onSubmitted: (_) => FocusScope.of(context).requestFocus(_repsFocusNode),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _repsCtrl,
              focusNode: _repsFocusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(hintText: widget.suggestedTarget ?? 'reps'),
              onChanged: (v) => widget.onChanged(
                widget.data.copyWith(repsText: v),
                triggeredByCheckbox: false,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Checkbox(
            value: widget.data.done,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              widget.onChanged(
                widget.data.copyWith(done: v ?? false),
                triggeredByCheckbox: true,
              );
            },
          ),
        ],
      ),
    );
  }
}
