from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def replace_once(path: Path, old: str, new: str) -> bool:
    text = path.read_text(encoding="utf-8")
    if old not in text:
        return False
    path.write_text(text.replace(old, new, 1), encoding="utf-8")
    return True


def replace_all(path: Path, old: str, new: str) -> int:
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count:
        path.write_text(text.replace(old, new), encoding="utf-8")
    return count


def main() -> None:
    widths = {
        "flutter_app/lib/pages/home_page.dart": 1100,
        "flutter_app/lib/pages/access_citizen_page.dart": 560,
        "flutter_app/lib/pages/legal_page.dart": 860,
        "flutter_app/lib/pages/citizen/citizen_home_page.dart": 760,
        "flutter_app/lib/pages/citizen/citizen_consultations_page.dart": 760,
        "flutter_app/lib/pages/citizen/citizen_poll_question_page.dart": 760,
        "flutter_app/lib/pages/citizen/citizen_profile_page.dart": 760,
    }

    changed: list[str] = []
    for relative, target_width in widths.items():
        path = ROOT / relative
        count = replace_all(path, "maxWidth: 430", f"maxWidth: {target_width}")
        if count:
            changed.append(f"{relative}: largeur {target_width} ({count})")

    citizen_home = ROOT / "flutter_app/lib/pages/citizen/citizen_home_page.dart"
    if replace_once(
        citizen_home,
        """        child: Ink(
          height: 226,
""",
        """        child: Ink(
          constraints: const BoxConstraints(minHeight: 226),
""",
    ):
        changed.append("citizen_home_page.dart: hero participation à hauteur flexible")

    if replace_once(
        citizen_home,
        """                  const Spacer(),
                  const Row(
""",
        """                  const SizedBox(height: 24),
                  const Row(
""",
    ):
        changed.append("citizen_home_page.dart: contenu du hero sans Spacer contraint")

    if replace_once(
        citizen_home,
        """    return SizedBox(
      height: 184,
      child: Stack(
""",
        """    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final illustrationWidth = compact ? 136.0 : 182.0;
        final textWidth = compact
            ? (constraints.maxWidth * 0.68).clamp(170.0, 210.0).toDouble()
            : (constraints.maxWidth * 0.62).clamp(210.0, 330.0).toDouble();
        return SizedBox(
          height: compact ? 196 : 184,
          child: Stack(
""",
    ):
        changed.append("citizen_home_page.dart: hero de bienvenue adaptatif")

    if replace_once(
        citizen_home,
        """                SizedBox(
                  width: 245,
                  child: Text(
""",
        """                SizedBox(
                  width: textWidth,
                  child: Text(
""",
    ):
        changed.append("citizen_home_page.dart: largeur de texte adaptative")

    if replace_once(
        citizen_home,
        """                width: 182,
                height: 150,
""",
        """                width: illustrationWidth,
                height: compact ? 126 : 150,
""",
    ):
        changed.append("citizen_home_page.dart: illustration adaptative")

    if replace_once(
        citizen_home,
        """        ],
      ),
    );
  }
}

class _ParticipationHero""",
        """            ],
          ),
        );
      },
    );
  }
}

class _ParticipationHero""",
    ):
        changed.append("citizen_home_page.dart: fermeture du LayoutBuilder")

    # Le Positioned de gauche ne peut plus rester const car sa largeur dépend
    # désormais de la contrainte calculée par le LayoutBuilder.
    if replace_once(
        citizen_home,
        """          const Positioned(
            left: 10,
            top: 20,
""",
        """          Positioned(
            left: 10,
            top: 20,
""",
    ):
        changed.append("citizen_home_page.dart: retire le const devenu invalide")

    print("Corrections responsive appliquées :")
    for item in changed:
        print(f"- {item}")
    if not changed:
        print("- aucune modification nécessaire")


if __name__ == "__main__":
    main()
