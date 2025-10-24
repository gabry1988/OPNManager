#!/bin/bash
set -e

# 📌 Se passi una versione come argomento la usa, altrimenti default v3.1.2
if [ -n "$1" ]; then
  TAG="v$1"
else
  TAG="v3.1.2"
fi

echo "🏷️ Rilascio forzato del tag $TAG"

# 📥 Aggiorna il branch locale main
echo "📥 Eseguo git pull..."
git pull origin main

# 🔄 Aggiorno lista tag remoti
echo "🔄 Aggiorno i tag remoti..."
git fetch --tags

# 🧽 Rimuovo eventuale tag locale esistente
if git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "🧽 Rimuovo tag locale esistente $TAG"
  git tag -d "$TAG" || true
fi

# 🧼 Rimuovo eventuale tag remoto esistente
if git ls-remote --tags origin | grep -q "refs/tags/$TAG"; then
  echo "🧼 Rimuovo tag remoto esistente $TAG"
  git push origin ":refs/tags/$TAG" || true
fi

# 🏷️ Crea e pusha il nuovo tag
echo "🏷️ Creo nuovo tag $TAG"
git tag "$TAG"

echo "🚀 Pusho il nuovo tag su origin..."
git push origin "$TAG"

echo "✅ Fatto! La build GitHub Actions partirà automaticamente per $TAG."