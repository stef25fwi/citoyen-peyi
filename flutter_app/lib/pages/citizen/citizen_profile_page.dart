import 'package:flutter/material.dart';

import '../../services/citizen_public_access_service.dart';
import '../../services/push_notification_service.dart';
import '../../theme/citizen_design_tokens.dart';
import '../../widgets/citizen/citizen_card.dart';

/// Page de profil citoyen : code d'acces masque, historique de connexion,
/// preference de notification et deconnexion.
class CitizenProfilePage extends StatefulWidget {
  const CitizenProfilePage({super.key, this.initialSession});

  final CitizenPublicAccessSession? initialSession;

  @override
  State<CitizenProfilePage> createState() => _CitizenProfilePageState();
}

class _CitizenProfilePageState extends State<CitizenProfilePage> {
  bool _codeVisible = false;
  String? _notificationCategory;
  bool _isSavingCategory = false;

  CitizenPublicAccessSession? get _session =>
      widget.initialSession ??
      CitizenPublicAccessService.instance.currentSession;

  @override
  void initState() {
    super.initState();
    _loadNotificationCategory();
  }

  Future<void> _loadNotificationCategory() async {
    final category =
        await CitizenPublicAccessService.instance.loadNotificationCategory();
    if (!mounted) return;
    setState(() => _notificationCategory = category);
  }

  Future<void> _selectCategory(String category) async {
    if (_isSavingCategory) return;
    final previous = _notificationCategory;
    setState(() {
      _notificationCategory = category;
      _isSavingCategory = true;
    });

    await CitizenPublicAccessService.instance
        .saveNotificationCategory(category);

    final session = _session;
    if (session != null) {
      await PushNotificationService.instance.registerForCitizenCommune(
        rawCode: session.accessCode,
        communeId: session.communeId,
        communeName: session.communeName,
        category: category,
      );
    }

    if (!mounted) return;
    setState(() => _isSavingCategory = false);

    if (previous != category) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notifications : ${_categoryLabel(category)}')),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Vous devrez saisir a nouveau votre code citoyen pour revenir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await CitizenPublicAccessService.instance.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/access', (route) => false);
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'actualites':
        return 'Actualités';
      case 'consultations':
        return 'Consultations';
      case 'resultats':
        return 'Résultats';
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final code = session?.accessCode ?? '';
    final masked = _maskCode(code);

    return Scaffold(
      backgroundColor: CitizenDesignTokens.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SafeArea(
            child: Column(
              children: [
                _ProfileHeader(onBack: () => Navigator.of(context).maybePop()),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CitizenCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionTitle(
                                icon: Icons.key_rounded,
                                title: 'Votre code d\'accès',
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: CitizenDesignTokens.lightBlue,
                                  borderRadius: BorderRadius.circular(
                                      CitizenDesignTokens.radiusSmall),
                                  border: Border.all(
                                      color: CitizenDesignTokens.cardBorder),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        code.isEmpty
                                            ? 'Indisponible'
                                            : (_codeVisible ? code : masked),
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          letterSpacing: 1.2,
                                          color: CitizenDesignTokens.deepBlue,
                                        ),
                                      ),
                                    ),
                                    if (code.isNotEmpty)
                                      IconButton(
                                        tooltip: _codeVisible
                                            ? 'Masquer le code'
                                            : 'Afficher le code',
                                        onPressed: () => setState(
                                            () => _codeVisible = !_codeVisible),
                                        icon: Icon(
                                          _codeVisible
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: CitizenDesignTokens.deepBlue,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        CitizenCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionTitle(
                                icon: Icons.history_rounded,
                                title: 'Historique de connexion',
                              ),
                              const SizedBox(height: 12),
                              _InfoRow(
                                label: 'Première connexion',
                                value: _formatFrenchDateTime(
                                  CitizenPublicAccessService
                                      .instance.firstConnectionAt,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _InfoRow(
                                label: 'Dernière connexion',
                                value: _formatFrenchDateTime(
                                  CitizenPublicAccessService
                                      .instance.lastConnectionAt,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        CitizenCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionTitle(
                                icon: Icons.notifications_none_rounded,
                                title: 'Recevoir des notifications',
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Choisissez une catégorie à suivre.',
                                style: TextStyle(
                                  color: CitizenDesignTokens.textMuted,
                                  fontSize: 12.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _CategoryTile(
                                icon: Icons.campaign_rounded,
                                label: 'Actualités',
                                selected: _notificationCategory == 'actualites',
                                onTap: () => _selectCategory('actualites'),
                              ),
                              const SizedBox(height: 8),
                              _CategoryTile(
                                icon: Icons.chat_bubble_rounded,
                                label: 'Consultations',
                                selected:
                                    _notificationCategory == 'consultations',
                                onTap: () => _selectCategory('consultations'),
                              ),
                              const SizedBox(height: 8),
                              _CategoryTile(
                                icon: Icons.bar_chart_rounded,
                                label: 'Résultats',
                                selected: _notificationCategory == 'resultats',
                                onTap: () => _selectCategory('resultats'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _logout,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(color: Color(0xFFFCA5A5)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    CitizenDesignTokens.radiusButton),
                              ),
                            ),
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text(
                              'Se déconnecter',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
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

String _maskCode(String code) {
  final clean = code.trim();
  if (clean.length < 4) return clean.isEmpty ? '' : '••••';
  return '${clean.substring(0, 2)}${'•' * (clean.length - 4)}${clean.substring(clean.length - 2)}';
}

String _formatFrenchDateTime(DateTime? date) {
  if (date == null) return 'Indisponible';
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} à ${two(local.hour)}:${two(local.minute)}';
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      width: double.infinity,
      decoration:
          const BoxDecoration(gradient: CitizenDesignTokens.headerGradient),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Retour',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
          const Text(
            'Mon profil',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: CitizenDesignTokens.primaryBlue),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: CitizenDesignTokens.textDark,
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: CitizenDesignTokens.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: CitizenDesignTokens.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(CitizenDesignTokens.radiusSmall),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? CitizenDesignTokens.skyBlue
                  : CitizenDesignTokens.lightBlue,
              borderRadius:
                  BorderRadius.circular(CitizenDesignTokens.radiusSmall),
              border: Border.all(
                color: selected
                    ? CitizenDesignTokens.primaryBlue
                    : CitizenDesignTokens.cardBorder,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon,
                    size: 20,
                    color: selected
                        ? CitizenDesignTokens.primaryBlue
                        : CitizenDesignTokens.textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: CitizenDesignTokens.textDark,
                      fontSize: 14.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 20,
                  color: selected
                      ? CitizenDesignTokens.primaryBlue
                      : const Color(0xFFB8CBDD),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
