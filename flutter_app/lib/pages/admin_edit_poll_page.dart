import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/poll_models.dart';
import '../services/poll_photo_upload_service.dart';
import '../services/poll_service.dart';

/// Etat d'edition d'une option : libelle + photos deja televersees
/// (existingPhotoUrls) + nouvelles photos locales pas encore televersees
/// (newPhotos). Total limite a [PollPhotoUploadService.maxPhotosPerOption].
class _OptionEditState {
  _OptionEditState({String label = '', List<String> photoUrls = const []})
      : controller = TextEditingController(text: label),
        existingPhotoUrls = List<String>.from(photoUrls);

  final TextEditingController controller;
  final List<String> existingPhotoUrls;
  final List<XFile> newPhotos = <XFile>[];

  int get photoCount => existingPhotoUrls.length + newPhotos.length;

  void dispose() => controller.dispose();
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
  final _questionController = TextEditingController();
  final _targetPopulationController = TextEditingController();
  final _voterCountController = TextEditingController();
  final List<_OptionEditState> _optionStates = [];

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
    _questionController.dispose();
    _targetPopulationController.dispose();
    _voterCountController.dispose();
    for (final option in _optionStates) {
      option.dispose();
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
    _questionController.text = poll.question;
    _targetPopulationController.text = poll.targetPopulation;
    _voterCountController.text = poll.totalVoters.toString();
    _openDate = DateTime.tryParse(poll.openDate);
    _closeDate = DateTime.tryParse(poll.closeDate);

    for (final option in _optionStates) {
      option.dispose();
    }
    _optionStates
      ..clear()
      ..addAll(poll.options.map((option) => _OptionEditState(
            label: option.label,
            photoUrls: option.photoUrls,
          )));
    if (_optionStates.length < 2) {
      _optionStates.add(_OptionEditState());
      _optionStates.add(_OptionEditState());
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

  void _addOption() {
    if (!_canEditOptions) return;
    setState(() {
      _optionStates.add(_OptionEditState());
    });
  }

  void _removeOption(int index) {
    if (!_canEditOptions || _optionStates.length <= 2) return;
    setState(() {
      final option = _optionStates.removeAt(index);
      option.dispose();
    });
  }

  Future<void> _pickOptionPhotos(int index) async {
    if (!_canEditOptions || _isSubmitting || _isUploadingPhotos) return;

    final option = _optionStates[index];
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

  void _removeExistingOptionPhoto(int optionIndex, int photoIndex) {
    if (!_canEditOptions) return;
    final urls = _optionStates[optionIndex].existingPhotoUrls;
    if (photoIndex < 0 || photoIndex >= urls.length) return;
    setState(() {
      urls.removeAt(photoIndex);
    });
  }

  void _removeNewOptionPhoto(int optionIndex, int photoIndex) {
    if (!_canEditOptions) return;
    final photos = _optionStates[optionIndex].newPhotos;
    if (photoIndex < 0 || photoIndex >= photos.length) return;
    setState(() {
      photos.removeAt(photoIndex);
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
      final options = <PollOptionDraft>[];
      if (_canEditOptions) {
        final needsUpload =
            _optionStates.any((option) => option.newPhotos.isNotEmpty);
        if (needsUpload) setState(() => _isUploadingPhotos = true);
        try {
          for (var index = 0; index < _optionStates.length; index++) {
            final option = _optionStates[index];
            final label = option.controller.text.trim();
            if (label.isEmpty) continue;

            var uploadedUrls = const <String>[];
            if (option.newPhotos.isNotEmpty) {
              uploadedUrls = await PollPhotoUploadService.instance.uploadPhotos(
                photos: option.newPhotos,
                draftId: '${poll.id}-opt-$index',
              );
            }
            options.add(PollOptionDraft(
              label: label,
              photoUrls: [...option.existingPhotoUrls, ...uploadedUrls],
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
        question: _questionController.text,
        options: options,
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
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _questionController,
                        decoration: const InputDecoration(
                            labelText: 'Question de la consultation'),
                        minLines: 2,
                        maxLines: 3,
                        validator: (value) => value == null ||
                                value.trim().isEmpty
                            ? 'La question de la consultation est obligatoire.'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _FormSection(
                  title: 'Options de vote',
                  action: TextButton.icon(
                    onPressed: _canEditOptions ? _addOption : null,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Ajouter'),
                  ),
                  child: Column(
                    children: [
                      if (_canEditOptions)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(
                            'Vous pouvez illustrer chaque option avec jusqu a ${PollPhotoUploadService.maxPhotosPerOption} photos.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      for (var index = 0; index < _optionStates.length; index++)
                        Padding(
                          padding: EdgeInsets.only(
                              bottom:
                                  index == _optionStates.length - 1 ? 0 : 20),
                          child: _OptionEditRow(
                            index: index,
                            option: _optionStates[index],
                            canRemove:
                                _canEditOptions && _optionStates.length > 2,
                            enabled: _canEditOptions &&
                                !_isSubmitting &&
                                !_isUploadingPhotos,
                            onRemove: () => _removeOption(index),
                            onAddPhotos: () => _pickOptionPhotos(index),
                            onRemoveExistingPhoto: (photoIndex) =>
                                _removeExistingOptionPhoto(index, photoIndex),
                            onRemoveNewPhoto: (photoIndex) =>
                                _removeNewOptionPhoto(index, photoIndex),
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

class _OptionEditRow extends StatelessWidget {
  const _OptionEditRow({
    required this.index,
    required this.option,
    required this.canRemove,
    required this.enabled,
    required this.onRemove,
    required this.onAddPhotos,
    required this.onRemoveExistingPhoto,
    required this.onRemoveNewPhoto,
  });

  final int index;
  final _OptionEditState option;
  final bool canRemove;
  final bool enabled;
  final VoidCallback onRemove;
  final VoidCallback onAddPhotos;
  final void Function(int photoIndex) onRemoveExistingPhoto;
  final void Function(int photoIndex) onRemoveNewPhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAddPhoto = enabled &&
        option.photoCount < PollPhotoUploadService.maxPhotosPerOption;

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
