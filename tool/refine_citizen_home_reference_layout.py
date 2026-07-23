from pathlib import Path

path = Path('flutter_app/lib/pages/citizen/citizen_home_page.dart')
text = path.read_text(encoding='utf-8')

replacements = {
    "final height = compact ? (narrow ? 154.0 : 166.0) : 190.0;":
        "final height = compact ? (narrow ? 178.0 : 190.0) : 270.0;",
    "maxWidth: compact ? (narrow ? 190 : 248) : 360,":
        "maxWidth: compact ? (narrow ? 200 : 258) : 410,",
    """          child: Row(
            children: [
              const Spacer(),
              const Text(
                'Je participe',
                style: TextStyle(
                  color: CitizenDesignTokens.deepBlue,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const Spacer(),
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: CitizenDesignTokens.primaryBlue,
                  size: 28,
                ),
              ),
            ],
          ),""":
        """          child: Row(
            children: [
              const SizedBox(width: 42),
              const Expanded(
                child: Text(
                  'Je participe',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CitizenDesignTokens.deepBlue,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: CitizenDesignTokens.primaryBlue,
                  size: 28,
                ),
              ),
            ],
          ),""",
}

for old, new in replacements.items():
    if old in text:
        text = text.replace(old, new, 1)
    elif new not in text:
        raise SystemExit(f'motif introuvable: {old[:80]!r}')

path.write_text(text, encoding='utf-8')
