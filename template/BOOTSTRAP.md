# Greenfield Bootstrap — AI-DLC

> Runbook secuencial para adoptar AI-DLC **manualmente** en un repo
> **nuevo, sin código todavía**. Pensado para que un dev pueda
> completarlo solo en ~30 minutos sin herramientas adicionales —
> sólo este template y un agente AI a mano (Claude/Cursor/OpenCode).
>
> Para repos que ya tienen código en producción, ver
> `BROWNFIELD-CHECKLIST.md` (2 h, audit + negociación con lo
> existente).

**Versión metodología que aplica**: leer el frontmatter de
`ai-dlc-methodology.md` (campo `version:`) y usar ese valor cuando
este runbook diga `<METHODOLOGY_VERSION>`. Secciones de referencia:
§ 6, § 10.

**Tiempo estimado**: 30 minutos (5 min crear repo + 10 min decisiones
+ 10 min llenar archivos + 5 min primer commit y verificación).

**Principio raíz**: NO ASUMIR. Cada decisión se documenta — si no
está clara, **preguntar al equipo / lead**, no decidir solo (§3.12).

---

## Antes de empezar (2 min)

- [ ] **Sabés qué vas a construir** — al menos a nivel "es un
      servicio backend / una librería / una SPA". No necesitás la
      lista completa de features, sí la **naturaleza** del repo
      (define `repo_type`).
- [ ] **Tenés permisos** para crear el repo en el host destino
      (Azure DevOps / GitHub) y un branch protection rule en `main`.
- [ ] **Tenés una copia local del repo AI-DLC** (clonado del git
      corporativo). Este runbook se ejecuta usando el `template/`
      del repo AI-DLC como fuente — referenciado abajo como
      `$AI_DLC_REPO/template`.
- [ ] **Tenés acceso a un agente AI** abierto sobre este repo
      (Claude Code / Cursor / OpenCode / Codex CLI). El bootstrap
      es manual pero el llenado de `stack/` se hace mejor con un
      agente.

> A diferencia del brownfield, acá **no hay nada que respetar ni
> que negociar** — no hay código previo, no hay AI infra previa,
> no hay drift de branches, no hay memoria ad-hoc. Sí hay
> **decisiones** que tomar antes de la primera línea de código.

---

## Phase 1 — Crear repo + estructura base (5 min)

### 1.1 Crear el repo

En el host destino:

- [ ] Crear repo vacío (sin README inicial; lo trae el template).
- [ ] Clonar localmente y `cd <repo>`.
- [ ] Configurar branch protection en `main` (PR-only, 1+
      reviewer). Para `repo_type: service` con default SYC,
      también proteger `pruebas` y `qa` cuando se creen (Phase
      3.4).

### 1.2 Copiar estructura base desde el template

```bash
TEMPLATE="$AI_DLC_REPO/template"     # ej. ~/dev/ai-dlc/template

# archivos al root
cp "$TEMPLATE/AGENTS.md" ./
cp "$TEMPLATE/CLAUDE.md" ./
cp "$TEMPLATE/repo-config.yaml" ./
cp "$TEMPLATE/.gitignore" ./

# stack/ — todo viene con TODOs por diseño
cp -r "$TEMPLATE/stack" ./

# specs/ — vacío salvo .gitkeep
mkdir -p specs
[ -f "$TEMPLATE/specs/.gitkeep" ] && cp "$TEMPLATE/specs/.gitkeep" specs/

# .agents/commands/ (slash commands canonical)
mkdir -p .agents/commands
cp "$TEMPLATE/.agents/commands/"*.md .agents/commands/

# .claude/commands/ (symlinks a .agents/commands/)
mkdir -p .claude/commands
for f in .agents/commands/*.md; do
  ln -sf "../../$f" ".claude/commands/$(basename $f)"
done

# .agents/skills/ — sólo README (zero defaults)
mkdir -p .agents/skills
cp "$TEMPLATE/.agents/skills/README.md" .agents/skills/

# .org/ — sólo si planeás publicar contracts cross-team
# (opcional en greenfield; agregar después cuando aparezca el primer
# consumer externo)
# cp -r "$TEMPLATE/.org" ./
```

**Verificar**: `git status` muestra los archivos copiados como
`untracked`. Nada más.

---

## Phase 2 — Decisiones (10 min)

7 decisiones. **Documentar la decisión** — si no la sabés y nadie
del equipo la sabe todavía, marcala `OPEN_QUESTION` en
`repo-config.yaml` y resolvela antes del primer merge.

### D1 — `repo_type`

> ¿Qué tipo de repo es?

