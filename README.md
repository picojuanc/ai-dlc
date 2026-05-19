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

### Adoptar AI-DLC en un proyecto personal nuevo

```bash
# Desde un agente IA (Claude Code / Cursor / OpenCode), con este repo
# cargado como contexto (cwd = ai-dlc/template):

/adopt /path/to/mi-proyecto-nuevo --greenfield
```

El agente sigue el protocolo de `template/ADOPT.md`. Te entrevista, escribe el plan, ejecuta cuando das OK.

### Actualizar un proyecto a una versión nueva del methodology

```bash
/adopt /path/to/mi-proyecto --upgrade
```

Reconcilia el proyecto contra la versión actual sin destruir tus customizaciones. Detalle en `template/ADOPT.md` sección "Modo `--upgrade`".

### Sin agente IA (a mano)

`template/BOOTSTRAP.md` (greenfield) o `template/BROWNFIELD-CHECKLIST.md` (brownfield).

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
