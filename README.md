# ai-dlc

**AI-DLC** (AI-Driven Development Lifecycle) — versión "open" mantenida por Juan Pico. Metodología de Spec-Driven Development con agentes IA, sin integración corporativa específica.

## Qué es

Repo unificado con la metodología + template ejecutable para adoptar AI-DLC en proyectos nuevos.

**Usos previstos**:
- Proyectos personales y side-projects de Juan.
- Side-projects que pueden ir a producción.
- Open source / proyectos compartidos con colaboradores.
- Equipos pequeños sin Azure DevOps corporativo.

**Es un fork** de una versión empresarial específica (con Azure DevOps + OpenShift como defaults). Este fork remueve lo atado al stack corporativo y mantiene el modelo metodológico completo:

**Mantenido del original**:
- Spec-Driven Development con EARS (`WHEN/WHILE/IF ... THE SYSTEM SHALL ...`)
- Bug taxonomy A/B/C/D/E + Amendments
- Lifecycle states + gates G0-G6
- Sistema de slash commands (`/spec-new`, `/spec-implement`, etc.)
- Harness engineering: ratchet de bugs, capas Consejo/Garantía/Bloqueo
- Upgrade safety: manifiesto per-archivo en `.ai-dlc-version`, sentinels en AGENTS.md
- SHAPE guides (servicio compartido, LLM agent como producto, data pipeline)

**Removido del original** (porque ataban a stack corporativo):
- Sección §13 *Integración con Azure DevOps*.
- Sección §14 *Integración con OpenShift*.
- Slash commands `/ado-*` y `/oc-*`.
- Multi-tracker con roles `owner / stakeholder / qa` (complejidad cross-team específica del entorno empresarial; si tu equipo lo necesita, vale agregarlo).

**Defaults vs asunciones**: los defaults del fork son livianos (tracker `none`, 1 ambiente `main`). Eso es **default**, no asunción — si tu proyecto tiene 3 ambientes, múltiples colaboradores, deploy a producción, tracker formal (GitHub Issues / Jira / Linear), todo se declara en `repo-config.yaml` y la metodología se adapta. La intención no es restringir el uso a "1 dev / sin prod / sin tracker" — es no asumir nada corporativo-específico.

## Versión

`v0.21-personal` — ver `methodology/ai-dlc-methodology.md` frontmatter.

## Estructura

```
ai-dlc/
├── README.md                       (este archivo)
├── CLAUDE.md                       instrucciones para agentes IA sobre este repo
├── install.sh                      script de bootstrap (Opción 1 abajo)
├── methodology/
│   └── ai-dlc-methodology.md       documento canónico de la metodología
├── template/                       starter para repos nuevos
│   ├── AGENTS.md
│   ├── ADOPT.md                    protocolo del agente bootstrap
│   ├── BOOTSTRAP.md                runbook manual greenfield
│   ├── BROWNFIELD-CHECKLIST.md     runbook manual brownfield
│   ├── CLAUDE.md
│   ├── repo-config.yaml
│   ├── stack/
│   ├── specs/
│   ├── .agents/commands/           bodies canonical de slash commands
│   ├── .claude/commands/           symlinks a .agents/commands/
│   ├── guides/                     SHAPE guides (servicio compartido / LLM / pipeline)
│   └── scripts/restore-symlinks.sh
└── examples/
    └── neo-estampillas/            ejemplos de prompts del fork empresarial
```

## Cómo se usa

### Setup recomendado — `install.sh` (con agente IA)

```bash
curl -fsSL https://raw.githubusercontent.com/picojuanc/ai-dlc/main/install.sh \
  | bash -s -- ~/dev/mi-proyecto-nuevo --greenfield
```

Qué hace el script:

1. **Mantiene un clone permanente** de `ai-dlc` en `~/.ai-dlc/` (configurable). Si ya existe lo actualiza al tag vigente.
2. **Crea el target vacío**. NO copia archivos al target — eso lo hace el agente en Phase 4.
3. **Imprime el comando exacto** a pegar en tu agente IA — junto con la ruta del template (`~/.ai-dlc/template/`) donde el agente debe arrancar con `cwd` (modelo X→Y de la metodología — el agente arranca con el template canónico como autoridad).