- [ ] **(a) `service`** — backend desplegable (HTTP/gRPC/worker).
      Default SYC. Ambientes `pruebas → qa → main`.
- [ ] **(b) `library`** — paquete npm / nuget / pip / maven.
      Ambientes `pruebas (prerelease) → main (release)`. No tiene
      `qa`.
- [ ] **(c) `frontend-app`** — SPA / Next.js / app web con previews
      por PR.
- [ ] **(d) `infra`** — terraform / helm / pulumi. Típicamente
      `sandbox → prod`.
- [ ] **(e) `custom`** — algo que no cuadra (CLI tool, monorepo
      heterogéneo de día 1). Declarás `environments` y
      `deploy_trigger` a mano.

### D2 — Tracker de work items

> ¿Qué sistema de tracking usás?

- [ ] **(a) `azure-devops`** — default SYC. Necesitás `org`,
      `project`, `default_area_path`.
- [ ] **(b) `github-issues`** — formato `[R*.*] #<issue>`.
- [ ] **(c) `jira`** — formato `[R*.*] PROJ-<id>`.
- [ ] **(d) `linear`** — formato `[R*.*] <TEAM>-<n>`.
- [ ] **(e) `none`** — sólo `[R*.*]` en commits, sin board. Válido
      para empezar; migrable a AzDO después sin re-trabajo (§6
      *Migración: adoptar un tracker después del bootstrap*).

### D3 — Ambientes

> ¿Qué ambientes desplegables va a tener este repo?

Default por `repo_type`:

| repo_type | environments default | promotion_path |
|---|---|---|
| `service` | `pruebas`, `qa`, `main` | `[pruebas, qa, main]` |
| `library` | `pruebas`, `main` | `[pruebas, main]` |
| `frontend-app` | `pruebas`, `qa`, `main` | `[pruebas, qa, main]` |
| `infra` | `sandbox`, `prod` | `[sandbox, prod]` |
| `custom` | (declarar a mano) | (declarar a mano) |

- [ ] **(a) Aceptar el default** para el `repo_type` elegido.
- [ ] **(b) Reducir** — ej. `service` sin `qa` si el equipo no lo
      usa todavía. Documentar por qué.
- [ ] **(c) Agregar** — ej. `staging` adicional entre `qa` y
      `main`. Documentar quién es el gate de cada uno.

> Regla: no inventar ambientes que el equipo no va a usar. Es
> trivial agregar uno después; sacar uno con historia ya cuesta.

### D4 — Runtime / deploy target

> ¿A dónde se despliega?

- [ ] **(a) `openshift`** — default SYC para `service`. Cluster:
      `_______` (típicamente `ocp-eu-west-1`). Namespace pattern:
      `_______` (típicamente `{service}-{env}`).
- [ ] **(b) `k8s`** — Kubernetes vanilla.
- [ ] **(c) `npm-registry` / `nuget-feed`** — `library`.
      Registry/feed: `_______`.
- [ ] **(d) `static-host`** — Vercel / Netlify / S3+CloudFront.
      Host: `_______`.
- [ ] **(e) `none`** — repo no se despliega (`docs-only`,
      `catalog-only`, sólo CLI/tool local).
- [ ] **(f) `TBD`** — no lo sabés todavía. Aceptable; queda como
      OPEN_QUESTION en `repo-config.yaml`. Resolver antes del
      primer feature que requiera deploy real.

### D5 — Convención de branches

> ¿Cómo nombrás las ramas de feature?

- [ ] **(a) `feat/<slug>`** — default AI-DLC. Recomendado para
      greenfield (alinea con el resto del template).
- [ ] **(b) `feature/<slug>`** — más común en .NET shops.
- [ ] **(c) otra** — declarala explícitamente en
      `repo-config.yaml > branch_pattern`.

### D6 — Diseño (Figma)

> ¿Este repo tiene dependencia del servicio de diseño?

- [ ] **(a) Sí** — declarar `design_service.figma_team_url` en
      `repo-config.yaml`. Los slash commands `/figma-*` aplican.
- [ ] **(b) No** — dejar la sección comentada. No-op.

### D7 — Owner, equipo, lead

> Reemplaza placeholders en `AGENTS.md` y `repo-config.yaml`:

- Service name (slug): `_______________`
- Owner team: `_______________`
- Lead email: `_______________` (típicamente `@example.com.co`)

---

## Phase 3 — Apply (10 min)

### 3.1 Reemplazar placeholders

En `AGENTS.md` y `repo-config.yaml`:

