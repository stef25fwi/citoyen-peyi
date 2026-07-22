import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/citizen_design_tokens.dart';
import 'citizen/citizen_header.dart';
import 'debug_log_viewer.dart';

class PublicPageShell extends StatelessWidget {
  const PublicPageShell({
    required this.title,
    required this.body,
    required this.navigationBar,
    super.key,
  });

  final String title;
  final Widget body;
  final Widget navigationBar;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final headerHeight = width < 360
        ? 96.0
        : width >= 800
            ? 112.0
            : 104.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: CitizenDesignTokens.background,
        body: SafeArea(
          bottom: false,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: CitizenDesignTokens.softBackgroundGradient,
            ),
            child: Column(
              children: [
                CitizenHeader(
                  title: title,
                  showBack: false,
                  height: headerHeight,
                  trailing: kDebugMode
                      ? const DebugLogButton(label: '')
                      : null,
                ),
                Expanded(child: body),
                navigationBar,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PublicResponsiveList extends StatelessWidget {
  const PublicResponsiveList({
    required this.children,
    this.controller,
    this.topPadding = CitizenDesignTokens.space20,
    this.bottomPadding = CitizenDesignTokens.space32,
    super.key,
  });

  final List<Widget> children;
  final ScrollController? controller;
  final double topPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final sidePadding = width < 340
            ? CitizenDesignTokens.space12
            : width < 600
                ? CitizenDesignTokens.space16
                : width < 900
                    ? CitizenDesignTokens.space24
                    : CitizenDesignTokens.space32;
        final available = width - (sidePadding * 2);
        final contentLimit = width >= 1000
            ? 860.0
            : width >= 700
                ? 720.0
                : available;
        final contentWidth =
            available < contentLimit ? available : contentLimit;

        return ListView(
          controller: controller,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(
            sidePadding,
            topPadding,
            sidePadding,
            bottomPadding,
          ),
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: contentWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class PublicPageIntro extends StatelessWidget {
  const PublicPageIntro({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        final iconExtent = compact ? 42.0 : 48.0;
        final iconSize = compact ? 23.0 : 25.0;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(
            compact
                ? CitizenDesignTokens.space16
                : CitizenDesignTokens.space20,
          ),
          decoration: CitizenDesignTokens.elevatedCardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: iconExtent,
                    height: iconExtent,
                    decoration: BoxDecoration(
                      color: CitizenDesignTokens.surfaceBlue,
                      borderRadius: BorderRadius.circular(
                        CitizenDesignTokens.radiusSmall,
                      ),
                      border: Border.all(
                        color: CitizenDesignTokens.cardBorder,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: CitizenDesignTokens.primaryBlue,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(
                    width: compact
                        ? CitizenDesignTokens.space12
                        : CitizenDesignTokens.space16,
                  ),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: compact ? 18 : 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: CitizenDesignTokens.space12),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: CitizenDesignTokens.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PublicLoadingState extends StatelessWidget {
  const PublicLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(CitizenDesignTokens.space32),
      decoration: CitizenDesignTokens.cardDecoration,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class PublicEmptyState extends StatelessWidget {
  const PublicEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(
            compact
                ? CitizenDesignTokens.space20
                : CitizenDesignTokens.space24,
          ),
          decoration: CitizenDesignTokens.cardDecoration,
          child: Column(
            children: [
              Container(
                width: compact ? 58 : 64,
                height: compact ? 58 : 64,
                decoration: const BoxDecoration(
                  color: CitizenDesignTokens.surfaceBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: compact ? 30 : 34,
                  color: CitizenDesignTokens.primaryBlue,
                ),
              ),
              const SizedBox(height: CitizenDesignTokens.space16),
              Text(
                title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: compact ? 17 : 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: CitizenDesignTokens.space8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: CitizenDesignTokens.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}