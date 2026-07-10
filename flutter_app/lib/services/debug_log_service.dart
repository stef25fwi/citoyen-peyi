import 'package:flutter/foundation.dart';

/// Une entree de journal de diagnostic capturee en memoire.
class DebugLogEntry {
  DebugLogEntry(this.tag, this.message) : time = DateTime.now();

  final DateTime time;
  final String tag;
  final String message;

  String get timeLabel {
    String two(int n) => n.toString().padLeft(2, '0');
    String three(int n) => n.toString().padLeft(3, '0');
    return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}'
        '.${three(time.millisecond)}';
  }

  @override
  String toString() => '[$timeLabel] $tag $message';
}

/// Journal de diagnostic en memoire, alimente par le flux d'authentification.
///
/// Contrairement aux `debugPrint` existants (actifs uniquement en `kDebugMode`),
/// ce service capture les logs meme en build release, afin qu'ils puissent etre
/// affiches dans l'application via le bouton debug et copies pour analyse.
class DebugLogService {
  DebugLogService._();

  static final DebugLogService instance = DebugLogService._();

  static const int _maxEntries = 500;

  /// Liste observable des entrees, la plus recente en fin de liste.
  final ValueNotifier<List<DebugLogEntry>> entries =
      ValueNotifier<List<DebugLogEntry>>(const []);

  /// Ajoute une ligne de log. Toujours active (y compris en release).
  void log(String tag, String message) {
    final entry = DebugLogEntry(tag, message);
    final next = List<DebugLogEntry>.from(entries.value)..add(entry);
    if (next.length > _maxEntries) {
      next.removeRange(0, next.length - _maxEntries);
    }
    entries.value = next;
    // Reste visible dans la console de dev quand elle est disponible.
    if (kDebugMode) {
      debugPrint(entry.toString());
    }
  }

  void clear() {
    entries.value = const [];
  }

  /// Rend l'integralite du journal sous forme de texte copiable.
  String exportAsText() {
    final buffer = StringBuffer()
      ..writeln('Citoyen Peyi — journal de diagnostic')
      ..writeln('Genere le ${DateTime.now().toIso8601String()}')
      ..writeln('---');
    for (final entry in entries.value) {
      buffer.writeln(entry.toString());
    }
    return buffer.toString();
  }
}
