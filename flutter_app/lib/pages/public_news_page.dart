import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/citizen_public_access_service.dart';
import '../services/firestore_data_service.dart';
import '../widgets/citizen/citizen_bottom_nav.dart';
import '../widgets/citizen_connect_invite.dart';
import '../widgets/public_bottom_nav.dart';
import 'public_results_page.dart';

/// Page actualités / projets de la commune.
///
/// Lit la collection Firestore `public_news` (champs: title, body, communeName,
/// publishedAt, link). Si la collection est vide ou indisponible, un empty
/// state honnête est affiché.
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
    setState(() => _isLoading = true);
    final db = FirestoreDataService.instance;
    List<_NewsItem> items = const [];    if (db != null) {
      try {
        final snapshot = await db
            .collection('public_news')
            .orderBy('publishedAt', descending: true)
            .limit(50)
            .get();
        items = snapshot.docs.map((doc) => _NewsItem.fromMap(doc.data())).toList();
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Actualités / Projets'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 20),
              children: [
                 if (CitizenPublicAccessService.instance.currentSession == null) ...[
                   const CitizenConnectInvite(
                     message:
                         ‘Connectez-vous à votre compte pour suivre les actualités et participer aux consultations de votre commune.’,
                   ),
                 ] else ...[
                   Text(
                     ‘Informations communales et projets soumis à consultation.’,
                     style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF5A6573)),
                     textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 18),
                   if (_isLoading)
                     const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
                   else if (_items.isEmpty)
                     Card(
                       child: Padding(
                         padding: const EdgeInsets.all(28),
                         child: Column(
                           children: [
                             const Icon(Icons.newspaper_rounded, size: 42, color: Color(0xFF5A6573)),
                             const SizedBox(height: 12),
                             Text(‘Aucune actualité pour le moment’, style: theme.textTheme.titleLarge),
                             const SizedBox(height: 6),
                             const Text(
                               ‘Les communes peuvent publier ici leurs actualités et projets soumis à consultation. Revenez bientôt.’,
                               textAlign: TextAlign.center,
                             ),
                           ],
                         ),
                       ),
                     )
                   else
                     for (final item in _items) _NewsCard(item: item),
                 ],              : const PublicBottomNav(currentTab: PublicTab.news),
    );
  }

  void _onCitizenNav(CitizenNavTab tab) {
    switch (tab) {
      case CitizenNavTab.home:
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/citizen/welcome',
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (item.communeName.isNotEmpty)
                Text(item.communeName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(color: const Color(0xFF5A6573))),
              const SizedBox(height: 4),
              Text(item.title, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
              if (item.publishedAt.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(item.publishedAt,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF5A6573))),
              ],
              if (item.body.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(item.body, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
              ],
            ],
          ),
        ),
      ),
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
      body: (data['body'] as String? ?? data['content'] as String? ?? '').trim(),
      communeName: (data['communeName'] as String? ?? '').trim(),
      publishedAt: publishedIso,
    );
  }
}
