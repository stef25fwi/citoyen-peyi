import 'package:flutter/material.dart';

import '../services/auth_session_store.dart';
import '../services/citizen_access_code_service.dart';

class DuplicateRequestDetailPage extends StatefulWidget {
  const DuplicateRequestDetailPage({required this.requestId, super.key});

  final String requestId;

  @override
  State<DuplicateRequestDetailPage> createState() => _DuplicateRequestDetailPageState();
}

class _DuplicateRequestDetailPageState extends State<DuplicateRequestDetailPage> {
  final _rejectionController = TextEditingController();
  bool _isLoading = true;
  bool _isSubmitting = false;
  DuplicateCodeRequestModel? _request;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _rejectionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final requests = await CitizenAccessCodeService.instance.getDuplicateRequestsForSuperAdmin(status: 'all');
    if (!mounted) return;
    setState(() {
      _request = requests.where((item) => item.id == widget.requestId).firstOrNull;
      _isLoading = false;
    });
  }

  Future<void> _approve() async {
    setState(() => _isSubmitting = true);
    final session = AuthSessionStore.instance.currentSession;
    final updated = await CitizenAccessCodeService.instance.approveDuplicateRequest(
      requestId: widget.requestId,
      reviewedBySuperAdminId: session?.id ?? session?.code,
    );
    if (!mounted) return;
    setState(() {
      _request = updated;
      _isSubmitting = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(updated?.newAccessCode == null ? 'Demande traitee.' : 'Nouveau code valide : ${updated!.newAccessCode}')),
    );
  }

  Future<void> _reject() async {
    if (_rejectionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Renseigner le motif de refus.')));
      return;
    }
    setState(() => _isSubmitting = true);
    final session = AuthSessionStore.instance.currentSession;
    final updated = await CitizenAccessCodeService.instance.rejectDuplicateRequest(
      requestId: widget.requestId,
      rejectionReason: _rejectionController.text,
      reviewedBySuperAdminId: session?.id ?? session?.code,
    );
    if (!mounted) return;
    setState(() {
      _request = updated;
      _isSubmitting = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demande refusee.')));
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;
    return Scaffold(
      appBar: AppBar(title: const Text('Detail doublon')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : request == null
                  ? const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('Demande introuvable.')))
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(spacing: 8, children: [Chip(label: Text(request.status)), Chip(label: Text(request.duplicateReason.label))]),
                                const SizedBox(height: 16),
                                _Line('Commune', request.communeName),
                                _Line('Controleur', request.requestedByControllerName),
                                _Line('Date tentative', request.requestedAt),
                                _Line('Cle source masquee superadmin', request.sourceKeyMasked),
                                _Line('Code existant', request.existingAccessCode),
                                if (request.controllerComment != null) _Line('Commentaire controleur', request.controllerComment!),
                                if (request.newAccessCode != null) _Line('Nouveau code', request.newAccessCode!),
                                if (request.rejectionReason != null) _Line('Motif refus', request.rejectionReason!),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (request.status == 'pending')
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Decision superadmin', style: Theme.of(context).textTheme.titleLarge),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _rejectionController,
                                    minLines: 2,
                                    maxLines: 4,
                                    decoration: const InputDecoration(labelText: 'Motif de refus si rejet'),
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      FilledButton.icon(
                                        onPressed: _isSubmitting ? null : _approve,
                                        icon: const Icon(Icons.check_rounded),
                                        label: const Text('Valider la regeneration'),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: _isSubmitting ? null : _reject,
                                        icon: const Icon(Icons.close_rounded),
                                        label: const Text('Refuser'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SelectableText('$label : $value'),
    );
  }
}