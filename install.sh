#!/usr/bin/env bash
# install.sh — bootstrap AI-DLC en un directorio target
#
# Trae los archivos del template/ del repo AI-DLC al directorio target.
# Es el primer paso del bootstrap; después corrés /adopt desde tu
# agente IA (Claude Code / Cursor / OpenCode / Codex CLI) para la
# entrevista de Phase 2 CLARIFY y la personalización.
#
# Uso:
#   ./install.sh <target-dir> [--greenfield|--brownfield|--upgrade]
#
# Desde curl (one-liner):
#   curl -fsSL https://raw.githubusercontent.com/picojuanc/ai-dlc/main/install.sh \
#     | bash -s -- /path/target [--greenfield]
#
# Variables de entorno:
#   AI_DLC_VERSION   tag a usar (default: latest stable)
#   AI_DLC_REPO_URL  override del repo source

set -euo pipefail

# ─── Parámetros ────────────────────────────────────────────────────
TARGET="${1:-}"
MODE="${2:---greenfield}"
VERSION="${AI_DLC_VERSION:-v0.21-personal}"
REPO_URL="${AI_DLC_REPO_URL:-https://github.com/picojuanc/ai-dlc.git}"

if [[ -z "$TARGET" ]]; then
  cat <<'EOF' >&2
ERROR: falta target dir.

Uso:
  ./install.sh <target-dir> [--greenfield|--brownfield|--upgrade]

Ejemplos:
  ./install.sh ~/dev/mi-proyecto-nuevo --greenfield
  ./install.sh ~/dev/proyecto-existente --brownfield

EOF
  exit 1
fi

# Validar modo
case "$MODE" in
  --greenfield|--brownfield|--upgrade) ;;
  *)
    echo "ERROR: modo inválido '$MODE'. Usar --greenfield, --brownfield, o --upgrade." >&2
    exit 1
    ;;
esac

# ─── Pre-flight ────────────────────────────────────────────────────
if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: git no está instalado." >&2
  exit 1
fi

# Resolver target a path absoluto (puede no existir todavía)
mkdir -p "$TARGET"
TARGET_ABS=$(cd "$TARGET" && pwd)

# Para --greenfield: el target debería estar vacío (o casi)
if [[ "$MODE" == "--greenfield" ]]; then
  if [[ -n "$(ls -A "$TARGET_ABS" 2>/dev/null)" ]]; then
    echo "WARNING: target $TARGET_ABS no está vacío." >&2
    echo "         --greenfield asume un repo nuevo. ¿Querés --brownfield?" >&2
    echo "         Continuar de todos modos? (y/N)" >&2
    read -r ANSWER < /dev/tty || ANSWER="n"
    [[ "$ANSWER" =~ ^[Yy]$ ]] || exit 1
  fi
fi

# Para --upgrade: el target debe tener .ai-dlc-version ya
if [[ "$MODE" == "--upgrade" ]]; then
  if [[ ! -f "$TARGET_ABS/.ai-dlc-version" ]]; then
    echo "ERROR: $TARGET_ABS/.ai-dlc-version no existe." >&2
    echo "       --upgrade requiere un repo ya adoptado previamente." >&2
    echo "       Para repo nuevo usar --greenfield." >&2
    exit 1
  fi
fi

# ─── Clone temp ────────────────────────────────────────────────────
TMP=$(mktemp -d)
trap "rm -rf '$TMP'" EXIT

echo "→ Clonando AI-DLC $VERSION..."
if ! git clone --depth 1 --branch "$VERSION" "$REPO_URL" "$TMP/ai-dlc" 2>&1 | grep -v "^Cloning\|^Note:" >&2; then
  echo "ERROR: clone falló. Verificá:" >&2
  echo "  - Conexión a internet" >&2
  echo "  - Que el tag/branch '$VERSION' exista en $REPO_URL" >&2
  exit 1
fi

# ─── Copiar template ───────────────────────────────────────────────
echo "→ Copiando template a $TARGET_ABS..."

# Usar -R para preservar symlinks (.claude/commands/* → .agents/commands/*)
cp -R "$TMP/ai-dlc/template/." "$TARGET_ABS/"

# Si --upgrade y restore-symlinks.sh existe, correrlo (defensa contra
# transferencias previas que rompieron symlinks)
if [[ -x "$TARGET_ABS/scripts/restore-symlinks.sh" ]]; then
  echo "→ Verificando symlinks..."
  bash "$TARGET_ABS/scripts/restore-symlinks.sh" "$TARGET_ABS" >/dev/null
fi

# ─── Mensaje final ─────────────────────────────────────────────────
cat <<EOF

AI-DLC $VERSION copiado a:
  $TARGET_ABS

Próximos pasos:
  1. cd $TARGET_ABS

  2. Abrir tu agente IA (Claude Code / Cursor / OpenCode / Codex CLI)
     desde el directorio del template del repo AI-DLC. Recomendado:
     modelo X→Y — el agente arranca con cwd en el template del repo
     AI-DLC, no en el target.

  3. Desde el agente, ejecutar:
        /adopt $TARGET_ABS $MODE

     El agente va a hacer la entrevista de Phase 2 CLARIFY, escribir
     el plan en .ai-dlc-adoption-plan.md, y al darle OK aplicar las
     personalizaciones (placeholders, repo-config.yaml, etc.).

  4. Cuando esté listo, vos hacés:
        git add . && git commit -m "chore: adopt AI-DLC $VERSION [bootstrap]"

     (el agente NO hace commit por vos — el commit es decisión humana).

Documentación:
  - methodology/ai-dlc-methodology.md (en el repo AI-DLC)
  - $TARGET_ABS/ADOPT.md (protocolo del agente)

EOF
