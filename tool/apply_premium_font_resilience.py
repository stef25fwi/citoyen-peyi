from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def update(path: str, transform) -> None:
    file_path = ROOT / path
    text = file_path.read_text(encoding="utf-8")
    next_text = transform(text)
    if next_text != text:
        file_path.write_text(next_text, encoding="utf-8")
        print(f"updated {path}")


def remove_google_fonts(text: str) -> str:
    text = text.replace("import 'package:google_fonts/google_fonts.dart';\n", "")
    return text.replace("GoogleFonts.inter(", "TextStyle(")


def update_app_theme(text: str) -> str:
    text = text.replace(
        "import 'package:flutter/material.dart';\n",
        "import 'package:flutter/foundation.dart';\nimport 'package:flutter/material.dart';\n",
        1,
    )
    text = text.replace("import 'package:google_fonts/google_fonts.dart';\n", "")
    return text.replace(
        "final base = GoogleFonts.interTextTheme();",
        "final base = Typography.material2021(\n"
        "      platform: defaultTargetPlatform,\n"
        "    ).black;",
    )


def update_main(text: str) -> str:
    text = text.replace("import 'package:google_fonts/google_fonts.dart';\n", "")
    start = text.find("    // google_fonts recupere ses polices")
    end_marker = "    GoogleFonts.config.allowRuntimeFetching = false;\n"
    if start >= 0:
        end = text.find(end_marker, start)
        if end >= 0:
            end += len(end_marker)
            text = (
                text[:start]
                + "    // La typographie utilise la pile native de la plateforme : aucun\n"
                + "    // téléchargement de police ne peut bloquer l'affichage.\n"
                + text[end:]
            )
    return text


def update_test(text: str) -> str:
    text = text.replace("import 'package:google_fonts/google_fonts.dart';\n", "")
    block = """  setUpAll(() {
    // Reproduit le comportement de production défini dans main.dart : aucune
    // police distante ne doit bloquer l'affichage ou les tests hors réseau.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

"""
    return text.replace(block, "")


def update_pubspec(text: str) -> str:
    return text.replace("  google_fonts: ^6.2.1\n", "")


def update_audit(text: str) -> str:
    text = text.replace(
        "**Inter** devient la typographie unique de l’interface. Elle correspond au positionnement institutionnel souhaité et assure une meilleure cohérence entre les écrans publics et les espaces professionnels. Les titres utilisent des graisses 800–900 et les textes courants 400–600.",
        "Une **pile sans-serif native** devient la typographie unique de l’interface. Elle utilise les polices système optimisées de chaque plateforme, sans téléchargement distant susceptible de bloquer le texte. Les titres utilisent des graisses 800–900 et les textes courants 400–600.",
    )
    return text.replace(
        "- Inter comme typographie globale ;",
        "- pile typographique native, cohérente et disponible hors ligne ;",
    )


def main() -> None:
    update("flutter_app/lib/theme/app_theme.dart", update_app_theme)
    update("flutter_app/lib/main.dart", update_main)
    update("flutter_app/lib/pages/home_page.dart", remove_google_fonts)
    update("flutter_app/lib/pages/access_citizen_page.dart", remove_google_fonts)
    update("flutter_app/lib/widgets/primary_participate_button.dart", remove_google_fonts)
    update("flutter_app/test/premium_theme_test.dart", update_test)
    update("flutter_app/pubspec.yaml", update_pubspec)
    update("docs/design/audit-harmonisation-premium-2026-07.md", update_audit)


if __name__ == "__main__":
    main()
