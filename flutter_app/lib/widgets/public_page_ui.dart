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
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SafeArea(
              bottom: false,
              child: ColoredBox(
                color: CitizenDesignTokens.background,
                child: Column(
                  children: [
                    CitizenHeader(
                      title: title,
                      showBack: false,
                      trailing: const DebugLogButton(label: ''),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: CitizenDesignTokens.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: CitizenDesignTokens.skyBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: CitizenDesignTokens.primaryBlue,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
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
  }
}

class PublicLoadingState extends StatelessWidget {
  const PublicLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: CitizenDesignTokens.cardDecoration,
      child: Column(
        children: [
          Icon(icon, size: 42, color: CitizenDesignTokens.textMuted),
          const SizedBox(height: 12),
          Text(
            title,
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
  }
}
