import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Palette commune aux widgets analytiques premium.
class AnalyticsPalette {
  static const Color primary = Color(0xFF0D73F2);
  static const Color secondary = Color(0xFF20B69C);
  static const Color accent = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color slate = Color(0xFF334155);
  static const Color slateMuted = Color(0xFF64748B);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE5E7EB);

  static const List<Color> funnel = <Color>[
    Color(0xFF0EA5E9),
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFF22C55E),
  ];
}

/// Carte KPI premium : grand chiffre, libellé, micro-tendance (sparkline) et
/// variation vs période précédente.
class AnalyticsKpiCard extends StatelessWidget {
  const AnalyticsKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.subtitle,
    this.sparkline = const <double>[],
    this.delta,
    this.accentColor = AnalyticsPalette.primary,
    this.width = 240,
  });

  /// Libellé court ("Votes émis").
  final String label;

  /// Valeur principale formatée ("1 248").
  final String value;

  /// Icône représentant la métrique.
  final IconData icon;

  /// Sous-titre contextuel ("sur 4 200 inscrits").
  final String? subtitle;

  /// Série brute pour la sparkline (ex. 7 derniers jours).
  final List<double> sparkline;

  /// Variation en % vs période précédente. Positive → vert, négative → rouge.
  final double? delta;

  /// Couleur d'accent (sparkline, icône, badge delta).
  final Color accentColor;

  /// Largeur minimale (responsive : la card peut s'étendre).
  final double width;

  @override
  Widget build(BuildContext context) {
    final hasDelta = delta != null && delta!.isFinite && delta!.abs() > 0.01;
    final positive = (delta ?? 0) >= 0;
    final deltaColor = positive
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);

    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: AnalyticsPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AnalyticsPalette.border),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const Spacer(),
              if (hasDelta)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: deltaColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        positive
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: deltaColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${positive ? '+' : ''}${delta!.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: deltaColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: AnalyticsPalette.slateMuted,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AnalyticsPalette.slate,
              height: 1.1,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                color: AnalyticsPalette.slateMuted,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (sparkline.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: _Sparkline(values: sparkline, color: accentColor),
            ),
          ],
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    final spots = <FlSpot>[
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];
    final maxValue = values.reduce(math.max);
    final minValue = values.reduce(math.min);
    final span = (maxValue - minValue).abs();
    final padding = span < 0.01 ? 1.0 : span * 0.15;

    return LineChart(
      LineChartData(
        minY: minValue - padding,
        maxY: maxValue + padding,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: color,
            barWidth: 2.4,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.28),
                  color.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 350),
    );
  }
}

/// Jauge radiale de participation (0-100%). Affichage style "donut" avec valeur
/// au centre et contexte secondaire.
class ParticipationGauge extends StatelessWidget {
  const ParticipationGauge({
    super.key,
    required this.percentage,
    this.label = 'Participation',
    this.subtitle,
    this.size = 200,
    this.thickness = 16,
    this.trackColor = const Color(0xFFE2E8F0),
  });

  final double percentage;
  final String label;
  final String? subtitle;
  final double size;
  final double thickness;
  final Color trackColor;

  Color get _color {
    if (percentage >= 66) return const Color(0xFF16A34A);
    if (percentage >= 33) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final clamped = percentage.clamp(0.0, 100.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: clamped / 100),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return CustomPaint(
                  painter: _GaugePainter(
                    progress: value,
                    color: _color,
                    trackColor: trackColor,
                    thickness: thickness,
                  ),
                );
              },
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${clamped.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w800,
                  color: AnalyticsPalette.slate,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AnalyticsPalette.slateMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AnalyticsPalette.slateMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.thickness,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = math.min(size.width, size.height) / 2 - thickness / 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [color.withValues(alpha: 0.7), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.thickness != thickness;
}

/// Étape d'un funnel d'engagement.
class FunnelStep {
  const FunnelStep({required this.label, required this.value, this.hint});

  final String label;
  final int value;
  final String? hint;
}

/// Funnel d'engagement horizontal animé. Largeur de chaque barre proportionnelle
/// à la première étape ; un pourcentage de conversion est affiché.
class EngagementFunnel extends StatelessWidget {
  const EngagementFunnel({
    super.key,
    required this.steps,
    this.colors = AnalyticsPalette.funnel,
  });

  final List<FunnelStep> steps;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return const Text('Aucune donnée d\'engagement pour le moment.');
    }
    final maxValue = steps.first.value <= 0 ? 1 : steps.first.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          _funnelRow(context, steps[i], maxValue, colors[i % colors.length], i),
          if (i < steps.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _funnelRow(
    BuildContext context,
    FunnelStep step,
    int maxValue,
    Color color,
    int index,
  ) {
    final ratio = (step.value / maxValue).clamp(0.0, 1.0);
    final conversionFromTop =
        steps.first.value == 0 ? 0.0 : (step.value / steps.first.value) * 100;
    final conversionFromPrev = index == 0
        ? null
        : (steps[index - 1].value == 0
            ? 0.0
            : (step.value / steps[index - 1].value) * 100);

    return LayoutBuilder(
      builder: (context, constraints) {
        final fullWidth = constraints.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    step.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AnalyticsPalette.slate,
                    ),
                  ),
                ),
                Text(
                  '${step.value}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AnalyticsPalette.slate,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${conversionFromTop.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Container(
                    height: 14,
                    color: const Color(0xFFF1F5F9),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: ratio),
                    duration: Duration(milliseconds: 500 + index * 80),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return Container(
                        height: 14,
                        width: fullWidth * value,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color.withValues(alpha: 0.85), color],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            if (step.hint != null || conversionFromPrev != null) ...[
              const SizedBox(height: 4),
              Text(
                [
                  if (conversionFromPrev != null)
                    '${conversionFromPrev.toStringAsFixed(0)}% depuis l\'étape précédente',
                  if (step.hint != null) step.hint,
                ].whereType<String>().join(' · '),
                style: const TextStyle(
                  fontSize: 11,
                  color: AnalyticsPalette.slateMuted,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
