#!/bin/bash
ROOT="/workspaces/citoyen-peyi"
OUT="$ROOT/audit2.txt"; echo "" > "$OUT"
S() { echo -e "\n\n=== $1 ===" >> "$OUT"; }
S "FIND FLUTTER ROOT"
FL=$(find "$ROOT" -name "pubspec.yaml" -not -path "*/build/*" 2>/dev/null | head -1 | xargs dirname 2>/dev/null)
echo "Flutter root: $FL" | tee -a "$OUT"
S "PUBSPEC.YAML"; cat "$FL/pubspec.yaml" >> "$OUT" 2>/dev/null || echo INTROUVABLE >> "$OUT"
S "MAIN.DART"; cat "$FL/lib/main.dart" >> "$OUT" 2>/dev/null || echo INTROUVABLE >> "$OUT"
S "HOME PAGE"; find "$FL/lib" -name "home_page.dart" | xargs cat >> "$OUT" 2>/dev/null || echo INTROUVABLE >> "$OUT"
S "VOTE PAGE"; find "$FL/lib" -name "vote_page.dart" | xargs cat >> "$OUT" 2>/dev/null || echo INTROUVABLE >> "$OUT"
S "CITIZEN DASHBOARD"; find "$FL/lib" -name "citizen_dashboard_page.dart" | xargs cat >> "$OUT" 2>/dev/null || echo INTROUVABLE >> "$OUT"
S "BUILD GRADLE"; cat "$FL/android/app/build.gradle" >> "$OUT" 2>/dev/null || echo INTROUVABLE >> "$OUT"
S "ANDROIDMANIFEST"; cat "$FL/android/app/src/main/AndroidManifest.xml" >> "$OUT" 2>/dev/null || echo INTROUVABLE >> "$OUT"
S "GOOGLE-SERVICES"; python3 -c "import json; d=json.load(open('$FL/android/app/google-services.json')); print('project_id:', d['project_info']['project_id']); [print('pkg:', c['client_info']['android_client_info']['package_name']) for c in d.get('client',[])]" 2>/dev/null >> "$OUT" || echo INTROUVABLE >> "$OUT"
S "STRUCTURE LIB"; find "$FL/lib" -name "*.dart" | sort >> "$OUT"
S "FIREBASERC"; cat "$ROOT/.firebaserc" >> "$OUT" 2>/dev/null || echo INTROUVABLE >> "$OUT"
S "PACKAGE.JSON"; cat "$ROOT/package.json" >> "$OUT"
echo "=== DONE ===" && wc -l "$OUT" && cat "$OUT"
