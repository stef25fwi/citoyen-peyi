import 'package:flutter/material.dart';

import '../../../models/support_ticket.dart';
import '../../../services/support_ticket_service.dart';

class AdminCreateTicketScreen extends StatefulWidget {
  const AdminCreateTicketScreen({super.key});

  @override
  State<AdminCreateTicketScreen> createState() => _AdminCreateTicketScreenState();
}

class _AdminCreateTicketScreenState extends State<AdminCreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String? _category;
  String _priority = 'normale';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    try {
      await SupportTicketService.instance.createTicket(
        subject: _subjectCtrl.text,
        category: _category!,
        priority: _priority,
        message: _messageCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Votre ticket a bien été envoyé au super administrateur.')),
      );
      Navigator.of(context).pushReplacementNamed('/admin/support');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau ticket'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Assistance interne', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        const Text(
                          'Cette messagerie permet aux administrateurs communaux de contacter directement le super administrateur pour signaler un problème technique, une demande de modification ou un besoin d’accompagnement.',
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _subjectCtrl,
                          decoration: const InputDecoration(labelText: 'Sujet du ticket *'),
                          validator: (value) => (value == null || value.trim().length < 5) ? 'Sujet minimum 5 caractères.' : null,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _category,
                          decoration: const InputDecoration(labelText: 'Catégorie *'),
                          items: supportTicketCategories.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                          onChanged: _isSubmitting ? null : (value) => setState(() => _category = value),
                          validator: (value) => value == null ? 'Catégorie obligatoire.' : null,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _priority,
                          decoration: const InputDecoration(labelText: 'Priorité *'),
                          items: const [
                            DropdownMenuItem(value: 'faible', child: Text('Faible')),
                            DropdownMenuItem(value: 'normale', child: Text('Normale')),
                            DropdownMenuItem(value: 'urgente', child: Text('Urgente')),
                          ],
                          onChanged: _isSubmitting ? null : (value) => setState(() => _priority = value ?? 'normale'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _messageCtrl,
                          minLines: 5,
                          maxLines: 9,
                          decoration: const InputDecoration(labelText: 'Message détaillé *'),
                          validator: (value) => (value == null || value.trim().length < 10) ? 'Message minimum 10 caractères.' : null,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send_rounded),
                          label: Text(_isSubmitting ? 'Envoi...' : 'Envoyer le ticket'),
                        ),
                      ],
                    ),
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
