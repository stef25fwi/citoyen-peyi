import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/poll_models.dart';
import '../services/auth_session_store.dart';
import '../services/citizen_access_code_service.dart';
import '../services/poll_service.dart';
import '../services/qr_download_service.dart';
import '../services/vote_access_service.dart';

class RegistrationReviewPage extends StatefulWidget {
  const RegistrationReviewPage({super.key});

  @override
  State<RegistrationReviewPage> createState() => _RegistrationReviewPageState();
}

class _RegistrationReviewPageState extends State<RegistrationReviewPage> {
  static const _idDocumentTypes = [
    'Carte nationale d\'identite',
    'Passeport',
    'Titre de sejour',
    'Permis de conduire',
  ];
  static const _addressDocumentTypes = [
    'Facture d\'electricite / gaz',
    'Facture d\'eau',
    'Facture internet / telephone',
    'Quittance de loyer',
    'Avis d\'imposition',
  ];

  bool _isLoading = true;
  bool _isSubmitting = false;
  List<PollModel> _polls = const [];
  List<VoteAccessRecordModel> _records = const [];
  List<DuplicateCodeRequestModel> _duplicateRequests = const [];
  String? _selectedPollId;
  String? _selectedRecordId;
  String? _selectedIdDoc;
  String? _selectedAddressDoc;
  String _statusFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _citizenFirstNameController = TextEditingController();
  final TextEditingController _citizenLastNameController = TextEditingController();
  final TextEditingController _citizenBirthYearController = TextEditingController();
  final TextEditingController _citizenPhoneSuffixController = TextEditingController();
  final TextEditingController _duplicateCommentController = TextEditingController();
  DuplicateReason _duplicateReason = DuplicateReason.lostCode;
  String? _lastCitizenCodeMessage;
  bool _isCitizenCodeSubmitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _citizenFirstNameController.dispose();
    _citizenLastNameController.dispose();
    _citizenBirthYearController.dispose();
    _citizenPhoneSuffixController.dispose();
    _duplicateCommentController.dispose();
    super.dispose();
  }

  bool _matchesStatusFilter(VoteAccessRecordModel record) {
    switch (_statusFilter) {
      case 'available':
        return record.status == 'available';
      case 'validated':
        return record.status == 'validated';
      case 'activated':
        return record.activated && !record.hasVoted;
      case 'voted':
        return record.hasVoted;
      default:
        return true;
    }
  }

  bool _matchesSearch(VoteAccessRecordModel record) {
    final query = _searchController.text.trim().toUpperCase();
    if (query.isEmpty) {
      return true;
    }

    return record.code.toUpperCase().contains(query) ||
        record.pollId.toUpperCase().contains(query) ||
        (record.verifiedByControleurLabel?.toUpperCase().contains(query) ?? false) ||
        (record.communeName?.toUpperCase().contains(query) ?? false);
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
    });

    final session = AuthSessionStore.instance.currentSession;
    final polls = await PollService.instance.loadPolls();
    final records = await VoteAccessService.instance.loadAllRecords();
    final duplicateRequests = session?.isController == true
      ? await CitizenAccessCodeService.instance.getDuplicateRequestsForCurrentController(status: 'all')
      : const <DuplicateCodeRequestModel>[];

    if (!mounted) {
      return;
    }

    setState(() {
      _polls = polls;
      _records = records;
      _duplicateRequests = duplicateRequests;
      _selectedPollId ??= polls.isNotEmpty ? polls.first.id : null;
      _isLoading = false;
    });
  }

  Future<void> _validateSelectedRecord() async {
    if (_isSubmitting || _selectedRecordId == null || _selectedIdDoc == null || _selectedAddressDoc == null) {
      return;
    }

    final session = AuthSessionStore.instance.currentSession;

    setState(() {
      _isSubmitting = true;
    });

    final updated = await VoteAccessService.instance.validateRecord(
      recordId: _selectedRecordId!,
      documentType: '$_selectedIdDoc + $_selectedAddressDoc',
      communeName: session?.commune?.name,
      verifiedByControleurCode: session?.code,
      verifiedByControleurLabel: session?.label,
    );
    await _load();

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
      _selectedRecordId = updated?.id;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Inscription validee et QR pret a diffuser.')),
    );
  }

  Future<void> _createCitizenAccessCode() async {
    if (_isCitizenCodeSubmitting) {
      return;
    }

    setState(() {
      _isCitizenCodeSubmitting = true;
      _lastCitizenCodeMessage = null;
    });

    try {
      final result = await CitizenAccessCodeService.instance.createCitizenAccessCode(
        firstName: _citizenFirstNameController.text,
        lastName: _citizenLastNameController.text,
        birthYear: _citizenBirthYearController.text,
        phoneSuffix: _citizenPhoneSuffixController.text,
        duplicateReason: _duplicateReason,
        controllerComment: _duplicateCommentController.text,
        session: AuthSessionStore.instance.currentSession,
      );

      if (!mounted) return;
      setState(() {
        if (result.created) {
          _lastCitizenCodeMessage = 'Code citoyen genere : ${result.accessCode!.accessCode}';
          _duplicateCommentController.clear();
        } else {
          _lastCitizenCodeMessage =
              'Un acces existe deja pour cette personne. Une demande de verification a ete transmise au super administrateur.';
        }
      });
      final duplicateRequests = await CitizenAccessCodeService.instance.getDuplicateRequestsForCurrentController(status: 'all');
      if (mounted) {
        setState(() => _duplicateRequests = duplicateRequests);
      }
    } on ArgumentError catch (error) {
      if (!mounted) return;
      setState(() => _lastCitizenCodeMessage = error.message?.toString() ?? 'Informations minimales invalides.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _lastCitizenCodeMessage = 'Impossible de generer le code citoyen.');
    } finally {
      if (mounted) {
        setState(() => _isCitizenCodeSubmitting = false);
      }
    }
  }

  Future<void> _copyToClipboard(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showQrPreview(VoteAccessRecordModel record) {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('QR code d\'acces'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (record.qrPayload != null)
                QrImageView(
                  data: record.qrPayload!,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              const SizedBox(height: 16),
              SelectableText(
                record.code,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (record.qrPayload != null) ...[
                const SizedBox(height: 12),
                SelectableText(
                  record.qrPayload!,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _copyToClipboard(record.code, 'Code copie dans le presse-papiers.'),
            child: const Text('Copier le code'),
          ),
          if (record.qrPayload != null)
            TextButton(
              onPressed: () => _copyToClipboard(record.qrPayload!, 'Contenu du QR copie dans le presse-papiers.'),
              child: const Text('Copier le QR'),
            ),
          if (record.qrPayload != null)
            TextButton(
              onPressed: () => _downloadQrPng(record),
              child: const Text('Telecharger PNG'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadQrPng(VoteAccessRecordModel record) async {
    if (record.qrPayload == null || record.qrPayload!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun QR disponible pour ce dossier.')),
      );
      return;
    }

    try {
      final bytes = await _buildQrPngBytes(record.qrPayload!);
      await QrDownloadService.instance.downloadPng(
        bytes: bytes,
        fileName: 'qr-${record.code.toLowerCase()}.png',
      );
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QR telecharge pour ${record.code}.')),
      );
    } on UnsupportedError catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Telechargement indisponible.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de generer le fichier PNG du QR.')),
      );
    }
  }

  Future<Uint8List> _buildQrPngBytes(String data) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
      color: const Color(0xFF111827),
      emptyColor: Colors.white,
    );
    final imageData = await painter.toImageData(1200, format: ui.ImageByteFormat.png);
    if (imageData == null) {
      throw StateError('QR PNG vide');
    }

    return imageData.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = AuthSessionStore.instance.currentSession;
    final canValidateFiles = session?.isController == true;
    final pollTitlesById = {
      for (final poll in _polls) poll.id: poll.projectTitle,
    };
    final pollScopedRecords = _selectedPollId == null
        ? _records
        : _records.where((item) => item.pollId == _selectedPollId).toList();
    final filteredRecords = pollScopedRecords
        .where((item) => _matchesStatusFilter(item) && _matchesSearch(item))
        .toList();
    final availableRecords = filteredRecords.where((item) => item.status == 'available').toList();
    final selectedRecord = _records.where((item) => item.id == _selectedRecordId).firstOrNull;
    final stats = (
      total: pollScopedRecords.length,
      available: pollScopedRecords.where((item) => item.status == 'available').length,
      validated: pollScopedRecords.where((item) => item.status == 'validated').length,
      activated: pollScopedRecords.where((item) => item.activated).length,
      voted: pollScopedRecords.where((item) => item.hasVoted).length,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscriptions'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _ControllerHeaderCard(
                        session: session,
                        canValidateFiles: canValidateFiles,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _StatCard(label: 'Codes', value: '${stats.total}', subtitle: 'pour le sondage selectionne'),
                          _StatCard(label: 'Disponibles', value: '${stats.available}', subtitle: 'en attente de verification'),
                          _StatCard(label: 'Valides', value: '${stats.validated}', subtitle: 'QR diffusable'),
                          _StatCard(label: 'Votes', value: '${stats.voted}', subtitle: '${stats.activated} codes actives'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const _SectionTitle(
                        title: 'Gestion des acces',
                        subtitle: 'Zone controleur unique : code citoyen anonyme, verification du dossier et QR diffusable.',
                      ),
                      const SizedBox(height: 12),
                      _ValidationCard(
                        title: 'Zone controleur',
                        roleLabel: 'CONTROLEUR',
                        roleDescription: canValidateFiles
                          ? 'Vous pouvez generer/verifier un code citoyen anonyme, valider les pieces, puis diffuser ou telecharger le QR.'
                          : 'Lecture seule. Les actions sont reservees aux controleurs.',
                        enabled: canValidateFiles,
                        polls: _polls,
                        selectedPollId: _selectedPollId,
                        onPollChanged: (value) {
                          setState(() {
                            _selectedPollId = value;
                            _selectedRecordId = null;
                          });
                        },
                        firstNameController: _citizenFirstNameController,
                        lastNameController: _citizenLastNameController,
                        birthYearController: _citizenBirthYearController,
                        phoneSuffixController: _citizenPhoneSuffixController,
                        duplicateCommentController: _duplicateCommentController,
                        duplicateReason: _duplicateReason,
                        isCitizenCodeSubmitting: _isCitizenCodeSubmitting,
                        lastCitizenCodeMessage: _lastCitizenCodeMessage,
                        duplicateRequests: _duplicateRequests,
                        onReasonChanged: (value) => setState(() => _duplicateReason = value),
                        onCitizenCodeSubmit: _createCitizenAccessCode,
                        availableRecords: availableRecords,
                        selectedRecordId: _selectedRecordId,
                        selectedIdDoc: _selectedIdDoc,
                        selectedAddressDoc: _selectedAddressDoc,
                        onRecordChanged: canValidateFiles
                          ? (value) => setState(() => _selectedRecordId = value)
                          : null,
                        onIdDocChanged: canValidateFiles
                          ? (value) => setState(() => _selectedIdDoc = value)
                          : null,
                        onAddressDocChanged: canValidateFiles
                          ? (value) => setState(() => _selectedAddressDoc = value)
                          : null,
                        onValidate: canValidateFiles && !_isSubmitting ? _validateSelectedRecord : null,
                        onPreviewQr: selectedRecord?.qrPayload == null
                            ? null
                            : () => _showQrPreview(selectedRecord!),
                        onCopyCode: selectedRecord == null
                            ? null
                            : () => _copyToClipboard(
                                  selectedRecord.code,
                                  'Code copie dans le presse-papiers.',
                                ),
                        onCopyQrPayload: selectedRecord?.qrPayload == null
                            ? null
                            : () => _copyToClipboard(
                                  selectedRecord!.qrPayload!,
                                  'Contenu du QR copie dans le presse-papiers.',
                                ),
                        onDownloadQr: selectedRecord?.qrPayload == null
                            ? null
                            : () => _downloadQrPng(selectedRecord!),
                        idDocumentTypes: _idDocumentTypes,
                        addressDocumentTypes: _addressDocumentTypes,
                        selectedRecord: selectedRecord,
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionTitle(
                                title: 'Codes recents',
                                subtitle: 'Cartes inspirees de la page controleur du ZIP : statut, pieces, QR et actions rapides.',
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.search_rounded),
                                  labelText: 'Filtrer par code, commune ou controleur',
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _StatusFilterChip(
                                    label: 'Tous',
                                    selected: _statusFilter == 'all',
                                    onSelected: (_) => setState(() => _statusFilter = 'all'),
                                  ),
                                  _StatusFilterChip(
                                    label: 'Disponibles',
                                    selected: _statusFilter == 'available',
                                    onSelected: (_) => setState(() => _statusFilter = 'available'),
                                  ),
                                  _StatusFilterChip(
                                    label: 'Valides',
                                    selected: _statusFilter == 'validated',
                                    onSelected: (_) => setState(() => _statusFilter = 'validated'),
                                  ),
                                  _StatusFilterChip(
                                    label: 'Actives',
                                    selected: _statusFilter == 'activated',
                                    onSelected: (_) => setState(() => _statusFilter = 'activated'),
                                  ),
                                  _StatusFilterChip(
                                    label: 'Votes',
                                    selected: _statusFilter == 'voted',
                                    onSelected: (_) => setState(() => _statusFilter = 'voted'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (filteredRecords.isEmpty)
                                const Text('Aucun code ne correspond au filtre courant.')
                              else
                                for (final record in filteredRecords.take(12))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _CodeRow(
                                      record: record,
                                      pollLabel: pollTitlesById[record.pollId] ?? record.pollId,
                                      onPreviewQr: record.qrPayload == null
                                          ? null
                                          : () => _showQrPreview(record),
                                      onCopyCode: () => _copyToClipboard(
                                        record.code,
                                        'Code copie dans le presse-papiers.',
                                      ),
                                      onCopyQrPayload: record.qrPayload == null
                                          ? null
                                          : () => _copyToClipboard(
                                                record.qrPayload!,
                                                'Contenu du QR copie dans le presse-papiers.',
                                              ),
                                      onDownloadQr: record.qrPayload == null
                                          ? null
                                          : () => _downloadQrPng(record),
                                    ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final availableWidth = MediaQuery.sizeOf(context).width - 40;
    final cardWidth = availableWidth < 260 ? availableWidth : 220.0;

    return SizedBox(
      width: cardWidth,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControllerHeaderCard extends StatelessWidget {
  const _ControllerHeaderCard({
    required this.session,
    required this.canValidateFiles,
  });

  final AuthSession? session;
  final bool canValidateFiles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileName = session?.label?.trim().isNotEmpty == true ? session!.label!.trim() : 'Utilisateur';
    final communeName = session?.commune?.name.trim().isNotEmpty == true ? session!.commune!.name.trim() : 'Non renseignee';
    final codePostal = session?.commune?.codePostal?.trim();
    final communeLabel = codePostal != null && codePostal.isNotEmpty ? '$communeName · CP $codePostal' : communeName;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final icon = Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFF0B6FA4).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.badge_outlined, size: 38, color: Color(0xFF0B6FA4)),
            );
            final content = Column(
              crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                Text(
                  'Inscriptions et codes',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  textAlign: wide ? TextAlign.start : TextAlign.center,
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: wide ? WrapAlignment.start : WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _ControllerIdentityTile(
                      icon: Icons.person_outline_rounded,
                      label: 'Nom et prenom',
                      value: session == null ? 'Aucune session chargee' : profileName,
                    ),
                    _ControllerIdentityTile(
                      icon: Icons.location_city_rounded,
                      label: 'Commune de rattachement',
                      value: session == null ? 'Non renseignee' : communeLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  session == null ? 'Mode: -' : 'Role: ${session!.role} · Mode: ${session!.modeLabel}',
                  style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF5A6573)),
                  textAlign: wide ? TextAlign.start : TextAlign.center,
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: wide ? WrapAlignment.start : WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _RoleCapabilityChip(
                      label: 'Controleur',
                      enabled: canValidateFiles,
                      icon: Icons.verified_user_rounded,
                      activeText: 'Verification des dossiers et diffusion du QR autorisees',
                      inactiveText: 'Validation reservee aux controleurs',
                    ),
                  ],
                ),
              ],
            );

            if (!wide) {
              return Column(
                children: [icon, const SizedBox(height: 16), content],
              );
            }

            return Row(
              children: [
                icon,
                const SizedBox(width: 18),
                Expanded(child: content),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ControllerIdentityTile extends StatelessWidget {
  const _ControllerIdentityTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 340),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7E0EA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF0B6FA4), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF5A6573),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF5A6573)),
          ),
        ],
      ],
    );
  }
}

