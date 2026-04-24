import 'package:flutter/material.dart';

import '../services/poll_service.dart';

class AdminCreatePollPage extends StatefulWidget {
  const AdminCreatePollPage({super.key});

  @override
  State<AdminCreatePollPage> createState() => _AdminCreatePollPageState();
}

class _AdminCreatePollPageState extends State<AdminCreatePollPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _questionController = TextEditingController();
  final _voterCountController = TextEditingController(text: '50');
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  DateTime? _openDate;
  DateTime? _closeDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _questionController.dispose();
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
        const SnackBar(content: Text('La date de fermeture doit etre posterieure a la date d\'ouverture.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await PollService.instance.createPoll(
        projectTitle: _titleController.text,
        question: _questionController.text,
        options: _optionControllers.map((item) => item.text).toList(),
        openDate: _formatDate(openDate),
        closeDate: _formatDate(closeDate ?? openDate),
        totalVoters: int.tryParse(_voterCountController.text.trim()) ?? 50,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sondage cree avec succes.')),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/admin', (route) => route.settings.name == '/');
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
            controller: _voterCountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Nombre de QR codes a prevoir',
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
            'Ce total sert de capacite initiale pour mesurer la participation et preparer la distribution des acces.',
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
        title: const Text('Creer un sondage'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
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
                        controller: _questionController,
                        decoration: const InputDecoration(
                          labelText: 'Question du sondage',
                          hintText: 'Ex : Quelle option preferez-vous ?',
                        ),
                        minLines: 2,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La question du sondage est obligatoire.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
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
                      for (var index = 0; index < _optionControllers.length; index++)
                        Padding(
                          padding: EdgeInsets.only(bottom: index == _optionControllers.length - 1 ? 0 : 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: theme.colorScheme.primaryContainer,
                                child: Text('${index + 1}'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _optionControllers[index],
                                  decoration: InputDecoration(labelText: 'Option ${index + 1}'),
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
                                  icon: const Icon(Icons.delete_outline_rounded),
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
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
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
                      label: Text(_isSubmitting ? 'Creation...' : 'Creer le sondage'),
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