| Placeholder | Reemplazar por (D7) |
|---|---|
| `{{SERVICE_NAME}}` | service name slug |
| `{{OWNER_TEAM}}` | owner team |
| `{{LEAD_EMAIL}}` | lead email |

Con `sed` (macOS):

```bash
SVC="mi-servicio"; OWNER="team-x"; EMAIL="x@example.com.co"
sed -i '' "s|{{SERVICE_NAME}}|$SVC|g; s|{{OWNER_TEAM}}|$OWNER|g; s|{{LEAD_EMAIL}}|$EMAIL|g" AGENTS.md repo-config.yaml
```

### 3.2 Configurar `repo-config.yaml` con las decisiones D1–D6

Abrí `repo-config.yaml` y llenalo:

- `repo_type`: D1
- `tracker`: D2
- `tracker_config`: si D2 ≠ `none`, llenar campos (org/project, etc.)
- `environments`: D3 — la lista exacta
- `promotion_path`: D3 — el orden
- `runtime.type`: D4 (o `TBD` si OPEN_QUESTION)
- `branch_pattern`: D5 (default `feat/`)
- `design_service`: D6 — descomentar y llenar si aplica, eliminar
  si no

Marcá `# OPEN_QUESTION:` cualquier campo sin decidir. **No
inventes valores**.

### 3.3 Llenar `stack/`

Editá cada archivo en orden, **con un agente al lado**:

- [ ] **`stack/tech-stack.md`** — lenguaje, versión, framework,
      build tool, deps internas, deploy target. Esto **sí lo
      sabés** porque el repo es greenfield y vos elegís el stack.
- [ ] **`stack/architecture.md`** — patrones (clean architecture,
      hexagonal, MVC, layered). Si no lo sabés todavía, dejá un
      TODO acotado y resolvelo cuando empieces la primera feature
      (el `design.md` te forzará a explicitarlo).
- [ ] **`stack/patterns.md`** — naming, formato de commits,
      convenciones del repo. Mínimo: convención de commits
      (`feat(spec): [R*.*] descripción AB#<id>`).
- [ ] **`stack/security.md`** — manejo de secrets, PII si aplica,
      auth/authz expected, compliance (GDPR, SOX, etc. si toca).
      Si no aplica todavía, declarar "N/A — pública" o similar.
- [ ] **`stack/constraints.md`** — anti-patrones específicos de
      este repo (qué NO hacer).
- [ ] **`stack/testing.md`** — framework (vitest/jest/pytest/
      xunit), niveles (unit/integration/e2e), cobertura mínima,
      comando de run.

> **El Service Agent NO genera código mientras `stack/` tiene
> TODOs sin resolver** (§ Bootstrap en `AGENTS.md`). Esto es a
> propósito: sin stack explícito, el `design.md` sale genérico y
> los tests no pueden trazar a naming/convenciones.

### 3.4 Crear ramas de ambiente (si aplica)

Sólo si D3 declara ambientes distintos a `main`:

```bash
# ejemplo para service con pruebas → qa → main
git checkout -b pruebas main
git checkout -b qa main
git checkout main
git push -u origin main pruebas qa
```

Configurá branch protection en cada una (PR-only, sin force-push).

### 3.5 Primer commit

```bash
git add .
git status        # revisar que no se cuele nada raro
git commit -m "chore: bootstrap AI-DLC v<METHODOLOGY_VERSION>

- AGENTS.md, CLAUDE.md, repo-config.yaml, stack/, .agents/commands/
- repo_type=<D1>, tracker=<D2>, runtime=<D4>
- OPEN_QUESTIONS: <lista, si las hay>

Methodology: see ai-dlc-methodology.md v<METHODOLOGY_VERSION>"

git push -u origin main
```

---

## Phase 4 — Primera feature (5 min para verificar el loop)

### 4.1 Abrir agente sobre el repo

- [ ] Claude Code / Cursor / OpenCode lee `AGENTS.md` automáticamente.
- [ ] Verificar que el agente reconoce los slash commands (debería
      listar `/spec-new`, `/spec-implement`, etc.).

### 4.2 Crear la primera spec

- [ ] Invocar `/spec-new <slug-de-feature>` o describir la feature
      en lenguaje natural — el protocolo entry-point de `AGENTS.md`
      arranca con CLARIFY antes de escribir.
- [ ] El agente debe **pausar al final de `/spec-new` (gate G2)** y
      esperar tu OK explícito antes de implementar. Si no pausa,
      revisar que `.agents/commands/spec-new.md` esté completo.

### 4.3 Validar el flujo

- [ ] Spec creada en `specs/<slug>/{requirements.md, design.md,
      tasks.md, status.md}`.