class _ValidationCard extends StatelessWidget {
  const _ValidationCard({
    required this.title,
    required this.roleLabel,
    required this.roleDescription,
    required this.enabled,
    required this.polls,
    required this.selectedPollId,
    required this.onPollChanged,
    required this.firstNameController,
    required this.lastNameController,
    required this.birthYearController,
    required this.phoneSuffixController,
    required this.duplicateCommentController,
    required this.duplicateReason,
    required this.isCitizenCodeSubmitting,
    required this.lastCitizenCodeMessage,
    required this.duplicateRequests,
    required this.onReasonChanged,
    required this.onCitizenCodeSubmit,
    required this.availableRecords,
    required this.selectedRecordId,
    required this.selectedIdDoc,
    required this.selectedAddressDoc,
    required this.onRecordChanged,
    required this.onIdDocChanged,
    required this.onAddressDocChanged,
    required this.onValidate,
    required this.onPreviewQr,
    required this.onCopyCode,
    required this.onCopyQrPayload,
    required this.onDownloadQr,
    required this.idDocumentTypes,
    required this.addressDocumentTypes,
    required this.selectedRecord,
  });

  final String title;
  final String roleLabel;
  final String roleDescription;
  final bool enabled;
  final List<PollModel> polls;
  final String? selectedPollId;
  final ValueChanged<String?> onPollChanged;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController birthYearController;
  final TextEditingController phoneSuffixController;
  final TextEditingController duplicateCommentController;
  final DuplicateReason duplicateReason;
  final bool isCitizenCodeSubmitting;
  final String? lastCitizenCodeMessage;
  final List<DuplicateCodeRequestModel> duplicateRequests;
  final ValueChanged<DuplicateReason> onReasonChanged;
  final VoidCallback onCitizenCodeSubmit;
  final List<VoteAccessRecordModel> availableRecords;
  final String? selectedRecordId;
  final String? selectedIdDoc;
  final String? selectedAddressDoc;
  final ValueChanged<String?>? onRecordChanged;
  final ValueChanged<String?>? onIdDocChanged;
  final ValueChanged<String?>? onAddressDocChanged;
  final VoidCallback? onValidate;
  final VoidCallback? onPreviewQr;
  final VoidCallback? onCopyCode;
  final VoidCallback? onCopyQrPayload;
  final VoidCallback? onDownloadQr;
  final List<String> idDocumentTypes;
  final List<String> addressDocumentTypes;
  final VoteAccessRecordModel? selectedRecord;

