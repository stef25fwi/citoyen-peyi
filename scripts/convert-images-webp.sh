#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if command -v cwebp >/dev/null 2>&1; then
  converter="cwebp"
elif command -v ffmpeg >/dev/null 2>&1; then
  converter="ffmpeg"
elif command -v magick >/dev/null 2>&1; then
  converter="magick"
elif command -v convert >/dev/null 2>&1; then
  converter="convert"
else
  echo "Aucun convertisseur WebP trouve (cwebp, ffmpeg, magick, convert)." >&2
  exit 1
fi

find_cmd=(
  find "$repo_root"
  -type f
  \(
    -iname '*.png' -o
    -iname '*.jpg' -o
    -iname '*.jpeg' -o
    -iname '*.gif' -o
    -iname '*.bmp' -o
    -iname '*.tif' -o
    -iname '*.tiff' -o
    -iname '*.avif' -o
    -iname '*.heic'
  \)
  ! -path '*/.git/*'
  ! -path '*/node_modules/*'
  ! -path '*/build/*'
  ! -path '*/dist/*'
  ! -path '*/.dart_tool/*'
  ! -path '*/coverage/*'
  ! -path '*/web/icons/*'
  ! -iname 'favicon.*'
)

mapfile -t images < <("${find_cmd[@]}" | sed "s#^$repo_root/##" | LC_ALL=C sort)

if [[ ${#images[@]} -eq 0 ]]; then
  echo "Aucune image convertible trouvee dans le depot."
  exit 0
fi

convert_image() {
  local source_path="$1"
  local target_path="${source_path%.*}.webp"

  if [[ ! -f "$source_path" ]]; then
    if [[ -f "$target_path" ]]; then
      echo "Deja converti: $target_path"
      return
    fi

    echo "Image introuvable: $source_path" >&2
    exit 1
  fi

  echo "Conversion: $source_path -> $target_path"

  case "$converter" in
    cwebp)
      cwebp -quiet -q 85 "$source_path" -o "$target_path"
      ;;
    ffmpeg)
      ffmpeg -loglevel error -y -i "$source_path" -c:v libwebp -quality 85 -compression_level 6 "$target_path"
      ;;
    magick)
      magick "$source_path" -quality 85 "$target_path"
      ;;
    convert)
      convert "$source_path" -quality 85 "$target_path"
      ;;
  esac

  rm "$source_path"
}

echo "Convertisseur WebP: $converter"

for image_path in "${images[@]}"; do
  convert_image "$image_path"
done

echo "Conversion terminee."