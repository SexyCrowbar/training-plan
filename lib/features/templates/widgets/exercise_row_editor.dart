import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/db/app_database.dart';

/// Inline editor row for a single [TemplateExercise]. Each field commits on
/// `onEditingComplete` / unfocus so there's no separate "save" button.
class ExerciseRowEditor extends StatefulWidget {
  final TemplateExercise exercise;
  final void Function({
    String? name,
    int? sets,
    String? target,
    int? restSeconds,
    String? note,
  }) onCommit;
  final VoidCallback onDelete;
  final Widget? dragHandle;

  const ExerciseRowEditor({
    super.key,
    required this.exercise,
    required this.onCommit,
    required this.onDelete,
    this.dragHandle,
  });

  @override
  State<ExerciseRowEditor> createState() => _ExerciseRowEditorState();
}

class _ExerciseRowEditorState extends State<ExerciseRowEditor> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _setsCtrl;
  late final TextEditingController _targetCtrl;
  late final TextEditingController _restCtrl;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.exercise.name);
    _setsCtrl = TextEditingController(text: widget.exercise.sets.toString());
    _targetCtrl = TextEditingController(text: widget.exercise.target);
    _restCtrl = TextEditingController(text: widget.exercise.restSeconds.toString());
    _noteCtrl = TextEditingController(text: widget.exercise.note);
  }

  @override
  void didUpdateWidget(covariant ExerciseRowEditor old) {
    super.didUpdateWidget(old);
    _syncIfChanged(_nameCtrl, widget.exercise.name, old.exercise.name);
    _syncIfChanged(_setsCtrl, widget.exercise.sets.toString(), old.exercise.sets.toString());
    _syncIfChanged(_targetCtrl, widget.exercise.target, old.exercise.target);
    _syncIfChanged(
      _restCtrl,
      widget.exercise.restSeconds.toString(),
      old.exercise.restSeconds.toString(),
    );
    _syncIfChanged(_noteCtrl, widget.exercise.note, old.exercise.note);
  }

  void _syncIfChanged(TextEditingController c, String next, String oldVal) {
    if (next != oldVal && c.text != next) c.text = next;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _setsCtrl.dispose();
    _targetCtrl.dispose();
    _restCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _commitName() {
    final v = _nameCtrl.text.trim();
    if (v.isNotEmpty && v != widget.exercise.name) widget.onCommit(name: v);
  }

  void _commitSets() {
    final v = int.tryParse(_setsCtrl.text.trim());
    if (v != null && v > 0 && v != widget.exercise.sets) {
      widget.onCommit(sets: v);
    } else {
      _setsCtrl.text = widget.exercise.sets.toString();
    }
  }

  void _commitTarget() {
    final v = _targetCtrl.text.trim();
    if (v.isNotEmpty && v != widget.exercise.target) widget.onCommit(target: v);
  }

  void _commitRest() {
    final v = int.tryParse(_restCtrl.text.trim());
    if (v != null && v >= 0 && v != widget.exercise.restSeconds) {
      widget.onCommit(restSeconds: v);
    } else {
      _restCtrl.text = widget.exercise.restSeconds.toString();
    }
  }

  void _commitNote() {
    final v = _noteCtrl.text;
    if (v != widget.exercise.note) widget.onCommit(note: v);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.dragHandle != null) widget.dragHandle!,
              Expanded(
                child: Focus(
                  onFocusChange: (f) {
                    if (!f) _commitName();
                  },
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Exercise name',
                      border: InputBorder.none,
                      isDense: true,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                    onEditingComplete: _commitName,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                icon: Icon(Icons.delete_outline, color: scheme.error, size: 20),
                onPressed: widget.onDelete,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _LabeledField(
                  label: 'Sets',
                  child: TextField(
                    controller: _setsCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(hintText: '3'),
                    onEditingComplete: _commitSets,
                    onTapOutside: (_) => _commitSets(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: _LabeledField(
                  label: 'Target',
                  child: TextField(
                    controller: _targetCtrl,
                    decoration: const InputDecoration(hintText: '3-5 reps'),
                    onEditingComplete: _commitTarget,
                    onTapOutside: (_) => _commitTarget(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _LabeledField(
                  label: 'Rest (s)',
                  child: TextField(
                    controller: _restCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(hintText: '90'),
                    onEditingComplete: _commitRest,
                    onTapOutside: (_) => _commitRest(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _LabeledField(
            label: 'Note',
            child: TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(hintText: 'Cues, tempo, etc.'),
              style: const TextStyle(fontSize: 12),
              maxLines: null,
              onEditingComplete: _commitNote,
              onTapOutside: (_) => _commitNote(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 2),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