  @override
  Widget build(BuildContext context) {
    final citizenCodeFields = Listenable.merge([
      firstNameController,
      lastNameController,
      birthYearController,
      phoneSuffixController,
    ]);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RoleSectionHeader(
              title: title,
              roleLabel: roleLabel,
              icon: Icons.verified_user_rounded,
            ),
            const SizedBox(height: 12),
            Text(roleDescription, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedPollId,
              decoration: const InputDecoration(
                labelText: 'Sondage suivi',
                helperText: 'Les tuiles Codes / Disponibles / Valides / Votes utilisent ce sondage.',
              ),
              items: polls
                  .map(
                    (poll) => DropdownMenuItem<String>(
                      value: poll.id,
                      child: Text(poll.projectTitle),
                    ),
                  )
                  .toList(),
              onChanged: polls.isEmpty ? null : onPollChanged,
            ),
            const SizedBox(height: 18),
            _CitizenCodeGeneratorCard(
              firstNameController: firstNameController,
              lastNameController: lastNameController,
              birthYearController: birthYearController,
              phoneSuffixController: phoneSuffixController,
              duplicateCommentController: duplicateCommentController,
              duplicateReason: duplicateReason,
              isSubmitting: isCitizenCodeSubmitting,
              lastMessage: lastCitizenCodeMessage,
              enabled: enabled,
              onReasonChanged: onReasonChanged,
            ),
            const SizedBox(height: 18),
            _ControllerDuplicateRequestsCard(requests: duplicateRequests),
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: selectedRecordId,
              decoration: const InputDecoration(labelText: 'Code a verifier'),
              items: availableRecords
                  .map(
                    (record) => DropdownMenuItem<String>(
                      value: record.id,
                      child: Text(record.code),
                    ),
                  )
                  .toList(),
              onChanged: enabled ? onRecordChanged : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedIdDoc,
              decoration: const InputDecoration(labelText: 'Piece d\'identite'),
              items: idDocumentTypes
                  .map((value) => DropdownMenuItem<String>(value: value, child: Text(value)))
                  .toList(),
              onChanged: enabled ? onIdDocChanged : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedAddressDoc,
              decoration: const InputDecoration(labelText: 'Justificatif de domicile'),
              items: addressDocumentTypes
                  .map((value) => DropdownMenuItem<String>(value: value, child: Text(value)))
                  .toList(),
              onChanged: enabled ? onAddressDocChanged : null,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: enabled ? onValidate : null,
              icon: const Icon(Icons.verified_user_outlined),
              label: const Text('Valider l\'inscription'),
            ),
            if (selectedRecord?.qrPayload != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD7E0EA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('QR diffusable', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    QrImageView(
                      data: selectedRecord!.qrPayload!,
                      version: QrVersions.auto,
                      size: 180,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    SelectableText(selectedRecord!.code, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: onPreviewQr,
                          icon: const Icon(Icons.fullscreen_rounded),
                          label: const Text('Agrandir'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: onCopyCode,
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('Copier le code'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: onCopyQrPayload,
                          icon: const Icon(Icons.qr_code_2_rounded),
                          label: const Text('Copier le QR'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: onDownloadQr,
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Telecharger PNG'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(selectedRecord!.qrPayload!),
            ],
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: citizenCodeFields,
              builder: (context, _) {
                final hasFirstName = firstNameController.text.trim().isNotEmpty;
                final hasLastName = lastNameController.text.trim().isNotEmpty;
                final hasValidBirthYear = RegExp(r'^\d{4}$').hasMatch(birthYearController.text.trim());
                final hasValidPhoneSuffix = RegExp(r'^\d{2}$').hasMatch(phoneSuffixController.text.trim());
                final canGenerate = enabled &&
                    !isCitizenCodeSubmitting &&
                    selectedPollId != null &&
                    hasFirstName &&
                    hasLastName &&
                    hasValidBirthYear &&
                    hasValidPhoneSuffix;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: canGenerate ? onCitizenCodeSubmit : null,
                        icon: isCitizenCodeSubmitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.lock_reset_rounded),
                        label: Text(isCitizenCodeSubmitting ? 'Traitement...' : 'Generer / verifier le code citoyen'),
                      ),
                    ),
                    if (!canGenerate && !isCitizenCodeSubmitting) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Renseigner le sondage, le prenom, le nom, l\'annee de naissance sur 4 chiffres et les 2 derniers chiffres du telephone pour activer la generation.',
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF5A6573)),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CitizenCodeGeneratorCard extends StatelessWidget {
  const _CitizenCodeGeneratorCard({
    required this.firstNameController,
    required this.lastNameController,
    required this.birthYearController,
    required this.phoneSuffixController,
    required this.duplicateCommentController,
    required this.duplicateReason,
    required this.isSubmitting,
    required this.lastMessage,
    required this.enabled,
    required this.onReasonChanged,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController birthYearController;
  final TextEditingController phoneSuffixController;
  final TextEditingController duplicateCommentController;
  final DuplicateReason duplicateReason;
  final bool isSubmitting;
  final String? lastMessage;
  final bool enabled;
  final ValueChanged<DuplicateReason> onReasonChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD7E0EA)),
      ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.vpn_key_rounded, color: Color(0xFF0F6D8F)),
                const SizedBox(width: 10),
                Expanded(child: Text('Code citoyen anonyme', style: theme.textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Saisir uniquement les informations minimales autorisees. Les donnees completes ne sont jamais stockees.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                final fields = [
                  TextField(
                    controller: firstNameController,
                    enabled: enabled && !isSubmitting,
                    decoration: const InputDecoration(labelText: 'Premiere lettre du prenom ou prenom saisi'),
                  ),
                  TextField(
                    controller: lastNameController,
                    enabled: enabled && !isSubmitting,
                    decoration: const InputDecoration(labelText: 'Premiere lettre du nom ou nom saisi'),
                  ),
                  TextField(
                    controller: birthYearController,
                    enabled: enabled && !isSubmitting,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: const InputDecoration(labelText: 'Annee de naissance', counterText: ''),
                  ),
                  TextField(
                    controller: phoneSuffixController,
                    enabled: enabled && !isSubmitting,
                    keyboardType: TextInputType.phone,
                    maxLength: 2,
                    decoration: const InputDecoration(labelText: '2 derniers chiffres telephone', counterText: ''),
                  ),
                ];

                if (!wide) {
                  return Column(children: [for (final field in fields) ...[field, const SizedBox(height: 12)]]);
                }

                return Column(
                  children: [
                    Row(children: [Expanded(child: fields[0]), const SizedBox(width: 12), Expanded(child: fields[1])]),
                    const SizedBox(height: 12),
                    Row(children: [Expanded(child: fields[2]), const SizedBox(width: 12), Expanded(child: fields[3])]),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<DuplicateReason>(
              initialValue: duplicateReason,
              decoration: const InputDecoration(labelText: 'Motif si doublon detecte'),
              items: DuplicateReason.values
                  .map((reason) => DropdownMenuItem(value: reason, child: Text(reason.label)))
                  .toList(),
                onChanged: !enabled || isSubmitting
                  ? null
                  : (value) {
                    if (value != null) onReasonChanged(value);
                  },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: duplicateCommentController,
              enabled: enabled && !isSubmitting,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Commentaire controleur optionnel'),
            ),
            if (lastMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: lastMessage!.contains('genere') ? const Color(0xFFE0F2FE) : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SelectableText(lastMessage!),
              ),
            ],
          ],
        ),
    );
  }
}

class _CodeRow extends StatelessWidget {
  const _CodeRow({
    required this.record,
    required this.pollLabel,
    required this.onPreviewQr,
    required this.onCopyCode,
    required this.onCopyQrPayload,
    required this.onDownloadQr,
  });

