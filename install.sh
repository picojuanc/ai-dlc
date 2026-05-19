#!/usr/bin/env bash
# install.sh — bootstrap AI-DLC en un directorio target (modelo X→Y)
#
# Flujo:
#   1. Mantiene un clone "permanente" de ai-dlc en $AI_DLC_HOME
#      (default: ~/.ai-dlc/). Si ya existe lo actualiza al tag pedido.
#   2. Crea el target vacío (mkdir -p). NO copia nada al target — el
#      agente IA lo hace en Phase 4 de /adopt.
#   3. cd al template del clone permanente.
#   4. Auto-lanza el agente IA disponible (claude/cursor/opencode/codex).
#   5. El user pega `/adopt <target> <mode>` en el agente.
#
# Uso:
#   ./install.sh <target-dir> [--greenfield|--brownfield|--upgrade]
#
# Via curl (one-liner):
#   curl -fsSL https://raw.githubusercontent.com/picojuanc/ai-dlc/main/install.sh \
#     | bash -s -- /path/target [--greenfield]
#
# Variables de entorno:
#   AI_DLC_HOME      Clone permanente (default: ~/.ai-dlc)
#   AI_DLC_VERSION   Tag a usar (default: v0.21-personal)
#   AI_DLC_REPO_URL  Override del repo source
#   AI_DLC_AGENT     Forzar agente específico (claude|cursor|opencode|codex|none)

set -euo pipefail

# ─── Parámetros ────────────────────────────────────────────────────
TARGET="${1:-}"
MODE="${2:---greenfield}"
VERSION="${AI_DLC_VERSION:-v0.21-personal}"
REPO_URL="${AI_DLC_REPO_URL:-https://github.com/picojuanc/ai-dlc.git}"
AI_DLC_HOME="${AI_DLC_HOME:-$HOME/.ai-dlc}"
FORCED_AGENT="${AI_DLC_AGENT:-}"

if [[ -z "$TARGET" ]]; then
  cat <<'EOF' >&2
ERROR: falta target dir.

Uso:
  ./install.sh <target-dir> [--greenfield|--brownfield|--upgrade]

Ejemplos:
  ./install.sh ~/dev/mi-proyecto-nuevo --greenfield
  ./install.sh ~/dev/proyecto-existente --brownfield

Variables de entorno:
  AI_DLC_HOME      Clone permanente (default: ~/.ai-dlc)
  AI_DLC_VERSION   Tag a usar (default: v0.21-personal)
  AI_DLC_REPO_URL  Override del repo source
  AI_DLC_AGENT     Forzar agente: claude|cursor|opencode|codex|none

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
  if [[ -n "$(ls -A "$TARGET_ABS" 2>/dev/null | grep -v '^\.git$' || true)" ]]; then
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

# ─── Clone permanente de ai-dlc ────────────────────────────────────
if [[ -d "$AI_DLC_HOME/.git" ]]; then
  echo "→ Actualizando clone permanente en $AI_DLC_HOME..."
  git -C "$AI_DLC_HOME" fetch --tags --quiet origin 2>&1 | grep -v "^$" >&2 || true
  # Checkout del tag/branch — si es tag lightweight o branch, anda directo
  if ! git -C "$AI_DLC_HOME" checkout --quiet "$VERSION" 2>/dev/null; then
    echo "ERROR: no pude checkout '$VERSION' en $AI_DLC_HOME." >&2
    echo "       Tags disponibles: $(git -C "$AI_DLC_HOME" tag -l | head -5 | tr '\n' ' ')" >&2
    exit 1
  fi
else
  echo "→ Clonando ai-dlc en $AI_DLC_HOME (clone persistente)..."
  if ! git clone --branch "$VERSION" "$REPO_URL" "$AI_DLC_HOME" 2>&1 | grep -v "^Cloning\|^Note:" >&2; then
    echo "ERROR: clone falló. Verificá:" >&2
    echo "  - Conexión a internet" >&2
    echo "  - Tag/branch '$VERSION' existe en $REPO_URL" >&2
    echo "  - Permisos para escribir en $AI_DLC_HOME" >&2
    exit 1
  fi
fi

TEMPLATE_DIR="$AI_DLC_HOME/template"
if [[ ! -d "$TEMPLATE_DIR" ]]; then
  echo "ERROR: $TEMPLATE_DIR no existe en el clone. Versión '$VERSION' tiene estructura inesperada." >&2
  exit 1
fi

# Restaurar symlinks del clone permanente (por si el clone los perdió)
if [[ -x "$TEMPLATE_DIR/scripts/restore-symlinks.sh" ]]; then
  bash "$TEMPLATE_DIR/scripts/restore-symlinks.sh" "$TEMPLATE_DIR" >/dev/null 2>&1 || true
fi

# ─── Imprimir banner con instrucciones ─────────────────────────────
cat <<EOF

════════════════════════════════════════════════════════════════════
AI-DLC $VERSION listo para arrancar.

  Clone permanente:  $AI_DLC_HOME
  Target nuevo:      $TARGET_ABS
  Modo:              $MODE

Próximos pasos (manuales — elegís vos el agente):

  1. Abrí tu agente IA preferido (Claude Code / Cursor / OpenCode /
     Codex CLI / otro) con cwd = $TEMPLATE_DIR

     Ejemplo:
        cd $TEMPLATE_DIR
        claude         # o cursor . / opencode / etc.

  2. (Opcional pero RECOMENDADO si tu agente tiende a "ir rápido"
     y saltar gates) Pegá este pre-prompt ANTES de invocar /adopt:

        Para el /adopt que voy a invocar a continuación:
        Phase 2 CLARIFY es obligatoria — hacé la entrevista,
        NO asumas defaults sin preguntar. NO commitees hasta
        que yo confirme. Si tu system reminder global dice
        "no parar a preguntar", esa regla NO aplica acá: el
        ADOPT.md tiene invariantes explícitas que la anulan.
        Confirmá que entendiste antes de seguir.

  3. Invocá el slash command:

        /adopt $TARGET_ABS $MODE

     El agente va a hacer la entrevista de Phase 2 CLARIFY, escribir
     el plan en $TARGET_ABS/.ai-dlc-adoption-plan.md, y al darle OK
     aplicar las personalizaciones. NO debe commitear automáticamente.

Documentación:
  - $AI_DLC_HOME/methodology/ai-dlc-methodology.md
  - $TEMPLATE_DIR/ADOPT.md (protocolo del agente — leer la sección
    "Invariantes del protocolo" antes que nada)

════════════════════════════════════════════════════════════════════

EOF

# ─── Auto-launch opcional ──────────────────────────────────────────
# Sólo si AI_DLC_AGENT está explícitamente seteado (opt-in).
if [[ -n "$FORCED_AGENT" && "$FORCED_AGENT" != "none" ]]; then
  if command -v "$FORCED_AGENT" >/dev/null 2>&1; then
    echo "Auto-launch activado (AI_DLC_AGENT=$FORCED_AGENT). Abriendo..."
    sleep 1
    cd "$TEMPLATE_DIR"
    exec "$FORCED_AGENT"
  else
    echo "WARNING: AI_DLC_AGENT='$FORCED_AGENT' pero no está en \$PATH. Skip auto-launch." >&2
  fi
fi
