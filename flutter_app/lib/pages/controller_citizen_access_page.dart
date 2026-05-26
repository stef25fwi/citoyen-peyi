import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/poll_models.dart';
import '../services/auth_session_store.dart';
import '../services/citizen_access_code_service.dart';
import '../services/poll_service.dart';
import '../services/qr_download_service.dart';

class ControllerCitizenAccessPage extends StatefulWidget {
  const ControllerCitizenAccessPage({super.key});

  @override
  State<ControllerCitizenAccessPage> createState() =>
      _ControllerCitizenAccessPageState();
}

class _ControllerCitizenAccessPageState
    extends State<ControllerCitizenAccessPage> {
  static const _allOpenPollsValue = '__all_open_polls__';

  final TextEditingController _firstInitialController = TextEditingController();
  final TextEditingController _lastInitialController = TextEditingController();
  final TextEditingController _birthYearController = TextEditingController();
  final TextEditingController _phoneSuffixController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _identityChecked = false;
  bool _addressChecked = false;
  bool _residencyChecked = false;
  String _selectedPollScope = _allOpenPollsValue;
  DuplicateReason _duplicateReason = DuplicateReason.lostCode;
  List<PollModel> _openPolls = const [];
  List<CitizenAccessCodeModel> _codes = const [];
  List<DuplicateCodeRequestModel> _duplicateRequests = const [];
  CitizenCodeCreationResult? _lastResult;
  String? _lastMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _firstInitialController.dispose();
    _lastInitialController.dispose();
    _birthYearController.dispose();
    _phoneSuffixController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final polls = await PollService.instance.loadPolls();
    final results = await Future.wait([
      CitizenAccessCodeService.instance.loadAccessCodesForCurrentController(),
      CitizenAccessCodeService.instance
          .getDuplicateRequestsForCurrentController(status: 'all'),
    ]);
    if (!mounted) {
      return;
    }

    setState(() {
      _openPolls = polls.where(_isOpenPoll).toList();
      _codes = results[0] as List<CitizenAccessCodeModel>;
      _duplicateRequests = results[1] as List<DuplicateCodeRequestModel>;
      _isLoading = false;
    });
  }

  bool _isOpenPoll(PollModel poll) {
    final today = DateTime.now().toIso8601String().split('T').first;
    final opened = poll.openDate.isEmpty || poll.openDate.compareTo(today) <= 0;
    final notClosed =
        poll.closeDate.isEmpty || poll.closeDate.compareTo(today) >= 0;
    return poll.status == 'active' && opened && notClosed;
  }

  Future<void> _submit() async {
    final firstInitial = _firstInitialController.text.trim().toUpperCase();
    final lastInitial = _lastInitialController.text.trim().toUpperCase();
    final birthYear = _birthYearController.text.trim();
    final phoneSuffix = _phoneSuffixController.text.trim();
    final isValid = !_isSubmitting &&
        _identityChecked &&
        _addressChecked &&
        _residencyChecked &&
        RegExp(r'^[A-Z]$').hasMatch(firstInitial) &&
        RegExp(r'^[A-Z]$').hasMatch(lastInitial) &&
        RegExp(r'^\d{4}$').hasMatch(birthYear) &&
        RegExp(r'^\d{2}$').hasMatch(phoneSuffix);

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Completez la verification physique et les donnees minimales autorisees.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _lastMessage = null;
      _lastResult = null;
    });

    try {
      final result =
          await CitizenAccessCodeService.instance.createCitizenAccessCode(
        firstName: firstInitial,
        lastName: lastInitial,
        birthYear: birthYear,
        phoneSuffix: phoneSuffix,
        identityDocumentChecked: _identityChecked,
        addressProofChecked: _addressChecked,
        communeEligibilityChecked: _residencyChecked,
        duplicateReason: _duplicateReason,
        selectedPollId: _selectedPollScope == _allOpenPollsValue
            ? null
            : _selectedPollScope,
        controllerComment: _commentController.text,
        session: AuthSessionStore.instance.currentSession,
      );

      await _load();
      if (!mounted) {
        return;
      }

      setState(() {
        _lastResult = result;
        if (result.created) {
          _lastMessage = 'Code citoyen genere avec succes.';
          _commentController.clear();
        } else {
          _lastMessage =
              'Un acces existe deja pour cette empreinte. La demande de regeneration est en attente de validation super administrateur.';
        }
      });
    } on ArgumentError catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _lastMessage =
            error.message?.toString() ?? 'Informations minimales invalides.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _lastMessage = 'Impossible de generer le code citoyen pour le moment.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _copy(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _downloadLastGeneratedQr() async {
    final createdCode = _lastResult?.accessCode;
    if (createdCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Aucun code citoyen genere a telecharger.')),
      );
      return;
    }

    try {
      final bytes = await _buildQrPngBytes(createdCode.accessCode);
      await QrDownloadService.instance.downloadPng(
        bytes: bytes,
        fileName: 'code-citoyen-${createdCode.accessCode.toLowerCase()}.png',
      );
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('QR telecharge pour ${createdCode.accessCode}.')),
      );
    } on UnsupportedError catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.message ??
                'Telechargement indisponible sur cette plateforme.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Impossible de generer le fichier PNG du QR.')),
      );
    }
  }

  Future<Uint8List> _buildQrPngBytes(String data) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF111827),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF111827),
      ),
    );
    final imageData =
        await painter.toImageData(1200, format: ui.ImageByteFormat.png);
    if (imageData == null) {
      throw StateError('QR PNG vide');
    }

    return imageData.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = AuthSessionStore.instance.currentSession;
    final communeName = session?.commune?.name ?? 'Commune non rattachee';
    final today = DateTime.now().toIso8601String().split('T').first;
    final generatedToday =
        _codes.where((item) => item.createdAt.startsWith(today)).length;
    final pendingRequests =
        _duplicateRequests.where((item) => item.status == 'pending').length;
    final activeCodes = _codes.where((item) => item.status == 'active').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acces citoyen'),
        actions: [
          TextButton.icon(
            onPressed: () =>
                Navigator.of(context).pushNamed('/controleur/historique'),
            icon: const Icon(Icons.history_rounded),
            label: const Text('Historique'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Controleur / agent d\'accueil',
                                  style: theme.textTheme.headlineSmall),
                              const SizedBox(height: 10),
                              Text(
                                'Commune de rattachement : $communeName\nLe controleur verifie l\'eligibilite sans enregistrer l\'identite complete.',
                                style: theme.textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  _MetricCard(
                                      label: 'Codes generes aujourd\'hui',
                                      value: '$generatedToday',
                                      icon: Icons.vpn_key_rounded),
                                  _MetricCard(
                                      label: 'Codes actifs',
                                      value: '$activeCodes',
                                      icon: Icons.verified_rounded),
                                  _MetricCard(
                                      label: 'Doublons en attente',
                                      value: '$pendingRequests',
                                      icon: Icons.content_copy_rounded),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Workflow de verification',
                                  style: theme.textTheme.titleLarge),
                              const SizedBox(height: 12),
                              const _StepLine(
                                  index: 1,
                                  text:
                                      'Commune determinee automatiquement depuis le profil controleur'),
                              const _StepLine(
                                  index: 2,
                                  text:
                                      'Selection facultative d\'une consultation active ou de toutes les consultations ouvertes'),
                              const _StepLine(
                                  index: 3,
                                  text:
                                      'Verification physique de la piece, du justificatif et du rattachement communal'),
                              const _StepLine(
                                  index: 4,
                                  text:
                                      'Saisie des donnees minimales uniquement: initiales, annee de naissance, 2 chiffres du telephone'),
                              const _StepLine(
                                  index: 5,
                                  text:
                                      'Generation d\'une empreinte anonyme et du code citoyen'),
                              const _StepLine(
                                  index: 6,
                                  text:
                                      'En cas de doublon, demande de regeneration transmise au super administrateur'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Generer un acces citoyen',
                                  style: theme.textTheme.titleLarge),
                              const SizedBox(height: 8),
                              Text(
                                'Votre code citoyen vous permet d\'acceder aux consultations ouvertes de votre commune.',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 18),
                              InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Commune',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(communeName),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedPollScope,
                                decoration: const InputDecoration(
                                  labelText: 'Consultations ouvertes',
                                  helperText:
                                      'Le code citoyen donne acces a toutes les consultations ouvertes si vous laissez l\'option par defaut.',
                                ),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: _allOpenPollsValue,
                                    child: Text(
                                        'Toutes les consultations ouvertes de la commune'),
                                  ),
                                  for (final poll in _openPolls)
                                    DropdownMenuItem<String>(
                                      value: poll.id,
                                      child: Text(poll.projectTitle),
                                    ),
                                ],
                                onChanged: (value) => setState(() =>
                                    _selectedPollScope =
                                        value ?? _allOpenPollsValue),
                              ),
                              const SizedBox(height: 16),
                              CheckboxListTile(
                                value: _identityChecked,
                                onChanged: (value) => setState(
                                    () => _identityChecked = value ?? false),
                                title: const Text('Piece d\'identite verifiee'),
                                contentPadding: EdgeInsets.zero,
                              ),
                              CheckboxListTile(
                                value: _addressChecked,
                                onChanged: (value) => setState(
                                    () => _addressChecked = value ?? false),
                                title: const Text(
                                    'Justificatif de domicile verifie'),
                                contentPadding: EdgeInsets.zero,
                              ),
                              CheckboxListTile(
                                value: _residencyChecked,
                                onChanged: (value) => setState(
                                    () => _residencyChecked = value ?? false),
                                title: const Text(
                                    'Residence ou rattachement communal confirme'),
                                subtitle: const Text(
                                    'Aucune copie de document n\'est conservee dans ce workflow.'),
                                contentPadding: EdgeInsets.zero,
                              ),
                              const SizedBox(height: 16),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final wide = constraints.maxWidth >= 760;
                                  final fields = [
                                    TextField(
                                      controller: _firstInitialController,
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      maxLength: 1,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                            RegExp(r'[a-zA-Z]'))
                                      ],
                                      decoration: const InputDecoration(
                                        labelText: 'Premiere lettre du prenom',
                                        counterText: '',
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                    TextField(
                                      controller: _lastInitialController,
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      maxLength: 1,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                            RegExp(r'[a-zA-Z]'))
                                      ],
                                      decoration: const InputDecoration(
                                        labelText: 'Premiere lettre du nom',
                                        counterText: '',
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                    TextField(
                                      controller: _birthYearController,
                                      keyboardType: TextInputType.number,
                                      maxLength: 4,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly
                                      ],
                                      decoration: const InputDecoration(
                                        labelText: 'Annee de naissance',
                                        counterText: '',
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                    TextField(
                                      controller: _phoneSuffixController,
                                      keyboardType: TextInputType.number,
                                      maxLength: 2,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly
                                      ],
                                      decoration: const InputDecoration(
                                        labelText:
                                            '2 derniers chiffres du telephone',
                                        counterText: '',
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ];

                                  if (!wide) {
                                    return Column(
                                      children: [
                                        for (var index = 0;
                                            index < fields.length;
                                            index++) ...[
                                          fields[index],
                                          if (index != fields.length - 1)
                                            const SizedBox(height: 12),
                                        ],
                                      ],
                                    );
                                  }

                                  return Column(
                                    children: [
                                      Row(children: [
                                        Expanded(child: fields[0]),
                                        const SizedBox(width: 12),
                                        Expanded(child: fields[1])
                                      ]),
                                      const SizedBox(height: 12),
                                      Row(children: [
                                        Expanded(child: fields[2]),
                                        const SizedBox(width: 12),
                                        Expanded(child: fields[3])
                                      ]),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<DuplicateReason>(
                                initialValue: _duplicateReason,
                                decoration: const InputDecoration(
                                  labelText:
                                      'Motif a utiliser si un doublon est detecte',
                                ),
                                items: DuplicateReason.values
                                    .map((reason) =>
                                        DropdownMenuItem<DuplicateReason>(
                                            value: reason,
                                            child: Text(reason.label)))
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _duplicateReason = value);
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _commentController,
                                minLines: 2,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  labelText: 'Commentaire controleur optionnel',
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _isSubmitting ? null : _submit,
                                  icon: _isSubmitting
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : const Icon(Icons.qr_code_2_rounded),
                                  label: Text(_isSubmitting
                                      ? 'Generation en cours...'
                                      : 'Generer un code citoyen'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Une demande de regeneration doit etre validee par le super administrateur en cas de doublon.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_lastMessage != null) ...[
                        const SizedBox(height: 16),
                        _ResultCard(
                          message: _lastMessage!,
                          result: _lastResult,
                          onCopy: (value) => _copy(value,
                              'Code citoyen copie dans le presse-papiers.'),
                          onDownload: _downloadLastGeneratedQr,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                      child: Text('Codes recemment generes',
                                          style: theme.textTheme.titleLarge)),
                                  TextButton(
                                    onPressed: () => Navigator.of(context)
                                        .pushNamed('/controleur/historique'),
                                    child:
                                        const Text('Voir tout l\'historique'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_codes.isEmpty)
                                const Text(
                                    'Aucun code citoyen n\'a encore ete genere.')
                              else
                                for (final code in _codes.take(6))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _RecentCodeTile(code: code),
                                  ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD7E0EA)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE0F2FE),
                child: Icon(icon, color: const Color(0xFF0F6D8F)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: Theme.of(context).textTheme.headlineSmall),
                    Text(label),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
              radius: 13,
              child: Text('$index', style: const TextStyle(fontSize: 12))),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.message,
    required this.result,
    required this.onCopy,
    required this.onDownload,
  });

  final String message;
  final CitizenCodeCreationResult? result;
  final ValueChanged<String> onCopy;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final createdCode = result?.accessCode;
    final duplicateRequest = result?.duplicateRequest;
    final isSuccess = createdCode != null;

    return Card(
      color: isSuccess ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSuccess ? 'Code citoyen disponible' : 'Doublon detecte',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(message),
            if (createdCode != null) ...[
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFD7E0EA)),
                      ),
                      child: Column(
                        children: [
                          QrImageView(
                              data: createdCode.accessCode,
                              size: 150,
                              backgroundColor: Colors.white),
                          const SizedBox(height: 10),
                          SelectableText(
                            createdCode.accessCode,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Le code citoyen permet d\'acceder aux consultations ouvertes de ${createdCode.communeName}.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () => onCopy(createdCode.accessCode),
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('Copier'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: onDownload,
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Telecharger PNG'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            if (duplicateRequest != null) ...[
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Statut: En attente de validation',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Demande: ${duplicateRequest.id}'),
                      Text('Commune: ${duplicateRequest.communeName}'),
                      Text('Motif: ${duplicateRequest.duplicateReason.label}'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecentCodeTile extends StatelessWidget {
  const _RecentCodeTile({required this.code});

  final CitizenAccessCodeModel code;

  @override
  Widget build(BuildContext context) {
    final usedLabel =
        code.usedForLogin ? 'Utilise pour le vote' : 'Non utilise';
    final statusColor =
        code.usedForLogin ? const Color(0xFF2E7D32) : const Color(0xFF0F6D8F);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7E0EA)),
      ),
      child: ListTile(
        leading: const Icon(Icons.qr_code_2_rounded),
        title: Text(code.accessCode),
        subtitle: Text('${code.communeName} · ${code.createdAt}'),
        trailing: Chip(
          backgroundColor: statusColor.withValues(alpha: 0.12),
          label: Text(usedLabel),
        ),
      ),
    );
  }
}