  final VoteAccessRecordModel record;
  final String pollLabel;
  final VoidCallback? onPreviewQr;
  final VoidCallback onCopyCode;
  final VoidCallback? onCopyQrPayload;
  final VoidCallback? onDownloadQr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFD7E0EA)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0B6FA4).withValues(alpha: 0.10),
          child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF0B6FA4)),
        ),
        title: SelectableText(
          record.code,
          style: theme.textTheme.titleMedium?.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('Sondage: $pollLabel · ${record.communeName ?? 'Commune non renseignee'}'),
        ),
        trailing: _StatusBadge(record: record),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 620;
              final details = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CodeDetailLine(icon: Icons.how_to_vote_outlined, label: 'Sondage', value: pollLabel),
                  if (record.communeName != null) _CodeDetailLine(icon: Icons.location_city_rounded, label: 'Commune', value: record.communeName!),
                  if (record.documentType != null) _CodeDetailLine(icon: Icons.description_outlined, label: 'Documents', value: record.documentType!),
                  if (record.validatedAt != null) _CodeDetailLine(icon: Icons.verified_user_outlined, label: 'Valide le', value: record.validatedAt!),
                  if (record.expiresAt != null) _CodeDetailLine(icon: Icons.event_busy_outlined, label: 'Expire le', value: record.expiresAt!),
                  if (record.verifiedByControleurLabel != null)
                    _CodeDetailLine(icon: Icons.badge_outlined, label: 'Controleur', value: record.verifiedByControleurLabel!),
                ],
              );
              final qr = record.qrPayload == null
                  ? const SizedBox.shrink()
                  : Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD7E0EA)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          QrImageView(
                            data: record.qrPayload!,
                            size: 112,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Text('QR diffusable', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    );

              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [details, if (record.qrPayload != null) ...[const SizedBox(height: 14), Center(child: qr)]],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: details),
                  if (record.qrPayload != null) ...[const SizedBox(width: 16), qr],
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: onCopyCode,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copier le code'),
                ),
                if (record.qrPayload != null)
                  OutlinedButton.icon(
                    onPressed: onPreviewQr,
                    icon: const Icon(Icons.visibility_rounded, size: 18),
                    label: const Text('Voir le QR'),
                  ),
                if (record.qrPayload != null)
                  OutlinedButton.icon(
                    onPressed: onCopyQrPayload,
                    icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                    label: const Text('Copier le QR'),
                  ),
                if (record.qrPayload != null)
                  OutlinedButton.icon(
                    onPressed: onDownloadQr,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Telecharger PNG'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeDetailLine extends StatelessWidget {
  const _CodeDetailLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0B6FA4)),
          const SizedBox(width: 8),
          SizedBox(width: 86, child: Text('$label :', style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ControllerDuplicateRequestsCard extends StatelessWidget {
  const _ControllerDuplicateRequestsCard({required this.requests});

  final List<DuplicateCodeRequestModel> requests;

  @override
  Widget build(BuildContext context) {
    final recent = requests.take(6).toList();
    final pending = requests.where((item) => item.status == 'pending').length;
    final approved = requests.where((item) => item.status == 'approved').length;
    final rejected = requests.where((item) => item.status == 'rejected').length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: Color(0xFF0F6D8F)),
                const SizedBox(width: 10),
                Expanded(child: Text('Mes demandes de regeneration', style: Theme.of(context).textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Suivi des doublons transmis au super administrateur. Les empreintes et la cle source restent masquees cote controleur.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('$pending en attente')),
                Chip(label: Text('$approved validee(s)')),
                Chip(label: Text('$rejected refusee(s)')),
              ],
            ),
            const SizedBox(height: 14),
            if (recent.isEmpty)
              const Text('Aucune demande transmise pour le moment.')
            else
              for (final request in recent)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ControllerDuplicateRequestRow(request: request),
                ),
          ],
        ),
      ),
    );
  }
}

