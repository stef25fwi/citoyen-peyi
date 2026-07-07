import 'package:flutter/material.dart';

import '../services/auth_session_store.dart';
import '../services/citizen_commune_store.dart';
import '../services/commune_branding_service.dart';

class CommuneBrandingBanner extends StatefulWidget {
  const CommuneBrandingBanner({
    this.communeId,
    this.communeName,
    this.title = 'Commune connectee',
    this.subtitle = 'Vous naviguez dans l’espace de votre collectivite.',
    super.key,
  });

  final String? communeId;
  final String? communeName;
  final String title;
  final String subtitle;

  @override
  State<CommuneBrandingBanner> createState() => _CommuneBrandingBannerState();
}

class _CommuneBrandingBannerState extends State<CommuneBrandingBanner> {
  CommuneBrandingModel? _branding;
  String _resolvedCommuneId = '';
  String _resolvedCommuneName = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sessionCommune = AuthSessionStore.instance.currentSession?.commune;
    final citizenContext = await CitizenCommuneStore.instance.currentContext();
    final communeId = (widget.communeId ?? '').trim().isNotEmpty
        ? widget.communeId!.trim()
        : (sessionCommune?.code ?? citizenContext?.communeId ?? '');
    final communeName = (widget.communeName ?? '').trim().isNotEmpty
        ? widget.communeName!.trim()
        : (sessionCommune?.name ?? citizenContext?.communeName ?? '');
    final branding = await CommuneBrandingService.instance.loadForCommune(
      communeId: communeId,
      communeName: communeName,
    );
    if (!mounted) return;
    setState(() {
      _resolvedCommuneId = communeId;
      _resolvedCommuneName = communeName;
      _branding = branding;
    });
  }

  @override
  Widget build(BuildContext context) {
    final communeName = _branding?.communeName.isNotEmpty == true
        ? _branding!.communeName
        : _resolvedCommuneName;
    if (communeName.isEmpty && (_branding?.hasLogo ?? false) == false) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: const Color(0xFFF7FBFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFD6E9F8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _branding?.hasLogo == true
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      _branding!.logoUrl,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _fallbackLogo(),
                    ),
                  )
                : _fallbackLogo(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: const Color(0xFF0F6D8F),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    communeName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF52627A),
                        ),
                  ),
                  if (_resolvedCommuneId.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Code collectivité : $_resolvedCommuneId',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF7B8794),
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackLogo() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFE5F3FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.location_city_rounded,
        color: Color(0xFF0F6D8F),
        size: 36,
      ),
    );
  }
}
