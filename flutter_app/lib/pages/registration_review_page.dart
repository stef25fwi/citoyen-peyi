import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/poll_models.dart';
import '../services/auth_session_store.dart';
import '../services/poll_service.dart';
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
  String? _selectedPollId;
  String? _selectedRecordId;
  String? _selectedIdDoc;
  String? _selectedAddressDoc;
  String _statusFilter = 'all';
  final TextEditingController _generateCountController = TextEditingController(text: '10');
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _generateCountController.dispose();
    _searchController.dispose();
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

    final polls = await PollService.instance.loadPolls();
    final records = await VoteAccessService.instance.loadAllRecords();

    if (!mounted) {
      return;
    }

    setState(() {
      _polls = polls;
      _records = records;
      _selectedPollId ??= polls.isNotEmpty ? polls.first.id : null;
      _isLoading = false;
    });
  }

  Future<void> _generateCodes() async {
    if (_isSubmitting || _selectedPollId == null) {
      return;
    }

    final count = int.tryParse(_generateCountController.text.trim());
    if (count == null || count < 1 || count > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saisir un nombre de codes entre 1 et 500.')),
      );
      return;
    }

    final session = AuthSessionStore.instance.currentSession;

    setState(() {
      _isSubmitting = true;
    });

    await VoteAccessService.instance.generateCodes(
      pollId: _selectedPollId!,
      count: count,
      communeName: session?.commune?.name,
    );
    await _load();

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$count code(s) d\'inscription generes.')),
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = AuthSessionStore.instance.currentSession;
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
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Session active', style: theme.textTheme.headlineSmall),
                              const SizedBox(height: 12),
                              Text(
                                session == null
                                    ? 'Aucune session chargee.'
                                    : 'Role: ${session.role}\nProfil: ${session.label ?? 'Utilisateur'}\nCode: ${session.code ?? '-'}\nCommune: ${session.commune?.name ?? '-'}\nMode: ${session.modeLabel}',
                                style: theme.textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
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
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 860;
                          final left = _ManagementCard(
                            polls: _polls,
                            selectedPollId: _selectedPollId,
                            generateCountController: _generateCountController,
                            onPollChanged: (value) {
                              setState(() {
                                _selectedPollId = value;
                                _selectedRecordId = null;
                              });
                            },
                            onGenerate: _isSubmitting ? null : _generateCodes,
                          );
                          final right = _ValidationCard(
                            availableRecords: availableRecords,
                            selectedRecordId: _selectedRecordId,
                            selectedIdDoc: _selectedIdDoc,
                            selectedAddressDoc: _selectedAddressDoc,
                            onRecordChanged: (value) => setState(() => _selectedRecordId = value),
                            onIdDocChanged: (value) => setState(() => _selectedIdDoc = value),
                            onAddressDocChanged: (value) => setState(() => _selectedAddressDoc = value),
                            onValidate: _isSubmitting ? null : _validateSelectedRecord,
                            idDocumentTypes: _idDocumentTypes,
                            addressDocumentTypes: _addressDocumentTypes,
                            selectedRecord: selectedRecord,
                          );

                          if (wide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: left),
                                const SizedBox(width: 16),
                                Expanded(child: right),
                              ],
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              left,
                              const SizedBox(height: 16),
                              right,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Codes recents', style: theme.textTheme.titleLarge),
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
                                    child: _CodeRow(record: record),
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

class _ManagementCard extends StatelessWidget {
  const _ManagementCard({
    required this.polls,
    required this.selectedPollId,
    required this.generateCountController,
    required this.onPollChanged,
    required this.onGenerate,
  });

  final List<PollModel> polls;
  final String? selectedPollId;
  final TextEditingController generateCountController;
  final ValueChanged<String?> onPollChanged;
  final VoidCallback? onGenerate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilotage des inscriptions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedPollId,
              decoration: const InputDecoration(labelText: 'Sondage cible'),
              items: polls
                  .map(
                    (poll) => DropdownMenuItem<String>(
                      value: poll.id,
                      child: Text(poll.projectTitle),
                    ),
                  )
                  .toList(),
              onChanged: onPollChanged,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: generateCountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nombre de codes a generer'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: polls.isEmpty ? null : onGenerate,
              icon: const Icon(Icons.qr_code_2_rounded),
              label: const Text('Generer des codes'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValidationCard extends StatelessWidget {
  const _ValidationCard({
    required this.availableRecords,
    required this.selectedRecordId,
    required this.selectedIdDoc,
    required this.selectedAddressDoc,
    required this.onRecordChanged,
    required this.onIdDocChanged,
    required this.onAddressDocChanged,
    required this.onValidate,
    required this.idDocumentTypes,
    required this.addressDocumentTypes,
    required this.selectedRecord,
  });

  final List<VoteAccessRecordModel> availableRecords;
  final String? selectedRecordId;
  final String? selectedIdDoc;
  final String? selectedAddressDoc;
  final ValueChanged<String?> onRecordChanged;
  final ValueChanged<String?> onIdDocChanged;
  final ValueChanged<String?> onAddressDocChanged;
  final VoidCallback? onValidate;
  final List<String> idDocumentTypes;
  final List<String> addressDocumentTypes;
  final VoteAccessRecordModel? selectedRecord;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Verification d\'un dossier', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
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
              onChanged: onRecordChanged,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedIdDoc,
              decoration: const InputDecoration(labelText: 'Piece d\'identite'),
              items: idDocumentTypes
                  .map((value) => DropdownMenuItem<String>(value: value, child: Text(value)))
                  .toList(),
              onChanged: onIdDocChanged,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedAddressDoc,
              decoration: const InputDecoration(labelText: 'Justificatif de domicile'),
              items: addressDocumentTypes
                  .map((value) => DropdownMenuItem<String>(value: value, child: Text(value)))
                  .toList(),
              onChanged: onAddressDocChanged,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onValidate,
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
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(selectedRecord!.qrPayload!),
            ],
          ],
        ),
      ),
    );
  }
}

class _CodeRow extends StatelessWidget {
  const _CodeRow({required this.record});

  final VoteAccessRecordModel record;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7E0EA)),
        color: const Color(0xFFF8FAFC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  record.code,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(width: 12),
              _StatusBadge(record: record),
            ],
          ),
          const SizedBox(height: 8),
          Text('Sondage: ${record.pollId}'),
          if (record.communeName != null) Text('Commune: ${record.communeName}'),
          if (record.documentType != null) Text('Documents: ${record.documentType}'),
          if (record.validatedAt != null) Text('Valide le: ${record.validatedAt}'),
          if (record.expiresAt != null) Text('Expire le: ${record.expiresAt}'),
          if (record.verifiedByControleurLabel != null) Text('Verifie par: ${record.verifiedByControleurLabel}'),
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