- [ ] `requirements.md` tiene `R*.*` en formato EARS con NFRs
      medibles.
- [ ] `design.md` referencia decisiones que aparecen en `stack/`
      (esto valida que `stack/` quedó bien llenado).
- [ ] El primer commit de implementación cita `[R*.*]` y el work
      item del tracker (si D2 ≠ `none`).

Si todo lo anterior se cumple, el bootstrap está **operativo**.

---

## Apéndice A — Inventario canónico de archivos AI-DLC

Lo que debería existir tras el bootstrap:

```
<repo>/
├── AGENTS.md                          ← protocolo del agente (standard abierto)
├── CLAUDE.md                          ← override Claude-específico
├── repo-config.yaml                   ← config operacional del repo (§6)
├── BOOTSTRAP.md                       ← este archivo (opcional dejarlo tras bootstrap)
├── stack/
│   ├── tech-stack.md
│   ├── architecture.md
│   ├── patterns.md
│   ├── security.md
│   ├── constraints.md
│   └── testing.md
├── specs/                             ← vacío al inicio; se va llenando feature a feature
│   └── <feature-slug>/                ← creado por /spec-new
│       ├── requirements.md
│       ├── design.md
│       ├── tasks.md
│       ├── status.md
│       ├── bugs.md                    ← opcional
│       ├── amendments.md              ← opcional
│       └── dependencies.md            ← opcional
├── .agents/
│   ├── commands/                      ← slash commands canonical
│   │   ├── spec-new.md
│   │   ├── spec-implement.md
│   │   ├── spec-amend.md
│   │   ├── spec-status.md
│   │   ├── spec-verify.md
│   │   ├── spec-handoff.md
│   │   ├── spec-promote.md
│   │   ├── bug-triage.md
│   │   ├── ado-link.md                ← sólo si tracker=azure-devops
│   │   └── ado-status.md              ← sólo si tracker=azure-devops
│   └── skills/
│       └── README.md                  ← zero defaults; cada repo decide qué instalar
├── .claude/
│   └── commands/                      ← symlinks a ../.agents/commands/*.md
└── .org/                              ← (opcional) catálogo cross-team
    └── contracts/                     ← OpenAPI/AsyncAPI publicados
```

---

## Apéndice B — Diferencias greenfield vs brownfield

| Aspecto | Greenfield (este doc) | Brownfield (`BROWNFIELD-CHECKLIST.md`) |
|---|---|---|
| **Tiempo** | ~30 min | ~2 h |
| **Phase 1** | Crear repo + copiar template | Audit (10 min) — detectar stack, AI infra previa, memoria ad-hoc, branches, estructura |
| **Phase 2** | 7 decisiones (D1–D7) | 12 decisiones (D1–D12) — incluye negociación con CLAUDE.md, .cursorrules, .cursor/plans/, sessions ad-hoc, skills previas |
| **Phase 3** | Llenar stack/ con lo que vos decidís | Llenar stack/ con lo **detectado** + lo decidido; respetar archivos previos |
| **Stack** | Vos elegís — todo es tabla rasa | Detectado primero, decidido después si hay ambigüedad |
| **AI infra previa** | N/A | Espejar reglas codificables, no migrar archivos del tool original |
| **Memoria ad-hoc** | N/A | 3 opciones: archive / migrate-to-specs / leave |
| **Branches** | Crear las de ambiente desde `main` | Detectar las existentes; no inventar ambientes que no existen |
| **Features legacy** | N/A | Stub `state: legacy` cuando se vuelva a tocar (§15 strangler) |
| **Riesgo** | Bajo — repo vacío | Mayor — anti-patrones documentados en §15 (sobreescribir CLAUDE.md, "consolidar" borrando, migrar masivo sin pedirlo) |

---

## Apéndice C — Qué decidir ahora vs después

**Decidir ahora (bloquea el bootstrap)**:
- D1 `repo_type` — define la forma del repo
- D5 `branch_pattern` — antes del primer feature branch
- D7 Owner/team/email — para placeholders

**Decidir antes del primer feature**:
- D2 `tracker` — afecta formato de commits
- D3 `environments` — antes de configurar branch protection y CI
- `stack/tech-stack.md` y `stack/testing.md` — el agente no genera
  código sin esto

**Decidir cuando aparezca el caso**:
- D4 `runtime` — válido `TBD` si el deploy real está lejos
- D6 `design_service` — sólo si vas a integrar diseño
- `.org/contracts/` — sólo cuando aparezca el primer consumer
  cross-team
- MCPs adicionales en `repo-config.yaml > mcps` — declarativos,
  per uso