class _ControllerDuplicateRequestRow extends StatelessWidget {
  const _ControllerDuplicateRequestRow({required this.request});

  final DuplicateCodeRequestModel request;

  @override
  Widget build(BuildContext context) {
    final isApproved = request.status == 'approved';
    final isRejected = request.status == 'rejected';
    final background = isApproved
        ? const Color(0xFFE0F2FE)
        : isRejected
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFFFF7ED);
    final icon = isApproved
        ? Icons.check_circle_rounded
        : isRejected
            ? Icons.cancel_rounded
            : Icons.hourglass_top_rounded;
    final title = isApproved
        ? 'Nouveau code valide : ${request.newAccessCode ?? '-'}'
        : isRejected
            ? 'Demande refusee'
            : 'En attente de decision superadmin';
    final subtitle = isRejected && request.rejectionReason?.isNotEmpty == true
        ? 'Motif : ${request.rejectionReason}'
        : 'Motif demande : ${request.duplicateReason.label} · ${request.requestedAt}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: const Color(0xFF0F172A)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleSectionHeader extends StatelessWidget {
  const _RoleSectionHeader({
    required this.title,
    required this.roleLabel,
    required this.icon,
  });

  final String title;
  final String roleLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF0F6D8F).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF0F6D8F)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Chip(label: Text(roleLabel)),
      ],
    );
  }
}

