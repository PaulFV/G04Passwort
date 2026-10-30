import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_x.dart';
import '../../../../widgets/glass_card.dart';
import '../../application/vault_providers.dart';

/// Read-only field in the item detail view with reveal & copy actions.
class FieldRow extends ConsumerStatefulWidget {
  const FieldRow({
    super.key,
    required this.label,
    required this.value,
    this.secret = false,
    this.copyable = true,
    this.monospace = false,
    this.footer,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final bool secret;
  final bool copyable;
  final bool monospace;
  final Widget? footer;
  final int maxLines;

  @override
  ConsumerState<FieldRow> createState() => _FieldRowState();
}

class _FieldRowState extends ConsumerState<FieldRow> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final hidden = widget.secret && !_revealed;
    final shown = hidden
        ? '•' * widget.value.length.clamp(8, 16)
        : widget.value;
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
      borderRadius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: context.text.labelSmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 3),
                    SelectableText(
                      shown.isEmpty ? '—' : shown,
                      minLines: 1,
                      maxLines: _revealed ? null : widget.maxLines,
                      style: context.text.bodyLarge?.copyWith(
                        fontFamily:
                            widget.monospace || (widget.secret && _revealed)
                            ? 'monospace'
                            : null,
                        letterSpacing: hidden ? 2 : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.secret && widget.value.isNotEmpty)
                IconButton(
                  tooltip: _revealed ? 'Verbergen' : 'Anzeigen',
                  icon: Icon(
                    _revealed
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () => setState(() => _revealed = !_revealed),
                ),
              if (widget.copyable && widget.value.isNotEmpty)
                IconButton(
                  tooltip: 'Kopieren',
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  onPressed: () async {
                    final ok = await ref
                        .read(vaultActionsProvider)
                        .copy(widget.value, secret: widget.secret);
                    if (!context.mounted) return;
                    if (!ok) {
                      context.showError(kCopyFailed);
                    } else {
                      context.showSnack(
                        widget.secret
                            ? '${widget.label} kopiert – wird automatisch gelöscht'
                            : '${widget.label} kopiert',
                      );
                    }
                  },
                ),
            ],
          ),
          if (widget.footer != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 10),
              child: widget.footer!,
            ),
        ],
      ),
    );
  }
}
