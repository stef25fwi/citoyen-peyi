import 'package:flutter/material.dart';

import '../../services/citizen_public_access_service.dart';
import '../../theme/citizen_design_tokens.dart';
import '../../widgets/citizen/citizen_primary_button.dart';

class CitizenWelcomePage extends StatelessWidget {
  const CitizenWelcomePage({
    super.key,
    this.initialSession,
  });

  final CitizenPublicAccessSession? initialSession;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: CitizenDesignTokens.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: CitizenDesignTokens.primaryGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: media.size.height -
                    media.padding.top -
                    media.padding.bottom -
                    52,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        await CitizenPublicAccessService.instance.clearSession();
                        if (!context.mounted) {
                          return;
                        }
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/access',
                          (route) => false,
                        );
                      },
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Se deconnecter',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _CitizenFlowerLogo(size: 112),
                  const SizedBox(height: 12),
                  const _AppTitle(),
                  const SizedBox(height: 22),
                  const _WelcomeSlogan(),
                  const SizedBox(height: 34),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(34),
                    ),
                    child: const Column(
                      children: [
                        _ReassuranceRow(
                          icon: Icons.verified_user_rounded,
                          title: 'Anonyme et securise',
                          subtitle: 'Vos avis sont proteges\net 100% confidentiels',
                        ),
                        SizedBox(height: 20),
                        _ReassuranceRow(
                          icon: Icons.groups_rounded,
                          title: 'Simple et accessible',
                          subtitle: 'Participez en quelques clics,\nou que vous soyez',
                        ),
                        SizedBox(height: 20),
                        _ReassuranceRow(
                          icon: Icons.bar_chart_rounded,
                          title: 'Utile et impactant',
                          subtitle:
                              'Vos reponses aident a construire\nles decisions de demain',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _ProgressDots(),
                  const SizedBox(height: 26),
                  CitizenPrimaryButton(
                    label: 'Je participe',
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed(
                        '/citizen/home',
                        arguments: {'session': initialSession},
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Deja un compte ? ',
                        style: TextStyle(
                          color: CitizenDesignTokens.textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/access');
                        },
                        child: const Text(
                          'Se connecter',
                          style: TextStyle(
                            color: CitizenDesignTokens.deepBlue,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CitizenFlowerLogo extends StatelessWidget {
  const _CitizenFlowerLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int i = 0; i < 8; i++)
            Transform.rotate(
              angle: i * 0.785,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: size * 0.34,
                  height: size * 0.52,
                  decoration: BoxDecoration(
                    color: i == 1 || i == 2
                        ? CitizenDesignTokens.yellow.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.48),
                    borderRadius: BorderRadius.circular(size),
                  ),
                ),
              ),
            ),
          Container(
            width: size * 0.18,
            height: size * 0.18,
            decoration: const BoxDecoration(
              color: CitizenDesignTokens.yellow,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppTitle extends StatelessWidget {
  const _AppTitle();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: -0.8,
        ),
        children: [
          TextSpan(
            text: 'Citoyen ',
            style: TextStyle(color: Colors.white),
          ),
          TextSpan(
            text: 'Peyi',
            style: TextStyle(color: CitizenDesignTokens.yellow),
          ),
        ],
      ),
    );
  }
}

class _WelcomeSlogan extends StatelessWidget {
  const _WelcomeSlogan();

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: const TextSpan(
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          height: 1.25,
          fontWeight: FontWeight.w700,
        ),
        children: [
          TextSpan(text: 'Votre collectivite place\n'),
          TextSpan(
            text: 'votre parole\n',
            style: TextStyle(
              color: CitizenDesignTokens.yellow,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(text: 'au coeur de l\'action publique'),
        ],
      ),
    );
  }
}

class _ReassuranceRow extends StatelessWidget {
  const _ReassuranceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 58,
          width: 58,
          decoration: const BoxDecoration(
            color: CitizenDesignTokens.deepBlue,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: CitizenDesignTokens.deepBlue,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: CitizenDesignTokens.textDark,
                  fontSize: 13.5,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: index == 0 ? 11 : 9,
          height: index == 0 ? 11 : 9,
          decoration: BoxDecoration(
            color: index == 0
                ? CitizenDesignTokens.yellowStrong
                : CitizenDesignTokens.skyBlue,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