class _RoleCapabilityChip extends StatelessWidget {
  const _RoleCapabilityChip({
    required this.label,
    required this.enabled,
    required this.icon,
    required this.activeText,
    required this.inactiveText,
  });

  final String label;
  final bool enabled;
  final IconData icon;
  final String activeText;
  final String inactiveText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFE0F2FE) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled ? const Color(0xFF7DD3FC) : const Color(0xFFD7E0EA),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: enabled ? const Color(0xFF0F6D8F) : const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$label · ${enabled ? activeText : inactiveText}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.record});

  final VoteAccessRecordModel record;

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color background;
    late final Color foreground;

    if (record.hasVoted) {
      label = 'Vote';
      background = const Color(0xFFDCFCE7);
      foreground = const Color(0xFF166534);
    } else if (record.activated) {
      label = 'Active';
      background = const Color(0xFFE0F2FE);
      foreground = const Color(0xFF075985);
    } else if (record.status == 'validated') {
      label = 'Valide';
      background = const Color(0xFFF3E8FF);
      foreground = const Color(0xFF6B21A8);
    } else {
      label = 'Disponible';
      background = const Color(0xFFFFF7ED);
      foreground = const Color(0xFF9A3412);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  String _labelForStatus(VoteAccessRecordModel record) {
    if (record.hasVoted) {
      return 'Vote';
    }
    if (record.activated) {
      return 'Active';
    }
    if (record.status == 'validated') {
      return 'Valide';
    }
    return 'Disponible';
  }
}
