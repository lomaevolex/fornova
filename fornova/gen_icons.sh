#!/bin/bash
set -e

SRC="icon-1024.png"
ICONSET="AppIcon.appiconset"

# Удаляем старый набор и создаём заново
rm -rf "$ICONSET"
mkdir "$ICONSET"

# Массив: размеры в pt и масштаб
specs=(
  "20 2" "20 3"
  "29 2" "29 3"
  "38 2" "38 3"      # Notification iOS 38pt
  "40 2" "40 3"
  "60 2" "60 3"
  "64 2" "64 3"      # название «64pt» 
  "68 2"             # специальный слот 68pt@2x
  "76 1" "76 2"
  "83.5 2"
  "1024 1"
)

for spec in "${specs[@]}"; do
  pt=${spec% *}
  scale=${spec#* }
  # вычисляем итоговый размер в px
  pixels=$(printf "%.0f" "$(echo "$pt * $scale" | bc)")
  # формируем имя файла
  name="icon_${pt}pt@${scale}x.png"
  # генерируем версию
  sips -Z $pixels "$SRC" --out "$ICONSET/$name" >/dev/null
  echo "Создан $name (${pixels}×${pixels})"
done

echo
echo "✅ Все иконки готовы в папке $ICONSET. Перетащите её в Assets.xcassets → AppIcon."