import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/debug_log_service.dart';

const bool _showDebugLogInRelease = bool.fromEnvironment(
  'SHOW_DEBUG_LOG',
  defaultValue: false,
);

bool get _canShowDebugLog => kDebugMode || _showDebugLogInRelease;

/// Ouvre la popup affichant le journal de diagnostic en direct.
Future<void> showDebugLogDialog(BuildContext context) {
  if (!_canShowDebugLog) return Future<void>.value();
  return showDialog<void>(
    context: context,
    builder: (_) => const _DebugLogDialog(),
  );
}

/// Bouton discret ouvrant le journal de diagnostic. Invisible en production
/// sauf si le build est lance avec `--dart-define=SHOW_DEBUG_LOG=true`.
class DebugLogButton extends StatelessWidget {
  const DebugLogButton({super.key, this.label = 'Debug'});

  final String label;

  @override
  Widget build(BuildContext context) {
    if (!_canShowDebugLog) {
      return const SizedBox.shrink();
    }

    if (label.isEmpty) {
      return IconButton(
        tooltip: 'Journal de diagnostic',
        onPressed: () => showDebugLogDialog(context),
        icon: const Icon(Icons.bug_report_outlined, size: 20),
        color: const Color(0xFF6B7280),
      );
    }
    return TextButton.icon(
      onPressed: () => showDebugLogDialog(context),
      icon: const Icon(Icons.bug_report_outlined, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF6B7280)),
    );
  }
}

class _DebugLogDialog extends StatelessWidget {
  const _DebugLogDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.bug_report_outlined,
                      color: Color(0xFF0F6D8F)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Journal de diagnostic',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Fermer',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1220),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ValueListenableBuilder<List<DebugLogEntry>>(
                    valueListenable: DebugLogService.instance.entries,
                    builder: (context, entries, _) {
                      if (entries.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'Aucun log pour le moment.\n'
                              'Tentez une connexion, les etapes et erreurs '
                              's\'afficheront ici.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF9AA9B8)),
                            ),
                          ),
                        );
                      }
                      return Scrollbar(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: SelectableText(
                                entry.toString(),
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  height: 1.35,
                                  color: Color(0xFFD7E0EA),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F6D8F)),
                      onPressed: () async {
                        final text =
                            DebugLogService.instance.exportAsText();
                        await Clipboard.setData(ClipboardData(text: text));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Journal copie dans le presse-papiers.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copier le texte'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => DebugLogService.instance.clear(),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Effacer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
