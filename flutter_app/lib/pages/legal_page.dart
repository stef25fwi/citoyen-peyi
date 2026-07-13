import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../services/legal_document_exporter.dart';
import '../theme/citizen_design_tokens.dart';
import '../widgets/citizen/citizen_header.dart';
import '../widgets/public_bottom_nav.dart';
import 'access_citizen_page.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  static const routeName = '/legal';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final legalDocumentText = buildFullLegalDocumentText();

    Future<void> copyLegalText() async {
      await Clipboard.setData(ClipboardData(text: legalDocumentText));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Texte copié. Vous pouvez le conserver hors application.'),
        ),
      );
    }

    Future<void> downloadLegalText() async {
      final downloaded = await downloadLegalDocumentText(
        filename: 'citoyen-peyi-cgu-mentions-legales.txt',
        content: legalDocumentText,
      );
      if (!context.mounted) return;
      final message = downloaded
          ? 'Téléchargement lancé.'
          : 'Téléchargement non disponible ici. Utilisez Copier le texte complet.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

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
            constraints: const BoxConstraints(maxWidth: 430),
            child: ColoredBox(
              color: CitizenDesignTokens.background,
              child: Column(
                children: [
                  const CitizenHeader(title: 'Informations légales'),
                  Expanded(
                    child: SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(12, 18, 12, 24),
                        child: Card(
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Container(
                                    width: 74,
                                    height: 74,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: const Icon(
                                      Icons.gavel_rounded,
                                      color: Color(0xFF0D73F2),
                                      size: 36,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Center(
                                  child: Text(
                                    'CGU, confidentialité, anonymat et données personnelles',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF64748B),
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: copyLegalText,
                                      icon: const Icon(Icons.copy_rounded),
                                      label:
                                          const Text('Copier le texte complet'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: downloadLegalText,
                                      icon: const Icon(Icons.download_rounded),
                                      label: const Text('Télécharger (.txt)'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                const _LegalSection(data: _preambleSection),
                                const Divider(
                                    height: 34, color: Color(0xFFE5E7EB)),
                                for (final section in _legalSections)
                                  _LegalSection(data: section),
                                const Divider(
                                    height: 34, color: Color(0xFFE5E7EB)),
                                Text(
                                  'Mentions légales',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: const Color(0xFF0D73F2),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                for (final block in _legalNoticeBlocks)
                                  _LegalNoticeBlock(block: block),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: FilledButton.icon(
                                    key: const ValueKey(
                                        'legalAcknowledgementButton'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF0D73F2),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    onPressed: () {
                                      if (Navigator.of(context).canPop()) {
                                        Navigator.of(context).pop();
                                        return;
                                      }
                                      Navigator.of(context)
                                          .pushReplacementNamed(
                                        AccessCitizenPage.routeName,
                                      );
                                    },
                                    icon: const Icon(Icons.check_rounded),
                                    label: const Text('J’ai pris connaissance'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: const PublicBottomNav(currentTab: PublicTab.vote),
      ),
    );
  }
}

String buildFullLegalDocumentText() {
  final buffer = StringBuffer()
    ..writeln('CGU, confidentialite, anonymat et mentions legales')
    ..writeln('');

  void writeSection(_LegalSectionData section) {
    buffer.writeln(section.title);
    buffer.writeln('');
    for (final paragraph in section.paragraphs) {
      buffer.writeln(paragraph);
      buffer.writeln('');
    }
    for (final bullet in section.bullets) {
      buffer.writeln('- $bullet');
    }
    if (section.bullets.isNotEmpty) {
      buffer.writeln('');
    }
    for (final paragraph in section.afterBullets) {
      buffer.writeln(paragraph);
      buffer.writeln('');
    }
  }

  writeSection(_preambleSection);
  for (final section in _legalSections) {
    writeSection(section);
  }

  buffer
    ..writeln('Mentions legales')
    ..writeln('');
  for (final block in _legalNoticeBlocks) {
    buffer.writeln(block.title);
    for (final line in block.lines) {
      buffer.writeln('- $line');
    }
    buffer.writeln('');
  }

  return buffer.toString().trim();
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({required this.data});

  final _LegalSectionData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: const Color(0xFF0D73F2),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final paragraph in data.paragraphs) _LegalParagraph(paragraph),
          if (data.bullets.isNotEmpty) _LegalBulletList(data.bullets),
          for (final paragraph in data.afterBullets) _LegalParagraph(paragraph),
        ],
      ),
    );
  }
}

class _LegalParagraph extends StatelessWidget {
  const _LegalParagraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF0F172A),
          height: 1.5,
        ),
      ),
    );
  }
}

