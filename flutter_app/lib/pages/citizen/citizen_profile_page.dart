import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/citizen_public_access_service.dart';
import '../../services/push_notification_service.dart';
import '../../theme/citizen_design_tokens.dart';
import '../../widgets/citizen/citizen_card.dart';
import '../../widgets/citizen/citizen_header.dart';

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
      widget.initialSession ?? CitizenPublicAccessService.instance.currentSession;

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
    setState(() {
      _notificationCategory = category;
      _isSavingCategory = true;
    });
    await CitizenPublicAccessService.instance.saveNotificationCategory(category);

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notifications : ${_labelFor(category)}')),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Vous devrez saisir à nouveau votre code citoyen pour revenir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            key: const ValueKey('confirmCitizenLogoutButton'),
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

  String _labelFor(String category) {
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemStatusBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SafeArea(
              bottom: false,
              child: ColoredBox(
                color: CitizenDesignTokens.background,
                child: Column(
                  children: [
                    const CitizenHeader(title: 'Mon profil'),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CitizenCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _SectionTitle(
                                    icon: Icons.location_city_rounded,
                                    title: 'Votre espace citoyen',
                                  ),
                                  const SizedBox(height: 14),
                                  _InfoRow(
                                    label: 'Commune',
                                    value: session?.communeName.isNotEmpty == true
                                        ? session!.communeName
                                        : 'Indisponible',
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: CitizenDesignTokens.lightBlue,
                                      borderRadius: BorderRadius.circular(
                                        CitizenDesignTokens.radiusSmall,
                                      ),
                                      border: Border.all(
                                        color: CitizenDesignTokens.cardBorder,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            code.isEmpty
                                                ? 'Code indisponible'
                                                : _codeVisible
                                                    ? code
                                                    : _maskCode(code),
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                              color:
                                                  CitizenDesignTokens.deepBlue,
                                              fontSize: 16,
                                              letterSpacing: 1.1,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        if (code.isNotEmpty)
                                          IconButton(
                                            tooltip: _codeVisible
                                                ? 'Masquer le code'
                                                : 'Afficher le code',
                                            onPressed: () => setState(
                                              () => _codeVisible = !_codeVisible,
                                            ),
                                            icon: Icon(
                                              _codeVisible
                                                  ? Icons.visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color:
                                                  CitizenDesignTokens.deepBlue,
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
                                  const SizedBox(height: 14),
                                  _InfoRow(
                                    label: 'Première connexion',
                                    value: _formatFrenchDateTime(
                                      CitizenPublicAccessService
                                          .instance.firstConnectionAt,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
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
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Choisissez la catégorie prioritaire à suivre.',
                                    style: TextStyle(
                                      color: CitizenDesignTokens.textMuted,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _CategoryChoice(
                                    value: 'actualites',
                                    label: 'Actualités',
                                    icon: Icons.article_outlined,
                                    selected: _notificationCategory,
                                    onChanged: _selectCategory,
                                  ),
                                  _CategoryChoice(
                                    value: 'consultations',
                                    label: 'Consultations',
                                    icon: Icons.edit_square,
                                    selected: _notificationCategory,
                                    onChanged: _selectCategory,
                                  ),
                                  _CategoryChoice(
                                    value: 'resultats',
                                    label: 'Résultats',
                                    icon: Icons.bar_chart_rounded,
                                    selected: _notificationCategory,
                                    onChanged: _selectCategory,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton.icon(
                              key: const ValueKey('citizenLogoutButton'),
                              onPressed: _logout,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFDC2626),
                                side:
                                    const BorderSide(color: Color(0xFFFCA5A5)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    CitizenDesignTokens.radiusButton,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.logout_rounded),
                              label: const Text(
                                'Se déconnecter',
                                style: TextStyle(fontWeight: FontWeight.w900),
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
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} à ${two(local.hour)}:${two(local.minute)}';
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: CitizenDesignTokens.primaryBlue),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: CitizenDesignTokens.textDark,
              fontSize: 16,
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
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: CitizenDesignTokens.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryChoice extends StatelessWidget {
  const _CategoryChoice({
    required this.value,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onChanged,
  });

  final String value;
  final String label;
  final IconData icon;
  final String? selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(CitizenDesignTokens.radiusSmall),
        onTap: () => onChanged(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: CitizenDesignTokens.primaryBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: CitizenDesignTokens.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected
                    ? CitizenDesignTokens.primaryBlue
                    : CitizenDesignTokens.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
