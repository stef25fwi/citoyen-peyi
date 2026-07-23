from pathlib import Path

path = Path('flutter_app/lib/pages/citizen/citizen_home_page.dart')
text = path.read_text(encoding='utf-8')
replacements = {
    "final height = compact ? (narrow ? 132.0 : 148.0) : 190.0;":
        "final height = compact ? (narrow ? 154.0 : 166.0) : 190.0;",
    "maxWidth: compact ? (narrow ? 190 : 220) : 360,":
        "maxWidth: compact ? (narrow ? 190 : 248) : 360,",
    "fontSize: compact ? (narrow ? 27 : 31) : 42,":
        "fontSize: compact ? (narrow ? 26 : 30) : 42,",
    "fontSize: compact ? (narrow ? 14.5 : 16.5) : 21,":
        "fontSize: compact ? (narrow ? 13.5 : 15) : 21,",
    "height: compact ? 148 : 210,":
        "height: compact ? 158 : 210,",
    "compact ? 18 : 26,":
        "compact ? 15 : 26,",
    "compact ? 16 : 24,":
        "compact ? 14 : 24,",
    "vertical: compact ? 6 : 8,":
        "vertical: compact ? 5 : 8,",
    "SizedBox(height: compact ? 10 : 15),":
        "SizedBox(height: compact ? 8 : 15),",
    "fontSize: compact ? 24 : 34,":
        "fontSize: compact ? 23 : 34,",
    "height: 76,":
        "height: 84,",
    "width: 54,\n                    height: 54,":
        "width: 56,\n                    height: 56,",
    "width: 62,\n                    height: 58,":
        "width: 64,\n                    height: 64,",
}
for old, new in replacements.items():
    if old not in text:
        raise SystemExit(f'motif introuvable: {old!r}')
    text = text.replace(old, new, 1)
path.write_text(text, encoding='utf-8')
