#!/bin/bash
# ============================================================================
# Publica el libro en https://github.com/lihkir/SpatioTemporalAI
#   1) Sincroniza el codigo fuente del libro en la rama principal.
#   2) Elimina _sources de la build y publica el HTML en gh-pages (ghp-import).
# Proyecto: spatio-temporal/jbook_datachallenge
# Autor: Lihki
# ============================================================================

# Raiz del libro (carpeta que contiene _config.yml y _toc.yml)
BOOK_DIR="/mnt/c/Users/USER/OneDrive - Universidad del Norte/Drive/Uninorte/lrubio_courses/courses_lastversion/spatio-temporal/jbook_datachallenge"
BUILD_DIR="$BOOK_DIR/docs/_build/html"
REPO_URL="https://github.com/lihkir/SpatioTemporalAI.git"
SOURCE_BRANCH="main"

echo "------------------------------------------------------------"
echo "Verificando que exista la build..."
if [ ! -f "$BUILD_DIR/index.html" ]; then
    echo "[ERROR] No se encontro $BUILD_DIR/index.html"
    echo "        Genere la build primero con:"
    echo "        cd \"$BOOK_DIR/docs\" && jupyter-book build ."
    exit 1
fi
echo "[OK] Build encontrada en $BUILD_DIR"

echo "------------------------------------------------------------"
echo "Accediendo a la raiz del libro..."
cd "$BOOK_DIR" || { echo "[ERROR] No se pudo acceder a $BOOK_DIR"; exit 1; }

echo "------------------------------------------------------------"
echo "Verificando repositorio Git..."
if [ ! -d ".git" ]; then
    echo "[AVISO] $BOOK_DIR no es un repositorio Git. Inicializando..."
    git init -b "$SOURCE_BRANCH" || { echo "[ERROR] git init fallo."; exit 1; }
fi
echo "[OK] Repositorio Git disponible."

echo "------------------------------------------------------------"
echo "Verificando remote 'origin'..."
CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null)

if [ -z "$CURRENT_REMOTE" ]; then
    echo "[AVISO] No existe remote 'origin'. Agregandolo..."
    git remote add origin "$REPO_URL"
    echo "[OK] Remote 'origin' agregado -> $REPO_URL"
elif [ "$CURRENT_REMOTE" != "$REPO_URL" ]; then
    echo "[AVISO] Remote 'origin' apunta a un repo distinto: $CURRENT_REMOTE"
    echo "        Corrigiendo a: $REPO_URL"
    git remote set-url origin "$REPO_URL"
    echo "[OK] Remote 'origin' actualizado."
else
    echo "[OK] Remote 'origin' ya apunta correctamente a $REPO_URL"
fi

echo "------------------------------------------------------------"
echo "Asegurando entradas en .gitignore (la build no se versiona en la rama fuente)..."
touch .gitignore
for ENTRY in "docs/_build/" "docs/_sources" ".ipynb_checkpoints/" "__pycache__/"; do
    if grep -Fxq "$ENTRY" .gitignore; then
        echo "[OK] '$ENTRY' ya estaba en .gitignore"
    else
        echo "$ENTRY" >> .gitignore
        echo "[OK] '$ENTRY' anadido a .gitignore"
    fi
done

echo "------------------------------------------------------------"
echo "Eliminando del indice cualquier '_build' o '_sources' rastreado previamente..."
git rm -r --cached docs/_build docs/_sources 2>/dev/null

echo "------------------------------------------------------------"
echo "Sincronizando el codigo fuente en la rama '$SOURCE_BRANCH'..."
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ "$CURRENT_BRANCH" != "$SOURCE_BRANCH" ]; then
    echo "[AVISO] Rama actual: '$CURRENT_BRANCH'. Cambiando a '$SOURCE_BRANCH'..."
    git checkout -B "$SOURCE_BRANCH" || { echo "[ERROR] No se pudo cambiar a $SOURCE_BRANCH."; exit 1; }
fi

git add -A

if ! git diff --cached --quiet; then
    echo "[INFO] Cambios detectados. Haciendo commit y push..."
    git commit -m "Update Jupyter Book source (spatio-temporal data challenge)"
    if ! git push -u origin "$SOURCE_BRANCH"; then
        echo "[ERROR] El push a '$SOURCE_BRANCH' fallo."
        echo "        Si el repositorio remoto ya tiene commits (por ejemplo, un README),"
        echo "        ejecute: git pull --rebase origin $SOURCE_BRANCH   y vuelva a correr el script."
        exit 1
    fi
    echo "[OK] Codigo fuente enviado a $REPO_URL ($SOURCE_BRANCH)."
else
    echo "[OK] No hay cambios en el codigo fuente que commitear."
fi

echo "------------------------------------------------------------"
echo "Eliminando '_sources' de la build antes de publicar..."
rm -rf "$BUILD_DIR/_sources"
echo "[OK] Carpeta '_sources' eliminada de la build."

echo "------------------------------------------------------------"
echo "Publicando en GitHub Pages (rama gh-pages) con ghp-import..."
# -n: crea .nojekyll | -p: hace push | -r origin: remote destino | -f: fuerza el push
# NOTA: -c es para CNAME (dominio personalizado), NO para indicar el repo.
ghp-import -n -p -r origin -f "$BUILD_DIR"

STATUS=$?
if [ $STATUS -eq 0 ]; then
    echo "[OK] Publicacion completada con exito en GitHub Pages."
else
    echo "[ERROR] Ocurrio un error durante la publicacion con ghp-import."
    exit $STATUS
fi

echo "------------------------------------------------------------"
echo "Proceso completado."
echo "  Codigo fuente: https://github.com/lihkir/SpatioTemporalAI"
echo "  Libro:         https://lihkir.github.io/SpatioTemporalAI/"
echo "------------------------------------------------------------"