#!/bin/bash
set -e

# 📌 Questo script serve per aggiornare un tag git e rilanciare la build automatica su GitHub
# 📥 Aggiorna la tua copia locale del branch main
# 🧽 Cancella eventuale tag remoto esistente
# 🏷️ Crea e pusha il nuovo tag

# 🛑 Controllo versione passata
if [ -z "$1" ]; then
  echo "❌ Errore: devi specificare la versione. Esempio:"
  echo "./scripts/retag.sh 3.1.5"
  exit 1
fi

VERSION="$1"
TAG="v$VERSION"

# 📥 Aggiorna il branch main locale
echo "📥 Aggiorno branch locale..."
git pull origin main

# 🔄 Sincronizza anche i tag remoti
echo "🔄 Aggiorno lista tag..."
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

echo "🚀 Pusho nuovo tag su origin"
git push origin "$TAG"

echo "✅ Fatto! È stato creato e pushato il tag $TAG."
echo "ℹ️ La build GitHub Actions partirà automaticamente."