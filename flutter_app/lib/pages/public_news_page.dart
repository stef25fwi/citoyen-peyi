import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/citizen_public_access_service.dart';
import '../services/firestore_data_service.dart';
import '../theme/citizen_design_tokens.dart';
import '../widgets/citizen/citizen_bottom_nav.dart';
import '../widgets/citizen_connect_invite.dart';
import '../widgets/public_bottom_nav.dart';
import '../widgets/public_page_ui.dart';
import 'public_results_page.dart';

class PublicNewsPage extends StatefulWidget {
  const PublicNewsPage({super.key});

  @override
  State<PublicNewsPage> createState() => _PublicNewsPageState();
}

class _PublicNewsPageState extends State<PublicNewsPage> {
  bool _isLoading = true;
  List<_NewsItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _isLoading = true);
    final db = FirestoreDataService.instance;
    List<_NewsItem> items = const [];
    if (db != null) {
      try {
        final snapshot = await db
            .collection('public_news')
            .orderBy('publishedAt', descending: true)
            .limit(50)
            .get();
        items =
            snapshot.docs.map((doc) => _NewsItem.fromMap(doc.data())).toList();
      } catch (_) {
        items = const [];
      }
    }
    if (!mounted) return;
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = CitizenPublicAccessService.instance.currentSession;
    final connected = session != null;

    return PublicPageShell(
      title: 'Actualités / Projets',
      navigationBar: connected
          ? CitizenBottomNav(
              activeTab: CitizenNavTab.news,
              onTabSelected: _onCitizenNav,
            )
          : const PublicBottomNav(currentTab: PublicTab.news),
      body: RefreshIndicator(
        color: CitizenDesignTokens.primaryBlue,
        onRefresh: _load,
        child: PublicResponsiveList(
          children: [
            if (!connected)
              const CitizenConnectInvite(
                message:
                    'Connectez-vous avec votre code citoyen pour suivre votre commune et participer anonymement aux consultations.',
              ),
            const PublicPageIntro(
              icon: Icons.article_rounded,
              title: 'Actualités et projets',
              description:
                  'Retrouvez les informations communales et les projets présentés aux citoyens.',
            ),
            const SizedBox(height: 14),
            if (_isLoading)
              const PublicLoadingState()
            else if (_items.isEmpty)
              const PublicEmptyState(
                icon: Icons.newspaper_rounded,
                title: 'Aucune actualité pour le moment',
                message:
                    'Les communes publieront ici leurs actualités et leurs projets. Revenez prochainement.',
              )
            else
              for (final item in _items) _NewsCard(item: item),
          ],
        ),
      ),
    );
  }

  void _onCitizenNav(CitizenNavTab tab) {
    switch (tab) {
      case CitizenNavTab.home:
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/citizen/home',
          (route) => route.isFirst,
        );
        break;
      case CitizenNavTab.news:
        break;
      case CitizenNavTab.opinion:
        Navigator.of(context).pushNamed('/citizen/consultations');
        break;
      case CitizenNavTab.results:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PublicResultsPage()),
        );
        break;
    }
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item});

  final _NewsItem item;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(compact ? 16 : 18),
          decoration: CitizenDesignTokens.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: compact ? 40 : 44,
                    height: compact ? 40 : 44,
                    decoration: const BoxDecoration(
                      color: CitizenDesignTokens.skyBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.article_outlined,
                      color: CitizenDesignTokens.primaryBlue,
                      size: compact ? 22 : 24,
                    ),
                  ),
                  SizedBox(width: compact ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: CitizenDesignTokens.textDark,
                            fontSize: 16,
                            height: 1.25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (item.communeName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.communeName,
                            style: const TextStyle(
                              color: CitizenDesignTokens.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (item.publishedAt.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  item.publishedAt,
                  style: const TextStyle(
                    color: CitizenDesignTokens.textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (item.body.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  item.body,
                  style: const TextStyle(
                    color: CitizenDesignTokens.textDark,
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _NewsItem {
  const _NewsItem({
    required this.title,
    required this.body,
    required this.communeName,
    required this.publishedAt,
  });

  final String title;
  final String body;
  final String communeName;
  final String publishedAt;

  factory _NewsItem.fromMap(Map<String, dynamic> data) {
    final published = data['publishedAt'];
    String publishedIso = '';
    if (published is Timestamp) {
      publishedIso = published.toDate().toIso8601String().split('T').first;
    } else if (published is String) {
      publishedIso = published;
    }
    return _NewsItem(
      title: (data['title'] as String? ?? '').trim(),
      body:
          (data['body'] as String? ?? data['content'] as String? ?? '').trim(),
      communeName: (data['communeName'] as String? ?? '').trim(),
      publishedAt: publishedIso,
    );
  }
}
