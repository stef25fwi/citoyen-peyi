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
        backgroundColor: Colors.white,
        body: LayoutBuilder(
          builder: (context, viewport) {
            final viewportWidth = viewport.maxWidth;
            final outerMargin = viewportWidth >= 600 ? 16.0 : 0.0;
            final availableWidth = viewportWidth - (outerMargin * 2);
            final frameLimit = viewportWidth >= 1200
                ? 1120.0
                : viewportWidth >= 800
                    ? 900.0
                    : availableWidth;
            final frameWidth = availableWidth < frameLimit
                ? availableWidth
                : frameLimit;
            final wide = viewportWidth >= 600;
            final headerHeight = viewportWidth < 360
                ? 96.0
                : viewportWidth >= 800
                    ? 112.0
                    : 104.0;

            return ColoredBox(
              color: wide ? const Color(0xFFEAF5FB) : Colors.white,
              child: SafeArea(
                bottom: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: outerMargin),
                    child: SizedBox(
                      width: frameWidth,
                      height: viewport.maxHeight,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(wide ? 28 : 0),
                        child: ColoredBox(
                          color: CitizenDesignTokens.background,
                          child: Column(
                            children: [
                              CitizenHeader(
                                title: title,
                                showBack: false,
                                height: headerHeight,
                                trailing:
                                    const DebugLogButton(label: ''),
                              ),
                              Expanded(child: body),
                              navigationBar,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class PublicResponsiveList extends StatelessWidget {
  const PublicResponsiveList({
    required this.children,
    this.controller,
    this.topPadding = 18,
    this.bottomPadding = 26,
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
            ? 12.0
            : width < 600
                ? 16.0
                : width < 900
                    ? 24.0
                    : 32.0;
        final available = width - (sidePadding * 2);
        final contentLimit = width >= 1000
            ? 860.0
            : width >= 700
                ? 720.0
                : available;
        final contentWidth = available < contentLimit ? available : contentLimit;

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        final iconExtent = compact ? 42.0 : 46.0;
        final iconSize = compact ? 24.0 : 26.0;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 16 : 18),
          decoration: CitizenDesignTokens.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: iconExtent,
                    height: iconExtent,
                    decoration: const BoxDecoration(
                      color: CitizenDesignTokens.skyBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: CitizenDesignTokens.primaryBlue,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: compact ? 10 : 12),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CitizenDesignTokens.textDark,
                        fontSize: 20,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: const TextStyle(
                  color: CitizenDesignTokens.textMuted,
                  fontSize: 14,
                  height: 1.4,
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
      padding: const EdgeInsets.all(30),
      decoration: CitizenDesignTokens.cardDecoration,
      child: const Center(
        child: CircularProgressIndicator(
          color: CitizenDesignTokens.primaryBlue,
        ),
      ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 20 : 24),
          decoration: CitizenDesignTokens.cardDecoration,
          child: Column(
            children: [
              Icon(
                icon,
                size: compact ? 38 : 42,
                color: CitizenDesignTokens.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: CitizenDesignTokens.textDark,
                  fontSize: 18,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: CitizenDesignTokens.textMuted,
                  fontSize: 14,
                  height: 1.4,
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
