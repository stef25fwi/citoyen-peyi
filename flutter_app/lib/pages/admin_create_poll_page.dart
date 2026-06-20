import 'package:flutter/material.dart';

import '../services/poll_ai_draft_service.dart';
import '../services/poll_service.dart';

class AdminCreatePollPage extends StatefulWidget {
  const AdminCreatePollPage({super.key});

  @override
  State<AdminCreatePollPage> createState() => _AdminCreatePollPageState();
}

class _AdminCreatePollPageState extends State<AdminCreatePollPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _questionController = TextEditingController();
  final _targetPopulationController = TextEditingController();
  final _voterCountController = TextEditingController(text: '50');
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  DateTime? _openDate;
  DateTime? _closeDate;
  bool _isSubmitting = false;
  bool _isRewritingWithAi = false;
  bool _aiProposalAccepted = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _questionController.dispose();
    _targetPopulationController.dispose();
    _voterCountController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '';
    }

    return value.toIso8601String().split('T').first;
  }

  Future<void> _pickDate({required bool isOpenDate}) async {
    final initialDate = isOpenDate
        ? (_openDate ?? DateTime.now())
        : (_closeDate ?? _openDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      if (isOpenDate) {
        _openDate = picked;
        if (_closeDate != null && !_closeDate!.isAfter(picked)) {
          _closeDate = picked.add(const Duration(days: 1));
        }
      } else {
        _closeDate = picked;
      }
    });
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) {
      return;
    }

    setState(() {
      final controller = _optionControllers.removeAt(index);
      controller.dispose();
    });
  }

  PollAiDraft _currentAiDraft() {
    return PollAiDraft(
      projectTitle: _titleController.text,
      description: _descriptionController.text,
      question: _questionController.text,
      targetPopulation: _targetPopulationController.text,
      options: _optionControllers.map((item) => item.text).toList(),
    );
  }

  void _applyAiDraft(PollAiDraft draft) {
    final options = draft.options
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (options.length < 2) {
      return;
    }

    setState(() {
      _titleController.text = draft.projectTitle;
      _descriptionController.text = draft.description;
      _questionController.text = draft.question;
      _targetPopulationController.text = draft.targetPopulation;

      for (final controller in _optionControllers) {
        controller.dispose();
      }

      _optionControllers
        ..clear()
        ..addAll(options.map((label) => TextEditingController(text: label)));

      _aiProposalAccepted = true;
    });
  }

  Future<void> _requestAiRewrite() async {
    if (_isSubmitting || _isRewritingWithAi) {
      return;
    }

    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Completez les champs obligatoires avant de lancer l assistant IA.'),
        ),
      );
      return;
    }

    final original = _currentAiDraft();

    setState(() {
      _isRewritingWithAi = true;
    });

    try {
      final proposal = await PollAiDraftService.instance.rewriteDraft(original);

      if (!mounted) {
        return;
      }

      final accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _PollAiProposalDialog(
          original: original,
          proposal: proposal,
        ),
      );

      if (accepted == true) {
        _applyAiDraft(proposal);
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Proposition IA appliquee. Vous pouvez maintenant creer la consultation.'),
          ),
        );
      }
    } on PollAiDraftServiceException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange.shade800,
          content: Text(error.message),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange.shade800,
          content: Text('Assistant IA indisponible: ${error.toString()}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRewritingWithAi = false;
        });
      }
    }
  }

  Widget _buildAiAssistantTopCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;

            final textContent = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Assistant de redaction IA disponible',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Remplissez les champs de la consultation, puis cliquez ici pour proposer une reformulation claire, neutre et professionnelle avant la creation.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                if (_aiProposalAccepted) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Proposition IA appliquee. Vous pouvez maintenant creer la consultation.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ],
            );

            final button = FilledButton.icon(
              onPressed: _isSubmitting || _isRewritingWithAi
                  ? null
                  : _requestAiRewrite,
              icon: _isRewritingWithAi
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(
                _isRewritingWithAi
                    ? 'Reformulation IA...'
                    : _aiProposalAccepted
                        ? 'Relancer l assistant IA'
                        : 'Assistant de redaction IA',
              ),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  textContent,
                  const SizedBox(height: 14),
                  button,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: textContent),
                const SizedBox(width: 16),
                button,
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) {
      return;
    }

    final openDate = _openDate ?? DateTime.now();
    final closeDate = _closeDate;
    if (closeDate != null && !closeDate.isAfter(openDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'La date de fermeture doit etre posterieure a la date d\'ouverture.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await PollService.instance.createPoll(
        projectTitle: _titleController.text,
        description: _descriptionController.text,
        question: _questionController.text,
        options: _optionControllers.map((item) => item.text).toList(),
        targetPopulation: _targetPopulationController.text,
        openDate: _formatDate(openDate),
        closeDate: _formatDate(closeDate ?? openDate),
        totalVoters: int.tryParse(_voterCountController.text.trim()) ?? 50,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consultation creee avec succes.')),
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
          '/admin', (route) => route.settings.name == '/');
    } catch (error, stackTrace) {
      debugPrint('[AdminCreatePoll] createPoll failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            'Creation de la consultation impossible: ${error.toString()}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildPlanningSection() {
    return _FormSection(
      title: 'Planification',
      child: Column(
        children: [
          _DateField(
            label: 'Date d\'ouverture',
            value: _formatDate(_openDate),
            onTap: () => _pickDate(isOpenDate: true),
          ),
          const SizedBox(height: 12),
          _DateField(
            label: 'Date de fermeture',
            value: _formatDate(_closeDate),
            onTap: () => _pickDate(isOpenDate: false),
          ),
        ],
      ),
    );
  }

  Widget _buildCapacitySection(ThemeData theme) {
    return _FormSection(
      title: 'Capacite du vote',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _targetPopulationController,
            decoration: const InputDecoration(
              labelText: 'Population cible',
              hintText: 'Ex : habitants majeurs de la commune',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _voterCountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Objectif de participation',
            ),
            validator: (value) {
              final parsed = int.tryParse((value ?? '').trim());
              if (parsed == null || parsed < 1 || parsed > 1000) {
                return 'Saisir une valeur entre 1 et 1000.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Ce total sert uniquement a mesurer la participation attendue. Aucun stock de QR code n\'est genere a cette etape.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Creer une consultation'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 20),
              children: [
                _FormSection(
                  title: 'Informations du projet',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Titre du projet',
                          hintText: 'Ex : Reamenagement du centre-ville',
                        ),
                        maxLength: 255,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le titre du projet est obligatoire.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText:
                              'Contexte, objectifs et informations utiles pour les citoyens',
                        ),
                        minLines: 3,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _questionController,
                        decoration: const InputDecoration(
                          labelText: 'Question de la consultation',
                          hintText: 'Ex : Quelle option preferez-vous ?',
                        ),
                        minLines: 2,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La question de la consultation est obligatoire.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildAiAssistantTopCard(theme),
                const SizedBox(height: 16),
                _FormSection(
                  title: 'Options de vote',
                  action: TextButton.icon(
                    onPressed: _addOption,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Ajouter'),
                  ),
                  child: Column(
                    children: [
                      for (var index = 0;
                          index < _optionControllers.length;
                          index++)
                        Padding(
                          padding: EdgeInsets.only(
                              bottom: index == _optionControllers.length - 1
                                  ? 0
                                  : 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                child: Text('${index + 1}'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _optionControllers[index],
                                  decoration: InputDecoration(
                                      labelText: 'Option ${index + 1}'),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Toutes les options doivent etre remplies.';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              if (_optionControllers.length > 2) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _removeOption(index),
                                  icon:
                                      const Icon(Icons.delete_outline_rounded),
                                  tooltip: 'Supprimer cette option',
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 720;
                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildPlanningSection()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildCapacitySection(theme)),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPlanningSection(),
                        const SizedBox(height: 16),
                        _buildCapacitySection(theme),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _isSubmitting || _isRewritingWithAi
                          ? null
                          : _requestAiRewrite,
                      icon: _isRewritingWithAi
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome_rounded),
                      label: Text(
                        _isRewritingWithAi
                            ? 'Reformulation IA...'
                            : _aiProposalAccepted
                                ? 'Proposition IA appliquee'
                                : 'Assistant de redaction IA',
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(_isSubmitting
                          ? 'Creation...'
                          : 'Creer la consultation'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PollAiProposalDialog extends StatelessWidget {
  const _PollAiProposalDialog({
    required this.original,
    required this.proposal,
  });

  final PollAiDraft original;
  final PollAiDraft proposal;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Proposition de l assistant IA'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                'Comparez votre texte avec la proposition IA. Vous pouvez appliquer la proposition ou revenir a votre version.',
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 680;
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _PollDraftPreview(
                            title: 'Votre version',
                            draft: original,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PollDraftPreview(
                            title: 'Proposition IA',
                            draft: proposal,
                            highlighted: true,
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      _PollDraftPreview(
                        title: 'Votre version',
                        draft: original,
                      ),
                      const SizedBox(height: 12),
                      _PollDraftPreview(
                        title: 'Proposition IA',
                        draft: proposal,
                        highlighted: true,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Revenir a ma version'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Valider la proposition IA'),
        ),
      ],
    );
  }
}

class _PollDraftPreview extends StatelessWidget {
  const _PollDraftPreview({
    required this.title,
    required this.draft,
    this.highlighted = false,
  });

  final String title;
  final PollAiDraft draft;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.34)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted
              ? theme.colorScheme.primary.withValues(alpha: 0.45)
              : theme.dividerColor.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          _PreviewLine(label: 'Titre', value: draft.projectTitle),
          _PreviewLine(label: 'Description', value: draft.description),
          _PreviewLine(label: 'Question', value: draft.question),
          _PreviewLine(
              label: 'Population cible', value: draft.targetPopulation),
          const SizedBox(height: 8),
          Text('Options', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          for (var index = 0; index < draft.options.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('${index + 1}. ${draft.options[index]}'),
            ),
        ],
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelLarge),
          const SizedBox(height: 2),
          SelectableText(cleaned),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.child,
    this.action,
  });

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                if (action != null) action!,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(value.isEmpty ? 'Selectionner une date' : value),
      ),
    );
  }
}