Después vos:
1. **Abrís el agente IA que prefieras** (Claude Code, Cursor, OpenCode, Codex CLI, etc.) con `cwd = ~/.ai-dlc/template/`.
2. **Pegás el comando** que el script imprimió:
   ```
   /adopt ~/dev/mi-proyecto-nuevo --greenfield
   ```

El agente desde ahí hace toda la entrevista (Phase 2 CLARIFY), escribe el plan (Phase 3), y al darle OK aplica los archivos personalizados al target (Phase 4).

Modos: `--greenfield` (repo nuevo), `--brownfield` (repo con código), `--upgrade` (proyecto ya adoptado en una versión previa).

Variables de entorno (todas opcionales):
- `AI_DLC_HOME` — clone permanente (default: `~/.ai-dlc`)
- `AI_DLC_VERSION` — tag específico (default: `v0.21-personal`)
- `AI_DLC_REPO_URL` — override del source (para forks)
- `AI_DLC_AGENT` — auto-launch opt-in del agente especificado (`claude`/`cursor`/`opencode`/`codex`). Si seteás esto, el script abre el agente al final en lugar de solo imprimir instrucciones.

### Opt-in: auto-launch del agente

Si querés que el script abra tu agente automáticamente al final (modelo "one-shot"):

```bash
AI_DLC_AGENT=claude curl -fsSL https://raw.githubusercontent.com/picojuanc/ai-dlc/main/install.sh \
  | bash -s -- ~/dev/mi-proyecto-nuevo --greenfield
```

El script hace todo lo de arriba + abre Claude Code (o cualquier agente que pidas) con cwd correcto. Vos pegás `/adopt`. Útil si siempre usás el mismo agente.

### Alternativa — sin agente IA, todo a mano

`template/BOOTSTRAP.md` (greenfield) o `template/BROWNFIELD-CHECKLIST.md` (brownfield). Runbooks paso-a-paso para humanos sin agente.

### Upgrade

Cuando salga una versión nueva del methodology y quieras actualizar un proyecto ya adoptado:

```bash
curl -fsSL https://raw.githubusercontent.com/picojuanc/ai-dlc/main/install.sh \
  | bash -s -- /path/to/proyecto-ya-adoptado --upgrade
```

El script valida que el target tiene `.ai-dlc-version` (señal de que ya fue adoptado). Actualiza el clone permanente al tag más nuevo. Auto-lanza el agente con cwd correcto. Pegás `/adopt <target> --upgrade` y el agente ejecuta el protocolo de upgrade (manifiesto per-archivo, diff prompts, etc. — detalle en `template/ADOPT.md` sección *"Modo `--upgrade`"*).

## Convenciones del repo

- **Versionado**: cada cambio sustantivo bumpea `version:` del frontmatter de `ai-dlc-methodology.md`. Cuando cierres una versión, tag: `git tag v0.X-personal && git push origin v0.X-personal`.
- **Tag al cierre de versión**: es crítico — sin tag, los `--upgrade` futuros degradan a 2-way diff.
- **Cambios al methodology + template juntos**: si un cambio toca ambos (típico), un solo commit.

## Diferencias con la versión empresarial

| Aspecto | Empresarial | Open (este repo) |
|---|---|---|
| Tracker default | Azure DevOps multi-tracker con roles | `none` (configurable a GitHub Issues / Jira / Linear) |
| Ambientes default | `pruebas / qa / main` | `main` solo (configurable a 2+ si tu proyecto los necesita) |
| Runtime default | OpenShift | TBD por proyecto (declarar en `repo-config.yaml`) |
| Slash commands `/ado-*` | Sí | No (removidos) |
| Slash commands `/oc-*` | Sí | No (removidos) |
| `/figma-*` | Sí | Opcional |
| Initiative cross-team | Sí (con Architect Agent) | Initiative sigue siendo opcional (aplica si tu proyecto coordina varios repos) |
| Multi-tracker con roles `owner/stakeholder/qa` | Sí | Removido (agregable si tu equipo lo necesita) |

Ver `methodology/ai-dlc-methodology.md` para el detalle (las secciones `## Integración con Azure DevOps` y `## Integración con OpenShift` fueron removidas en este fork).

## Cómo contribuir a este repo (vos mismo)

- Iteración conversacional: cambios chiquitos, conversacional con agente IA.
- No re-escrituras masivas.
- Antes de bumpear versión: ejercitar en al menos 1 proyecto personal real.