class _LegalBulletList extends StatelessWidget {
  const _LegalBulletList(this.items);

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: Color(0xFF20B69C),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF0F172A),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LegalNoticeBlock extends StatelessWidget {
  const _LegalNoticeBlock({required this.block});

  final _LegalNoticeData block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              block.title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            for (final line in block.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  line,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF0F172A),
                    height: 1.4,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegalSectionData {
  const _LegalSectionData({
    required this.title,
    this.paragraphs = const <String>[],
    this.bullets = const <String>[],
    this.afterBullets = const <String>[],
  });

  final String title;
  final List<String> paragraphs;
  final List<String> bullets;
  final List<String> afterBullets;
}

class _LegalNoticeData {
  const _LegalNoticeData({required this.title, required this.lines});

  final String title;
  final List<String> lines;
}

const _preambleSection = _LegalSectionData(
  title: 'Préambule',
  paragraphs: <String>[
    'Citoyen Peyi est une plateforme numérique de consultation citoyenne destinée à faciliter l’expression des habitants sur des sujets d’intérêt général proposés par une collectivité, une commune, un établissement public, une association ou tout organisme autorisé.',
    'La plateforme permet aux citoyens de participer à des consultations, sondages, questionnaires ou démarches de concertation locale dans un cadre sécurisé, confidentiel et respectueux de la vie privée.',
    'L’objectif de Citoyen Peyi est de renforcer le dialogue entre les citoyens et les acteurs publics, d’encourager la participation locale et de permettre une meilleure prise en compte des attentes du territoire.',
    'L’utilisation de la plateforme implique l’acceptation des présentes conditions générales d’utilisation, de la politique de confidentialité et des informations légales présentées sur cette page.',
  ],
);

const _legalSections = <_LegalSectionData>[
  _LegalSectionData(
    title: '1. Objet des conditions générales d’utilisation',
    paragraphs: <String>[
      'Les présentes conditions générales d’utilisation ont pour objet de définir les règles d’accès, de participation et d’utilisation de la plateforme Citoyen Peyi.',
      'Elles précisent notamment :',
    ],
    bullets: <String>[
      'les conditions d’accès aux consultations ;',
      'les règles d’utilisation du code citoyen ;',
      'les engagements de l’utilisateur ;',
      'les règles relatives à la confidentialité des réponses ;',
      'les principes applicables aux données personnelles ;',
      'les responsabilités de l’éditeur, de la collectivité et de l’utilisateur ;',
      'les informations légales obligatoires relatives à la plateforme.',
    ],
    afterBullets: <String>[
      'En accédant à Citoyen Peyi, l’utilisateur reconnaît avoir pris connaissance des présentes informations et s’engage à les respecter.',
    ],
  ),
  _LegalSectionData(
    title: '2. Présentation du service',
    paragraphs: <String>[
      'Citoyen Peyi permet à une collectivité ou à un organisme autorisé de proposer des consultations citoyennes en ligne.',
      'Ces consultations peuvent prendre différentes formes :',
    ],
    bullets: <String>[
      'questions à choix unique ;',
      'questions à choix multiples ;',
      'avis favorables ou défavorables ;',
      'classement de priorités ;',
      'questionnaires thématiques ;',
      'consultations de quartier ;',
      'enquêtes d’opinion locale ;',
      'consultations publiques préparatoires à un projet.',
    ],
    afterBullets: <String>[
      'Les résultats peuvent être utilisés pour mieux comprendre les attentes des habitants, orienter les politiques publiques, préparer des projets, améliorer un service public ou enrichir une démarche de concertation.',
      'Sauf mention expresse contraire, les consultations organisées sur Citoyen Peyi ont une valeur consultative. Elles ne remplacent pas les procédures légales obligatoires, les élections, les référendums officiels, les enquêtes publiques réglementaires, les délibérations des assemblées compétentes ou les décisions administratives formelles.',
    ],
  ),
  _LegalSectionData(
    title: '3. Accès citoyen et code de participation',
    paragraphs: <String>[
      'L’accès à certaines consultations peut être conditionné à la saisie d’un code citoyen.',
      'Ce code peut être utilisé pour :',
    ],
    bullets: <String>[
      'vérifier que la personne est autorisée à participer ;',
      'limiter les participations multiples non autorisées ;',
      'sécuriser l’accès à la consultation ;',
      'garantir une meilleure fiabilité des résultats ;',
      'protéger la consultation contre les abus, robots ou tentatives de manipulation.',
    ],
    afterBullets: <String>[
      'Le code citoyen ne doit pas être partagé avec une autre personne lorsque la consultation est personnelle ou réservée à un public défini.',
      'L’utilisateur est responsable de l’utilisation de son code citoyen. Toute tentative de contournement, de duplication ou de fraude peut entraîner le refus de prise en compte de la participation.',
    ],
  ),
  _LegalSectionData(
    title: '4. Consultation obligatoire des CGU avant participation',
    paragraphs: <String>[
      'Avant de valider son code citoyen et d’accéder à une consultation, l’utilisateur doit consulter les présentes conditions générales d’utilisation et informations légales.',
      'L’utilisateur doit confirmer avoir pris connaissance des CGU avant de pouvoir valider son code citoyen.',
      'Cette étape permet de s’assurer que chaque participant comprend :',
    ],
    bullets: <String>[
      'le fonctionnement de la plateforme ;',
      'le principe de confidentialité ;',
      'l’utilisation du code citoyen ;',
      'la finalité des consultations ;',
      'les conditions de traitement des données ;',
      'les droits dont il dispose.',
    ],
    afterBullets: <String>[
      'La validation du code citoyen ne doit pas être possible tant que l’utilisateur n’a pas confirmé la lecture des présentes informations.',
    ],
  ),
  _LegalSectionData(
    title: '5. Principe de confidentialité de la participation',
    paragraphs: <String>[
      'Citoyen Peyi est conçu pour permettre une participation citoyenne confidentielle.',
      'Les choix exprimés par les participants ne sont pas destinés à être affichés publiquement avec leur identité.',
      'Les résultats présentés à la collectivité ou au public sont, sauf mention contraire, exploités sous forme statistique, agrégée ou synthétique.',
      'Cela signifie que les résultats peuvent présenter, par exemple :',
    ],
    bullets: <String>[
      'le nombre total de participants ;',
      'les pourcentages de réponses ;',
      'les tendances générales ;',
      'les priorités exprimées ;',
      'les résultats par thème ou par zone géographique lorsque cela ne permet pas d’identifier directement une personne.',
    ],
  ),
  _LegalSectionData(
    title: '6. Principe d’anonymat et limites techniques',
    paragraphs: <String>[
      'Citoyen Peyi vise à protéger l’identité des participants et à éviter que les réponses exprimées soient publiquement associées à une personne identifiable.',
      'Toutefois, lorsqu’un code citoyen, un identifiant technique ou un mécanisme de contrôle est utilisé pour vérifier l’éligibilité, éviter les doublons ou sécuriser la consultation, certaines informations techniques peuvent être traitées séparément des réponses.',
      'La plateforme doit donc distinguer :',
    ],
    bullets: <String>[
      'les réponses citoyennes, destinées à être exploitées de manière anonyme ou agrégée ;',
      'les données techniques de contrôle, utilisées uniquement pour sécuriser la consultation ;',
      'les données d’administration, utilisées uniquement par les personnes habilitées.',
    ],
    afterBullets: <String>[
      'L’objectif est de limiter au maximum les données collectées, de séparer les informations de contrôle des réponses, et de ne pas afficher publiquement l’identité du participant avec son vote ou son avis.',
    ],
  ),
  _LegalSectionData(
    title: '7. Engagements de l’utilisateur',
    paragraphs: <String>[
      'L’utilisateur s’engage à utiliser Citoyen Peyi de manière loyale, sincère et conforme à sa finalité citoyenne.',
      'Il s’engage notamment à :',
    ],
    bullets: <String>[
      'ne pas tenter de voter plusieurs fois lorsque cela n’est pas autorisé ;',
      'ne pas utiliser le code citoyen d’une autre personne ;',
      'ne pas contourner les dispositifs de sécurité ;',
      'ne pas perturber le fonctionnement de la plateforme ;',
      'ne pas transmettre de contenu injurieux, discriminatoire, violent, diffamatoire ou contraire à l’ordre public ;',
      'ne pas utiliser la plateforme à des fins commerciales, politiques illicites, frauduleuses ou malveillantes ;',
      'ne pas tenter d’accéder à des données, comptes, résultats ou espaces d’administration auxquels il n’est pas autorisé.',
    ],
    afterBullets: <String>[
      'Tout usage abusif peut entraîner le blocage de l’accès, le retrait d’une contribution ou le signalement à l’organisateur de la consultation.',
    ],
  ),
  _LegalSectionData(
    title: '8. Exactitude des informations',
    paragraphs: <String>[
      'Lorsque l’utilisateur est amené à renseigner une information, il s’engage à fournir une information sincère, exacte et conforme à la réalité.',
      'Dans le cas d’une consultation réservée à certains habitants, usagers, agents, quartiers ou publics, l’utilisateur s’engage à ne participer que s’il répond aux conditions prévues par l’organisateur.',
      'L’éditeur ou la collectivité peut mettre en œuvre des contrôles proportionnés pour limiter les abus et préserver la fiabilité des résultats.',
    ],
  ),
  _LegalSectionData(
    title: '9. Résultats des consultations',
    paragraphs: <String>[
      'Les résultats des consultations peuvent être affichés dans l’application, communiqués à la collectivité, publiés dans un bilan ou utilisés dans un rapport de concertation.',
      'Les résultats sont présentés sous une forme qui ne doit pas permettre d’identifier directement un participant.',
      'La collectivité reste libre d’utiliser les résultats comme outil d’aide à la décision, sans que ceux-ci constituent nécessairement une décision administrative définitive.',
      'Lorsque la consultation porte sur un sujet sensible, la collectivité peut décider de ne publier que des résultats globaux afin de préserver la confidentialité et d’éviter toute identification indirecte.',
    ],
  ),
  _LegalSectionData(
    title: '10. Modération des contenus',
    paragraphs: <String>[
      'Certaines consultations peuvent permettre l’expression de commentaires libres, propositions ou contributions textuelles.',
      'Dans ce cas, les contenus peuvent faire l’objet d’une modération préalable ou a posteriori.',
      'Peuvent être refusés, masqués ou supprimés les contenus :',
    ],
    bullets: <String>[
      'injurieux ;',
      'diffamatoires ;',
      'discriminatoires ;',
      'menaçants ;',
      'violents ;',
      'contraires à l’ordre public ;',
      'portant atteinte à la vie privée d’une personne ;',
      'contenant des données personnelles inutiles ;',
      'sans rapport avec l’objet de la consultation ;',
      'visant à manipuler ou perturber la consultation.',
    ],
    afterBullets: <String>[
      'La modération ne doit pas avoir pour objet de censurer une opinion citoyenne exprimée de manière respectueuse et conforme au cadre de la consultation.',
    ],
  ),
  _LegalSectionData(
    title: '11. Données personnelles traitées',
    paragraphs: <String>[
      'Citoyen Peyi est conçu selon un principe de minimisation des données.',
      'Selon la configuration choisie par la collectivité ou l’organisateur, les données susceptibles d’être traitées peuvent notamment comprendre :',
    ],
    bullets: <String>[
      'un code citoyen ou code de participation ;',
      'un identifiant technique ;',
      'la date et l’heure de participation ;',
      'la consultation concernée ;',
      'les réponses données ;',
      'des informations techniques nécessaires au fonctionnement du service ;',
      'des journaux de sécurité ;',
      'des données de session ;',
      'des informations permettant de limiter les participations multiples ;',
      'des données nécessaires à l’administration de la consultation.',
    ],
    afterBullets: <String>[
      'La plateforme n’a pas vocation à publier publiquement le nom, le prénom, l’adresse ou l’identité complète d’un participant avec ses réponses.',
    ],
  ),
  _LegalSectionData(
    title: '12. Finalités du traitement des données',
    paragraphs: <String>[
      'Les données traitées dans le cadre de Citoyen Peyi peuvent avoir pour finalités :',
    ],
    bullets: <String>[
      'permettre l’accès à une consultation ;',
      'vérifier l’éligibilité d’un participant ;',
      'recueillir les réponses citoyennes ;',
      'produire des statistiques ;',
      'éviter les doublons ;',
      'sécuriser la plateforme ;',
      'détecter les tentatives de fraude ;',
      'administrer les consultations ;',
      'produire un bilan de consultation ;',
      'améliorer le fonctionnement du service ;',
      'répondre aux demandes d’assistance ;',
      'respecter les obligations légales applicables.',
    ],
    afterBullets: <String>[
      'Aucune donnée ne doit être collectée sans finalité déterminée, explicite et légitime.',
    ],
  ),
  _LegalSectionData(
    title: '13. Base légale du traitement',
    paragraphs: <String>[
      'Selon le cadre de la consultation et l’identité de l’organisateur, les traitements de données peuvent reposer sur différentes bases légales, notamment :',
    ],
    bullets: <String>[
      'l’exécution d’une mission d’intérêt public lorsque la consultation est organisée par une collectivité ou un organisme public ;',
      'l’intérêt légitime de l’organisateur à sécuriser la consultation et prévenir les abus ;',
      'le consentement de l’utilisateur lorsque celui-ci est requis pour certains traitements optionnels ;',
      'le respect d’une obligation légale lorsque la réglementation l’impose.',
    ],
    afterBullets: <String>[
      'La base légale exacte doit être précisée par l’organisateur ou le responsable du traitement en fonction du contexte de chaque consultation.',
    ],
  ),
  _LegalSectionData(
    title: '14. Responsable du traitement',
    paragraphs: <String>[
      'Le responsable du traitement est l’organisme qui détermine les finalités et les moyens du traitement des données.',
      'Pour Citoyen Peyi, le responsable du traitement peut être :',
      '[Nom de la collectivité / commune / organisme responsable]',
      '[Adresse complète]',
      '[Email de contact]',
      '[Téléphone]',
      '[DPO ou référent données personnelles, si applicable]',
      'Lorsque Citoyen Peyi est utilisé par plusieurs collectivités ou organismes, chaque organisateur peut être responsable des traitements liés à ses propres consultations.',
    ],
  ),
  _LegalSectionData(
    title: '15. Destinataires des données',
    paragraphs: <String>[
      'Les données peuvent être accessibles uniquement aux personnes habilitées, dans la limite de leurs missions.',
      'Les destinataires peuvent notamment être :',
    ],
    bullets: <String>[
      'les administrateurs autorisés de la plateforme ;',
      'les agents ou services désignés par la collectivité ;',
      'les prestataires techniques intervenant pour l’hébergement, la maintenance ou la sécurité ;',
      'les personnes chargées de produire les bilans de consultation ;',
      'les autorités compétentes lorsque la loi l’exige.',
    ],
    afterBullets: <String>[
      'Les réponses individuelles ne doivent pas être communiquées publiquement avec l’identité du participant.',
    ],
  ),
  _LegalSectionData(
    title: '16. Sous-traitants et hébergement',
    paragraphs: <String>[
      'La plateforme peut faire appel à des prestataires techniques pour assurer son hébergement, sa maintenance, sa sécurité, son stockage ou son fonctionnement.',
      'Ces prestataires n’agissent que dans le cadre des instructions du responsable du traitement et ne peuvent pas utiliser les données pour leurs propres finalités.',
      'Hébergeur à compléter :',
      'Nom de l’hébergeur : [Nom de l’hébergeur]',
      'Adresse : [Adresse de l’hébergeur]',
      'Pays d’hébergement : [Pays]',
      'Contact : [Contact hébergeur]',
      'Si l’application utilise Firebase, Google Cloud ou un autre service cloud, indiquer ici les informations exactes d’hébergement et les éventuelles garanties contractuelles applicables.',
    ],
  ),
  _LegalSectionData(
    title: '17. Durée de conservation',
    paragraphs: <String>[
      'Les données sont conservées pendant une durée limitée et proportionnée aux finalités de la consultation.',
      'À titre indicatif :',
    ],
    bullets: <String>[
      'les réponses peuvent être conservées pendant la durée nécessaire à l’analyse de la consultation ;',
      'les résultats agrégés peuvent être conservés plus longtemps lorsqu’ils ne permettent pas d’identifier les participants ;',
      'les journaux techniques peuvent être conservés pendant une durée limitée pour assurer la sécurité du service ;',
      'les codes citoyens peuvent être conservés uniquement le temps nécessaire à la vérification de l’accès et à la prévention des doublons ;',
      'les données d’assistance peuvent être conservées le temps nécessaire au traitement de la demande.',
    ],
    afterBullets: <String>[
      'Durées exactes à compléter par l’organisateur :',
      'Durée de conservation des réponses : [à compléter]',
      'Durée de conservation des codes citoyens : [à compléter]',
      'Durée de conservation des journaux techniques : [à compléter]',
      'Durée de conservation des résultats agrégés : [à compléter]',
    ],
  ),
  _LegalSectionData(
    title: '18. Sécurité des données',
    paragraphs: <String>[
      'L’éditeur met en œuvre des mesures techniques et organisationnelles destinées à protéger la plateforme et les données traitées.',
      'Ces mesures peuvent notamment comprendre :',
    ],
    bullets: <String>[
      'contrôle des accès administrateurs ;',
      'limitation des droits selon les rôles ;',
      'sécurisation des échanges ;',
      'journalisation technique ;',
      'hébergement sécurisé ;',
      'sauvegardes lorsque nécessaire ;',
      'séparation des données de contrôle et des réponses lorsque cela est possible ;',
      'limitation des données collectées ;',
      'surveillance des anomalies ;',
      'protection contre les abus automatisés.',
    ],
    afterBullets: <String>[
      'Aucun système informatique ne pouvant garantir une sécurité absolue, l’utilisateur est invité à signaler toute anomalie, faille présumée ou usage abusif via le contact indiqué dans les mentions légales.',
    ],
  ),
  _LegalSectionData(
    title: '19. Droits des utilisateurs',
    paragraphs: <String>[
      'Conformément à la réglementation applicable en matière de protection des données personnelles, les utilisateurs peuvent disposer de plusieurs droits sur les données les concernant.',
      'Ces droits peuvent notamment comprendre :',
    ],
    bullets: <String>[
      'le droit d’accès ;',
      'le droit de rectification ;',
      'le droit d’effacement ;',
      'le droit de limitation ;',
      'le droit d’opposition ;',
      'le droit à la portabilité lorsque celui-ci s’applique ;',
      'le droit de retirer un consentement lorsque le traitement repose sur le consentement.',
    ],
    afterBullets: <String>[
      'Pour exercer ses droits, l’utilisateur peut contacter :',
      '[Email de contact données personnelles]',
      '[DPO ou référent données personnelles, si applicable]',
      '[Adresse postale]',
      'La demande doit permettre d’identifier raisonnablement la personne concernée sans compromettre le principe de confidentialité de la participation.',
      'L’utilisateur peut également introduire une réclamation auprès de l’autorité de protection des données compétente.',
    ],
  ),
  _LegalSectionData(
    title: '20. Cookies, traceurs et données techniques',
    paragraphs: <String>[
      'Citoyen Peyi peut utiliser des cookies ou traceurs strictement nécessaires au fonctionnement de la plateforme.',
      'Ces traceurs peuvent servir à :',
    ],
    bullets: <String>[
      'maintenir une session ;',
      'sécuriser l’accès ;',
      'mémoriser certains choix techniques ;',
      'prévenir les abus ;',
      'assurer le bon fonctionnement de l’application.',
    ],
    afterBullets: <String>[
      'Lorsque des cookies ou traceurs non strictement nécessaires sont utilisés, notamment à des fins de mesure d’audience, d’analyse ou d’amélioration du service, l’utilisateur doit être informé et son consentement peut être demandé selon la réglementation applicable.',
      'Les traceurs strictement nécessaires au fonctionnement du service peuvent, dans certains cas, être exemptés de consentement, mais l’utilisateur doit rester informé de leur existence.',
    ],
  ),
  _LegalSectionData(
    title: '21. Disponibilité du service',
    paragraphs: <String>[
      'L’éditeur s’efforce d’assurer l’accessibilité et le bon fonctionnement de Citoyen Peyi.',
      'Toutefois, l’accès à la plateforme peut être interrompu ou limité notamment en cas :',
    ],
    bullets: <String>[
      'de maintenance ;',
      'de mise à jour ;',
      'd’incident technique ;',
      'de panne réseau ;',
      'de problème d’hébergement ;',
      'de force majeure ;',
      'de tentative d’attaque ou d’abus ;',
      'de décision de suspension prise par l’organisateur.',
    ],
    afterBullets: <String>[
      'L’éditeur ne peut garantir une disponibilité permanente et continue du service.',
    ],
  ),
  _LegalSectionData(
    title: '22. Responsabilité de l’éditeur',
    paragraphs: <String>[
      'L’éditeur met en œuvre les moyens raisonnables pour assurer le bon fonctionnement, la sécurité et la fiabilité de la plateforme.',
      'L’éditeur ne peut être tenu responsable :',
    ],
    bullets: <String>[
      'd’une mauvaise utilisation de la plateforme par l’utilisateur ;',
      'd’une participation frauduleuse ou réalisée avec un code obtenu irrégulièrement ;',
      'd’une interruption temporaire du service ;',
      'd’une erreur provenant d’informations fournies par l’organisateur ;',
      'd’un dommage résultant d’un événement extérieur ;',
      'd’une impossibilité d’accès liée au matériel, au navigateur ou à la connexion internet de l’utilisateur.',
    ],
  ),
  _LegalSectionData(
    title: '23. Responsabilité de la collectivité ou de l’organisateur',
    paragraphs: <String>[
      'La collectivité ou l’organisateur de la consultation est responsable du contenu des questions, des modalités de participation, de la communication autour de la consultation et de l’usage fait des résultats.',
      'Il lui appartient notamment de définir :',
    ],
    bullets: <String>[
      'le public concerné ;',
      'la durée de la consultation ;',
      'les règles de participation ;',
      'les modalités de publication des résultats ;',
      'les finalités du traitement ;',
      'les durées de conservation ;',
      'les contacts utiles pour les citoyens.',
    ],
  ),
  _LegalSectionData(
    title: '24. Propriété intellectuelle',
    paragraphs: <String>[
      'Les éléments composant Citoyen Peyi, notamment les textes, interfaces, logos, graphismes, icônes, bases de données, développements, documents, visuels et éléments de marque, sont protégés lorsqu’ils sont originaux ou appartiennent à leurs titulaires respectifs.',
      'Toute reproduction, modification, diffusion, extraction, réutilisation ou exploitation non autorisée est interdite, sauf autorisation écrite préalable.',
      'L’utilisateur ne dispose d’aucun droit de propriété sur la plateforme du seul fait de son utilisation.',
    ],
  ),
  _LegalSectionData(
    title: '25. Accessibilité et égalité d’accès',
    paragraphs: <String>[
      'Citoyen Peyi a vocation à faciliter la participation du plus grand nombre.',
      'L’éditeur et l’organisateur peuvent mettre en place des moyens complémentaires pour accompagner les personnes rencontrant des difficultés d’accès numérique, notamment par l’aide d’agents habilités, de permanences physiques, de supports papier ou de dispositifs d’assistance.',
      'L’objectif est de permettre une participation équitable, sans exclure les personnes éloignées du numérique.',
    ],
  ),
  _LegalSectionData(
    title: '26. Modification des CGU',
    paragraphs: <String>[
      'Les présentes conditions générales d’utilisation peuvent être modifiées afin de tenir compte :',
    ],
    bullets: <String>[
      'de l’évolution de la plateforme ;',
      'de l’ajout de nouvelles fonctionnalités ;',
      'des demandes d’une collectivité ;',
      'des évolutions réglementaires ;',
      'des exigences de sécurité ;',
      'des retours utilisateurs.',
    ],
    afterBullets: <String>[
      'La version applicable est celle disponible dans l’application au moment de l’utilisation.',
      'En cas de modification importante, une nouvelle validation des CGU peut être demandée à l’utilisateur avant participation.',
    ],
  ),
  _LegalSectionData(
    title: '27. Contact',
    paragraphs: <String>[
      'Pour toute question relative à Citoyen Peyi, à une consultation, à l’exercice des droits ou à la protection des données, l’utilisateur peut contacter :',
      'Nom de l’organisme : [à compléter]',
      'Adresse : [à compléter]',
      'Email général : [à compléter]',
      'Email données personnelles : [à compléter]',
      'Téléphone : [à compléter]',
      'DPO / référent données : [à compléter]',
    ],
  ),
];

const _legalNoticeBlocks = <_LegalNoticeData>[
  _LegalNoticeData(
    title: 'Éditeur de la plateforme',
    lines: <String>[
      'Nom officiel : [Nom de la collectivité / structure / entreprise]',
      'Adresse : [Adresse complète]',
      'SIRET / RNA / identifiant administratif : [à compléter]',
      'Email : [à compléter]',
      'Téléphone : [à compléter]',
    ],
  ),
  _LegalNoticeData(
    title: 'Directeur de la publication',
    lines: <String>[
      'Nom : [à compléter]',
      'Fonction : [Maire / Président / Responsable légal / Directeur de publication]',
      'Contact : [à compléter]',
    ],
  ),
  _LegalNoticeData(
    title: 'Responsable du traitement des données',
    lines: <String>[
      'Organisme responsable : [à compléter]',
      'Adresse : [à compléter]',
      'Email : [à compléter]',
      'DPO ou référent données personnelles : [à compléter]',
    ],
  ),
  _LegalNoticeData(
    title: 'Hébergement',
    lines: <String>[
      'Hébergeur : [à compléter]',
      'Adresse : [à compléter]',
      'Pays d’hébergement : [à compléter]',
      'Contact hébergeur : [à compléter]',
    ],
  ),
  _LegalNoticeData(
    title: 'Développement et maintenance',
    lines: <String>[
      'Prestataire / service interne : [à compléter]',
      'Contact technique : [à compléter]',
      'Support : [à compléter]',
    ],
  ),
  _LegalNoticeData(
    title: 'Version du document',
    lines: <String>[
      'Version : 1.0',
      'Dernière mise à jour : [date à compléter]',
      'Application : Citoyen Peyi',
      'Objet : CGU, confidentialité, anonymat, données personnelles et mentions légales',
    ],
  ),
];
