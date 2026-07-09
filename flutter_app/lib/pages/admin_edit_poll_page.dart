import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/poll_models.dart';
import '../services/poll_photo_upload_service.dart';
import '../services/poll_service.dart';
import '../widgets/poll_option_icons.dart';

/// Etat d'edition d'une option : libelle + photos deja televersees
/// (existingPhotoUrls) + nouvelles photos locales pas encore televersees
/// (newPhotos). Total limite a [PollPhotoUploadService.maxPhotosPerOption].
class _OptionEditState {
  _OptionEditState({
    String label = '',
    this.icon = '',
    List<String> photoUrls = const [],
  })  : controller = TextEditingController(text: label),
        existingPhotoUrls = List<String>.from(photoUrls);

  final TextEditingController controller;
  final List<String> existingPhotoUrls;
  final List<XFile> newPhotos = <XFile>[];
  String icon;

  int get photoCount => existingPhotoUrls.length + newPhotos.length;

  void dispose() => controller.dispose();
}

/// Etat d'edition d'une question du questionnaire multi-etapes.
class _QuestionEditState {
  _QuestionEditState({String title = '', this.multiple = false})
      : titleController = TextEditingController(text: title);

  final TextEditingController titleController;
  bool multiple;
  final List<_OptionEditState> options = [];

  void dispose() {
    titleController.dispose();
    for (final option in options) {
      option.dispose();
    }
  }
}

class AdminEditPollPage extends StatefulWidget {
  const AdminEditPollPage({required this.pollId, super.key});

  final String pollId;

  @override
  State<AdminEditPollPage> createState() => _AdminEditPollPageState();
}

