#!/bin/bash
# ============================================================================
# Script para ignorar _sources + limpiar del repo + publicar con ghp-import
# con verificación previa de cambios antes de commitear
# Además elimina _sources antes de publicar para que no aparezca en GitHub Pages
# Autor: Lihki
# ============================================================================

# Configura la ruta de build
BUILD_DIR="/mnt/c/Users/rubio/OneDrive - Universidad del Norte/Drive/Uninorte/lrubio_courses/courses_lastversion/deep_learning/jbook_dl/docs/_build/html"
REPO_URL="https://github.com/lihkir/DeepLearning.git"

echo "------------------------------------------------------------"
echo "Accediendo al directorio de build..."
cd "$BUILD_DIR" || { echo "❌ No se pudo acceder a $BUILD_DIR"; exit 1; }

echo "------------------------------------------------------------"
echo "Verificando remote 'origin'..."
CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null)

if [ -z "$CURRENT_REMOTE" ]; then
    echo "⚠️  No existe remote 'origin'. Agregándolo..."
    git remote add origin "$REPO_URL"
    echo "✅ Remote 'origin' agregado -> $REPO_URL"
elif [ "$CURRENT_REMOTE" != "$REPO_URL" ]; then
    echo "⚠️  Remote 'origin' apunta a un repo distinto: $CURRENT_REMOTE"
    echo "    Corrigiendo a: $REPO_URL"
    git remote set-url origin "$REPO_URL"
    echo "✅ Remote 'origin' actualizado."
else
    echo "✅ Remote 'origin' ya apunta correctamente a $REPO_URL"
fi

echo "------------------------------------------------------------"
echo "Añadiendo '_sources' a .gitignore si no existe..."
if grep -Fxq "_sources" .gitignore 2>/dev/null; then
    echo "✅ '_sources' ya estaba en .gitignore"
else
    echo "_sources" >> .gitignore
    echo "✅ '_sources' añadido a .gitignore"
fi

echo "------------------------------------------------------------"
echo "Eliminando '_sources' del repositorio remoto si ya existía..."
git rm -r --cached _sources 2>/dev/null

echo "------------------------------------------------------------"
echo "Verificando si hay cambios para commitear..."
git add .gitignore

if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "📝 Cambios detectados. Haciendo commit y push..."
    git commit -m "Remove _sources folder and add to .gitignore"
    git push -u origin main
    echo "✅ Cambios commiteados y enviados al repositorio."
else
    echo "✅ No hay cambios que commitear; el repositorio ya está limpio."
fi

echo "------------------------------------------------------------"
echo "Eliminando '_sources' de la carpeta de build antes de publicar..."
rm -rf "$BUILD_DIR/_sources"
echo "✅ Carpeta '_sources' eliminada de la build."

echo "------------------------------------------------------------"
echo "Publicando en GitHub Pages con ghp-import..."
# NOTA: -c es para CNAME (dominio personalizado), NO para indicar el repo.
# El repo destino lo toma del remote 'origin', ya verificado/corregido arriba.
ghp-import -n -p -r origin -f "$BUILD_DIR"

STATUS=$?
if [ $STATUS -eq 0 ]; then
    echo "✅ Publicación completada con éxito en GitHub Pages."
else
    echo "❌ Ocurrió un error durante la publicación con ghp-import."
    exit $STATUS
fi

echo "------------------------------------------------------------"
echo "🚀 Proceso completado: '_sources' ignorada, repo limpio y publicado sin _sources."
echo "------------------------------------------------------------"