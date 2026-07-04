import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/poll_models.dart';
import '../services/poll_ai_draft_service.dart';
import '../services/poll_photo_upload_service.dart';
import '../services/poll_service.dart';

/// Brouillon d'une option de vote pendant la creation : libelle + jusqu'a
/// 2 photos locales (pas encore televersees).
class _OptionDraft {
  _OptionDraft({String label = ''}) : controller = TextEditingController(text: label);

  final TextEditingController controller;
  final List<XFile> photos = <XFile>[];

  void dispose() => controller.dispose();
}

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
  final List<_OptionDraft> _optionDrafts = [
    _OptionDraft(),
    _OptionDraft(),
  ];

  DateTime? _openDate;
  DateTime? _closeDate;
  bool _isSubmitting = false;
  bool _isRewritingWithAi = false;
  bool _aiProposalAccepted = false;
  bool _isUploadingPhotos = false;
  final List<XFile> _photos = <XFile>[];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _questionController.dispose();
    _targetPopulationController.dispose();
    _voterCountController.dispose();
    for (final option in _optionDrafts) {
      option.dispose();
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
      _optionDrafts.add(_OptionDraft());
    });
  }

  void _removeOption(int index) {
    if (_optionDrafts.length <= 2) {
      return;
    }

    setState(() {
      final option = _optionDrafts.removeAt(index);
      option.dispose();
    });
  }

  Future<void> _pickOptionPhotos(int index) async {
    if (_isSubmitting || _isUploadingPhotos) {
      return;
    }

    final option = _optionDrafts[index];
    try {
      final updated = await PollPhotoUploadService.instance.pickPhotos(
        current: option.photos,
        limit: PollPhotoUploadService.maxPhotosPerOption,
      );
      if (!mounted) return;
      setState(() {
        option.photos
          ..clear()
          ..addAll(updated);
      });
    } on PollPhotoUploadException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange.shade800,
          content: Text(error.message),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange.shade800,
          content: Text('Selection de photos impossible: ${error.toString()}'),
        ),
      );
    }
  }

  void _removeOptionPhoto(int optionIndex, int photoIndex) {
    final photos = _optionDrafts[optionIndex].photos;
    if (photoIndex < 0 || photoIndex >= photos.length) return;
    setState(() {
      photos.removeAt(photoIndex);
    });
  }

  PollAiDraft _currentAiDraft() {
    return PollAiDraft(
      projectTitle: _titleController.text,
      description: _descriptionController.text,
      question: _questionController.text,
      targetPopulation: _targetPopulationController.text,
      options: _optionDrafts.map((item) => item.controller.text).toList(),
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

      // Conserve les photos deja choisies tant qu'il reste assez d'options ;
      // les options excedentaires (et leurs photos) sont abandonnees.
      for (var i = options.length; i < _optionDrafts.length; i++) {
        _optionDrafts[i].dispose();
      }
      final reused = _optionDrafts.take(options.length).toList();
      for (var i = 0; i < reused.length; i++) {
        reused[i].controller.text = options[i];
      }
      for (var i = reused.length; i < options.length; i++) {
        reused.add(_OptionDraft(label: options[i]));
      }

      _optionDrafts
        ..clear()
        ..addAll(reused);

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

  Future<void> _pickPhotos() async {
    if (_isSubmitting || _isUploadingPhotos) {
      return;
    }

    try {
      final updated =
          await PollPhotoUploadService.instance.pickPhotos(current: _photos);
      if (!mounted) {
        return;
      }
      setState(() {
        _photos
          ..clear()
          ..addAll(updated);
      });
    } on PollPhotoUploadException catch (error) {
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
          content: Text('Selection de photos impossible: ${error.toString()}'),
        ),
      );
    }
  }

  void _removePhoto(int index) {
    if (index < 0 || index >= _photos.length) {
      return;
    }
    setState(() {
      _photos.removeAt(index);
    });
  }

  Widget _buildPhotosSection(ThemeData theme) {
    final canAdd = !_isSubmitting &&
        !_isUploadingPhotos &&
        _photos.length < PollPhotoUploadService.maxPhotos;

    return _FormSection(
      title: 'Photos de la consultation',
      action: TextButton.icon(
        onPressed: canAdd ? _pickPhotos : null,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Ajouter'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ajoutez jusqu a ${PollPhotoUploadService.maxPhotos} photos (JPG, PNG ou WebP, 10 Mo max). La premiere photo sert d illustration principale aux citoyens.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          if (_photos.isEmpty)
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: canAdd ? _pickPhotos : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.6),
                  ),
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.35),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 36,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aucune photo ajoutee. Cliquez pour en selectionner.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var index = 0; index < _photos.length; index++)
                  _PhotoThumbnail(
                    photo: _photos[index],
                    isMain: index == 0,
                    onRemove: _isSubmitting || _isUploadingPhotos
                        ? null
                        : () => _removePhoto(index),
                  ),
              ],
            ),
        ],
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
      final draftId = 'draft-${DateTime.now().millisecondsSinceEpoch}';
      var photoUrls = const <String>[];
      final options = <PollOptionDraft>[];
      final hasOptionPhotos =
          _optionDrafts.any((option) => option.photos.isNotEmpty);

      if (_photos.isNotEmpty || hasOptionPhotos) {
        setState(() => _isUploadingPhotos = true);
        try {
          if (_photos.isNotEmpty) {
            photoUrls = await PollPhotoUploadService.instance.uploadPhotos(
              photos: _photos,
              draftId: draftId,
            );
          }

          for (var index = 0; index < _optionDrafts.length; index++) {
            final option = _optionDrafts[index];
            final label = option.controller.text.trim();
            if (label.isEmpty) continue;

            var optionPhotoUrls = const <String>[];
            if (option.photos.isNotEmpty) {
              optionPhotoUrls =
                  await PollPhotoUploadService.instance.uploadPhotos(
                photos: option.photos,
                draftId: '$draftId-opt-$index',
              );
            }
            options.add(
                PollOptionDraft(label: label, photoUrls: optionPhotoUrls));
          }
        } finally {
          if (mounted) {
            setState(() => _isUploadingPhotos = false);
          }
        }
      } else {
        for (final option in _optionDrafts) {
          final label = option.controller.text.trim();
          if (label.isEmpty) continue;
          options.add(PollOptionDraft(label: label));
        }
      }

      await PollService.instance.createPoll(
        projectTitle: _titleController.text,
        description: _descriptionController.text,
        question: _questionController.text,
        options: options,
        photoUrls: photoUrls,
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
    } on PollPhotoUploadException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange.shade800,
          content: Text('Photos non televersees: ${error.message}'),
        ),
      );
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
                _buildPhotosSection(theme),
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
                      Text(
                        'Vous pouvez illustrer chaque option avec jusqu a ${PollPhotoUploadService.maxPhotosPerOption} photos (JPG, PNG ou WebP, 10 Mo max).',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      for (var index = 0;
                          index < _optionDrafts.length;
                          index++)
                        Padding(
                          padding: EdgeInsets.only(
                              bottom: index == _optionDrafts.length - 1
                                  ? 0
                                  : 20),
                          child: _OptionEditor(
                            index: index,
                            option: _optionDrafts[index],
                            canRemove: _optionDrafts.length > 2,
                            enabled: !_isSubmitting && !_isUploadingPhotos,
                            onRemove: () => _removeOption(index),
                            onAddPhotos: () => _pickOptionPhotos(index),
                            onRemovePhoto: (photoIndex) =>
                                _removeOptionPhoto(index, photoIndex),
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
                      label: Text(_isUploadingPhotos
                          ? 'Televersement des photos...'
                          : _isSubmitting
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

class _OptionEditor extends StatelessWidget {
  const _OptionEditor({
    required this.index,
    required this.option,
    required this.canRemove,
    required this.enabled,
    required this.onRemove,
    required this.onAddPhotos,
    required this.onRemovePhoto,
  });

  final int index;
  final _OptionDraft option;
  final bool canRemove;
  final bool enabled;
  final VoidCallback onRemove;
  final VoidCallback onAddPhotos;
  final void Function(int photoIndex) onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAddPhoto =
        enabled && option.photos.length < PollPhotoUploadService.maxPhotosPerOption;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  controller: option.controller,
                  enabled: enabled,
                  decoration: InputDecoration(labelText: 'Option ${index + 1}'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Toutes les options doivent etre remplies.';
                    }
                    return null;
                  },
                ),
              ),
              if (canRemove) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: enabled ? onRemove : null,
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Supprimer cette option',
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var photoIndex = 0;
                  photoIndex < option.photos.length;
                  photoIndex++)
                _OptionPhotoThumbnail(
                  photo: option.photos[photoIndex],
                  onRemove: enabled ? () => onRemovePhoto(photoIndex) : null,
                ),
              if (canAddPhoto)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onAddPhotos,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.6),
                      ),
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.35),
                    ),
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionPhotoThumbnail extends StatelessWidget {
  const _OptionPhotoThumbnail({required this.photo, required this.onRemove});

  final XFile photo;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              photo.path,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: 2,
              right: 2,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(3),
                    child: Icon(Icons.close_rounded,
                        size: 14, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({
    required this.photo,
    required this.isMain,
    required this.onRemove,
  });

  final XFile photo;
  final bool isMain;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              photo.path,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          if (isMain)
            Positioned(
              left: 0,
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 3),
                color: theme.colorScheme.primary.withValues(alpha: 0.85),
                alignment: Alignment.center,
                child: Text(
                  'Principale',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          if (onRemove != null)
            Positioned(
              top: 2,
              right: 2,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded,
                        size: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
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