class _AdminEditPollPageState extends State<AdminEditPollPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetPopulationController = TextEditingController();
  final _voterCountController = TextEditingController();
  final List<_QuestionEditState> _questionStates = [];

  PollModel? _poll;
  DateTime? _openDate;
  DateTime? _closeDate;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isUploadingPhotos = false;

  bool get _canEditOptions => (_poll?.totalVoted ?? 0) == 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetPopulationController.dispose();
    _voterCountController.dispose();
    for (final question in _questionStates) {
      question.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final poll = await PollService.instance.loadPollById(widget.pollId);
    if (!mounted) return;

    if (poll == null) {
      setState(() {
        _poll = null;
        _isLoading = false;
      });
      return;
    }

    _titleController.text = poll.projectTitle;
    _descriptionController.text = poll.description;
    _targetPopulationController.text = poll.targetPopulation;
    _voterCountController.text = poll.totalVoters.toString();
    _openDate = DateTime.tryParse(poll.openDate);
    _closeDate = DateTime.tryParse(poll.closeDate);

    for (final question in _questionStates) {
      question.dispose();
    }
    _questionStates.clear();
    // effectiveQuestions : questionnaire stocke, sinon pseudo-question unique
    // batie sur question/options historiques.
    for (final question in poll.effectiveQuestions) {
      final state = _QuestionEditState(
        title: question.title,
        multiple: question.multiple,
      );
      state.options.addAll(question.options.map((option) => _OptionEditState(
            label: option.label,
            icon: option.icon,
            photoUrls: option.photoUrls,
          )));
      while (state.options.length < 2) {
        state.options.add(_OptionEditState());
      }
      _questionStates.add(state);
    }
    if (_questionStates.isEmpty) {
      final state = _QuestionEditState();
      state.options.addAll([_OptionEditState(), _OptionEditState()]);
      _questionStates.add(state);
    }

    setState(() {
      _poll = poll;
      _isLoading = false;
    });
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '';
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

    if (picked == null) return;

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

  void _addQuestion() {
    if (!_canEditOptions || _questionStates.length >= 10) return;
    setState(() {
      final state = _QuestionEditState();
      state.options.addAll([_OptionEditState(), _OptionEditState()]);
      _questionStates.add(state);
    });
  }

  void _removeQuestion(int index) {
    if (!_canEditOptions || _questionStates.length <= 1) return;
    setState(() {
      final question = _questionStates.removeAt(index);
      question.dispose();
    });
  }

  void _addOption(_QuestionEditState question) {
    if (!_canEditOptions) return;
    setState(() {
      question.options.add(_OptionEditState());
    });
  }

  void _removeOption(_QuestionEditState question, int index) {
    if (!_canEditOptions || question.options.length <= 2) return;
    setState(() {
      final option = question.options.removeAt(index);
      option.dispose();
    });
  }

  Future<void> _pickOptionIcon(_OptionEditState option) async {
    if (!_canEditOptions) return;
    final slug = await showPollOptionIconPicker(context);
    if (slug == null || !mounted) return;
    setState(() => option.icon = slug);
  }

  Future<void> _pickOptionPhotos(_OptionEditState option) async {
    if (!_canEditOptions || _isSubmitting || _isUploadingPhotos) return;

    final remainingSlots = PollPhotoUploadService.maxPhotosPerOption -
        option.existingPhotoUrls.length;
    if (remainingSlots <= 0) return;

    try {
      final updated = await PollPhotoUploadService.instance.pickPhotos(
        current: option.newPhotos,
        limit: remainingSlots,
      );
      if (!mounted) return;
      setState(() {
        option.newPhotos
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

  void _removeExistingOptionPhoto(_OptionEditState option, int photoIndex) {
    if (!_canEditOptions) return;
    if (photoIndex < 0 || photoIndex >= option.existingPhotoUrls.length) {
      return;
    }
    setState(() {
      option.existingPhotoUrls.removeAt(photoIndex);
    });
  }

  void _removeNewOptionPhoto(_OptionEditState option, int photoIndex) {
    if (!_canEditOptions) return;
    if (photoIndex < 0 || photoIndex >= option.newPhotos.length) return;
    setState(() {
      option.newPhotos.removeAt(photoIndex);
    });
  }

  Future<void> _submit() async {
    final poll = _poll;
    if (_isSubmitting || poll == null) return;

    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) return;

    final openDate = _openDate ?? DateTime.now();
    final closeDate = _closeDate ?? openDate.add(const Duration(days: 1));
    if (!closeDate.isAfter(openDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'La date de fermeture doit etre posterieure a la date d\'ouverture.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final questions = <PollQuestionDraft>[];
      if (_canEditOptions) {
        final needsUpload = _questionStates.any(
            (question) => question.options.any((o) => o.newPhotos.isNotEmpty));
        if (needsUpload) setState(() => _isUploadingPhotos = true);
        try {
          for (var qIndex = 0; qIndex < _questionStates.length; qIndex++) {
            final question = _questionStates[qIndex];
            final title = question.titleController.text.trim();
            if (title.isEmpty) continue;

            final options = <PollOptionDraft>[];
            for (var index = 0; index < question.options.length; index++) {
              final option = question.options[index];
              final label = option.controller.text.trim();
              if (label.isEmpty) continue;

              var uploadedUrls = const <String>[];
              if (option.newPhotos.isNotEmpty) {
                uploadedUrls =
                    await PollPhotoUploadService.instance.uploadPhotos(
                  photos: option.newPhotos,
                  draftId: '${poll.id}-q$qIndex-opt-$index',
                );
              }
              options.add(PollOptionDraft(
                label: label,
                icon: option.icon,
                photoUrls: [...option.existingPhotoUrls, ...uploadedUrls],
              ));
            }
            questions.add(PollQuestionDraft(
              title: title,
              multiple: question.multiple,
              options: options,
            ));
          }
        } finally {
          if (mounted) setState(() => _isUploadingPhotos = false);
        }
      }

      final updated = await PollService.instance.updatePoll(
        pollId: poll.id,
        projectTitle: _titleController.text,
        description: _descriptionController.text,
        questions: questions,
        targetPopulation: _targetPopulationController.text,
        openDate: _formatDate(openDate),
        closeDate: _formatDate(closeDate),
        totalVoters:
            int.tryParse(_voterCountController.text.trim()) ?? poll.totalVoters,
      );

      if (!mounted) return;

      if (updated == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consultation introuvable.')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consultation mise a jour.')),
      );
      Navigator.of(context).pushReplacementNamed('/admin/poll/${updated.id}');
    } on PollPhotoUploadException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange.shade800,
          content: Text('Photos non televersees: ${error.message}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final poll = _poll;
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (poll == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edition de consultation')),
        body: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.poll_outlined, size: 42),
                  const SizedBox(height: 12),
                  Text('Consultation introuvable',
                      style: theme.textTheme.titleLarge),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Modifier la consultation')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 20),
              children: [
                if (!_canEditOptions)
                  Card(
                    color: const Color(0xFFFFF7ED),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Des votes ont deja ete enregistres pour cette consultation. Les options ne sont plus modifiables afin de conserver l\'integrite des resultats.',
                      ),
                    ),
                  ),
                if (!_canEditOptions) const SizedBox(height: 16),
                _FormSection(
                  title: 'Informations du projet',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration:
                            const InputDecoration(labelText: 'Titre du projet'),
                        maxLength: 255,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Le titre du projet est obligatoire.'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration:
                            const InputDecoration(labelText: 'Description'),
                        minLines: 3,
                        maxLines: 5,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _FormSection(
                  title: 'Questions du questionnaire',
                  action: TextButton.icon(
                    onPressed: _canEditOptions && _questionStates.length < 10
                        ? _addQuestion
                        : null,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Ajouter une question'),
                  ),
                  child: Column(
                    children: [
                      if (_canEditOptions)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(
                            'Le citoyen repond etape par etape. Chaque option peut porter une icone et jusqu a ${PollPhotoUploadService.maxPhotosPerOption} photos.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      for (var qIndex = 0;
                          qIndex < _questionStates.length;
                          qIndex++)
                        Padding(
                          padding: EdgeInsets.only(
                              bottom: qIndex == _questionStates.length - 1
                                  ? 0
                                  : 22),
                          child: _QuestionEditCard(
                            index: qIndex,
                            question: _questionStates[qIndex],
                            canRemove:
                                _canEditOptions && _questionStates.length > 1,
                            enabled: _canEditOptions &&
                                !_isSubmitting &&
                                !_isUploadingPhotos,
                            onRemove: () => _removeQuestion(qIndex),
                            onToggleMultiple: (value) => setState(
                                () => _questionStates[qIndex].multiple = value),
                            onAddOption: () =>
                                _addOption(_questionStates[qIndex]),
                            onRemoveOption: (index) =>
                                _removeOption(_questionStates[qIndex], index),
                            onPickIcon: _pickOptionIcon,
                            onAddPhotos: _pickOptionPhotos,
                            onRemoveExistingPhoto: _removeExistingOptionPhoto,
                            onRemoveNewPhoto: _removeNewOptionPhoto,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 720;
                    final planning = _FormSection(
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
                    final capacity = _FormSection(
                      title: 'Capacite du vote',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _targetPopulationController,
                            decoration: const InputDecoration(
                                labelText: 'Population cible'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _voterCountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Objectif de participation'),
                            validator: (value) {
                              final parsed = int.tryParse((value ?? '').trim());
                              if (parsed == null ||
                                  parsed < 1 ||
                                  parsed > 1000000) {
                                return 'Saisir une valeur valide.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Les codes citoyens restent geres par les agents de mobilisation citoyenne. Cet ecran ne genere pas de QR.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );

                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: planning),
                          const SizedBox(width: 16),
                          Expanded(child: capacity)
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        planning,
                        const SizedBox(height: 16),
                        capacity
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
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save_rounded),
                      label: Text(
                          _isSubmitting ? 'Enregistrement...' : 'Enregistrer'),
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
  const _FormSection({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(title,
                        style: Theme.of(context).textTheme.titleMedium)),
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
  const _DateField(
      {required this.label, required this.value, required this.onTap});

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

class _QuestionEditCard extends StatelessWidget {
  const _QuestionEditCard({
    required this.index,
    required this.question,
    required this.canRemove,
    required this.enabled,
    required this.onRemove,
    required this.onToggleMultiple,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onPickIcon,
    required this.onAddPhotos,
    required this.onRemoveExistingPhoto,
    required this.onRemoveNewPhoto,
  });

  final int index;
  final _QuestionEditState question;
  final bool canRemove;
  final bool enabled;
  final VoidCallback onRemove;
  final ValueChanged<bool> onToggleMultiple;
  final VoidCallback onAddOption;
  final void Function(int optionIndex) onRemoveOption;
  final void Function(_OptionEditState option) onPickIcon;
  final void Function(_OptionEditState option) onAddPhotos;
  final void Function(_OptionEditState option, int photoIndex)
      onRemoveExistingPhoto;
  final void Function(_OptionEditState option, int photoIndex) onRemoveNewPhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Question ${index + 1}',
                    style: theme.textTheme.titleSmall),
              ),
              if (canRemove)
                IconButton(
                  onPressed: enabled ? onRemove : null,
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Supprimer cette question',
                ),
            ],
          ),
          TextFormField(
            controller: question.titleController,
            enabled: enabled,
            decoration: const InputDecoration(
              labelText: 'Intitulé de la question',
            ),
            minLines: 1,
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'L\'intitulé de la question est obligatoire.';
              }
              return null;
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Choix multiples'),
            subtitle: const Text('Le citoyen peut cocher plusieurs réponses.'),
            value: question.multiple,
            onChanged: enabled ? onToggleMultiple : null,
          ),
          for (var index = 0; index < question.options.length; index++)
            Padding(
              padding: EdgeInsets.only(
                  bottom: index == question.options.length - 1 ? 0 : 14),
              child: _OptionEditRow(
                index: index,
                option: question.options[index],
                canRemove: question.options.length > 2,
                enabled: enabled,
                onRemove: () => onRemoveOption(index),
                onPickIcon: () => onPickIcon(question.options[index]),
                onAddPhotos: () => onAddPhotos(question.options[index]),
                onRemoveExistingPhoto: (photoIndex) =>
                    onRemoveExistingPhoto(question.options[index], photoIndex),
                onRemoveNewPhoto: (photoIndex) =>
                    onRemoveNewPhoto(question.options[index], photoIndex),
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: enabled ? onAddOption : null,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ajouter une option'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionEditRow extends StatelessWidget {
  const _OptionEditRow({
    required this.index,
    required this.option,
    required this.canRemove,
    required this.enabled,
    required this.onRemove,
    required this.onPickIcon,
    required this.onAddPhotos,
    required this.onRemoveExistingPhoto,
    required this.onRemoveNewPhoto,
  });

  final int index;
  final _OptionEditState option;
  final bool canRemove;
  final bool enabled;
  final VoidCallback onRemove;
  final VoidCallback onPickIcon;
  final VoidCallback onAddPhotos;
  final void Function(int photoIndex) onRemoveExistingPhoto;
  final void Function(int photoIndex) onRemoveNewPhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAddPhoto = enabled &&
        option.photoCount < PollPhotoUploadService.maxPhotosPerOption;
    final iconData = pollIconForSlug(option.icon);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Tooltip(
                message: 'Choisir une icône',
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: enabled ? onPickIcon : null,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      iconData ?? Icons.add_reaction_outlined,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
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
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Supprimer cette option',
                ),
              ],
            ],
          ),
          if (option.photoCount > 0 || canAddPhoto) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (var i = 0; i < option.existingPhotoUrls.length; i++)
                  _OptionPhotoThumb(
                    onRemove: enabled ? () => onRemoveExistingPhoto(i) : null,
                    child: Image.network(
                      option.existingPhotoUrls[i],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                for (var i = 0; i < option.newPhotos.length; i++)
                  _OptionPhotoThumb(
                    onRemove: enabled ? () => onRemoveNewPhoto(i) : null,
                    child: Image.network(
                      option.newPhotos[i].path,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
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
        ],
      ),
    );
  }
}

class _OptionPhotoThumb extends StatelessWidget {
  const _OptionPhotoThumb({required this.child, required this.onRemove});

  final Widget child;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: child),
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
