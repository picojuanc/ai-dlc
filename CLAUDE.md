# CLAUDE.md — ai-dlc (versión open)

Instrucciones para agentes IA (Claude Code, Cursor, OpenCode, Codex CLI) trabajando **sobre este repo** (`ai-dlc`).

No confundir con `template/AGENTS.md`, que son las instrucciones para agentes en los repos **adoptados** desde este template.

## Qué es este repo

Versión "open" de AI-DLC mantenida por Juan Pico. Fork de la versión empresarial sin integración corporativa específica. Pensada para:
- Proyectos personales de Juan.
- Side-projects que pueden ir a producción.
- Open source / proyectos compartidos.
- Equipos pequeños sin Azure DevOps corporativo.

Removidos del fork empresarial:
- Sección §13 Azure DevOps + slash commands `/ado-*`.
- Sección §14 OpenShift + slash commands `/oc-*`.
- Multi-tracker con roles `owner / stakeholder / qa` (default ahora es tracker `none`, único, sin roles).

Lo demás se mantiene. Los proyectos adoptados desde este template pueden ir a producción con múltiples ambientes y múltiples colaboradores — los defaults son livianos, no las asunciones.

`methodology/ai-dlc-methodology.md` v0.21-personal es la fuente canónica.

## Cuando se trabaja sobre este repo

### Editar el methodology
- **Lenguaje**: español (mixed con términos técnicos en inglés — `Architect Agent`, `Service Agent`, `spec`, `feature`, `task`, `harness`, etc.).
- **Frontmatter es load-bearing**: `version`, `date`. Bump cuando el cambio es sustantivo. Actualizar `date` a hoy.
- **TOC** debe quedar sincronizada con los `## Section`. Si agregás/quitás/renombrás sección, update TOC.
- **Archivo largo (>4500 líneas)**. Usar `offset`/`limit` con chunks de ~400 líneas.
- Las secciones de Integración con Azure DevOps y OpenShift están **removidas** en este fork; no las re-agregues.

### Editar el template
- **No pre-llenar `template/stack/*` con lenguaje específico**. Stack-agnostic.
- **No instalar skills en `template/.agents/skills/`**. Zero defaults.
- **AGENTS.md y CLAUDE.md del template** son los archivos que cada repo adoptado va a tener.
- **AGENTS.md del template tiene sentinels** `<!-- ai-dlc:section-start v=<METHODOLOGY_VERSION> -->`. Contenido nuevo va adentro.
- **No re-agregar** slash commands `/ado-*` ni `/oc-*` — fueron removidos intencionalmente.

### Coherencia cross-archivo

Cuando un cambio toca `methodology/` y `template/`, hacerlo en un solo commit. Casos típicos:
- Nueva regla en methodology → AGENTS.md del template debe reflejarla.
- Nuevo slash command en §11 → `template/.agents/commands/<name>.md` body completo + symlink en `.claude/commands/`.

### Cambios con consecuencias (requieren OK)

- Bump de versión (`v0.X → v0.Y`) — coordinarse con `git tag v0.Y-personal`.
- Cambios al protocolo de `ADOPT.md` — afectan a TODOS los repos que se adopten con esa versión.
- Cambios al schema de `.ai-dlc-version` — afectan al `--upgrade` de los repos ya adoptados.

### Cambios sin consecuencias (proceder)

- Typos, claridad, ejemplos.
- Anti-patrones nuevos derivados de uso real.
- Ajustes a wording.

## Iteración norms

- **Conversacional**. Cambios quirúrgicos.
- **Confirmar antes de mover/borrar** archivos.
- **Antes de bumpear versión**: ejercitar en al menos un proyecto personal real.

## Bug en este repo

No aplica taxonomía A/B/C/D/E (esto es metodología, no producto). Inconsistencias internas se corrigen + nota en commit. Si afecta protocolo, bumpear methodology.

## Si venís de la versión empresarial

Este fork sigue 95% el mismo modelo. Lo que cambia:
- Sin `/ado-*` ni `/oc-*` (slash commands removidos).
- §13 (Azure DevOps) y §14 (OpenShift) removidos del methodology.
- `repo-config.yaml` defaults distintos (tracker `none`, 1 ambiente — pero configurables hacia arriba).
- Referencias a "default empresarial" en el documento son históricas (de la rama empresarial) — explican qué tenía el fork original; no son asunciones de este fork.

**Importante**: el fork es para uso amplio (personal + side-projects + open source + equipos pequeños). Los defaults livianos son punto de partida, no restricciones. Un proyecto adoptado puede declarar 3 ambientes, multi-dev, deploy a prod, tracker formal — y la metodología se adapta vía `repo-config.yaml`.
