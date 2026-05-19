---
title: Metodología AI-DLC — Open
version: 0.21-personal (draft)
date: 2026-05-18
owner: Juan Pico (picojuanc@gmail.com)
status: Draft — fork sin integración corporativa específica
---

# Metodología AI-DLC — Open

> Versión del **AI-Driven Development Lifecycle** y **Spec-Driven
> Development** sin integración corporativa específica (sin Azure
> DevOps, sin OpenShift como defaults). Pensada para proyectos
> personales, side-projects, open source y equipos pequeños — pero
> los proyectos adoptados pueden ir a **producción** y tener
> **múltiples colaboradores**: la metodología sigue siendo válida
> en esos contextos, sólo cambia el tracker y los ambientes que el
> repo declare en su `repo-config.yaml`.
>
> **Fork de qué**: la versión empresarial vive en otro repo
> (corporativo, con `/ado-*`, `/oc-*` y secciones de integración con
> Azure DevOps + OpenShift). Este fork mantiene 95% de los conceptos
> (SDD, EARS, bug taxonomy, harness engineering, upgrade safety,
> SHAPE guides) y remueve sólo lo que ataba al stack corporativo
> específico.
>
> **Defaults vs asunciones**: los defaults del fork son livianos
> (tracker `none`, 1 ambiente `main`). Eso es **default**, no
> asunción. Si tu proyecto tiene 3 ambientes, multi-dev, deploy a
> prod, tracker formal — todo se declara en `repo-config.yaml` y la
> metodología se adapta. Ver §6 *Configuración del repo*.

---

## Tabla de contenidos

1. [TL;DR](#tldr)
2. [Contexto y motivación](#contexto-y-motivación)
3. [Conceptos fundamentales](#conceptos-fundamentales)
4. [Las 7 fases del AI-DLC](#las-7-fases-del-ai-dlc)
5. [Specs en formato EARS](#specs-en-formato-ears)
6. [Specs jerárquicas: Initiative → Feature → Task](#specs-jerárquicas-initiative--feature--task)
7. [Sistema de agentes](#sistema-de-agentes)
8. [Manejo de bugs](#manejo-de-bugs)
9. [Catálogo organizacional (`.org/`)](#catálogo-organizacional-org)
10. [Estructura de repositorios](#estructura-de-repositorios)
11. [Herramientas: Cursor + Claude Code](#herramientas-cursor--claude-code)
12. [Integración con el servicio de diseño (Figma + Figma Make)](#integración-con-el-servicio-de-diseño-figma--figma-make)
13. ~~Integración con Azure DevOps~~ — **removida en este fork**
14. ~~Integración con OpenShift~~ — **removida en este fork**
15. [Flujo end-to-end (ejemplo completo)](#flujo-end-to-end-ejemplo-completo)
16. [Plan de adopción gradual](#plan-de-adopción-gradual)
17. [Métricas de éxito](#métricas-de-éxito)
18. [Anti-patrones](#anti-patrones)
19. [Apéndices](#apéndices)

> **Nota del fork**: las secciones §13 (Azure DevOps) y §14
> (OpenShift) están **removidas**. La numeración se preserva (no se
> renumeró §15 → §13, etc.) para no romper referencias internas al
> documento. Las referencias inline a "Azure DevOps", "ADO",
> `az boards`, `ocp-eu-west-1`, multi-tracker con roles
> `owner/stakeholder/qa`, etc. que aparezcan en otras secciones son
> **ilustrativas / históricas** — el tracker concreto se declara en
> `repo-config.yaml > trackers` (default: `none`; configurable a
> GitHub Issues / Jira / Linear).

---

## TL;DR

- **Spec-Driven Development (SDD)** convierte la **especificación** en la fuente de verdad,
  no el código.
- **AI-DLC** es un ciclo de desarrollo donde agentes de IA participan como colaboradores
  en todas las fases del SDLC, con specs como contrato.
- En la empresa, lo adaptamos así:
  - **Specs por feature en cada repo** (la Feature es la unidad obligatoria;
    la Initiative es **opcional** y sólo aplica para coordinar varios equipos),
    versionadas en Git.
  - **Sistema de agentes** especializados (Architect, Service, Compliance, Ops, Cost).
  - **Contratos compartidos** publicados en `.org/contracts/` (lo único
    obligatorio del catálogo); el resto de `.org/` —`catalog.yaml`,
    `policies/`, ADRs, etc.— es opcional y depende de que haya quién
    lo mantenga.
  - **Servicio de diseño integrado** vía Figma + Figma Make, con dos prompts por repo
    (`Guidelines.md` + `figma-make-integration.md`) que actúan como contrato design↔dev.
  - **Integración con un tracker de work items** (Azure DevOps, GitHub Issues,
    Jira, o ninguno) **declarado por repo** en `repo-config.yaml`. La metodología
    no asume un tracker — el default empresarial es Azure DevOps.
  - **Integración con runtime / CI** (OpenShift + Azure Pipelines como default empresarial;
    npm registry para `repo_type: library`; otros adapters posibles), con la spec
    definiendo *qué* y *dónde* desplegar / publicar.
  - **Configuración por repo** (`repo-config.yaml`): `repo_type`
    (service / library / frontend-app / infra), `tracker`, `environments`,
    `promotion_path`. Soporta migraciones (`trackers: [] → con tracker`,
    `library → service`, etc.) sin reescribir specs.
- **Adopción gradual** en 4 fases (piloto → equipo → división → organización).

---

## Contexto y motivación

### Stack (configurable por repo)

En el fork personal, los defaults son intencionalmente livianos:

| Capa | Default personal | Configurable por repo en `repo-config.yaml` |
|---|---|---|
| Control de código | GitHub (Git) | Cualquier remoto Git |
| CI/CD | GitHub Actions (opcional) | Lo que prefieras o nada |
| Tracking | `none` (sin tracker formal) | `github-issues` / `jira` / `linear` / `none` |
| Runtime | varía por proyecto | Vercel / Cloudflare / docker-compose self-host / k8s personal / ninguno |
| Despliegue | manual o GitHub Actions | Depende de `repo_type` (§6) |

> La metodología no asume tracker ni runtime. Un proyecto personal
> típico arranca con `trackers: []` y un solo ambiente (`main`).
> Configurable hacia arriba si el proyecto crece.

### Problemas que AI-DLC busca resolver

1. **Requisitos ambiguos** → reprocesos costosos en implementación.
2. **Docs desactualizados** → onboarding lento, conocimiento concentrado en personas.
3. **Cambios cross-repo** → coordinación manual, errores en contratos entre servicios.
4. **Code reviews largos** → bottleneck humano sin visibilidad de intención.
5. **Bugs por gaps de especificación** → no hay forma sistemática de detectar qué casos
   no se contemplaron.
6. **Onboarding de IA** sin gobernanza → cada desarrollador usa agentes a su manera,
   sin trazabilidad ni estándares.

### Lo que esta metodología propone

- **Una sola fuente de verdad**: la spec.
- **Contrato claro entre humanos y agentes**: la spec.
- **Trazabilidad end-to-end**: requirement → tarea → commit → PR → pipeline → deploy.
- **Reducción del trabajo manual de bajo valor**: boilerplate, tests obvios, docs.
- **Más tiempo humano en alto valor**: arquitectura, decisiones de negocio, seguridad.

---

## Conceptos fundamentales

### Spec-Driven Development (SDD)

| Aspecto | SDLC clásico | SDD |
|---|---|---|
| Fuente de verdad | Código | **Spec** |
| Docs | Se desactualizan | **Son** el contrato |
| Tests | Escritos después | **Derivados** de la spec |
| Refactor | Riesgoso | **Regeneración** desde spec |
| Code review | Línea por línea | Spec + diff dirigido |

### AI-Driven Development Lifecycle (AI-DLC)

Es el ciclo donde agentes de IA participan activamente, con la spec como contrato.
**No reemplaza al humano** — lo mueve a tareas de mayor valor.

### Principios transversales (1-6)

1. **Specs como contratos** — si código y spec divergen, gana la spec.
2. **Agentes como colaboradores** — no autocompletado, sino responsables de tareas
   completas con contexto persistente.
3. **Humano en el alto nivel** — definir intención, revisar specs, validar resultados.
4. **Reversibilidad** — todo output de agente es regenerable desde la spec.
5. **Trazabilidad** — requirement → diseño → tarea → commit → PR → test → deploy → métrica.
6. **Gobernanza explícita** — gates humanos en puntos de alto impacto.

### Principios anti-burocracia (orgs grandes, 7-11)

En una organización con decenas de equipos y cientos de devs, una
metodología demasiado centralizada se vuelve, en la práctica, un freno.
Los siguientes principios actúan como **filtro**: cualquier propuesta
posterior (incluso bien intencionada) que los viole debe rechazarse.

7. **Spec locality** — Toda spec vive en el repo que la implementa. No
   hay repo de specs central, ni excepciones por "es muy importante".
   El único nivel superior posible es la Initiative, que es **opcional**
   (ver §6).
8. **No coordinator** — Ninguna feature necesita aprobación de un órgano
   centralizado para existir. La coordinación cross-team es **bilateral**
   entre los dos equipos involucrados, no mediada por un comité.
9. **Contract as handshake** — La coordinación cross-team se materializa
   en **un contrato** versionado (OpenAPI / AsyncAPI / SQL schema /
   evento), no en una ceremonia. El contrato *es* el acuerdo.
10. **Partial deploy by default** — Una feature no espera a estar completa
    para desplegar a dev/test. Las tasks `done` se despliegan; un
    feature flag controla la visibilidad en producción. Esperar a
    "todo listo" es la anti-pattern.
11. **Declared, not approved** — Una dependencia externa se **declara**
    en la spec (sección Dependencies). La confirmación del otro equipo
    es un mensaje en chat o un work item en su backlog — no una reunión
    de gate ni una firma.

### Cómo se comportan los agentes (conversacional, 12-18)

La metodología **no debe vivir en la cabeza del desarrollador** como
un checklist a recordar. El agente es quien guía: pregunta, cuestiona,
detecta gaps y propone el siguiente paso. El dev decide producto y
criterio; el agente se encarga del proceso.

12. **Nunca asumas — pregunta** — si la entrada del usuario es
    ambigua, incompleta u omite contexto (qué repo, qué feature, qué
    ambiente), el agente **pregunta antes de actuar**. Inferir sin
    verificar es la fuente principal de bugs Tipo C y trabajo
    descartado. Asunciones típicas a evitar (no exhaustivo):
    - *"Esto es feature nueva"* sin chequear si hay specs existentes
      en `specs/` que cubren o tocan el dominio (puede ser
      continuación o amendment).
    - *"Esta dep es estándar"* — `npm install <x>` sin confirmar
      licencia, vulnerabilidades conocidas, y si la empresa la prohíbe
      por políticas de legal/seguridad/arquitectura.
    - *"El stack es obvio"* — elegir framework, lenguaje o runtime
      sin cruzar con `stack/tech-stack.md` y `stack/constraints.md`.
    - *"Esto es código de prueba, no importa"* — escribir mocks,
      seeds o fixtures con datos que parecen reales pero no lo son.
    - *"El usuario quiere lo mismo que la última vez"* — repetir
      patrón de sesión previa sin verificar contexto actual.
13. **Pre-flight check antes de toda acción** — antes de implementar,
    desplegar o cerrar una feature, el agente lee el estado actual
    (`status.md`, dependencias, tests recientes, commits sin reflejar)
    y **lo reporta al usuario**. Si algo no cuadra, lo dice y para.
14. **Detecta gaps proactivamente** — si una `R*.*` no tiene tests
    declarados, si una `D-N` lleva semanas en `NEGOTIATING`, si un
    mock no tiene `Ready to unmock`, si el `state` declarado no
    coincide con la derivación del Lifecycle (§6), **el agente lo
    señala sin que el dev tenga que pedirlo**.
15. **Cierra reportando estado + siguiente paso** — toda interacción
    termina con tres líneas: (a) qué hizo, (b) qué quedó pendiente,
    (c) cuál es el siguiente paso sugerido. El dev nunca debería
    preguntarse "¿y ahora qué?".
16. **Confirma antes de lo irreversible** — el agente materializa por
    su cuenta acciones reversibles (escribir archivos, draftear
    contratos). Para acciones irreversibles (`git push`, abrir work
    items en backlogs de otros equipos, mover un contrato a `AGREED`,
    deploy a prod) **pide OK explícito** antes de ejecutar.
17. **Distingue lo que sabe de lo que asume** — si opera con
    información posiblemente desactualizada (memoria de sesión
    anterior, supuesto sobre stack), lo declara: *"asumo que sigues
    en Node 20 según `CLAUDE.md`, ¿correcto?"*.
18. **Claridad de jerga: define términos al primer uso por sesión**
    — la metodología tiene vocabulario propio (gates G0-G6, estados
    `partial-deploy-*`, tipos de bug A/B/C/D/E, conceptos
    Initiative/Feature/Task, modality, D-N, AMD-N, etc.) que es
    eficiente entre quienes la conocen pero **opaco** para
    principiantes. Cuando el agente mencione un término técnico de
    la metodología, debe **definirlo en línea la primera vez en la
    sesión** o usar la descripción humana con la sigla sólo como
    referencia secundaria.

    Ejemplo malo: *"¿Firmamos G2?"*
    Ejemplo bueno: *"¿Aprobamos requirements + design firmados?
    (gate G2 — autoriza pasar a implementación. Glosario rápido en
    §3 *Glosario*.)"*

    Versión más corta cuando el dev ya ha visto el término:
    *"¿Aprobamos requirements + design? (gate G2)"*

    Referencia: §3 *Glosario rápido* abajo.

> En conjunto, estos siete principios convierten al agente en un
> **colaborador conversacional**, no en un ejecutor procedimental. El
> dev no memoriza la metodología — la metodología vive en los agentes
> y los slash commands, y el dev la **descubre** a través de la
> conversación. El protocolo operacional concreto está en §7.

### Glosario rápido

Vocabulario AI-DLC frecuente. El agente lo usa como referencia
cuando aplica el principio §3.18 *Claridad de jerga*. Cuando aparezca
una sigla nueva en la sesión, el agente expande la primera vez con la
descripción de esta tabla.

| Término | Qué significa | Detalle |
|---|---|---|
| **G0** | Discovery cerrado | La spec existe — `requirements.md` y `design.md` escritos, aunque no firmados todavía. |
| **G1** | Initiative aprobada | Sólo aplica si la feature pertenece a una Initiative (nivel 0, opcional). |
| **G2** | Requirements + design firmados | Autoriza pasar a implementación. Es **el gate más importante** del flujo SDD — la spec está aprobada y se vuelve contrato. |
| **G3** | Code review aprobado | PR de implementación mergeable. |
| **G4** | QA sign-off | Tests verdes en el ambiente QA (cuando aplica). |
| **G5** | Ops sign-off | Rollout plan aprobado, deploy autorizado. |
| **G6** | Live | Feature al 100% en producción. |
| **`partial-deploy-<env>`** | Estado intermedio del lifecycle | Spec implementada y deployed al ambiente `<env>` (típicamente `pruebas` o `qa`), no aún en `main`. Ver §6 *Lifecycle*. |
| **`feature-complete`** | Spec implementada al 100% pero no deployed a prod | Estado previo a `live`. |
| **`deployed:<env>`** | Spec en producción para ambiente `<env>` | Para libraries: equivale a publicada al registry. |
| **`legacy`** | Feature en prod sin spec retroactiva | §6 *Lifecycle* + §15 *brownfield strangler*. Gradúa a `live` cuando se re-toca. |
| **Tipo A / B / C / D / E** | Taxonomía de bugs (§8) | A = implementation (código), B = spec gap (caso no contemplado), C = spec ambigua, D = critical hotfix, E = external dependency (3rd party). |
| **Initiative** | Nivel 0 de la jerarquía de specs (opcional) | Coordina specs cross-equipo/cross-repo. Mapea a Epic en ADO. |
| **Feature spec** | Nivel 1 (obligatoria) | Unidad atómica de SDD. Mapea a Feature en ADO (o User Story si el equipo no usa Features, §13). |
| **Task** | Nivel 2 | Item dentro de `tasks.md`. Mapea a User Story en ADO. |
| **`R*.*`** | Requirement EARS numerado | `R1.1`, `R1.2`, `R3.4`... — identificador estable que se referencia desde commits, tests y PRs. |
| **`D-N`** | External Dependency numerada | Algo que la feature necesita y aún no existe — endpoint de otro equipo, librería, componente de diseño. Estados: `NEGOTIATING` / `AGREED` / `IMPLEMENTED` / `LIVE`. |
| **`AMD-NNN`** | Amendment | Cambio post-aprobación (cliente, legal, negocio). NO es bug Tipo B. |
| **`BUG-NNN`** | Bug registrado en `bugs.md` | Con tipo (A/B/C/D/E) y `R*.*` afectada. |
| **`HANDOFF-NNN`** | Cambio de ownership de una spec | Entre devs (`/spec-handoff`) o entre equipos (`/spec-handoff --to-team`, v0.18+). |
| **`OPEN_QUESTION`** | Pregunta no resuelta, dueño + due | Bloquea aprobación (gate G2). Se documenta en la sección correspondiente de la spec. |
| **Modality** | Tipo de feature según naturaleza | `code` (default), `config-only`, `data-migration`, `catalog-only`, `docs-only`, `refactor-only`. Cambia qué gates aplican. |
| **Service Agent** | El agente del repo del servicio | Implementa specs, ejecuta `/spec-*`. Conoce el stack del repo. |
| **Architect Agent** | Coordinador cross-team / cross-repo | Maneja Initiatives, fan-out, sync. NO implementa. |
| **Discover-first** | Modo del agente al consultar trackers ADO (v0.17) | Default brownfield. Refleja jerarquía existente; sólo crea si hay gap. |
| **Categoría A vs B** | AI infra previa al adoptar AI-DLC (§15) | A = tool externo (Cursor/Copilot/...), B = custom interna del equipo. |
| **Harness** | Todo lo que rodea al modelo y lo convierte en agente operativo | `AGENTS.md`, slash commands, MCPs, sandbox, hooks, memoria de sesión, contexto cargado. Slogan: `Agent = Model + Harness`. AI-DLC tooling-agnostic — el harness concreto lo elige cada repo (Claude Code, Cursor, OpenCode, Codex, etc.). |
| **Harness engineering** | Disciplina hermana de SDD | Diseñar el harness para que el agente sea disciplinado *por construcción*, no por buena voluntad del modelo. En AI-DLC se manifiesta en: §7 *Consejo/Garantía/Bloqueo* (capas de enforcement), §8 *Ratchet harness* (cierre de bugs B/C contra el agente), §10 *Inventario de archivos* (qué se carga en sesión), §15 sub-protocolo AGENTS.md (4 categorías + appended-section). |
| **Ratchet harness** | Mecanismo de cierre de bugs Tipo B/C cuando el gap es **una clase** | El fix codifica la prevención de vuelta al harness (AGENTS.md, slash-command, plantilla EARS, `spec-lint`, hook de CI) además del `R*.*` en la spec. Trazabilidad: `Harness PR:` en `bugs.md`. Detalle en §8. |
| **`.ai-dlc-version` (manifiesto)** | Archivo al root del target con el estado de adopción AI-DLC | Versión instalada + bloque `files:` per-archivo con `role` y `sha256_at_install`. Habilita `--upgrade` safe. Schema en ADOPT.md P4.2 paso 11. |
| **Role** (`owned`/`bracketed`/`template`/`user`) | Categoría de cada archivo AI-DLC en el manifiesto | Define el algoritmo de upgrade. Tabla canónica en §15 *Upgrade*. `owned` = AI-DLC manda; `bracketed` = sólo entre sentinels; `template` = additive merge; `user` = nunca tocado. |
| **Sentinels `ai-dlc:section-start/end`** | Comentarios HTML que delimitan territorio AI-DLC dentro de un archivo compartido | `<!-- ai-dlc:section-start v=<X> --> ... <!-- ai-dlc:section-end -->`. Adentro = AI-DLC (reemplazable en upgrade); afuera = usuario (intocable). |
| **`--upgrade`** | Modo de `/adopt` para reconciliar un repo ya adoptado contra una versión nueva del methodology | Variante de las 6 fases. P3.U genera plan; P4.U lo aplica per-archivo según `role`. Detalle en ADOPT.md *Modo `--upgrade`*. |

### Lista canónica de acciones irreversibles (§3.16)

Cuando el agente está por ejecutar una de estas acciones, **siempre
pide OK explícito** al humano antes. Esto operacionaliza el principio
§3.16 *Confirma antes de lo irreversible*:

| Acción | Por qué irreversible | Quién aprueba |
|---|---|---|
| `git push` a rama compartida | Cambio visible para todos; revertir es ruidoso | Dev de la feature |
| `git push --force` a cualquier rama | Reescribe historia | Dev + tech lead |
| `git worktree remove` | Borra el cwd con cambios no commiteados | Dev de la feature |
| Borrar rama remota | Pérdida del historial visible | Dev de la feature |
| Abrir PR | Visible para reviewers y consumidores del repo | Dev de la feature |
| Mover una `D-N` a `AGREED` | Compromete a ambos equipos al contrato | Dev consumidor + confirmación del equipo proveedor |
| Publicar contrato breaking en `.org/contracts/` | Rompe consumidores existentes | Owner del contrato (proveedor) + ciclo de deprecación |
| Mergear Amendment con `R*.*` tachadas | Cambia el contrato funcional | Tech lead + stakeholder origen del cambio |
| Crear work item en project ADO de otro equipo | Aparece en el backlog ajeno | Tech lead consumidor + confirmación del otro lado |
| Deploy a `main` (producción) | Visible para usuarios reales | Tech lead + Ops sign-off + rollout-plan aprobado |
| `oc rollout undo` | Revierte deploy en prod | Ops on-call |
| Cancelar feature `live` (flag `OFF` y borrar código) | Pérdida de funcionalidad visible | Tech lead + `AMD-NNN` documentando |
| Eliminar feature flag con tráfico activo | Equivalente a cancelar `live` | Igual que arriba |
| `oc delete <recurso>` en namespace compartido | Afecta a otros servicios | Ops on-call |
| Borrar mock activo de una `D-N` no `LIVE` | Rompe tests del consumidor | Dev de la feature |

**Acciones reversibles** (el agente las ejecuta sin OK explícito):
escribir/editar archivos locales, crear/editar specs, draftear
contratos, correr tests / lint / typecheck, mover tasks de estado
dentro de `status.md`, hacer commits **locales** (sin push), crear
worktrees, generar resúmenes.

Ante duda: el agente **pregunta** (§3.12).

---

## Las 7 fases del AI-DLC

### Fase 1 — Intent Capture (captura de intención)

- Conversación entre humano y agente sobre **qué** se quiere lograr.
- Agente hace preguntas clarificadoras (ambigüedades, edge cases, stakeholders).
- **Sin código aún**. Solo entendimiento.
- **Output**: una conversación cristalizada, lista para formalizar.

### Fase 2 — Specification (especificación)

- La conversación se convierte en tres artefactos versionados:
  - `requirements.md` — EARS (qué)
  - `design.md` — arquitectura (cómo)
  - `tasks.md` — desglose ejecutable
- **Output**: PR de "spec" revisado por stakeholders (PM, arquitectura, legal).

### Fase 3 — Planning (planificación)

- Agente descompone la spec en plan de implementación.
- Identifica dependencias, archivos a tocar, orden de ejecución.
- **Output**: plan aprobado por humano *antes* de generar código.

### Fase 4 — Generation (generación)

- Agente escribe código + tests siguiendo la spec.
- Itera autónomamente hasta que linter, type checker y tests pasan.
- **Output**: PR de "code" referenciando los requirements cubiertos.

### Fase 5 — Verification (verificación)

- Validar que el código cumple la spec:
  - Cada `R*.*` tiene tests.
  - Cada test tiene trazabilidad (`// Derived from R*.*`).
  - Security scan, SAST, SCA.
- **Output**: reporte de cobertura de spec + revisión humana focalizada.

### Fase 6 — Integration & Deployment

- CI/CD ejecuta pipeline (Azure DevOps).
- Pipeline despliega en OpenShift.
- Agentes asisten: generan changelogs, descripciones de PR, release notes.
- **Output**: feature en producción tras gates aprobados.

### Fase 7 — Evolution (evolución)

- Cambios entran **por la spec**, no por el código.
- Bugs se clasifican y enrutan según taxonomía (ver [Manejo de bugs](#manejo-de-bugs)).
- Métricas alimentan retroalimentación: ¿qué specs fallaron más?

---

## Specs en formato EARS

**Easy Approach to Requirements Syntax** — propuesto por Alistair Mavin (Rolls-Royce).
Cinco plantillas que eliminan ambigüedad:

| Patrón | Plantilla | Uso |
|---|---|---|
| **Ubiquitous** | `THE SYSTEM SHALL <acción>` | Siempre se cumple |
| **Event-driven** | `WHEN <trigger>, THE SYSTEM SHALL <acción>` | Reacción a evento |
| **State-driven** | `WHILE <estado>, THE SYSTEM SHALL <acción>` | Mientras dura un estado |
| **Optional** | `WHERE <feature>, THE SYSTEM SHALL <acción>` | Si está habilitada una opción |
| **Unwanted** | `IF <condición>, THEN THE SYSTEM SHALL <acción>` | Manejo de errores |

### Ejemplo

```markdown
### R1 — Solicitud de reset de contraseña

**R1.1** WHEN un usuario no autenticado envía una solicitud de password reset
con un email, THE SYSTEM SHALL aceptar la solicitud y responder con HTTP 202
en menos de 500ms, independientemente de si el email existe.

**R1.2** WHEN se acepta una solicitud para un email registrado, THE SYSTEM SHALL
generar un token criptográficamente seguro de al menos 256 bits de entropía.

**R1.3** WHEN se genera un token, THE SYSTEM SHALL almacenar únicamente el hash
SHA-256, nunca el token en claro.

**R1.4** IF la generación o envío del email falla, THEN THE SYSTEM SHALL
registrar el error en logs estructurados sin exponer información al cliente.
```

### Reglas obligatorias

1. **Numeración estable** — `R1.1, R1.2, ...` referenciables en commits, PRs, tests.
2. **Una acción por requirement** — si tiene "y", divídelo.
3. **Sin "cómo"** — el "cómo" va en `design.md`.
4. **NFRs medibles** — "rápido" ❌ → "p99 < 500ms" ✅.
5. **Casos negativos explícitos** — si la spec no dice qué hacer ante X, alguien lo
   inventará (mal).
6. **Estrategia de pruebas declarada** — cada `R*.*` indica qué niveles de
   prueba lo cubren. Sintaxis sugerida (anexa al requirement):

   ```
   R1.2 — WHEN ... THE SYSTEM SHALL ...
          Tests: unit, integration
   ```

   Niveles válidos: `unit`, `integration`, `e2e`, `contract`, `load`,
   `accessibility`, `security`, `none` (este último con justificación
   explícita). Si la spec no lo declara, el agente lo propone durante
   `/spec-new` y pide confirmación antes de implementar. Permite que
   `/spec-status` reporte cobertura por nivel, no sólo cobertura global.
7. **`OPEN_QUESTIONS` con owner y deadline** — toda pregunta no
   resuelta durante la entrevista de `/spec-new` queda registrada como
   `OPEN_QUESTION` en la spec, con `owner:` (responsable de cerrarla)
   y `due:` (fecha máxima). El `status` de la feature **no puede pasar
   a `approved`** mientras queden preguntas abiertas; `/spec-status`
   las reporta y `/spec-verify` falla si alguna excedió su `due`.
   Formato:

   ```
   - [ ] <pregunta> — owner: @<persona>, due: <YYYY-MM-DD>
   - [x] <pregunta resuelta> — owner: @<persona>, due: <YYYY-MM-DD>,
         resuelto: <YYYY-MM-DD> con <decisión corta>
   ```

   Esto evita el anti-pattern típico: la spec se "aprueba" con
   preguntas abiertas que se resuelven en chat y se olvidan, y el
   código termina implementando una decisión que nadie registró.

---

## Specs jerárquicas: Initiative (opcional) → Feature → Task

La **Feature** es la unidad obligatoria: una feature por funcionalidad,
viviendo en el repo del servicio que la implementa (principio
**spec locality**, §3). La **Initiative** es un artefacto **opcional**
de coordinación, sólo cuando una iniciativa de negocio se reparte
deliberadamente en N repos/equipos.

```
<repo-del-servicio>/                   ← obligatorio
└── specs/<feature>/                   ← Nivel 1: SIEMPRE
    ├── requirements.md                ← EARS + Tests strategy
    ├── design.md
    ├── tasks.md                       ← Nivel 2
    ├── status.md
    ├── bugs.md
    └── amendments.md                  ← si hubo cambios post-aprobación

<repo-de-iniciativas>/                 ← Nivel 0: SÓLO si aplica
└── initiatives/<initiative-slug>/
    ├── overview.md                    ← qué, por qué, KPIs
    ├── stakeholders.md
    ├── constraints.md
    ├── architecture.md                ← qué servicios tocar
    ├── rollout-plan.md
    ├── decisions/                     ← ADRs
    └── features-index.md              ← apunta a specs/<feature> en cada repo
```

### Niveles

| Nivel | Nombre | Obligatorio | Owner | Contenido | Vive en |
|---|---|---|---|---|---|
| 0 | Initiative | **Opcional** | PM + arquitecto líder | Problema, KPIs, scope, restricciones cross-servicio | Repo separado de iniciativas |
| 1 | Feature | **Sí** | Tech lead del servicio | EARS + tests strategy, design, tasks de **un** servicio | El repo del servicio |
| 2 | Task | **Sí** | Dev / agente | Implementación atómica | El repo del servicio (en `tasks.md`) |

### Cuándo usar Initiative

| Caso | ¿Initiative? |
|---|---|
| Requerimiento toca **un** servicio | ❌ No. La feature sola basta. |
| Toca varios servicios del **mismo equipo** | ⚠️ Discrecional. Si la coordinación interna es informal, N features + un canal de chat suelen alcanzar. |
| Toca varios servicios de **equipos distintos** | ✅ Sí — para que cada equipo entienda su parte del todo. **Pero la Initiative es informativa, no autoritativa** (principio §3.8): cada equipo lleva su feature en su backlog sin pedir permiso al "dueño" de la Initiative. |
| Programa estratégico con stakeholders externos (legal, finanzas, comité) | ✅ Sí — documenta el "por qué" para auditoría. |

Cuando existe, la Initiative **no bloquea** el inicio de las features.
Las features arrancan en paralelo apenas el contrato cross-repo esté
acordado (principio §3.9 *Contract as handshake*). Cada feature
**puede** referenciar su Initiative con un enlace en el frontmatter o
en el header de `requirements.md`; nunca es prerrequisito de
arranque.

### Modalidades de feature

No toda feature es código de aplicación. La metodología contempla 6
modalidades; cada una **relaja qué artefactos son obligatorios** sin
romper el principio spec-driven:

| Modalidad | Cuándo aplica | Artefactos obligatorios | Opcionales |
|---|---|---|---|
| `code` (default) | Funcionalidad nueva o cambio de comportamiento en código | `requirements.md` (EARS + Tests strategy), `design.md`, `tasks.md`, `status.md`, código + tests | `bugs.md`, `amendments.md`, `mocks/`, `rollout-plan.md` |
| `config-only` | Cambio de flag, env var, ConfigMap, política — sin código nuevo | `requirements.md` corto (EARS describe el cambio de comportamiento + tests de validación), `status.md` | `design.md` omitido o 1 párrafo; `tasks.md` opcional |
| `data-migration` | Script de migración, backfill, ETL one-shot, schema change | `requirements.md` (EARS sobre estado antes/después), `design.md` con DDL + plan de rollback + plan de backfill, `tasks.md`, `status.md`. Ver § *Data migrations (patrón expand-contract)* abajo. | `bugs.md` |
| `catalog-only` | Publicar, versionar o deprecar un contrato en `.org/contracts/` | `requirements.md` muy corto (qué contrato, SemVer bump, breaking?), PR sobre `.org/contracts/` con consumidores notificados | `design.md`, `tasks.md`, `status.md` mínimos o ausentes |
| `docs-only` | Runbook, ADR, política, doc de onboarding | `requirements.md` mínimo (qué doc, qué audiencia, criterio de "completo"), `status.md` | Resto opcional |
| `refactor-only` | Rename, extract function, reorganización de archivos, optimización interna **sin cambio de comportamiento observable** | `status.md` (1-2 líneas: qué se refactorizó y por qué), tests existentes verdes pre y post (gate obligatorio) | `requirements.md` y `design.md` omitidos (no hay `R*.*` nuevos ni modificados) |

**Cómo se declara**: en el frontmatter de `requirements.md` (o
`status.md` si la modalidad no exige `requirements.md`):

```yaml
---
feature: <slug>
modality: code | config-only | data-migration | catalog-only | docs-only | refactor-only
...
---
```

Default `code` si se omite. El Service Agent en `/spec-new`
**pregunta** la modalidad cuando detecta señales (ej. el dev dice
*"sólo voy a tocar un flag"* → propone `config-only`; *"voy a renombrar
estas funciones para que sean más claras"* → propone `refactor-only`).
`/spec-verify` ajusta sus checks según la modalidad (no exige
`design.md` si `modality: catalog-only`, etc.).

**Anti-pattern `refactor-only`**: cambiar comportamiento "incidentalmente"
durante un refactor — ej. renombrar una función Y cambiar su default,
todo en el mismo PR. Si los tests existentes capturan el cambio, fallan
(detección automática). Si NO los capturan, es un bug Tipo B disfrazado
(la spec original no cubría ese caso → debió haberse hecho como
`modality: code` con nuevo `R*.*`). Regla simple: si el PR cambia el
comportamiento que un usuario / consumidor pueda detectar, **NO** es
`refactor-only`.

### Spikes y exploración (pre-spec)

A veces el equipo no sabe si una idea es viable hasta probarla con
código. SDD estricto (§3.12) prohíbe "código sin spec", pero **un
spike es código que produce una spec, no que la implementa** — la
restricción no aplica si el output es una decisión informada, no
producto. La metodología contempla este caso explícitamente.

**Patrón**:

- **Rama**: `spike/<slug>` (NO `feat/`), creada desde la rama base
  declarada en `repo-config.yaml`. El prefijo `spike/` declara
  visualmente que el código es throwaway.
- **Time-box explícito**: default 2 semanas; declarar `due:` en el
  `spike-output.md` al arrancar. Spikes sin `due` o vencidos se
  reportan en `/spec-verify` como warning.
- **Output obligatorio**: `specs/spikes/<slug>/spike-output.md` con:
  - Pregunta original que el spike responde.
  - Lo aprendido (qué funciona, qué no, qué costaría, qué riesgos).
  - **Decisión**: `kill` (matar), `promote` (promover a feature
    spec), o `freeze` (congelar para re-evaluar después con razón).
  - Si `promote`: link al `requirements.md` resultante (que el autor
    del spike escribe **basado en** lo aprendido, no del código).
- **El código del spike es throwaway por defecto**: NO se mergea a
  `pruebas` ni a ningún ambiente promotable. Si la decisión es
  `promote`, se **descarta** el código del spike y la feature se
  implementa con SDD normal (`/spec-new`) — el spike sirvió para
  informar la spec, no para evitarla.
  - Excepción justificada: piezas pequeñas y bien delimitadas del
    spike (helper functions, schemas validados, type definitions)
    pueden trasplantarse al PR de la feature nueva, declarándolo
    explícitamente en el commit message
    (`Reused from spike/<slug>`).

**Cuándo NO usar spike**:

- Si ya sabés qué construir y cómo: ir directo a `/spec-new`.
- Si el "spike" es realmente un POC que el negocio quiere demostrar:
  ese es un feature con `modality: code` y `status.md` que dice
  *"demo, no producción"* — no un spike.
- Si pasarás más de 2 semanas: probablemente no es un spike — es una
  feature mal definida. Volver a `/spec-new` con `OPEN_QUESTIONS`
  para descomponer.

**Slash command futuro**: `/spike-new <slug>` para arrancar un spike
con scaffolding mínimo; `/spike-conclude <slug>` para forzar la
decisión y cerrar. Hoy es manual.

**Anti-pattern**: *"spike eterno"*. Si pasaron 2 semanas y no hay
decisión, el spike se cancela explícitamente (no se renueva
silenciosamente). Documentar por qué se cerró sin decisión —eso es
información útil (*"se acabó el sprint y nadie tuvo tiempo"*,
*"el problema cambió"*, *"falta de stakeholder para validar"*) — y
abrir un nuevo spike si la pregunta sigue vigente.

### Data migrations (patrón expand-contract)

`modality: data-migration` cubre varios casos distintos. Los más
delicados son los **online** (la app sigue en producción mientras
migra el schema). El patrón canónico es **expand-contract** (también
conocido como *parallel change*):

**Fases**:

1. **Expand** (deploy a `pruebas`):
   - Agregar columna nueva (nullable) o tabla nueva.
   - Código escribe a la columna/tabla nueva (*dual-write*).
   - Código sigue **leyendo** de la columna/tabla vieja como fuente
     de verdad.
   - Tests cubren ambas escrituras.

2. **Backfill** (offline, post-deploy a `pruebas` o `qa`):
   - Job que rellena la columna nueva para filas existentes.
   - Lote pequeño (batch size declarado en `design.md`), **idempotente**
     y **resumible**.
   - Si falla a mitad, retomar desde el último checkpoint — no
     reiniciar.
   - Monitorear progreso con log estructurado y métricas.

3. **Switch** (deploy a `qa` / `main`):
   - Código **lee** de la columna nueva como fuente de verdad.
   - Sigue **escribiendo** a la vieja por compatibilidad (todavía
     dual-write).
   - Verificar invariantes (counts match, sumas iguales) antes de
     pasar a Contract.

4. **Contract** (deploy posterior, ≥ 1 release después de Switch):
   - Código deja de escribir a la columna vieja.
   - Drop de la columna vieja (irreversible).
   - Esto vive en un `data-migration` **distinto**, marcado
     `irreversible: true` en `design.md` — gate G6 (rollout) + DBA
     sign-off explícito + ventana de mantenimiento si aplica.

**Reglas operacionales**:

- **`design.md` obligatorio** (no opcional como en `config-only`):
  - DDL del cambio (SQL exacto, no descripción).
  - Plan de **rollback** por fase (Expand y Switch son reversibles;
    Backfill es idempotente; Contract NO es reversible — sólo desde
    backup).
  - **Plan de backfill**: batch size, idempotencia, ETA estimada.
  - **Plan de verificación**: queries que confirman invariantes
    (counts, sumas, no-NULL en filas esperadas).
- **`status.md` track de fases**: una task por fase
  (`T1 Expand, T2 Backfill, T3 Switch, T4 Contract`) con commits
  separados. Estados de feature pueden ir
  `partial-deploy-pruebas` → `partial-deploy-qa` por fase.
- **Gates extra**:
  - G3 (plan/tasks) requiere **DBA sign-off** además del tech lead.
  - G6 (rollout a prod) requiere DBA presente o disponible.
  - Migraciones contra DB con >10M filas: **ventana de cambio
    acordada**, aunque el patrón sea online (porque backfill consume
    IOPS).
- **Rollback en Switch**: si tras Switch se descubre un bug — código
  vuelve a leer columna vieja (toggle vía feature flag), columnas
  siguen co-existiendo, dual-write activo. **NUNCA hacer Contract**
  sin haber observado ≥1 release sin bugs en Switch.

**Migraciones offline** (con downtime): mismo patrón pero más simple
— la ventana de mantenimiento elimina la necesidad de dual-write.
Sigue requiriendo `design.md` con DDL + rollback + comunicaciones al
usuario final.

**Anti-pattern**: *"big-bang migration"*. Dropear columna vieja en el
mismo PR que la agrega/migra. Imposible rollback sin restore desde
backup. Si la presión del negocio lo exige, marcar `irreversible:
true` y exigir gate explícito con DBA + Ops + comms al usuario — pero
es desaconsejado.

**Cuándo NO es `data-migration`**:

- **ETL recurrente / job programado**: es código normal
  (`modality: code`) con tests específicos de transformación. La
  modalidad `data-migration` es para cambios *one-shot*, no para
  pipelines vivas.
- **Schema inicial de servicio nuevo sin datos productivos**: si es
  un servicio nuevo sin datos en prod, es código normal — no se
  aplica el patrón expand-contract (no hay nada que migrar).
- **Cambio de configuración de DB** (índice nuevo, tuning de
  parámetro): es `config-only` si no requiere movimiento de datos.

### External Dependencies, Contract-First y Mocks

Casi ninguna feature es self-contained. Si una feature **espera** a
todas sus dependencias antes de arrancar, los principios §3.8
(*no coordinator*) y §3.10 (*partial deploy by default*) se rompen en
la práctica. Esta sección define cómo modelar dependencias externas
para que el desarrollo paralelo sea viable y trazable, sin añadir
burocracia.

#### Sección `Dependencies` en `requirements.md`

Cada feature lista sus dependencias externas en una sección dedicada,
identificadas como `D1, D2, ...` (formato análogo a `R*.*`):

```markdown
## Dependencies

### D1 — POST /sso/exchange-token (identity-api)
- **Tipo**: humana (team-identity, project `identity-platform`)
- **Estado**: AGREED                     (NEGOTIATING|AGREED|IMPLEMENTED|LIVE)
- **Contrato**: `.org/contracts/apis/identity-sso.openapi.yaml` v1.2.0
- **Owner**: team-identity / @alice
- **Tracking**: ADO https://dev.azure.com/<org>/identity-platform/_workitems/edit/45123
- **ETA**: sprint 2026-06-W2 (informativo, no bloquea T1-T7)
- **Estrategia**: MOCK hasta LIVE
- **Mock**: `mocks/identity-sso.mock.json`
- **Ready to unmock**: endpoint desplegado a staging de identity

### D2 — Stored procedure sp_calcular_puntos
- **Tipo**: técnica (mismo equipo, otro repo: `dba-scripts`)
- **Estado**: AGREED
- **Contrato**: signature acordada con DBA el 2026-05-14
  (ver `mocks/sp_calcular_puntos.sql`)
- **Estrategia**: MOCK con stored proc dummy en BD de dev

### D3 — Stripe Webhooks v1 (vendor 3rd party)
- **Tipo**: externa (Stripe Inc.)
- **Estado**: AGREED (basado en docs públicos congelados)
- **Contrato**: https://docs.stripe.com/api/events @ commit del PR
- **Owner**: vendor — N/A internamente
- **Tracking**: ticket Stripe support #ABC-1234 (si hay duda activa)
- **ETA**: N/A (depende del vendor)
- **Estrategia**: MOCK con fixtures versionadas en `mocks/`
- **Mock**: `mocks/stripe-webhook.mock.json`
- **Ready to unmock**: webhook real recibido en `pruebas` tras
  configurar endpoint en el dashboard de Stripe
```

**Estados**:

| Estado | Significado |
|---|---|
| `NEGOTIATING` | Contrato propuesto, esperando confirmación del otro lado |
| `AGREED` | Contrato confirmado. El mock es la "fuente de verdad" mientras tanto |
| `IMPLEMENTED` | El proveedor ya implementó, pero no está deployado donde la feature lo consume |
| `LIVE` | Disponible en el ambiente que la feature necesita |

**Tipos**:

| Tipo | Origen | Tracking típico |
|---|---|---|
| `humana` | Otro equipo de la misma org (mismo team project u otro distinto) | URL al work item en el project ADO del proveedor |
| `técnica` | Pieza interna no lista (SP, librería, configuración, infra) | URL al ticket interno o PR del proveedor de la pieza |
| `externa` | Vendor 3rd party / SaaS / open source (sin ADO accesible) | URL al ticket de soporte del vendor, al issue del repo público, o al canal de comunicación |

> Una `D-N` de tipo `externa` típicamente usa estrategia `MOCK` (si el
> contrato del vendor es estable) o `PIN` (si la dependencia es un
> paquete con bug Tipo E, §8). El bump a `LIVE` puede tardar lo que
> tarde el vendor — aplicar las SLAs de §6 con tolerancia mayor y
> documentar el ETA del vendor (si lo dan) en el campo `ETA:`.

**Estrategias**:

| Estrategia | Cuándo aplicarla |
|---|---|
| `MOCK` | Default. El contrato existe; se implementa contra mock; cuando D pasa a `LIVE`, se desmockea. |
| `BLOCK` | Cuando trabajar contra mock no aporta nada (la feature depende esencialmente del comportamiento real). Raro — usar con justificación. |
| `PIN` | Dependencia es un paquete con bug Tipo E: fijar versión sana hasta release nuevo. |
| `WORKAROUND` | Parche local hasta que la dependencia esté disponible (con `TODO` referenciando la D). |

#### Contract-First: el contrato es el acuerdo

Para una dependencia humana (otro equipo), el flujo es:

1. **Drafteo el contrato** que necesito (OpenAPI / AsyncAPI / SQL
   schema / event schema). No espero a que el otro equipo lo escriba.
2. **Registro la dependencia** en mi `requirements.md` como `D-N` con
   estado `NEGOTIATING`.
3. **Envío al otro equipo** el draft + mi caso de uso. Bilateral, sin
   reunión de gate (principio §3.11 *declared, not approved*).
4. **El otro equipo evalúa**: acepta tal cual, propone ajustes o
   rechaza. Cuando hay acuerdo, el contrato pasa a `AGREED` y se
   versiona en `.org/contracts/` (o, si no hay catálogo aún, en el
   repo del proveedor con un tag SemVer).
5. **Ambos equipos arrancan en paralelo**: yo implemento contra mock,
   ellos implementan contra el contrato. Su feature vive en su repo
   con su propia spec; la mía vive en el mío. **No hay Initiative
   coordinadora** (principio §3.8).
6. **Cuando el proveedor entrega y deploya**, D pasa a `LIVE`. Yo
   desmockeo las tasks marcadas `blocked_by: D<n>=LIVE`.
7. **Si al integrar hay mismatch**, es un bug normal — se clasifica
   por el origen:
   - Tipo A: el implementador hizo algo distinto al contrato.
   - Tipo B: faltó un caso en el contrato.
   - Tipo C: el contrato era ambiguo.
   - Tipo E: la pieza es un paquete 3rd party con bug.

   **El contrato decide**: si el contrato y la realidad difieren, gana
   el contrato (versión vigente). Si la realidad debe cambiar, se
   bumpea el contrato y se notifica a todos los consumidores.

El contrato es **el único artefacto compartido** entre los dos equipos.
Es SDD entre equipos: el contrato es la spec del límite.

#### Resolución de conflictos consumidor ↔ proveedor

Cuando dos consumidores del mismo contrato discrepan, o cuando el
contrato y la implementación real divergen al desmockear, hay reglas
de arbitraje claras:

| Situación | Quién decide | Cómo se resuelve |
|---|---|---|
| Dos consumidores interpretan el contrato distinto | El **proveedor** (owner del contrato) arbitra | Publica nota clarificadora o bumpea el contrato a versión que elimine la ambigüedad. |
| Contrato y realidad difieren al desmockear | **El contrato decide** (es la spec, §3.1) | Si el contrato es correcto: fix en la implementación (Tipo A del proveedor). Si la realidad es la correcta: bumpear contrato, notificar consumidores con deprecation path. |
| Contrato ambiguo (ambos lo interpretaron de buena fe) | Bug **Tipo C contra el contrato**, no contra ninguna spec consumidora | Proveedor refina el contrato; consumidores ajustan mocks tras el bump. |
| Consumidor necesita campo nuevo | Bilateral; si proveedor acepta, **bump menor** compatible; si no, `WORKAROUND` en consumidor | No es bug del proveedor — es ampliación de `D-N` o nueva. |

**Principio operacional**: nunca se arregla un mismatch
*silenciosamente* en el consumidor (parchando el mock para que coincida
con la realidad observada). Eso enmascara el problema. Todo mismatch
genera una **decisión visible**: bump del contrato, bug del proveedor,
o `WORKAROUND` con TODO referenciando la `D-N`.

#### Mocks como ciudadanos de primera clase

Los mocks no son un hack; son artefactos versionados de la spec.

```
specs/<feature>/
├── requirements.md           ← declara D1, D2... y `Tests strategy`
├── design.md
├── tasks.md                  ← tasks con [D1], [D1=LIVE], [D2], ...
├── status.md                 ← estado de feature + lifecycle de tasks (ver Lifecycle ↓)
├── bugs.md
├── amendments.md
└── mocks/
    ├── identity-sso.mock.json
    ├── sp_calcular_puntos.mock.sql
    └── README.md             ← cómo activar los mocks en local/dev
```

En `tasks.md` las tasks declaran sobre qué dependencia trabajan:

```
T6  — E2E con mock de identity-sso              [R3.2, D1]
T7  — Implementar lógica de canje               [R4.1, D2]
T8  — Integración real con identity-sso         [R3.2, D1=LIVE]   ← blocked
T9  — Integration test con sp_calcular_puntos   [D2=LIVE]         ← blocked
```

`status.md` registra las tasks bloqueadas con su causa (formato
completo definido más abajo en *Lifecycle de feature y task*):

```yaml
state: partial-deploy-pruebas
feature_flag:
  name: <flag-name>
  envs: { pruebas: ON, qa: OFF, main: OFF }

# en la sección de tasks:
T8:  blocked  | blocked_by: D1=LIVE
T9:  blocked  | blocked_by: D2=LIVE
```

Una feature con T1-T7 done y T8-T9 bloqueadas por D1/D2 **es
desplegable a dev** (principio §3.10 *partial deploy*), no
"incompleta". El feature flag controla cuándo se enciende para
usuarios reales. `/spec-status` (§11) reporta esto como **progreso
real**, no como "feature a medias".

#### Integración con Azure DevOps cross-team-project (cuando aplica)

Si la dependencia humana es con otro equipo que vive en **otro team
project de ADO**, el patrón es:

1. El otro equipo recibe un **work item** (Feature o User Story) en
   su propio project, no en el mío. Ese work item es **su**
   requerimiento entrante; lo prioriza en **su** backlog.
2. Mi `D-N` lo registra en el campo `Tracking` con URL completa al
   work item externo.
3. Mis commits citan **mi** work item local (`AB#<id>` de mi project).
4. Los dos work items se enlazan con relación **Related** (no Parent),
   manteniendo cada project autónomo (principio §3.8).

**Nada de Epic supraordenado** atravesando team projects. Cada project
conserva su board y sus métricas. La Initiative, si existe, vive en un
solo project (el del equipo que la lidera) y los demás la consultan
por URL.

#### Resumen del modelo

| Pregunta | Respuesta |
|---|---|
| ¿Espero a que el otro equipo termine para arrancar? | **No.** Drafteo el contrato, lo acuerdo, implemento contra mock. |
| ¿Necesito una Initiative para coordinar con el otro equipo? | **No.** El contrato es la coordinación. |
| ¿Quién aprueba la dependencia? | El otro equipo, vía mensaje o work item en su backlog. No un comité. |
| ¿Puedo desplegar a dev con dependencias en mock? | **Sí.** Es el default. |
| ¿Y a producción? | Sí, con feature flag `OFF` hasta que todas las `D` críticas estén `LIVE`. |
| ¿Qué pasa si el mock no coincide con la realidad al desmockear? | Bug normal (A/B/C/E según origen). El contrato es el árbitro. |
| ¿Dónde vive el contrato? | `.org/contracts/` cuando hay catálogo; si no, en el repo del proveedor con tag SemVer, o (peor) compartido bilateralmente como gist/PR. |

### SLAs y escalación de bloqueos

La metodología es anti-burocrática (§3.7-3.11) pero eso no implica
que las cosas puedan estar bloqueadas indefinidamente sin escalación.
Cuando una `D-N` o una task lleva demasiado tiempo parada, hay reglas
claras:

#### Para `D-N` (dependencias externas)

| Estado | Tiempo | Acción |
|---|---|---|
| `NEGOTIATING` | > 10 días hábiles desde el draft del contrato | Escalar al Architect Agent + tech lead del proveedor. Si no hay confirmación en 5 días más, marcar como `NEGOTIATING-stale` y considerar `WORKAROUND` o cancelar la feature. |
| `AGREED` | > 6 semanas sin pasar a `IMPLEMENTED` | El proveedor no avanza. Tech lead consumidor habla con tech lead proveedor; si no se desbloquea, escalar a leads de área. |
| `IMPLEMENTED` | > 2 semanas sin pasar a `LIVE` en mi ambiente | Verificar que el deploy del proveedor cubre `pruebas`/`qa`/`main` que necesito; si no, pedirlo explícitamente. |

#### Para tasks `blocked`

| Tiempo | Acción |
|---|---|
| > 1 semana | `/spec-status` marca la task con bandera amarilla; el agente sugiere revisar la causa del `blocked_by:`. |
| > 4 semanas | **Revisión obligatoria**: decidir entre `BLOCK` real (esperar), `WORKAROUND` (parche local con TODO), o **cancelar la feature** con `AMD-NNN` documentando el motivo. No aceptable dejar una task indefinidamente bloqueada sin decisión. |

#### Para features sin update

| Tiempo desde `updated:` en `status.md` | Acción |
|---|---|
| > 30 días | `/spec-audit` (cron mensual del Service Agent) lo lista; pregunta al owner si la feature sigue viva. |
| > 90 días | Default: mover a `cancelled` con `AMD-NNN — feature stale auditada el <fecha>`. El owner puede reabrir si recupera vida. |

**Quién dispara la escalación**: el Service Agent en su pre-flight
de `/spec-implement` o `/spec-status` **detecta y propone** la
escalación; no la ejecuta sin OK del dev (§3.16). Escalaciones son
acciones reversibles (mensajes / cambios de estado en `status.md`),
no son irreversibles.

**Anti-pattern relacionado**: una `D-N` en `NEGOTIATING` durante meses
con "nadie le pregunta al proveedor" — la dependencia se convirtió en
un placeholder que da falsa sensación de avance. La escalación a 10
días hábiles evita esto (ver también §18 anti-patrón "Dependencia
pedida en chat sin work item").

### Lifecycle de feature y task: estados en `status.md`

`status.md` es el archivo que materializa el progreso real de la
feature. Se actualiza tras cada commit relevante (manualmente o por el
Service Agent al final de `/spec-implement`) y es el insumo principal
de `/spec-status` (§11). Su formato es **YAML simple** para que sea
legible por humanos, agentes y scripts (`spec-lint`, dashboards).

#### Estados válidos de feature

| Estado | Significado |
|---|---|
| `not-started` | Spec aprobada, ninguna task `done`. |
| `in-progress` | Hay tasks `done` o `in-progress`, pero ninguna desplegada todavía. |
| `partial-deploy-pruebas` | Subconjunto de tasks desplegado a `pruebas` (típicamente con mocks activos para `D` aún no `LIVE`). Quedan tasks `pending` o `blocked`. |
| `partial-deploy-qa` | Subconjunto desplegado a `qa`. Las `D` críticas deben estar `LIVE` o tener mock aprobado por QA. |
| `feature-complete` | Todas las tasks `done`, todas las `D` `LIVE`, tests verdes; feature flag aún `OFF` en `main`. |
| `live` | Feature flag `ON` en `main` (parcial o total). |
| `cancelled` | Feature abandonada. Requiere `AMD-NNN` en `amendments.md` explicando por qué. |
| `legacy` | Feature en producción **sin spec retroactiva** (código preexistente al adoptar AI-DLC). `status.md` mínimo (frontmatter + 1-3 líneas de descripción + dueño); no requiere `requirements.md`/`design.md`/`tasks.md`. "Gradúa" a `live` cuando alguien la re-toque y escriba spec retroactiva (§15 *Adopción en proyecto brownfield*). |

> **Nota — nombres y número de ambientes**: `pruebas`, `qa`, `main`
> corresponden al flujo empresarial típico (3 ambientes) para `repo_type: service`. Si
> tu equipo usa otros nombres (`develop`/`staging`/`release`, etc.) o
> tu repo tiene distinto número de ambientes (ej. `repo_type: library`
> con sólo `pruebas`/`main`; `infra` con sólo `sandbox`/`prod`),
> declaralos en `repo-config.yaml` (§6 *Configuración del repo*) y los
> estados pasan a `partial-deploy-<tu-env>` y `deployed:<tu-env>` según
> corresponda.

> **Nota — `status.md` es per-branch, no global**. `status.md` vive en
> `specs/<feature>/status.md` y viaja **con la feature** por PRs. La
> misma promoción `pruebas → qa → main` que promueve el código también
> arrastra el `status.md` actualizado. Por diseño, **distintas ramas
> pueden mostrar distintos estados** de la misma feature
> (`pruebas`: `partial-deploy-pruebas`; `main`: `live`) — eso es
> correcto. La **canonical state** para "qué está en producción" es
> siempre la de `main` (el agente la lee desde ahí cuando importa, no
> desde la rama local).
>
> **No se hace back-merge automático** de `status.md` desde `main` a
> ramas tributarias (`pruebas`, `qa`) — eso dispararía pipelines de
> deploy innecesarios. Las ramas tributarias se actualizan de forma
> natural cuando hay otra promoción adelante, o vía un PR explícito
> `chore/sync-from-main` cuando se necesite (raro). Esto es compatible
> con **branch protection** (PR-only) y **pipelines auto-triggered en
> push**: la promoción de la feature **es** un PR mergeado a la rama
> destino, que dispara el pipeline correspondiente exactamente una vez.

Los estados de **partial-deploy** existen para hacer cumplir el
principio §3.10 *partial deploy by default*: una feature con 7 de 10
tasks listas **es desplegable**, no "a medias".

#### Estados válidos de task

| Estado | Significado |
|---|---|
| `pending` | No iniciada. Sus dependencias previas (otras tasks, `D-N`) están listas o no aplican. |
| `blocked` | No iniciable por falta de algo externo. **Requiere** `blocked_by:` con la causa (otra task, una `D-N`, una decisión humana). |
| `in-progress` | Trabajada activamente, no merged aún. |
| `done` | Merged a la rama de la feature; tests verdes localmente. |
| `deployed:<env>` | `done` **y** desplegada a `<env>` — o **publicada** al registry si `repo_type: library` (§6 *Configuración del repo*). Nombres y cantidad de `<env>` configurables; default empresarial `repo_type: service` = `pruebas`/`qa`/`main` (ver *Worktree, ramas y flujo de promoción* abajo). |
| `cancelled` | Cancelada por un Amendment (`AMD-NNN`). |

Una task puede estar `deployed:pruebas` mientras su feature aún no
esté `live` — son ejes independientes (la feature está controlada
por feature flag, no por el estado de las tasks).

#### Formato canónico de `status.md`

```yaml
---
feature: loyalty-points-engine
state: partial-deploy-pruebas
updated: 2026-05-20
updated_by: "@juan"
feature_flag:
  name: loyalty_points_v1
  envs: { pruebas: ON, qa: OFF, main: OFF }
---

# Status

## Tasks

T1:  deployed:pruebas | commit a3f2c1 | 2026-05-15
T2:  deployed:pruebas | commit 9e8b4d | 2026-05-16
T3:  deployed:pruebas | commit 17fc20 | 2026-05-17
T4:  deployed:pruebas | commit b22e91 | 2026-05-18
T5:  deployed:pruebas | commit f1c003 | 2026-05-19
T6:  in-progress      | dev @maria
T7:  pending          |
T8:  blocked          | blocked_by: D1=LIVE
T9:  blocked          | blocked_by: D1=LIVE
T10: blocked          | blocked_by: D2=LIVE

## Dependencies snapshot

D1 (identity-sso /exchange-token): AGREED, ETA sprint 2026-06-W2
D2 (sp_calcular_puntos):           AGREED, ETA sprint 2026-05-W4

## Notas
- 2026-05-20: T6 en progreso; bloqueo previsto al llegar a T8 si D1 no
  está LIVE para entonces. Conversación con team-identity abierta.
```

#### Reglas de actualización

1. **Tras cada commit relevante** — el Service Agent actualiza
   `status.md` al final de `/spec-implement`; el dev lo hace
   manualmente si commitea fuera del flujo del agente.
2. **El estado de feature se deriva** de los estados de las tasks
   (algoritmo abajo). Si la derivación y el campo `state` divergen,
   `/spec-status` reporta la discrepancia — señal de que `status.md`
   está stale.
3. **`updated`** siempre lleva la fecha del último commit que tocó
   cualquier campo del archivo.
4. **`feature_flag`** se omite por completo si la feature no tiene
   flag; si lo tiene, mantener el estado por ambiente.

#### Algoritmo de derivación del estado de feature

```
si todas las tasks == cancelled               → cancelled
si feature_flag.prod == ON                    → live
si todas las tasks ∈ {done, deployed:*}
   y todas las D-N == LIVE
   y feature_flag.prod == OFF                 → feature-complete
si alguna task == deployed:qa                 → partial-deploy-qa
si alguna task == deployed:pruebas            → partial-deploy-pruebas
si alguna task ∈ {in-progress, done}          → in-progress
sino                                          → not-started
```

Este algoritmo es deterministico y se puede ejecutar como parte de
`/spec-status` o como script CI (`spec-lint`, candidato a paquete npm
en §16 Fase 3).

#### Limpieza de feature flags (post-`live`)

Los feature flags olvidados encendidos años después son una fuente
común de complejidad accidental. Reglas mínimas:

- Una feature en `live` con `feature_flag.main == ON` y **100% de
  tráfico** durante **> 90 días** se marca por `/spec-status` como
  `flag-cleanup-candidate`.
- El Service Agent **propone** una task nueva al `tasks.md` original:
  `Tn: Limpiar feature flag <name>` que incluye:
  - Borrar el flag del catálogo de flags.
  - Eliminar el branching `if (flag) { ... } else { ... }` del código,
    dejando sólo la rama activa.
  - Deprecar contratos publicados que existían **sólo** para soportar
    el flag.
- La task de limpieza sigue el flujo normal de promoción
  (`pruebas → qa → main`).
- Tras merge en `main`, el `state` de la feature se mantiene en `live`
  (la funcionalidad sigue); el bloque `feature_flag` se **elimina** del
  frontmatter de `status.md`.

**Anti-pattern**: dejar el flag "por si acaso" indefinidamente. Cada
flag activo en `main` es deuda de complejidad que crece con el tiempo:
código `if (flag)` que nadie revisa, paths que no se testean realmente,
métricas confundidas por dos comportamientos posibles.

### Configuración del repo (`repo-config.yaml`)

Cada repo declara su configuración operacional en un archivo
`repo-config.yaml` en la raíz. Es la **única fuente de verdad** para:
tipo de repo, tracker de work items, ambientes desplegables, flujo de
promoción y políticas de gates. Reemplaza al antiguo `branch-flow.md`
(que sólo cubría el subconjunto de ramas).

> **Por qué un archivo dedicado**: la metodología no asume globalmente
> ni Azure DevOps, ni 3 ambientes, ni OpenShift. Diferentes repos en
> la misma organización pueden tener stacks distintos (un servicio en
> OpenShift + AzDO; una librería npm sin tracker; una app de frontend
> con previews por PR). El `repo-config.yaml` declara eso explícitamente
> y el Service Agent + slash commands lo respetan.

#### Esquema

```yaml
# repo-config.yaml
repo_type: service                     # service | library | frontend-app | infra | custom

trackers:                              # lista; soporta multi-tracker cross-project (v0.17)
  - name: dev-team                     # alias libre — el que NO se declara es el implícito por nombre
    type: azure-devops                 # none | azure-devops | github-issues | jira | linear | custom
    role: owner                        # owner (UN solo) | stakeholder (N) | qa (opcional)
                                       # `owner` gobierna commits (AB#<id>), lifecycle, sprint planning
                                       # `stakeholder` = trazabilidad cross-team (read-only del agente)
                                       # `qa` = tracker separado de testing (opcional)
    org: syc
    project: loyalty
    default_area_path: loyalty\\backend
    creation_mode: discover-first      # discover-first (default brownfield) | assisted (greenfield)
                                       #   | auto (con MCP) | manual (dev pasa IDs)
                                       # Ver §13 *Discover-first vs creación nueva*
    work_item_mapping:                 # cómo se mapea jerarquía AI-DLC → niveles ADO (opcional)
      initiative_to: Epic              # default Epic
      feature_to: Feature              # default Feature; equipos sin Features → "User Story"
      task_to: User Story              # default User Story

  # Ejemplo de stakeholder (equipo cliente / receiving team):
  # - name: receiving-team
  #   type: azure-devops
  #   role: stakeholder
  #   org: syc
  #   project: Estampillas
  #   default_area_path: Estampillas\\NeoEstampillas
  #   # `creation_mode` y `work_item_mapping` no aplican (read-only)

# Atajo backwards-compat: `tracker:` (singular) sigue siendo válido
# como forma corta para repos con un solo tracker role=owner:
#   tracker: azure-devops
#   tracker_config: { org: syc, project: loyalty, default_area_path: ... }
# El parser lo expande internamente a `trackers: [{ ..., role: owner }]`.

environments:                          # lista; puede estar vacía (ej. library sin ambientes)
  - name: pruebas                      # nombre canónico (usado en partial-deploy-<env>, deployed:<env>)
    branch: pruebas                    # rama destino del PR de promoción
    deploy_trigger: auto-on-merge      # auto-on-merge | manual | scheduled | publish-prerelease | publish-release
    gate: "1+ reviewer del equipo"
  - name: qa
    branch: qa
    deploy_trigger: auto-on-merge
    gate: "QA sign-off explícito"
  - name: main
    branch: main
    deploy_trigger: manual
    gate: "Tech lead + Ops sign-off + rollout-plan aprobado"

promotion_path: [pruebas, qa, main]    # orden secuencial

design_service:                        # opcional; §12 aplica sólo si está declarado
  figma_team_url: https://www.figma.com/files/team/...

runtime:                               # opcional; permite que /oc-* sepa si aplica
  type: openshift                      # openshift | k8s | npm-registry | static-host | none
  cluster: ocp-eu-west-1
  namespace_pattern: "{service}-{env}"

branch_pattern: "feat/"                # opcional; default "feat/". Prefijo que el agente
                                       # usa al crear ramas nuevas. Aceptables: "feat/",
                                       # "feature/", "feature_", etc. Los slash commands
                                       # respetan lo declarado. En brownfield con drift
                                       # histórico (`feature/` + `feature_` mezclados),
                                       # declarar el prefijo más reciente; NO se renombran
                                       # ramas históricas para alinearlas.

monorepo:                              # opcional; sólo si el repo es monorepo con
                                       # sub-proyectos heterogéneos (services + libraries
                                       # + frontend-apps mezclados). Si TODOS los
                                       # sub-proyectos comparten `repo_type`, usar el
                                       # `repo_type` simple arriba y omitir este bloque.
                                       # Ver §10 *Monorepos* para el patrón completo.
  layout: services-and-libraries       # descripción libre, sólo informativa
  services:                            # lista de sub-proyectos con su tipo individual
    - { path: "EdeskWebCore.Server", type: service }
    - { path: "edesk-server-node", type: library, registry: "@syc/edesk-server-node" }
    - { path: "edeskweb.client", type: library, registry: "@syc/edesk-web-client" }
  cross_cutting_specs: false           # default false: specs van en <service>/specs/
                                       # (regla §10 monorepo). Poner `true` cuando hay
                                       # feature parity exigida entre sub-proyectos (ej.
                                       # mismo endpoint en backend .NET y Node) — en ese
                                       # caso las specs viven al ROOT y aplican
                                       # transversalmente. Ver §10 *Specs cross-cutting*.
```

#### Modalidad del repo (`repo_type`)

El campo `repo_type` cambia cómo se interpretan los estados de
lifecycle (§6 *Lifecycle*), qué gates se exigen, y qué slash commands
aplican. Variantes reconocidas:

| `repo_type` | Default `environments` | Interpretación de `deployed:<env>` | Slash commands relevantes | Slash commands N/A |
|---|---|---|---|---|
| `service` | `pruebas`, `qa`, `main` | Deploy del binario al namespace de ese ambiente | `/spec-promote`, `/oc-status`, `/oc-rollback` | — |
| `library` (paquete npm/pip/maven) | `pruebas`, `main` | `pruebas` = `publish-prerelease` al registry; `main` = `publish-release` | `/spec-promote` (interpreta como publish) | `/oc-*` (no hay deploy a infra) |
| `frontend-app` | `pruebas`, `qa`, `main` + previews por PR | Deploy a CDN/static host del ambiente | `/spec-promote`, `/figma-*` | `/oc-rollback` si no aplica |
| `infra` (terraform / helm) | `sandbox`, `prod` | `sandbox` = plan/apply a sandbox; `prod` = apply a prod | `/spec-promote` (con dry-run mandatorio) | `/figma-*` |
| `custom` | declarado en `environments` | declarado en `deploy_trigger` | a definir | a definir |

> **Ejemplo `repo_type: library`**: una librería npm interna
> tiene sólo dos ramas (`pruebas` → publica prerelease al registry,
> `main` → publica release). No tiene "ambiente" en el sentido de
> deploy a infraestructura, no aplica `rollout-plan.md`, y los gates
> G5/G6 (§15) se reinterpretan: G5 = "QA del consumidor firma sobre
> el prerelease publicado", G6 = "release tag firmado y publicado".
> Los estados de feature son: `partial-deploy-pruebas` = publicada
> como prerelease; `feature-complete` = lista para release;
> `live` = release publicada en `main`.

#### `trackers` pluggables (v0.17: multi-tracker)

El bloque `trackers` declara qué sistemas de work items se sincronizan
con las specs. Soporta **múltiples trackers con roles distintos**, lo
que permite escenarios cross-team comunes en organizaciones grandes:

- Mi equipo **desarrolla** algo para entregar a otro equipo →
  declaro **dos trackers**: `owner` (mi project ADO, donde van mis
  tareas técnicas) + `stakeholder` (project del cliente, donde viven
  sus Features y User Stories de cara al producto).
- Una organización mediana sin cross-team todavía → declaro **un solo
  tracker con role: owner** (caso simple).
- Un repo sin tracker → declaro `trackers: []` o uso `tracker: none`
  (atajo legacy).

Roles soportados:

| Role | Cardinalidad | Qué gobierna |
|---|---|---|
| **`owner`** | UN solo por repo | Commits (`AB#<id>` del owner), lifecycle de specs, sprint planning del equipo. Default para el work item citado en commits. |
| **`stakeholder`** | N | Trazabilidad cross-team. El agente **consulta read-only** el tracker (lista Features/Stories existentes, citas para `spec_represents`) pero NO crea ni modifica work items ahí. |
| **`qa`** | 0 o 1 | Opcional. Tracker separado si QA vive en otro project. Test plans, defectos. |

Por tipo de tracker:

| `type` | Convención de commits (owner) | Slash commands |
|---|---|---|
| `none` | `[R*.*]` solamente (ej. `feat(x): T1 [R1.2]`) | N/A |
| `azure-devops` | `[R*.*] AB#<id>` (id del owner) | `/ado-link`, `/ado-status`, `/ado-relate` |
| `github-issues` | `[R*.*] #<issue>` o `(closes #<n>)` | `/gh-link`, `/gh-status` (a definir) |
| `jira` | `[R*.*] PROJ-<id>` | `/jira-link`, `/jira-status` (a definir) |
| `linear` | `[R*.*] <TEAM>-<n>` | `/linear-link` (a definir) |
| `custom` | declarado | a definir |

Si NO hay tracker con `role: owner` (o `tracker: none` legacy):

- No se exige `AB#<id>` (o equivalente) en commits — sólo `[R*.*]`.
- Los slash commands específicos del tracker no se ofrecen.
- `/spec-verify` omite los checks de sync con boards.
- §13 entera se considera N/A para ese repo.

Si hay `stakeholder`(s) además del owner: las specs declaran
`work_items.stakeholders[]` en `status.md` (§13 *Discover-first*).
El agente cita esos work items en PR descriptions y `design.md`
pero NO en commit messages (sería ruido — la trazabilidad
cross-project vive en `status.md` + relaciones ADO, no en cada
commit). Ver §13 *Modelo owner + stakeholders* para el flujo
completo.

#### Migración: adoptar un tracker después del bootstrap

Un repo puede arrancar con `trackers: []` (o `tracker: none` legacy)
y adoptar uno después. El flujo:

1. Editar `repo-config.yaml`: añadir un `trackers:` con `role: owner`
   y `type: azure-devops` (u otro), incluyendo `creation_mode` (default
   `discover-first` si el equipo ya tiene work items creados,
   `assisted` si va a empezar de cero).
2. **No backfillear** commits históricos — quedan sin `AB#<id>`, lo
   cual es esperable.
3. Las **features nuevas y los Amendments** de features existentes
   incluyen referencias al tracker desde ese punto.
4. Si se quieren boards retroactivos para features ya en `main`,
   ejecutar `/spec-sync --backfill <feature>` (en modo
   `discover-first` busca matches por título primero; sólo crea
   work items si no encuentra; **nunca** modifica commits viejos).

#### Migración: agregar un stakeholder cross-team

Un repo con sólo `owner` declarado descubre que va a entregar a otro
equipo (caso real: Edesk desarrolla para Estampillas y va a entregar
en un cuatrimestre). Flujo:

1. Editar `repo-config.yaml`: agregar otro tracker en `trackers[]` con
   `role: stakeholder` apuntando al project del cliente.
2. Las specs **existentes** quedan como están — no se backfilea la
   relación con work items del stakeholder a menos que el dev lo
   pida explícitamente.
3. Las specs **nuevas** (y los Amendments) preguntan en `/spec-new`
   CLARIFY si corresponden a un work item del stakeholder y lo
   citan en `status.md > work_items.stakeholders[]`.
4. Para vincular relaciones cross-project en ADO (`System.LinkTypes.Related`),
   el dev ejecuta `/ado-relate` por cada par de work items (o el agente
   lo propone durante `/spec-new` cuando crea el work item del owner).

#### Migración: agregar MCP de un tracker existente

Un repo con `tracker: azure-devops` ya en uso (vía `az` CLI o web UI)
puede agregar el MCP de Azure DevOps después para tener integración
más rica (queries naturales sobre work items, relaciones cruzadas
automáticas, etc.). Ver §13 *Extensibilidad de MCPs* para el
procedimiento de 4 pasos.

#### Migración: cambiar el número de ambientes o el `repo_type`

Un `library` que crece a `service` (o viceversa) cambia `repo_type` y
`environments`. Reglas:

- Features `in-progress`: terminan en el flujo viejo; el `state`
  declarado en `status.md` se mantiene.
- Features `not-started` y nuevas: usan el flujo nuevo.
- Si se **reduce** el número de ambientes (ej. `qa` se elimina), las
  features en `partial-deploy-qa` se promocionan al siguiente ambiente
  declarado o se marcan `cancelled` — no se quedan en limbo.
- Si se **agrega** un ambiente intermedio, las features en flujo no
  retroceden; el nuevo ambiente aplica desde la próxima promoción.

#### Defaults si el archivo no existe

Si `repo-config.yaml` no existe en el repo (transición de un repo
legacy), el Service Agent **pregunta** y propone crearlo antes de
seguir con cualquier `/spec-*`. Hasta que exista, asume defaults
mínimos: `repo_type: service`, `trackers: []`, `environments:
[pruebas, qa, main]`, `promotion_path: [pruebas, qa, main]` — y **lo
dice explícitamente** al humano (§3.17 *distinguir sabido vs
asumido*).

### Worktree, ramas y flujo de promoción

Una feature es una unidad **paralela** de trabajo. Para que pueda
desarrollarse sin interferir con otras (principios §3.10 + paralelismo
cross-team) y para que el agente sepa siempre dónde está parado, cada
feature trabaja en **su propio Git worktree** con **convención de
ramas estándar** y **flujo de promoción explícito entre ambientes**.

#### Convención de ramas

| Rama | Cuándo | Origen típico | Destino del PR |
|---|---|---|---|
| `feat/<feature-slug>` | Feature nueva | Rama base elegida (ver Flujo de promoción) | `pruebas` |
| `amend/<feature-slug>/AMD-NNN` | Amendment a feature ya en flujo | Rama donde vive la feature | El mismo flujo que la feature original |
| `hotfix/<slug>` | Bug Tipo D (incidente en prod) | `main` | `main` directo + back-merge a `qa` y `pruebas` |
| `spec/<feature-slug>` | PR sólo de spec (sin código) | Rama base elegida | `pruebas` |

El `<feature-slug>` coincide con `specs/<feature-slug>/` — la rama, la
spec y el worktree quedan trazables por el mismo nombre.

#### Worktree por feature

Cada feature vive en un **Git worktree** separado del checkout
principal:

```
~/repos/<org>/<repo>/                    ← checkout principal (típicamente main)
~/repos/<org>/<repo>--<feature-slug>/    ← worktree de la feature
```

Comando que el agente ejecuta tras confirmar la rama base:

```bash
git worktree add -b feat/<feature-slug> \
  ../<repo>--<feature-slug> \
  origin/<base-branch>
```

**Ventajas vs `git checkout -b` en el repo principal**:
- No interfiere con otros worktrees activos: 3 features en paralelo
  sin `git stash` ni cambios de contexto en el checkout principal.
- El agente sabe **siempre dónde está parado**: el path del `cwd`
  identifica el worktree, que identifica la feature.

#### Monorepos

Si un repo contiene **varios servicios** (monorepo), `spec locality`
(§3.7) se interpreta a nivel de **servicio**, no de repo:

```
<monorepo>/
├── services/
│   ├── points-engine/
│   │   └── specs/<feature>/            ← spec del servicio
│   ├── checkout-api/
│   │   └── specs/<feature>/
│   └── notifications/
│       └── specs/<feature>/
└── .org/                                ← catálogo (opcional, §9)
```

Convenciones específicas para monorepo:

- **Rama**: `feat/<service>/<feature-slug>` (incluir servicio en el
  path para evitar colisiones entre features de distintos servicios).
- **Worktree**: `<monorepo>--<service>--<feature-slug>/`.
- **Spec path**: `services/<service>/specs/<feature-slug>/`.
- **CI**: el pipeline despliega sólo los servicios afectados por el
  PR (`paths-filter` o equivalente). El estado `deployed:<env>` aplica
  al servicio, no al monorepo entero.

El resto del flujo (Lifecycle, Dependencies, Contract-First, promoción)
opera **exactamente igual**: cada servicio dentro del monorepo se
trata como un repo lógico independiente para efectos de la metodología.

##### Monorepos con tipos mixtos (services + libraries + frontend-apps)

Lo anterior asume monorepo **homogéneo** (todos los sub-proyectos son
services). Los monorepos reales suelen ser **heterogéneos**: backend
service + librería compartida publicada a registry + frontend SPA, todo
en el mismo repo (caso típico: app full-stack con shared types).

Patrón canónico:

- En `repo-config.yaml` al root: usar `repo_type: custom` y declarar
  el bloque `monorepo:` (ver §6 *Configuración del repo*) listando
  cada sub-proyecto con su `type` individual (`service`, `library`,
  `frontend-app`, `infra`).
- Cada sub-proyecto **puede** tener su propio `repo-config.yaml` para
  overrides específicos (ambientes, tracker, runtime). Default: hereda
  del root.
- Las **interpretaciones de lifecycle** (`deployed:<env>` vs publish a
  registry) aplican per sub-proyecto según su `type`: el backend
  despliega a OpenShift, la library publica al npm registry, todo en
  el mismo PR si hace falta.
- Los **gates** aplican per sub-proyecto: G6 (Ops sign-off rollout)
  sólo a `service`/`frontend-app`; libraries usan G5 reinterpretado
  como "QA del consumidor sobre prerelease publicado".

##### Specs cross-cutting (feature parity entre sub-proyectos)

Excepción a la regla "specs por servicio" arriba: cuando un equipo
exige **feature parity** entre sub-proyectos (ej. mismo endpoint en
backend .NET + backend Node alterno, o backend + cliente que comparten
modelo de dominio), las specs **viven al ROOT del monorepo**, no per
servicio:

```
<monorepo>/
├── specs/
│   └── password-reset/                  ← spec transversal: aplica a TODOS los sub-proyectos
│       ├── requirements.md              ← R*.* describen contrato funcional, agnóstico a tech
│       ├── design.md                    ← incluye sección por sub-proyecto (impl .NET, impl Node, UI)
│       ├── tasks.md                     ← tasks tagged por sub-proyecto: T1 [backend-dotnet], T2 [backend-node], T3 [frontend]
│       └── status.md                    ← lifecycle único; deployed:<env> per sub-proyecto en tabla
├── EdeskWebCore.Server/                 ← backend .NET
├── edesk-server-node/                   ← backend Node alterno (parity con .NET)
└── edeskweb.client/                     ← frontend
```

Activar este patrón con `monorepo.cross_cutting_specs: true` en
`repo-config.yaml`. Implica:

- Una `R*.*` con ambigüedad sobre cuál sub-proyecto la cubre se
  resuelve por convención: TODOS la cubren (parity) salvo que se
  declare explícito (`R3.4 [only: backend-dotnet]`).
- Los tests por R*.* incluyen una matriz: cada R*.* se valida en TODOS
  los sub-proyectos relevantes. Tests faltantes en uno son gap de
  parity (no de cobertura).
- Bug Tipo A en un sub-proyecto que no aparece en el otro **es señal
  de drift de parity** (no se promociona feature hasta que cierra el
  drift).
- Anti-pattern: usar `cross_cutting_specs: true` sin que haya parity
  real exigida — termina en specs sobre-genéricas que nadie respeta.

#### Flujo de promoción entre ambientes

Flujo empresarial típico de (3 ambientes desplegables):

```
feat/<feature-slug>
       │   PR 1 ── tests verdes + review + spec aprobada
       ▼
   pruebas             ← dev/integration (despliegue automático)
       │   PR 2 ── QA sign-off de lo desplegado en pruebas
       ▼
     qa                ← UAT (QA + stakeholders verifican)
       │   PR 3 ── feature-complete + rollout-plan aprobado
       ▼
    main               ← producción (feature flag controla activación)
```

| PR | Estado de feature al cruzar | Gate humano |
|---|---|---|
| `feat/<slug>` → `pruebas` | `partial-deploy-pruebas` o `feature-complete` | 1+ reviewer del equipo |
| `pruebas` → `qa` | `partial-deploy-qa` o `feature-complete` | QA sign-off explícito |
| `qa` → `main` | `feature-complete`; rollout-plan revisado | Tech lead + Ops sign-off |

**Convenciones de nombre y número de ambientes**: los nombres
(`pruebas`, `qa`, `main`), su número y el orden están declarados en
`repo-config.yaml > environments` y `promotion_path` (§6 *Configuración
del repo* arriba). El agente respeta lo declarado y no inventa
nombres. Los valores de `feature.deployed:<env>` y
`partial-deploy-<env>` (§6 Lifecycle) coinciden con los
`environments[].name`.

El Service Agent lee `repo-config.yaml` en:

1. `/spec-new` → para preguntar la rama base ofreciendo sólo las ramas
   reales del repo (no genera `pruebas`/`qa`/`main` por reflejo).
2. `/spec-promote` → para validar destino y `deploy_trigger` (no
   propone merge a una rama con `deploy_trigger: manual` sin OK
   explícito; en `repo_type: library` interpreta `/spec-promote --to
   pruebas` como `publish-prerelease` y `--to main` como
   `publish-release`).
3. `/spec-status` → para nombrar correctamente los estados
   `partial-deploy-<env>` y para no exigir gates de runtime
   (rollout-plan, OpenShift) cuando el `repo_type` no los requiere.

#### Qué hace el Service Agent automáticamente

Bajo el protocolo §7:

1. **Al crear una spec** (`/spec-new`):
   - **Pregunta** cuál es la rama base leyendo
     `repo-config.yaml > environments[].branch` (§6 *Configuración del
     repo*); ofrece sólo ramas declaradas. Si `repo-config.yaml` no
     existe, lo señala y propone crearlo antes de seguir (no asume
     `pruebas/qa/main` por reflejo).
   - **Crea el worktree** con la nomenclatura estándar.
   - **Verifica** que el dev queda parado en él antes de seguir.
2. **Antes de cada `/spec-implement` y `/spec-amend`**:
   - **Verifica** que el `cwd` es el worktree correcto para la feature.
   - Si no, **propone** moverse: *"estás en
     `<repo>--otra-feature/`, ¿cambio a `<repo>--<feature-slug>/`?"*.
3. **Al cerrar una task o hito de promoción**:
   - **Propone PR** hacia el siguiente ambiente (ver `/spec-promote`
     en §11).
   - **No abre PR** sin OK explícito (§3.16).
4. **Al terminar la feature** (estado `live` o `cancelled`):
   - Propone `git worktree remove ../<repo>--<feature-slug>` y borrar
     la rama remota si ya está mergeada. **No lo ejecuta sin OK**.

### Trazabilidad entre niveles

- Cada `requirements.md` cita su Initiative **sólo si la feature
  pertenece a una** (línea opcional en el header):
  ```markdown
  > Parte de [Initiative: <name>](<url-al-repo-de-iniciativas>)
  > Contexto: [architecture.md](<url>)
  ```
- Cada task en `tasks.md` cita los `R*.*` que cubre y, si aplica, las
  `D-N` de las que depende (ej. `T7 [R4.1, D2]`).
- Cada commit/PR cita los `R*.*` y/o tasks (`T1, T2`). Si se generó
  por un Amendment, cita también `AMD-NNN`.

---

## Sistema de agentes

No es **un** agente — es un equipo coordinado.

### Architect Agent (orquestador)

**Conocimiento**:
- Mapa de repos, servicios, bases de datos (`.org/catalog.yaml`,
  **si existe**; si no, lo pregunta al humano).
- Diagrama de dependencias entre servicios (cuando esté disponible).
- Catálogo de eventos y contratos de API en `.org/contracts/`
  (**obligatorio cuando hay dependencias cross-repo**, §9).
- Convenciones organizacionales.
- ADRs históricos (cuando estén versionados).

**Responsabilidades**:
- Recibe requerimientos del cliente/PM.
- Entrevista stakeholders (PM, ops, legal, arquitectos).
- Produce spec de **nivel 0** (initiative).
- Decide qué servicios tocar, qué crear nuevo.
- Genera specs stub de **nivel 1**.
- Coordina rollout cross-repo.

**NO hace**: implementación. Estrictamente diseño y coordinación.

### Service Agents (especialistas por dominio + dispatcher local)

Uno por servicio/repo. Conocen profundamente su repo (código, tests,
migrations, CI/CD, `CLAUDE.md` local) **y** son el punto único de
conversación del dev dentro de ese repo.

**Doble rol**:

1. **Dispatcher por intención** — el dev habla en lenguaje natural
   (*"quiero arrancar una feature de export a Excel"*, *"retomemos lo
   de loyalty"*, *"el cliente cambió la regla de canjes"*). El Service
   Agent detecta intención, propone el slash command apropiado
   (`/spec-new`, `/spec-status`, `/spec-amend`...) y lo ejecuta tras
   confirmación. **El dev nunca necesita memorizar los slash commands**
   — están documentados en §11 sólo como atajos opcionales para devs
   experimentados que quieran saltarse la detección de intención.
2. **Ejecutor SDD** — implementa el flujo de §6 (specs, dependencies,
   lifecycle) y los slash commands de §11 dentro del repo.

**Escalación al Architect**: cuando la conversación toca coordinación
cross-service (otro equipo, otro repo, contrato nuevo cross-team), el
Service Agent **escala al Architect Agent** — no improvisa decisiones
cross-team (§3.8 *no coordinator*). En la práctica esto es un mensaje
del Service Agent al dev: *"esto toca al equipo de identidad. Voy a
consultar al Architect Agent para draftear el contrato. ¿OK?"*.

**Comportamiento conversacional** (§3.12-3.17 + §7 protocolo): el
Service Agent siempre verifica contexto, pregunta antes de asumir,
detecta gaps proactivamente, propone próximo paso, confirma antes de
acciones irreversibles.

### Agentes consultivos (revisores)

| Agente | Rol |
|---|---|
| **Compliance Agent** | Valida specs contra políticas (GDPR, PCI, SOC2, etc.) |
| **Security Agent** | Threat modeling, revisión de superficie de ataque |
| **Ops Agent** | Factibilidad de deploy, SLOs, capacidad, observabilidad |
| **Cost Agent** | Estimación de costo de infra |
| **Data Agent** | Schemas, ownership, retention, lineage |

Estos **no escriben** specs — las **revisan y anotan**.

### Consejo, garantía y bloqueo (capas de enforcement)

Los agentes consultivos son **una** de tres capas con responsabilidades
distintas. Distinguirlas evita el anti-patrón de meter toda la
disciplina en una sola capa (típicamente la más cara o la más lenta).

| Capa | Mecanismo | Cuándo corre | Si la regla falla | Cómo se skipea |
|---|---|---|---|---|
| **Consejo** | Agentes consultivos (Compliance, Security, Ops, Cost, Data), Architect Agent | Durante authoring de spec, antes del gate humano | Anota el riesgo en la spec; humano decide | Trivial — el dev lo ignora |
| **Garantía** | Hooks del harness (pre-commit, pre-push, hooks del runtime AI — Claude Code, Cursor, OpenCode), `spec-lint` local | En el cliente, antes de que el commit/push salga del laptop | Bloquea localmente con mensaje claro | `--no-verify` u opción equivalente; queda visible en el commit |
| **Bloqueo** | CI gates (PR checks, branch protection), gates humanos G2/G4 (§6) | En el server, antes del merge | El merge no avanza | Sólo con admin override visible |

**Cuándo usar cada una**:

- **Consejo** cuando la decisión requiere juicio (¿este threat model
  es aceptable para el negocio?), no regla mecánica.
- **Garantía** cuando la regla es mecanizable y conviene saberla
  **antes** del CI (formato de spec, `R*.*` referenciado en el
  commit, secretos en archivos). Reduce el ciclo "push → CI rojo →
  fix" a "commit fallido → fix" sin involucrar al equipo.
- **Bloqueo** cuando la regla **no puede confiarse al author**: el
  hook local se saltea con `--no-verify`; el CI gate no.

**Misma regla en varias capas**: una validación importante puede
vivir en *consejo* (Architect lo sugiere al authorear), *garantía*
(hook local rechaza el commit) **y** *bloqueo* (CI rechaza el merge).
No es duplicación — cada capa atrapa el caso que la anterior dejó
pasar.

**Anti-patrones**:

| Anti-patrón | Síntoma | Mitigación |
|---|---|---|
| Pretender que un agente consultivo *bloquee* | El dev "necesita el OK del Compliance Agent" para mergear; el agente se vuelve cuello de botella | Los consultivos anotan, el humano decide. Si necesitás bloqueo, escribís un CI gate explícito |
| Toda la disciplina en CI gates | Feedback lento; ciclos "push → 8 min de pipeline → fix → push" | Mover lo mecanizable a hooks locales; CI mantiene el bloqueo final |
| Hooks locales sin equivalente en CI | Un dev con `--no-verify` rompe la invariante para todos; falsa sensación de garantía | Hook ≠ garantía organizacional sin CI. Si la invariante importa, hay que duplicarla en CI |
| Ratchet harness (§8) que sólo agrega hooks | Cada Tipo B/C nuevo añade un hook; el pre-commit tarda 40 s; devs hacen `--no-verify` por reflejo | Empezar el ratchet en la capa más barata (AGENTS.md, slash-command), subir a hook/CI sólo si la regla recurre |

> **Stack-agnostic**: la metodología NO prescribe hooks concretos. Cada
> repo elige tooling (`husky`, `pre-commit`, `lefthook`, hooks nativos
> de Claude Code / Cursor / OpenCode, etc.) y los declara donde
> corresponda a su stack. Lo prescrito es la **distinción de capas**,
> no la tooling.

### Topología

```
                  ┌─────────────────────────┐
PM/Cliente ─────► │   Architect Agent       │ ◄── Catalog, ADRs,
                  │   (orquestador)         │     contracts, policies
                  └────────────┬────────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                ▼
        ┌──────────┐    ┌──────────┐    ┌──────────┐
        │Compliance│    │  Ops     │    │  Cost    │ ◄── Revisores
        │  Agent   │    │  Agent   │    │  Agent   │
        └──────────┘    └──────────┘    └──────────┘
                               │
      Spec aprobada por feature (Initiative si aplica) — gate humano
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                ▼
        ┌──────────┐    ┌──────────┐    ┌──────────┐
        │ Service  │    │ Service  │    │ Service  │ ◄── Ejecutores
        │ Agent A  │    │ Agent B  │    │ Agent C  │
        └──────────┘    └──────────┘    └──────────┘
              │                │                │
              ▼                ▼                ▼
           Repo A           Repo B            Repo C
```

### Protocolo de interacción del agente

Cada invocación de un slash command (Architect o Service) sigue el
mismo arco operacional. El agente lo respeta **incluso si el dev no
lo pide explícitamente** — eso es lo que materializa los principios
§3.12-3.17.

```
   ┌──────────────────────────────────────────────────────────┐
   │ 1. GREET & CONTEXT                                       │
   │    "Estás en repo X, feature Y. Último update: <fecha>." │
   │    Si falta contexto del usuario → preguntar.            │
   └──────────────────────────────────────────────────────────┘
                              │
                              ▼
   ┌──────────────────────────────────────────────────────────┐
   │ 2. PRE-FLIGHT CHECK                                      │
   │    Leer status.md, dependencies, amendments, tests       │
   │    recientes. Reportar: "Estado X. Bloqueos Y. Tests Z." │
   └──────────────────────────────────────────────────────────┘
                              │
                              ▼
   ┌──────────────────────────────────────────────────────────┐
   │ 3. CLARIFY                                               │
   │    Si la intención es ambigua o el contexto incompleto,  │
   │    hacer **preguntas concretas** (no genéricas).         │
   │    Ej: "¿T6 ya pasó code review o sigue en draft?"       │
   │    Una pregunta a la vez cuando sea posible.             │
   └──────────────────────────────────────────────────────────┘
                              │
                              ▼
   ┌──────────────────────────────────────────────────────────┐
   │ 4. PROPOSE                                               │
   │    Plantear qué va a hacer, qué NO, riesgos. Pedir OK    │
   │    explícito si la acción es irreversible (§3.16).       │
   └──────────────────────────────────────────────────────────┘
                              │
                              ▼
   ┌──────────────────────────────────────────────────────────┐
   │ 5. EXECUTE                                               │
   │    Hacer lo acordado. Reportar progreso si es largo.     │
   └──────────────────────────────────────────────────────────┘
                              │
                              ▼
   ┌──────────────────────────────────────────────────────────┐
   │ 6. CLOSE                                                 │
   │    "Hice: X. Pendiente: Y. Siguiente paso sugerido: Z."  │
   │    Update de status.md / tasks.md / amendments cuando    │
   │    aplique (§6 Lifecycle).                               │
   └──────────────────────────────────────────────────────────┘
```

**Reglas operacionales transversales** (que cada slash command de §11
hereda):

- **Verificar antes de implementar**: si `/spec-implement` no encuentra
  spec aprobada, **para y pregunta** — no improvisa.
- **Detectar el "ya pasó algo"**: si hay commits desde el último
  update de `status.md`, el agente lo señala — *"veo 3 commits sin
  reflejo en status.md, ¿los integro al lifecycle?"*.
- **Detectar drift**: si la derivación del estado de feature (§6
  Lifecycle) no coincide con el `state:` declarado, lo dice y propone
  alinearlos.
- **Memoria entre invocaciones**: el agente lee `status.md`,
  `amendments.md` y el commit reciente al arrancar. **No asume** que
  el dev recuerda la sesión anterior.
- **Falta de contexto explícito**: si el dev invoca `/spec-implement`
  sin argumento y hay múltiples features en `specs/`, el agente
  pregunta cuál; no elige por su cuenta.
- **Verificar el worktree** antes de toda acción que toque código
  (implement, amend, promote): el agente confirma que el `cwd` es el
  worktree correcto para la feature en curso y que la rama activa es
  la esperada (§6 Worktree). Si no coinciden, propone moverse y NO
  actúa sobre la rama equivocada.

---

## Manejo de bugs

### Taxonomía

| Tipo | Descripción | Acción |
|---|---|---|
| **A** | Implementation bug (spec OK, código mal) | Regression test + fix. **No tocar spec.** |
| **B** | Spec gap (caso no contemplado) | Actualizar `requirements.md` con nuevo `R*.*` + implementar |
| **C** | Ambiguous spec (interpretación) | Refinar/aclarar `requirements.md` + posible fix |
| **D** | Critical hotfix (producción rota) | Fix directo + spec retroactiva en post-mortem |
| **E** | External dependency bug — **3rd party** (paquete npm/nuget, librería open source, vendor SaaS). NO aplica a servicios de otros equipos internos: esos siguen A/B/C según el contrato (§6). | Reportar al vendor/upstream. Elegir estrategia: `WORKAROUND` (parche local con TODO), `PIN` (fijar versión sana) o `WAIT` (esperar release). La `R*.*` afectada queda `blocked_by: ext:<id>` en `status.md` mientras dure. **No tocar spec funcional.** |

### Decision tree

```
¿Hay un bug?
     │
     ▼
¿Existe spec relevante?
     │
 ┌───┴───┐
NO       SÍ
 │        │
 ▼        ▼
Crear   ¿La spec cubre este caso explícitamente?
nuevo       │
spec   ┌────┴────┐
       NO        SÍ
        │         │
        ▼         ▼
    Spec gap  ¿Es ambigua?
    (Tipo B)     │
              ┌──┴──┐
             NO     SÍ
              │      │
              ▼      ▼
        Implementation  Refinar
        bug (Tipo A)    (Tipo C)
```

### Tracking dentro de specs

`<repo-del-servicio>/specs/<feature>/bugs.md` (spec locality, §3.7):

```markdown
## BUG-1247 — Token expira en 15s en vez de 15min
- **Tipo:** A
- **Requirement:** R2.2
- **Reportado:** 2026-05-12
- **Fix commit:** a3f2c1
- **Regression test:** tests/auth/token-service.test.ts:expires-15-min

## BUG-1251 — Cambio de email durante reset pendiente
- **Tipo:** B
- **Requirements agregados:** R6.1, R6.2
- **Spec PR:** !341
- **Implementation PR:** !342
```

### Ratchet harness — cerrar Tipo B/C contra el agente, no sólo contra la spec

Un bug Tipo B/C cierra **dos veces**: una contra la spec (nuevo `R*.*`
o refinamiento) y otra contra el **harness** del agente (AGENTS.md,
skill / slash-command, plantilla EARS, `spec-lint`, hook de CI). El
`R*.*` parcha esta feature; el ratchet evita que el agente vuelva a
authorear el mismo gen de gap en la próxima.

No todo Tipo B/C amerita ratchet — sólo los que pintan como **clase**.
Criterio:

- ¿El gap es una clase detectable por regla, no un caso aislado? Ej.:
  "endpoint sin idempotencia declarada", "campo PII sin política de
  retención", "transición de estado sin guard".
- ¿Una regla en AGENTS.md, un paso del slash-command o un check de
  `spec-lint` lo habría disparado antes?

Si la respuesta a ambas es sí, el cierre del bug incluye un PR sobre
el harness además del PR de spec. Si no, cerrar con el `R*.*` y
seguir.

**Dónde puede vivir el ratchet** (de menor a mayor garantía; elegir la
capa más barata que efectivamente cierre el gen):

| Capa | Qué codifica | Cuándo elegirla |
|---|---|---|
| `AGENTS.md` / system prompt del repo | Recordatorio al agente ("antes de cerrar un endpoint, declarar idempotencia") | Gap conceptual; cuesta poco al agente preguntar |
| Skill / slash-command (`/spec-author`, `/bug-triage`) | Paso explícito en el protocolo | El agente ya tendría que preguntar pero se lo saltea |
| Plantilla EARS / checklist en `requirements.md` | Sección obligatoria del template | El gap es estructural a un tipo de feature |
| `spec-lint` rule | Bloqueo automático al commit de spec | Patrón estable, regla mecanizable |
| Hook de CI (pre-merge) | Garantía organizacional | El check no puede confiarse al author |

Las primeras filas son *consejo*; las últimas son *garantía*. Anti-
patrón opuesto: meter todo en hook de CI hasta paralizar el flujo —
empezar por AGENTS.md y bajar sólo si la regla se repite.

**Trazabilidad**: en `bugs.md`, el `BUG-NNN` Tipo B/C que ratcheta
declara `Harness PR:` además de `Spec PR:` / `Implementation PR:`.

> **Origen**: harness engineering — toda falla del agente se codifica
> de vuelta como restricción permanente para que no recurra. La
> taxonomía A/B/C/D/E mide *qué cambió*; el ratchet asegura *qué
> aprendió el harness*.

### Métrica clave

% de bugs tipo B:
- **>50%** → specs incompletas, invertir más tiempo en authoring.
- **<10%** → specs sólidas.
- **Muchos tipo C** → el lenguaje EARS no es lo bastante preciso.
- **Tipo B/C reincidentes del mismo gen** → ratchet harness no se está
  aplicando (ver subsección anterior).

### Amendments — cambios de spec post-aprobación

**Un Amendment NO es un bug.** Es un cambio impuesto desde fuera de la
ingeniería (cliente cambió de opinión, cambio regulatorio, decisión de
negocio, política nueva) que modifica una spec **ya aprobada y en
desarrollo**.

La distinción con un bug Tipo B (gap de spec):

| | Tipo B (Spec gap) | Amendment |
|---|---|---|
| **Naturaleza** | Caso que estaba mal/incompleto desde el inicio | Evento externo posterior a la aprobación |
| **Quién lo dispara** | Detecta el equipo (dev/QA/agente) durante implementación | Cliente / legal / negocio / stakeholder externo |
| **Métrica** | Cuenta contra calidad de spec authoring | NO cuenta contra calidad — es ruido externo |
| **Trazabilidad** | `bugs.md` con `BUG-NNN` | `amendments.md` con `AMD-NNN` |

Mantener la separación es clave para que la métrica de Tipo B sea
honesta: si todo se mete como Tipo B, el agente y el equipo nunca
aprenden a authorear specs mejor.

**Comando**: `/spec-amend <feature> --reason "<descripción>"` (ver
detalle en §11).

**Rama del amendment** (§6 *Worktree, ramas y flujo de promoción*):

| Estado de la feature | Rama donde trabaja el amendment |
|---|---|
| En desarrollo (state ≠ `deployed:*`/`live`, worktree `feat/<slug>` vivo) | La propia `feat/<slug>` — el amendment se acumula en la feature antes de mergear |
| Ya mergeada (state `deployed:<env>` o `live`, worktree borrado) | Rama **nueva** `amend/<slug>/AMD-NNN` cortada desde el ambiente vivo (típicamente `main`) |

**Editar directo sobre la rama del ambiente** (`main`, `qa`, `pruebas`)
**es un anti-patrón**: rompe la trazabilidad, salta el code review (G4)
y mezcla el amendment con cualquier otra cosa que esté en esa rama. El
slash command `/spec-amend` exige crear/cambiar a la rama antes de
tocar archivos (paso WORKTREE/RAMA, §11).

**Estructura de `amendments.md`**:

```markdown
## AMD-001 — Consentimiento explícito requerido (2026-06-10)
- **Motivo**: Regulación EU-2026/XX exige opt-in explícito antes de
  recolectar fecha de nacimiento.
- **Fuente**: legal@example.com (vía PM @maria)
- **R*.* afectadas**:
  - R3.2 → reescrita
  - R8.1 → nueva
  - R3.4 → tachada (deja de aplicar)
- **Tasks afectadas**: T5 cancelled, T6 modificada, T11–T12 nuevas
- **PR de spec**: !402
- **PR de implementación**: !403, !404
```

**Sin burocracia añadida**: un Amendment requiere registro y
trazabilidad, NO un comité de aprobación. La autoridad del cambio ya
está delegada en el stakeholder externo (cliente, legal, etc.); el
equipo lo recibe y lo materializa.

---

## Catálogo organizacional (`.org/`)

Versiones anteriores de esta metodología proponían un repo `.org/`
como "catálogo organizacional" con inventario de servicios, contratos,
políticas, ADRs y equipos. En una org de 100+ devs **eso no se
mantiene solo**: se desactualiza, la gente deja de consultarlo y se
convierte en un cementerio que el Architect Agent termina ignorando.

La versión realista distingue **lo obligatorio** (cosas que, si no se
mantienen, rompen visiblemente) de **lo aspiracional** (cosas que, si
no se mantienen, sólo son lentas de descubrir, pero el sistema sigue
funcionando).

### Lo obligatorio: contracts publicados

```
.org/
└── contracts/
    ├── events/                  ← AsyncAPI specs (eventos publicados)
    │   ├── order.placed.v2.yaml
    │   └── points.earned.v1.yaml
    └── apis/                    ← OpenAPI specs (APIs públicas)
        └── identity-sso.openapi.v1.2.0.yaml
```

Esto es lo único que **debe** vivir aquí, porque:

- Materializa el principio §3.9 *contract as handshake*: cuando dos
  equipos se acoplan, el contrato es el acuerdo.
- Si un contrato no se mantiene, **el integration test del consumidor
  rompe inmediatamente** — el catálogo se mantiene solo por presión
  del CI, no por un comité.
- Versionado SemVer en el nombre del archivo o en `metadata.version`
  del yaml. Owner = equipo **proveedor** del contrato.

**Gobernanza mínima**:
- PR en `.org/contracts/` requiere review del owner del contrato.
- CI valida: yaml válido, no se borra un contrato vivo sin deprecation
  path, SemVer respeta breaking-changes.
- **No** valida que "todos los repos existan" ni "todos los namespaces
  de OpenShift existen" — esa pretensión envejece mal en una org
  grande.

#### Política de deprecación de contratos

Un contrato breaking que se reemplaza por una versión nueva **no se
borra** — se mueve a `.org/contracts/deprecated/` con metadata de
sunset:

```
.org/contracts/
├── apis/
│   ├── identity-sso.openapi.v1.2.0.yaml     ← versión vigente
│   └── identity-sso.openapi.v1.1.0.yaml     ← vigente compatible
└── deprecated/
    └── apis/
        └── identity-sso.openapi.v0.9.0.yaml ← deprecated
```

Cada archivo en `deprecated/` lleva en su frontmatter:

```yaml
deprecated_at: 2026-04-01
sunset_date: 2026-07-01           # mínimo recomendado: 90 días
replaced_by: v1.0.0
reason: <breaking change descripción corta>
```

**Reglas mínimas**:

- **CI bloquea** el borrado de un archivo en `deprecated/` antes de
  `sunset_date`.
- Tras `sunset_date`, cualquier consumidor que aún lo referencie
  produce **build failure** (`spec-lint` busca referencias en specs
  vivas a contratos sunsetted).
- Período mínimo entre `deprecated_at` y `sunset_date`: **90 días**
  (el owner del contrato puede extenderlo).
- Cuando un contrato se mueve a `deprecated/`, el Service Agent del
  **proveedor** abre work items / mensajes a los equipos consumidores
  listados en el catálogo (si existe `catalog.yaml`) o pregunta al
  proveedor a quién notificar.

**Quién decide el sunset**: el owner del contrato. El sunset es
**irreversible** (§3.16): requiere OK explícito y notificación previa
a consumidores.

### Lo aspiracional (sólo si hay quién lo mantenga)

Los siguientes artefactos **pueden** vivir en `.org/`. **No** son
prerrequisito para arrancar features:

| Artefacto | Para qué sirve | Riesgo si no se mantiene |
|---|---|---|
| `catalog.yaml` (inventario de servicios, owners, runtime, SLOs) | Que Architect Agent no alucine al diseñar cross-service | Architect pregunta más al humano; no rompe el sistema |
| `service-map.mermaid` (diagrama de dependencias) | Onboarding visual | Onboarding más manual |
| `data-catalog/{databases,lineage}.yaml` | Compliance PII/residencia/lineage | Tracking manual en jiras |
| `policies/*.md` (data residency, PII, auth, change mgmt) | Política consultable por agentes consultivos | Se consultan vía wiki/Confluence |
| `adrs/` (Architecture Decision Records) | Memoria del "por qué" de decisiones grandes | Conocimiento tribal |
| `teams.yaml` | On-call, RACI | Slack channels / ADO teams |
| `templates/` (design templates, service-skeleton) | Bootstrap de repos nuevos | Cada equipo lo improvisa |

> **Recomendación pragmática por fase de adopción** (§16):
> - **Fase 1 (piloto)**: NO crear `.org/`. Si la feature piloto tiene
>   una dependencia cross-repo, su contrato vive temporalmente en uno
>   de los dos repos involucrados.
> - **Fase 2 (equipo completo)**: crear `.org/contracts/` cuando
>   aparezca la primera dependencia cross-repo. Nada más.
> - **Fase 3 (división)**: añadir `catalog.yaml` y `policies/` **sólo
>   si hay un Platform engineer FTE** dedicado a mantenerlos.
> - **Fase 4 (organización)**: el catálogo completo aparece de forma
>   orgánica cuando los equipos lo necesitan, no por decreto.

**Anti-pattern**: lanzar `.org/` "completo" desde el día 1, con todos
los YAML aspiracionales vacíos para "llenarlos más adelante". Lo que
se inicia con buenas intenciones queda incompleto para siempre y
desactualiza la fuente de verdad real.

> Para un ejemplo extenso de cómo se vería un `catalog.yaml`
> aspiracional maduro, ver Apéndice F (referencia, no plantilla
> obligatoria).

---

## Estructura de repositorios

### Recomendación: specs distribuidas (default)

**Cada repo de servicio contiene su propio `specs/`** — aplicación
directa del principio §3.7 *spec locality*. Una Initiative (cuando
aplica) vive en un repo "umbrella" de iniciativas y referencia las
features en cada repo por URL. No hay un repo central que contenga
specs de varios servicios.

```
<repo-de-iniciativas>/                  ← opcional, sólo si hay Initiatives
└── initiatives/<initiative-slug>/
    ├── overview.md
    ├── stakeholders.md
    ├── constraints.md
    ├── architecture.md
    ├── rollout-plan.md
    └── features-index.md               ← links a specs/<feature> en cada repo

<repo-de-servicio>/                     ← obligatorio (uno por servicio)
├── AGENTS.md
├── CLAUDE.md
├── repo-config.yaml                    ← config operacional del repo (§6 Configuración del repo)
├── .claude/commands/
├── .cursor/rules/
├── specs/<feature>/                    ← spec local del servicio
│   ├── requirements.md
│   ├── design.md
│   ├── tasks.md
│   ├── status.md
│   ├── bugs.md
│   ├── amendments.md
│   └── mocks/
├── src/
└── tests/

<repo-de-org>/                          ← opcional, sólo si hay catálogo
└── .org/
    ├── contracts/                      ← contratos publicados (§9)
    └── (otros artefactos compartidos)
```

**Ventajas**: autonomía de equipos, encaja con team projects
independientes en Azure DevOps, sin cuello de botella central,
escalable a 100+ devs.

**Disciplina requerida**: contratos versionados (§6) cuando hay
dependencias cross-repo. Sin contrato, la autonomía se vuelve
fragmentación.

### Inventario de archivos de la metodología en cada repo

Cada repo debe incluir en su `AGENTS.md` una sección **Inventario de
archivos de la metodología** que liste explícitamente qué paths
pertenecen a AI-DLC vs qué es código del proyecto. Esto evita
confusión cuando un dev nuevo abre el repo (¿qué es metodología?,
¿qué es de la app?), y sirve como checklist al agregar artefactos.

> **No prefijar archivos con el nombre de la org** (`syc-AGENTS.md`,
> `syc-spec-new.md`, etc.). Razones: (a) `AGENTS.md` y `CLAUDE.md` son
> estándares abiertos que las tools agente buscan literalmente —
> renombrarlos los rompe; (b) los slash commands ganan UX al ser
> cortos y consistentes entre adopciones (`/spec-new` se reconoce sin
> contexto, `/syc-spec-new` no); (c) atás la metodología a la
> identidad de la org, perdiendo portabilidad. **El namespace ya
> existe vía directorios**: `.claude/commands/`, `.agents/commands/`,
> `stack/`, `specs/`, `.org/` son todos paths exclusivos de AI-DLC.

Formato recomendado: tabla con columnas `Path | Propósito | Cargado
en sesión` que incluya `AGENTS.md`, `CLAUDE.md`, `repo-config.yaml`,
`.claude/commands/`, `.agents/commands/`, `.agents/skills/`, `stack/`,
`specs/<feature>/`, `.org/contracts/`, `.mcp.json` (si aplica). Más
una nota explícita: *"todo lo demás (`src/`, `tests/`, etc.) es código
del proyecto"*. La columna `Cargado en sesión` ayuda a justificar lazy
loading (`.agents/commands/<name>.md` se carga sólo al invocar el
comando, no en cada sesión).

#### Skills agente y su lifecycle

`.agents/skills/` merece nota especial. **El template starter NO
trae ninguna skill pre-instalada** — ni siquiera meta-skills tipo
`find-skills`. La decisión de qué skills usar (o si usar skills) es
de cada repo, no del template.

**Por qué cero defaults**:

- Las skills concretas (`shadcn`, `playwright-best-practices`,
  `vitest`, `next-best-practices`, etc.) son **específicas del
  stack** del repo. Un repo Python no necesita `shadcn`; un repo Go
  no necesita `vercel-react-best-practices`. Pre-instalarlas
  contamina repos con otro stack y desperdicia tokens (skills agente
  son grandes — un set típico Next.js ocupa ~1-2 MB en disco).
- Las meta-skills tipo `find-skills` también son una **decisión del
  repo**: leen de fuentes específicas (`skills.sh`, GitHub, etc.) y
  el equipo puede preferir otra fuente o crear skills propias a mano.

**Métodos de instalación** (la metodología es agnóstica al método):

- **Manual**: copiar el sub-directorio de la skill a
  `.agents/skills/<name>/` desde su repo de origen.
- **Vía meta-skill `find-skills`** (vercel-labs/skills, lee de
  skills.sh): instalar `find-skills`, invocarla con `stack/` completo,
  aprobar lista propuesta. Genera/actualiza `skills-lock.json`.
- **Vía `skills.sh`, `agnix`, u otro package manager** de skills.
- **Crear a mano**: escribir un `SKILL.md` con frontmatter
  `name` + `description` y body markdown.

**Formato canónico** de una skill:

```
.agents/skills/<name>/
├── SKILL.md          # principal, con frontmatter
└── (otros archivos)  # references, examples, sub-docs (opcional)
```

```yaml
---
name: <kebab-case-name>
description: <una línea — el agente la lee para decidir cuándo usar>
---

# <Título>

<Body markdown libre>
```

Las tools agente (Claude Code, OpenCode, Cursor, Codex CLI) leen
`.agents/skills/<name>/SKILL.md` directamente y dispatch por nombre +
descripción.

**Lock file `skills-lock.json`** (opcional, al root del repo): sólo
si se usan meta-skills que validan integridad (`find-skills` lo
genera). Si se instala manualmente o se crea a mano, no es necesario.

**Anti-patterns**:

- **Copiar skills de un repo a otro "porque sirvieron en el otro"**.
  Cada repo decide basándose en su stack/. Si dos repos comparten
  stack, ambos pueden llegar a conjuntos similares — pero la
  decisión vive en cada repo, no se hereda silenciosamente del
  template.
- **Pre-instalar skills en el template starter**. Aunque sea sólo
  `find-skills`, es una decisión de fuente (`skills.sh`) que ata el
  template a una herramienta. Mejor que el README de
  `.agents/skills/` documente las opciones y el usuario decida.

### Anti-pattern: specs centralizadas

Tener un repo central con todas las specs (estilo `<org>-specs/`
conteniendo features de todos los servicios) **rompe el principio
§3.7** y genera un cuello de botella político: en un repo donde
escribe todo el mundo, todo el mundo necesita aprobar.

Síntomas reproducibles en organizaciones que lo intentaron:

- PRs de spec se quedan días esperando review porque el "dueño" del
  repo central es uno solo o un comité.
- El repo se vuelve aspiracional: la verdad real migra a issues,
  Slack, o docs paralelos.
- No encaja con team projects de ADO (un repo Git ≈ un solo project).
- La métrica de Tipo B se contamina con "spec no estaba porque no me
  dejaron escribirla" — falsos negativos en authoring.

Si la organización requiere centralización por una razón regulatoria,
**el catálogo `.org/` cubre esa necesidad sin centralizar specs de
feature** (§9): basta con publicar oficialmente contratos, políticas y
ADRs en `.org/`, dejando las features en sus repos.

---

## Herramientas: Cursor + Claude Code

### División de roles

| Herramienta | Rol | Por qué |
|---|---|---|
| **Cursor** | Spec authoring, edición fina, exploración | UI rica, diff visual |
| **Claude Code** | Generación masiva, refactors, tareas largas | Agente autónomo en terminal |
| **Git / Azure Repos** | Fuente de verdad de specs y código | Versionado |

### Estructura de proyecto

```
my-service/
├── .cursor/
│   └── rules/
│       ├── 00-spec-driven.mdc        ← regla global SDD
│       ├── 10-stack.mdc              ← stack tecnológico
│       ├── 20-testing.mdc            ← convenciones de tests
│       └── 30-azure-devops.mdc       ← work item integration
├── .claude/
│   ├── CLAUDE.md                     ← instrucciones para Claude Code
│   └── commands/
│       ├── spec-new.md
│       ├── spec-implement.md
│       ├── spec-verify.md
│       └── bug-triage.md
├── specs/
├── src/
└── tests/
```

### Reglas globales de Cursor

**`.cursor/rules/00-spec-driven.mdc`**

```markdown
---
description: Spec-driven development workflow
alwaysApply: true
---

Este proyecto usa Spec-Driven Development (SDD). Las specs viven en
`/specs/<feature-name>/` y son la fuente de verdad.

## Reglas

1. NUNCA escribir código de producción sin spec en /specs/
2. Cuando te pidan implementar algo, primero revisa /specs/<feature>/
3. Requirements en formato EARS (WHEN/WHILE/WHERE/IF-THEN/SHALL)
4. Cada test debe trazar a un R*.* con comentario `// Derived from R*.*`
5. Si la spec es incorrecta/incompleta, STOP y actualízala primero
6. Vincular PRs a work items de Azure DevOps via AB#<id> en commit messages
```

### `CLAUDE.md` del repo

```markdown
# Project: <service-name>

## Workflow: AI-DLC con SDD

Este proyecto usa AI-DLC. Ver /specs/ para todas las especificaciones.

## Al implementar un feature

1. Leer /specs/<feature>/requirements.md
2. Leer /specs/<feature>/design.md
3. Seguir /specs/<feature>/tasks.md en orden
4. Actualizar /specs/<feature>/status.md tras cada tarea
5. Cada test debe tener `// Derived from R*.*`

## Si la spec es ambigua

STOP. No adivines. Pregunta al usuario o propón actualización de spec.

## Convención de commits

`<type>(<scope>): <desc> [R<x>.<y>] AB#<workitem-id>`

Ejemplo: `feat(auth): add reset token [R1.2, R1.3] AB#12345`

## Comandos disponibles

**Bootstrap / Adopción** (entry-point para adoptar AI-DLC sobre cualquier repo):
- /adopt &lt;target-path&gt; [--greenfield | --brownfield | --upgrade | --dry-run] — agente conversacional. Modelo recomendado **X → Y**: corre desde la instalación del template (`~/.syc/ai-dlc/`) operando sobre el repo target absoluto. Aísla el contexto del agente del AGENTS.md/CLAUDE.md previos del target (que entran como datos, no como autoridad). 6 fases: pre-flight → detect (Cat A vs B con sub-protocolo AGENTS.md previo de 4 sub-categorías) → clarify → propose plan → execute con OK → close. Modo Y fallback (cwd = target) disponible pero degradado. Canonical en `ADOPT.md` del template.

**Service Agent** (en el repo del servicio, ver §11 Slash commands clave):
- /spec-new <feature> — bootstrap de nueva spec con entrevista guiada
- /spec-implement <feature> — avanzar la siguiente task con pre-flight check
- /spec-status <feature> — resumen legible del estado (read-only)
- /spec-verify <feature> — auditar cobertura R*.* ↔ tests, gaps, drift
- /spec-amend <feature> --reason "<motivo>" — cambio post-aprobación
- /spec-handoff <feature> --to <@user> — transferir ownership a otro dev (rotación, baja)
- /spec-promote <feature> --to <env> — abrir PR de promoción (pruebas → qa → main)
- /bug-triage <desc> — clasificar bug (A/B/C/D/E)

**Architect Agent** (cross-service / Initiatives, ver §15 Flujo end-to-end). *Propuestos, no implementados — bodies completos diferidos hasta caso real cross-team que los ejerza*:
- /initiative-new <slug> — crear Initiative con discovery dirigido
- /initiative-fanout <slug> — generar stubs de feature en cada repo de servicio
- /spec-sync — sincronizar Initiative ↔ Azure Boards (Epic/Feature/Story)

**Diseño** (Figma + Figma Make, ver §12):
- /figma-brief <feature> — generar brief de diseño desde la spec
- /figma-make-integrate <ruta-zip> — integrar ZIP de Figma Make al repo

> **Fork personal**: `/ado-*` (Azure DevOps) y `/oc-*` (OpenShift) NO
> existen en este fork. Si tu proyecto personal usa GitHub Issues,
> Jira, Linear u otro tracker, los comandos de integración son
> opcionales y se construyen on-demand cuando aparezca el caso real.
```

> **Atajos, no obligación.** Los slash commands de esta sección son
> **opcionales** — el dev no necesita memorizarlos. El Service Agent
> (§7) actúa como dispatcher: detecta intención en lenguaje natural y
> propone el slash command apropiado. Estos comandos están aquí para
> (a) devs experimentados que prefieren invocar directo, (b) scripts
> CI / dashboards que necesitan invocación determinística, (c)
> documentar el contrato del agente.

> **`.agents/commands/` como fuente de verdad multi-tool**. Las
> definiciones de cada slash command viven en archivos individuales
> en `.agents/commands/<name>.md` de cada repo (canonical, lazy-loaded).
> AGENTS.md contiene **sólo** la tabla de comandos disponibles + un
> pointer a `.agents/commands/`; los bodies completos se cargan
> on-demand cuando el comando se invoca (sea por slash o por lenguaje
> natural), no en cada sesión. Esto baja el costo de contexto del
> AGENTS.md de ~10K tokens a ~2-3K tokens.
>
> AGENTS.md sigue siendo el archivo que **todas** las tools agente
> leen al arrancar (Claude Code, Cursor, Codex CLI, Continue, Aider,
> OpenCode). Los archivos en `.claude/commands/<n>.md` son **symlinks**
> a `.agents/commands/<n>.md` — existen sólo para que el slash menu
> de Claude Code descubra los comandos; el body canonical es el
> archivo apuntado, sin duplicación ni drift. Tools sin convención
> de archivos de slash commands (Cursor, Codex CLI, etc.) hacen
> **dispatch por lenguaje natural** leyendo la tabla en AGENTS.md
> (el dev dice *"arrancá una spec para canjes"*, la tool reconoce =
> `/spec-new canjes` desde la tabla, lee `.agents/commands/spec-new.md`
> on-demand). Por lo tanto **no se generan** `.cursor/rules/`,
> `.codex/...`, etc. — un repo agnóstico funciona idéntico para
> cualquier tool del equipo, sin duplicar bodies de comandos.
> `.agents/commands/` se alinea con `.agents/skills/` (estándar
> emergente para skills agente).

> **Symlinks y Windows**. Los symlinks de `.claude/commands/<n>.md` →
> `../../.agents/commands/<n>.md` funcionan nativamente en macOS y
> Linux. En **Windows** requieren: (a) `git config core.symlinks
> true` (default desde Git for Windows 2.10+), (b) developer mode
> habilitado en Windows 10+ o ejecutar git con permisos elevados. Si
> el equipo tiene compañeros con setup corporativo que **no permite**
> habilitar developer mode, hay 3 alternativas: (1) aceptar y
> documentar el setup requerido, (2) usar wrappers de texto en lugar
> de symlinks (peor: introduce drift), (3) script post-clone que
> materialice los symlinks como copies en Windows. La metodología
> recomienda (1) por simplicidad; (3) es razonable para equipos con
> >2 devs en Windows restringido.

> **Aplicabilidad por `repo-config.yaml`** (§6 *Configuración del
> repo*). En el fork personal los comandos de integración con tracker
> no vienen pre-construidos (se construyen on-demand). Los `/figma-*`
> sólo aplican si tu proyecto declara `design_service`. El Service
> Agent explica si un comando solicitado no aplica.

### Slash commands clave

#### `/adopt`

```markdown
---
description: Agente conversacional de adopción AI-DLC sobre un repo target
argument-hint: <target-path> [--greenfield | --brownfield | --upgrade | --dry-run]
---

Protocolo en 6 fases (canonical en `ADOPT.md` del template AI-DLC). El
agente ejecuta **desde la instalación del template** (X) operando
sobre el **repo target** (Y) pasado como argumento (modelo X → Y,
default recomendado).

**Setup (una sola vez)**:

```
git clone <ado>/syc/ai-dlc-stack-template ~/.syc/ai-dlc
```

**Uso típico**:

```
cd ~/.syc/ai-dlc && claude
> /adopt /Users/picojuanc/repos/<mi-repo>
```

Las 6 fases:

1. **Phase 0 — Pre-flight** (read-only, ~30 seg). **P0.0** resuelve
   target absoluto Y vs template X; STOP si target == template o
   target ⊂ template. P0.1 verifica que target es repo git, working
   tree limpio (4 opciones si sucio: stash/commit/cerrar feature
   primero/abort — la 3ra es default para >50 archivos modificados).
   P0.2 rama segura. P0.3 detecta modo (greenfield/brownfield/upgrade).
   **P0.4** detecta el default branch dinámicamente (no asumir `main`)
   via `git symbolic-ref refs/remotes/origin/HEAD`; pedir confirmación
   al dev. Esperar OK antes de Phase 1.

2. **Phase 1 — Detect** (read-only, ~3 min, sólo brownfield/upgrade).
   Audita: stack técnico (P1.1), **AI infra previa** clasificando
   Categoría A (tool externo) vs B (custom interna del equipo, §15)
   incluyendo el sub-protocolo `AGENTS.md` previo (4 sub-categorías
   A.1/A.2/A.3/A.4) y la detección de wrappers Cat A → Cat B
   archivo-por-archivo (P1.2), memoria de sesión `.md` + `.txt` con
   catálogo extensible (P1.3), branches y ambientes con drift
   detection (P1.4), estructura monorepo (P1.5), pipelines y
   multi-tenant fan-out (P1.6). Emite resumen estructurado (P1.7) y
   pide OK antes de Phase 2.

3. **Phase 2 — Clarify** (entrevista, ~10 min). Una pregunta a la
   vez, con evidencia citada, opciones explícitas y `(Recommended)`
   marcada. Catálogo de 18 preguntas — saltea las que no aplican.
   Pregunta clave (Q9): por cada AI infra Categoría B detectada,
   confirmar si es custom interna del equipo (consolidar en AI-DLC,
   con clasificación archivo-por-archivo) o externa mal identificada
   (tratar como A). **Q4.bis nueva en v0.16**: rama base del
   bootstrap (default branch directo vs primera rama del
   `promotion_path`; default fuerte para chores = directo al
   default).

4. **Phase 3 — Propose**. Escribe el plan completo en
   `<target>/.ai-dlc-adoption-plan.md`: decisiones,
   OPEN_QUESTIONS, archivos a crear/modificar/mover/consolidar/
   respetar, commit propuesto, reversión, siguientes pasos. STOP
   — pide OK explícito sobre el plan escrito antes de aplicar.

5. **Phase 4 — Execute** (escribe, ~2 min). Crea branch
   `chore/adopt-ai-dlc` en target. Aplica writes en orden estricto
   respetando invariantes (no sobreescribir CLAUDE.md sustantivo;
   no remover skills pobladas; espejar reglas Categoría A;
   consolidar Categoría B confirmada; AGENTS.md previo
   sustantivo → SÓLO append entre sentinels
   `ai-dlc:section-start/end`). Detección de plataforma para
   symlinks vs wrappers (Windows). NO ejecuta el commit final sin
   OK adicional.

6. **Phase 5 — Close**. Emite reporte humano (conteo de archivos,
   OPEN_QUESTIONS pendientes, siguientes pasos, comando de
   reversión). Archiva `.ai-dlc-adoption-plan.md` → `<target>/archive/`.

Reglas operacionales raíz:

- NO ASUMIR (§3.12). Decisión sin evidencia = pregunta o
  `OPEN_QUESTION`.
- Read-only hasta Phase 4. Sólo escribe el plan antes de tener OK.
- Una pregunta a la vez en Phase 2.
- Citar evidencia de Phase 1 en cada propuesta.
- Reversible: todo en `chore/adopt-ai-dlc`. `git branch -D` deshace.
- AGENTS.md previo sustantivo: NUNCA merge semántico — sólo
  appended-section entre sentinels.
- **PR-only por diseño**: el bootstrap NUNCA modifica el default
  branch directamente. NUNCA ejecuta `git push`, `git merge` o
  `git checkout <base>` que toque la base. Compatible con branch
  protection de Azure DevOps / GitHub / GitLab.

Modelos:

- **X → Y** (default): agente cwd = template (`~/.syc/ai-dlc/`),
  target pasado como argumento. Aísla contexto del agente.
- **Y** (fallback): agente cwd = target, invocado como `/adopt .`
  o "leé `<template>/ADOPT.md` y aplicalo a este repo". Pierde
  aislamiento — las tools cargan AGENTS.md/CLAUDE.md previos como
  autoridad. Reportar como degradado.

Modos (ortogonales al modelo):

- `--greenfield`: repo vacío. Saltea Phase 1.
- `--brownfield`: default. Las 6 fases.
- `--upgrade`: lee `.ai-dlc-version` existente, diff vs metodología
  actual, propone cambios incrementales.
- `--dry-run`: ejecuta Phase 0-3, escribe plan, NO ejecuta Phase 4.

Body completo en `ADOPT.md` del template. Anti-patrones explícitos
a rechazar listados ahí + en §15 *Anti-patrones brownfield*.
```

#### `/spec-new`

```markdown
---
description: Iniciar una feature spec con entrevista guiada
---

Sigue el protocolo §7. Para la feature $ARGUMENTS:

1. **CONTEXT** — verificar:
   - Repo actual y rama de trabajo.
   - ¿La feature pertenece a una Initiative? Si sí, pedir URL o slug
     (recordar: Initiative es opcional, §6).
   - ¿Hay un PR de requerimiento del cliente, work item de origen,
     conversación previa relevante?

2. **WORKTREE** — preparar el espacio de trabajo aislado (§6
   *Worktree, ramas y flujo de promoción*):
   - **Preguntar** la rama base ofreciendo las ramas declaradas en
     `repo-config.yaml > environments[].branch` (§6 *Configuración del
     repo*). Si `repo-config.yaml` no existe, parar y proponer crearlo
     antes de seguir.
   - **Proponer** crear:
     `git worktree add -b feat/<feature-slug> ../<repo>--<feature-slug> origin/<base>`
     y pedir OK antes de ejecutar (acción reversible pero observable).
   - Tras crear, **verificar** que el `cwd` quedó en el worktree
     nuevo antes de continuar.

3. **CLARIFY** — entrevista guiada, **una pregunta a la vez**:

   **3.a Discover existing work item (v0.17)** — sólo si
   `repo-config.yaml > trackers[]` declara al menos un tracker. Antes
   de cualquier otra pregunta:

   > "¿Esta spec corresponde a un work item existente en ADO?
   >
   > (a) Sí — pasame el ID o el título que busque. *(Recommended
   >   default en brownfield si `creation_mode: discover-first`.)*
   > (b) Parcial — el padre existe, faltan children por crear.
   > (c) No — es nueva, propondré crear la jerarquía después."

   IF (a) o (b): el agente consulta vía MCP o `az boards work-item show`
   y `az boards query`. Reporta lo encontrado (Feature, children, AC).
   Si el repo declara stakeholders, también pregunta:

   > "¿Esta spec implementa además alguna Feature/User Story en un
   > project stakeholder (ej. equipo cliente)? Si sí, pasame el ID."

   IF (c): salta al modo `assisted` para crear, pero sólo en EXECUTE.

   **3.b Entrevista funcional clásica**:
   - ¿La feature pertenece a una Initiative? Si sí, pedir URL o slug
     (recordar: Initiative es opcional, §6).
   - ¿Cuál es el problema que resuelve esta feature? ¿Quién es el
     usuario primario? (si vino de 3.a Feature ADO existente: el
     `Description` del work item es input, NO se descarta)
   - ¿Cuáles son los criterios de éxito **observables**? (forzar NFRs
     medibles — "rápido" no vale; "p99 < 500ms" sí)
   - ¿Restricciones legales / compliance / residencia de datos?
   - ¿Toca otros servicios? ¿De qué equipos?
   - ¿Depende de algo que aún no existe (SP, endpoint, librería,
     componente de diseño)? — futuras `D-N` (§6).
   - ¿Cómo se prueba cada R*.* (unit / integration / e2e / contract /
     load / accessibility)?
   - Si no hay respuesta clara, marcar `OPEN_QUESTION` en la spec —
     **NO inventar** (§3.12).

3. **PROPOSE** la estructura inicial; pedir OK antes de escribir.

   IF 3.a (a) — la jerarquía ADO existe: `requirements.md` extrae
   `R*.*` desde los Acceptance Criteria de los children. `tasks.md`
   mapea 1:1 a los work items existentes (con `discovered: true`).
   `status.md` declara `spec_represents` + `spec_owns` con flags.
   **Cero work items nuevos creados en ADO**.

   IF 3.a (b) — gap parcial: refleja los existentes + lista los
   nuevos a crear con sus comandos `az`. Pide OK por cada uno.

   IF 3.a (c) — spec nueva totalmente: propone la jerarquía
   AI-DLC + comandos `az` para crearla (modo `assisted` per
   `repo-config.yaml`).

   En cualquier caso: anti-patrón **duplicación catastrófica**. Antes
   de proponer crear, buscar por título similar (`az boards query
   --wiql "...CONTAINS '<título>'"`). Si hay matches, reportar al dev
   antes de seguir.

   **3.c Conflict scan cross-spec (v0.18)** — antes de PROPOSE:

   El agente compara la spec nueva con las specs activas del repo
   (state ≠ `legacy`, ≠ `archived`, ≠ `cancelled`) buscando
   contradicciones. Heurística textual simple:

   - Listar specs activas:
     `grep -rl "^state:" specs/ | xargs grep -L "state: \(legacy\|archived\|cancelled\)"`
   - Extraer "puntos de superficie" de la spec nueva (de CLARIFY
     3.b): endpoints citados, IDs de stored procedures, paths de
     módulos, feature flags, nombres de contratos, valores de NFRs
     conflictivos (timeouts, límites, formatos).
   - Cruzar contra los `R*.*` y `design.md` de las otras specs.
   - Reportar candidates con cita explícita:

   > "Posibles conflictos detectados:
   >
   > **1. `specs/saldo-puntos/` R3.1** dice: 'endpoint
   > `POST /points/award` retorna `{ amount, currency }`'. Tu nueva
   > spec menciona `/points/award` con shape `{ value, unit }`.
   > ¿Cambio intencional?
   >
   > **2. `specs/auth-revamp/` design.md** declara feature flag
   > `new-auth=ON @100% desde D30`. Tu nueva spec asume flujo de
   > auth viejo. ¿Esto es coexistencia temporal?
   >
   > Por cada conflicto, decime:
   > - (a) **Alinear mi spec** — modifico mi spec para no contradecir.
   > - (b) **Amendment de la otra spec** — la otra cambia (abrir
   >   `AMD-NNN` ahí).
   > - (c) **Coexisten intencionalmente** — documentar el por qué en
   >   mi `design.md` sección `Conflicts resolved`.
   > - (d) **OPEN_QUESTION** — diferir."

   Las decisiones se persisten en `requirements.md` (si afectan
   contratos) o `design.md` (si afectan implementación) bajo la
   sección `Conflicts resolved`.

   Falsos positivos esperables — la heurística textual es barata
   pero ruidosa. Mejor sobre-detectar que sub-detectar; el dev
   decide.

   Si NO hay conflictos detectados: el agente lo declara explícitamente
   (*"Scan completo, sin conflictos con las N specs activas. Si
   crees que falta uno, decímelo."*) — porque el silencio es
   ambiguo.

4. **EXECUTE** — crear /specs/$ARGUMENTS/:
   - requirements.md (EARS R1.1, R1.2... + Dependencies si aplica +
     Tests strategy por R*.*)
   - design.md (esqueleto con secciones obligatorias, a llenar tras
     aprobación de requirements)
   - tasks.md (vacío hasta que design esté firmado)
   - status.md (state: not-started, todas tasks pending — §6 Lifecycle)

5. **CLOSE** — reportar:
   - Qué se creó.
   - Qué `OPEN_QUESTION` quedan abiertas (bloquean aprobación).
   - Siguiente paso sugerido: completar `OPEN_QUESTION` → revisar con
     stakeholders → aprobar antes de pasar a design.

NO escribir código de producción. Esperar aprobación de la spec.
```

#### `/spec-implement`

```markdown
---
description: Avanzar la siguiente task con pre-flight check
---

Sigue el protocolo §7. Para feature $ARGUMENTS:

1. **CONTEXT** — leer status.md, tasks.md, requirements.md, design.md,
   y dependencies/amendments si existen.

2. **PRE-FLIGHT CHECK** — reportar al dev:
   - **Worktree correcto**: `cwd` es `<repo>--<feature-slug>/` y la
     rama activa es `feat/<feature-slug>` (§6 Worktree). Si no
     coinciden, **parar** y proponer moverse al worktree correcto.
   - Spec aprobada (status.md lo confirma; si no, **parar**).
   - Última task `done` y commit hash.
   - Cuál es la siguiente task `pending` (no `blocked`).
   - ¿Hay tasks `blocked` que el dev quizá quiera revisar antes
     (`blocked_by`: dependencia, decisión humana, etc.)?
   - ¿Tests del último deploy verdes? Si no, **parar** y reportar.
   - ¿Commits desde el último update de status.md? Si sí, preguntar
     si integrarlos al lifecycle (§7 reglas operacionales).
   - ¿`state` declarado coincide con la derivación del Lifecycle
     (§6)? Si no, decirlo.

3. **CLARIFY** — si la siguiente task tiene ambigüedad, depende de
   una `D-N` aún no `AGREED`, o requiere decisión humana (naming,
   migration risk, breaking change), **preguntar antes de tocar
   código** (§3.12).

4. **PROPOSE** — explicar:
   - Archivos a crear/modificar.
   - Tests a escribir (con `// Derived from R*.*`).
   - Nivel de riesgo / complejidad estimado.
   - Pedir OK explícito si la task es M/L o toca código compartido.

5. **EXECUTE**:
   - Tests primero con `// Derived from R*.*`.
   - Código que pase tests.
   - Linter, typecheck.
   - Iterar hasta verde.

6. **UPDATE STATUS** — status.md: task → `done` o `deployed:<env>`
   según corresponda, con commit hash y fecha (§6 Lifecycle).
   Actualizar el campo `state` si cambia.

7. **CLOSE** — reportar:
   - Qué se hizo (task ID, R*.* cubiertos, commit hash).
   - Qué quedó pendiente (siguientes tasks, `D-N` involucradas).
   - **Siguiente paso sugerido**: abrir PR ahora, continuar con la
     siguiente task, esperar review humano, desplegar a dev, etc.
   - Si la siguiente task podría avanzarse, **preguntar** antes de
     continuar — NO auto-avanzar (§3.16).
```

#### `/spec-status`

```markdown
---
description: Resumen legible del estado de la feature (read-only)
---

Para feature $ARGUMENTS, leer (sin modificar nada):
- requirements.md → contar R*.* totales, agrupar por estado
- tasks.md + status.md → done / in-progress / pending / blocked (con causa)
- bugs.md → bugs abiertos por tipo (A/B/C/D/E)
- (si existe) amendments.md → últimos `AMD-NNN` (cambios post-aprobación) y `HANDOFF-NNN` (eventos de ownership)
- sección `Dependencies` de requirements.md → `D-N` y su estado (§6)
- Última ejecución de tests por nivel (unit / integration / e2e / contract / load)
  con cuántos R*.* cubre cada nivel

Producir un resumen humano con:
- Progreso global de R*.* (implementadas / pendientes / bloqueadas)
- Tasks completadas vs pendientes vs bloqueadas y causa
- Cobertura de tests **por nivel** (no sólo global)
- Bugs abiertos con su tipo
- Amendments recientes
- **Siguiente paso sugerido** — qué task arrancar o desbloquear

Pensado para retomar trabajo tras una pausa (límite de tokens, fin de
jornada, handoff a otro dev, etc.). NO escribe nada. El mismo reporte
debe poder ejecutarse como CLI fuera de Claude Code (`npx
@syc/ai-dlc-status <feature>`) para pipelines y dashboards.
```

#### `/spec-amend`

```markdown
---
description: Cambio de spec post-aprobación (cliente, regulación, negocio)
---

Para feature $ARGUMENTS con motivo $REASON:

1. Leer requirements.md, tasks.md, status.md actuales.
2. Identificar qué R*.* y tasks están potencialmente afectadas por el
   cambio (proponer, NO decidir en solitario).
3. Confirmar con el usuario el alcance final del cambio.
4. Editar requirements.md:
   - R*.* que dejan de aplicar se marcan ~~tachadas~~ (no se borran).
   - R*.* que cambian se reescriben in-place.
   - R*.* nuevas se añaden con la siguiente numeración disponible.
5. Editar tasks.md:
   - Tasks que dejan de aplicar → cancelled.
   - Tasks que cambian → modificadas.
   - Tasks nuevas → añadidas al final, ordenadas por dependencia.
6. Anotar el evento en amendments.md (crear si no existe):

   ## AMD-NNN — <título corto> (<fecha>)
   - Motivo: <descripción + fuente: cliente / legal / negocio>
   - Autor: <quién lo dictó> vía <quién lo registró>
   - R*.* afectadas: <lista>
   - Tasks afectadas: <lista>
   - PR de spec: !<id>
   - PR de implementación: !<id>

7. Los commits posteriores citan AMD-NNN además de R*.*. Ejemplo:
   `feat(loyalty): T11 - consent gate [R3.2 AMD-001] AB#12399`

Un Amendment NO es un bug Tipo B. Tipo B son cosas que estaban mal
desde el inicio; un Amendment es un evento nuevo posterior a la
aprobación. Mantener la distinción mejora la métrica de calidad de
spec authoring (si todo se mete como Tipo B, el agente nunca aprende).
```

#### `/spec-handoff`

```markdown
---
description: Transferir ownership de una feature a otro dev (rotación, baja)
---

Sigue el protocolo §7. Para feature $FEATURE con destino $NEW_OWNER:

1. **CONTEXT** — leer requirements.md, status.md, amendments.md,
   bugs.md, commits recientes del worktree y `OPEN_QUESTIONS`.

2. **CLARIFY** — preguntar:
   - ¿Es handoff **total** (cambio de owner) o **parcial** (cubrir
     vacaciones, ayuda temporal)?
   - ¿El dev saliente sigue accesible para preguntas o es baja
     definitiva?
   - ¿Hay conversaciones abiertas (chat / email / call) con el equipo
     proveedor de alguna `D-N` que sólo el dev saliente conocía? ¿En
     qué canal?

3. **GENERATE RESUMEN** — producir resumen ejecutable para
   $NEW_OWNER (mostrar primero, NO escribir aún):
   - Problema y motivación (de `requirements.md`).
   - Estado actual: tasks done / in-progress / blocked y por qué
     (de `status.md` y derivación del Lifecycle).
   - `D-N` activas: estado, contrato vigente, owner del otro lado,
     último contacto conocido, riesgo si el dev saliente era el único
     interlocutor.
   - Bugs abiertos.
   - Amendments aplicados (qué cambió y por qué).
   - **Pre-flight check obvio**: qué task arrancaría yo ahora.
   - `OPEN_QUESTIONS` pendientes con owner / due.
   - Riesgos y "cosas a mirar primero".

4. **EXECUTE** — tras OK del dev saliente y, si está accesible, del
   $NEW_OWNER:
   - Actualizar `owner:` en frontmatter de `requirements.md`.
   - Re-asignar work items en ADO
     (`az boards work-item update --assigned-to`).
   - Anotar el evento en `amendments.md` como entrada especial con
     prefijo `HANDOFF-NNN`:

     ```
     ## HANDOFF-001 — <fecha>
     - **Tipo**: total | parcial
     - **De**: @<saliente>
     - **A**: @<entrante>
     - **Motivo**: <rotación | baja | vacaciones | ayuda>
     - **Conversaciones a re-abrir**: D1 (canal X), D3 (email a Y)
     - **Resumen handoff**: <link al doc del paso 3>
     ```

   - `D-N` cuyo `Tracking:` apuntaba a una conversación personal
     del saliente: marcar como `NEGOTIATING-stale` (§6 SLAs) y proponer
     reabrir el contacto desde $NEW_OWNER.

5. **CLOSE** — entregar a $NEW_OWNER:
   - Path del worktree.
   - Link al resumen del paso 3.
   - **Acciones inmediatas sugeridas**: leer requirements + design,
     correr `/spec-status`, reabrir `D-N` stale, decidir si seguir o
     `cancelled`.
   - Confirmación: el dev saliente puede ejecutar `git worktree
     remove` tras OK explícito del entrante (§3.16).

Un handoff **NO** es un Amendment ni un bug — es un evento de
ownership. El prefijo `HANDOFF-` en `amendments.md` lo distingue de
`AMD-` (Amendments) y no contamina las métricas de ninguno.
```

#### `/spec-promote`

```markdown
---
description: Abrir PR de promoción al siguiente ambiente (pruebas → qa → main)
---

Sigue el protocolo §7. Para feature $ARGUMENTS con destino $TO_ENV:

1. **CONTEXT** — verificar:
   - Worktree correcto (`cwd` = `<repo>--<feature-slug>/`) y rama
     actual (§6 Worktree).
   - Estado actual de la feature (`status.md`).
   - Ambiente destino válido: presente en
     `repo-config.yaml > environments[].name` (§6 *Configuración del
     repo*). En `repo_type: library`, `--to pruebas` significa publicar
     prerelease al registry y `--to main` significa publicar release.

2. **PRE-FLIGHT CHECK** — verificar las condiciones del gate de
   promoción (§6 Flujo de promoción):
   - PR a `pruebas`: tests verdes + spec aprobada + state ≥
     `partial-deploy-pruebas`.
   - PR a `qa`: tests verdes + QA sign-off (pendiente o adquirido) +
     state ≥ `partial-deploy-qa` o `feature-complete`.
   - PR a `main`: state `feature-complete` + `rollout-plan.md` con
     fases definidas + Ops sign-off (pendiente o adquirido).
   - Si falta algo, **parar** y reportar qué falta y a quién pedirlo.

3. **CLARIFY** — si la rama destino del PR es ambigua (varias ramas
   `qa-*`, por ejemplo), preguntar cuál. Si el feature flag de prod
   debe ir `OFF` al merge (lo normal), confirmar.

4. **PROPOSE** — mostrar al dev:
   - Branch source y target.
   - Resumen del PR: `R*.*` cubiertos, `AMD-NNN` aplicados, tasks
     done, commit count.
   - Reviewers sugeridos (equipo / QA / Ops según destino).
   - **Pedir OK explícito** antes de abrir el PR (§3.16 — acción
     visible a otros equipos).

5. **EXECUTE**:
   - `az repos pr create --source-branch <current>
     --target-branch <target> --title "..." --description "..."`
     (vía MCP de ADO o `az` CLI).
   - Linkear work items relevantes (`--work-items`).

6. **UPDATE STATUS** — cuando el dev confirme que el PR se mergeó:
   - Tasks afectadas → `deployed:<target-env>`.
   - Recalcular `state:` de la feature según §6 Lifecycle.

7. **CLOSE** — reportar:
   - URL del PR.
   - Qué gates faltan para la siguiente promoción.
   - **Siguiente paso sugerido** (ej. *"cuando QA firme, corre
     `/spec-promote <feature> --to qa`"*).
```

#### `/spec-verify`

```markdown
---
description: Auditar cobertura R*.* ↔ tests, gaps, drift, conflicts cross-spec (read-only)
argument-hint: <feature-slug> [--cross]
---

Sigue el protocolo §7. Para feature $ARGUMENTS:

1. **CONTEXT** — leer requirements.md, tasks.md, status.md, mocks/,
   tests/ del repo. Si flag `--cross`, leer también los `R*.*` y
   `design.md` de todas las specs activas del repo.

2. **CHECKS** — reportar (no escribir):
   - `R*.*` sin `Tests:` declarado (§5 regla 6).
   - `R*.*` con `Tests:` declarado pero **niveles no cubiertos**
     (ej. declara `Tests: unit, integration` pero sólo hay tests de
     unit con `// Derived from R*.*`; falta integration).
   - Tests con `// Derived from R*.*` cuyo `R*.*` ya no existe en
     `requirements.md` (tests huérfanos por Amendment).
   - Tasks `done` sin commit hash en `status.md`.
   - `D-N` en `NEGOTIATING` con > 10 días desde el draft (§6 SLAs).
   - `D-N` en `AGREED` con > 6 semanas sin pasar a `IMPLEMENTED`.
   - Tasks `blocked` > 4 semanas sin decisión `BLOCK`/`WORKAROUND`/
     `cancel` (§6 SLAs).
   - Mocks sin `Ready to unmock` o sin owner declarado.
   - Drift entre `state:` declarado y derivación del Lifecycle (§6).
   - `OPEN_QUESTIONS` sin owner o sin `due` (§5 regla 7); o con `due`
     vencido.
   - Feature con `feature_flag.main == ON` > 90 días al 100% sin task
     de limpieza propuesta (§6 *Limpieza de feature flags*).
   - **Ajuste por modalidad** (§6): si `modality: catalog-only`,
     omitir checks de `design.md` y `tasks.md`; si `docs-only`,
     omitir checks de tests; si `refactor-only`, **exigir** que
     tests existentes pasen pre y post (no hay `R*.*` nuevos);
     etc.
   - **Conflicts cross-spec** (sólo si flag `--cross`): mismo scan
     de `/spec-new` CLARIFY 3.c, pero ejecutable a demanda contra
     todas las specs activas. Útil para auditar coherencia del
     catálogo después de N specs, o antes de mergear un PR grande
     que toca varias specs. Reporta posibles contradicciones con
     citas explícitas (`spec/R*.*` vs `otra spec/R*.*`). NO escribe
     nada — el dev decide si abrir Amendments, alinear specs o
     documentar coexistencia.

3. **CLOSE** — reportar:
   - Lista de gaps por categoría.
   - Sugerencia de fix concreta para cada uno.
   - Si todo verde: confirmar que la feature cumple condiciones de
     promoción y sugerir `/spec-promote`.
```

#### `/bug-triage`

```markdown
---
description: Clasificar un bug en la taxonomía A/B/C/D/E (§8) con entrevista
---

Sigue el protocolo §7. Para el bug descrito en $ARGUMENTS:

1. **CONTEXT** — verificar:
   - ¿En qué feature/spec aparece?
   - ¿Hay repro estable o es intermitente?
   - ¿Ya hay `BUG-NNN` abierto en `bugs.md` con síntomas similares?

2. **CLARIFY** — entrevistar al reportero:
   - ¿Qué se esperaba? ¿Qué pasó?
   - ¿La spec cubre este caso explícitamente? (cita `R*.*`).
   - ¿Es un cambio externo (cliente, ley) o un defecto técnico?
   - ¿La dependencia involucrada es 3rd party (paquete / SaaS)?

3. **PROPOSE** clasificación:
   - **A** — la spec cubre el caso y el código está mal.
   - **B** — la spec NO cubre el caso (gap; abrir PR de spec antes
     del fix).
   - **C** — la spec lo cubre pero es ambigua (refinar antes de fix).
   - **D** — incidente en prod con SLA roto (hotfix + spec retroactiva).
   - **E** — causa raíz es un paquete / SaaS 3rd party.
   - **Amendment** — no es bug; es cambio externo. Redirigir a
     `/spec-amend` (no contaminar la métrica de Tipo B).
   - Pedir confirmación al reportero.

4. **EXECUTE** — registrar en `bugs.md` (formato §8 Tracking):
   - `BUG-NNN`, tipo, requirement afectado, fecha, reportero.
   - Para Tipo B / C: abrir PR de spec antes del fix.
   - Para Tipo E: marcar `blocked_by: ext:<id>` en `status.md`
     mientras se espera al vendor.

5. **CLOSE** — siguiente paso sugerido (PR de spec, fix directo,
   workaround, escalación a vendor, etc.).

   Para Tipo B / C, además: aplicar **ratchet harness** si el gap es
   una clase (§8 *Ratchet harness*). Preguntar: ¿qué entrada del
   harness — AGENTS.md, slash-command, plantilla EARS, `spec-lint`,
   hook — habría evitado este gap a priori? Si la respuesta existe,
   abrir PR sobre el harness y referenciarlo como `Harness PR:` en
   `BUG-NNN`. Si no, cerrar con el `R*.*` y seguir.
```

**Ejemplo trabajado — Tipo B disfrazado de Tipo A**

QA reporta: *"Al abrir el detalle de una orden en dev, los puntos se
acreditan dos veces. En prod sólo una."*

1. **CONTEXT**
   - Feature: `points-engine/award-on-purchase`.
   - Spec relevante: `requirements.md` R3.1 — *"Cuando el sistema
     confirma una orden, THE SYSTEM SHALL acreditar puntos equivalentes
     al 1% del total."*
   - Repro: 100% en `npm run dev` (Vite + React 18); no reproducible en
     `npm run build && preview`.
   - No hay `BUG-NNN` con síntomas similares.

2. **CLARIFY**
   - Esperado: una orden = una acreditación. Observado: dos.
   - `<OrderDetail>` dispara `POST /points/award` desde un `useEffect`.
     `src/main.tsx` envuelve la app en `<React.StrictMode>`, que en dev
     invoca cada effect dos veces para detectar efectos no idempotentes.
   - ¿La spec habla de idempotencia? R3.1 garantiza que se acredita,
     pero no protege contra dobles invocaciones (retries de cliente,
     reintentos de cola, double-fire de dev, etc.).
   - Origen interno (defecto técnico), no externo.

3. **PROPOSE**
   - Primer impulso: **Tipo A** — el componente está mal escrito.
   - Pero la spec NO cubre el caso "el endpoint recibe la misma orden
     dos veces". Hoy hay un único caller bien comportado; mañana habrá
     más. El contrato del endpoint tiene un gap.
   - Reclasificar: **Tipo B**. Hay que añadir un `R*.*` sobre
     idempotencia **antes** del fix.
   - Apagar `<StrictMode>` no es el fix: esconde el síntoma sin cerrar
     el gap del contrato (anti-patrón).
   - Confirmar con reportero.

4. **EXECUTE**
   - PR de spec con `R3.4` — *"WHEN el sistema recibe `POST
     /points/award` con un `idempotency_key` ya procesado para la misma
     orden, THE SYSTEM SHALL responder 200 con el resultado original
     sin reacreditar."*
   - Registrar en `bugs.md`:

     ```markdown
     ## BUG-2034 — Doble acreditación en dev (StrictMode)
     - **Tipo:** B
     - **Requirements agregados:** R3.4
     - **Spec PR:** !512
     - **Implementation PR:** !513
     ```

5. **CLOSE**
   - Siguiente paso: tras merge de !512, fix en `points-engine`
     (deduplicación por `idempotency_key`) y en `<OrderDetail>`
     (mandar `idempotency_key = order_id` en el header).
   - Métrica: este caso cuenta como **Tipo B** (no A). La señal de
     diagnóstico es que el endpoint no tenía contrato sobre
     idempotencia — el StrictMode sólo lo expuso.


---

## Integración con el servicio de diseño (Figma + Figma Make)

> El equipo de diseño funciona como **servicio** dentro de la organización.
> Esta sección documenta cómo encaja en AI-DLC y cómo los dos prompts por repo
> (`Guidelines.md` + `figma-make-integration.md`) actúan como **contrato**
> entre dev y diseño.

### Modelo de trabajo con diseño

Tres artefactos clave en la cadena:

| Artefacto | Uso | Quién lo opera |
|---|---|---|
| **Figma (diseños)** | Maquetación visual, lectura vía Figma MCP | Diseño |
| **Figma Make** | Generación de código frontend a partir de prompt + Guidelines | Diseño (con guía del dev) |
| **Prompts del repo** | Contrato técnico (Guidelines + integration) | Tech lead del repo (mantiene), Diseño y agentes (consumen) |

### Insight clave: los prompts SON specs

Los dos prompts no son "documentación informal" — son **specs de contrato**:

- `Guidelines.md` es la spec de **entrada** que diseño usa para generar código
  útil para tu repo (stack, estructura, convenciones, restricciones).
- `figma-make-integration.md` es la spec de **proceso** que el agente
  integrador (Claude Code) ejecuta para meter el código generado al repo
  sin romper lo existente.

Ambos viven en el repo, versionados en Git, revisados como código.

### Dónde viven los prompts

```
<repo>/
├── .ai-dlc/
│   └── design/
│       ├── Guidelines.md                    ← spec para Figma Make
│       ├── figma-make-integration.md        ← spec para el agente integrador
│       └── examples/                        ← integraciones pasadas como referencia
├── .claude/
│   └── commands/
│       └── figma-make-integrate.md          ← slash command que ejecuta el integration prompt
└── ...
```

### Estructura del `Guidelines.md` (resumen)

Basado en el patrón observado en proyectos reales del stack `.NET 9 + React + Clean Arch`:

| Sección | Propósito |
|---|---|
| **Regla fundamental** | "No asumas — pregunta". Forzar a Figma Make a preguntar ante ambigüedades |
| **Alcance de generación** | Frontend-only, datos mock, archivos adicionales (API_SPECS.md) |
| **Stack técnico bloqueado** | Tabla de librerías y versiones permitidas |
| **Librerías prohibidas** | Lista explícita (axios, moment, MUI, Redux, etc.) |
| **Dependencias privadas** | NO incluir (se agregan en integración) |
| **Componentes UI disponibles** | Tabla específica (PrimeReact, Material, etc.) |
| **Path alias** | Imports `@/*` obligatorios |
| **Estructura de carpetas** | Clean Architecture detallada |
| **Convenciones de nombres** | Tabla estricta (entity, repository, DTO, etc.) |
| **Patrones de código** | Ejemplos canónicos (entidad, use case, mapper, repo, store) |
| **Separación lógica/visual** | Componentes `common/` puros, sin lógica |
| **Buenas prácticas** | A11y, responsive, seguridad, optimización |
| **Mocks con metadata** | `TODO-INTEGRATION` para generar backend después |
| **Contexto backend** | Tecnologías y patrones del backend para `API_SPECS.md` |
| **Archivos a generar** | `API_SPECS.md`, `FIGMA_MAKE_CONTEXT.md`, `README.md`, `package.json` |
| **Principios de integración** | Sin fricción, re-generación segura, disciplina de dependencias |
| **Checklist de entrega** | Validación final antes de entregar ZIP |

### Estructura del `figma-make-integration.md` (resumen)

Es el spec/plan ejecutable que el agente sigue al recibir un ZIP de Figma Make.
Tiene 11 fases:

| Fase | Acción |
|---|---|
| 1 | Validación inicial (estructura, dependencias, convenciones, TODOs) |
| 2 | Verificación de dependencias del proyecto vs ZIP |
| 3 | Análisis de tareas de integración (TODOs, conflictos) |
| 4 | Copiar archivos con mapeo de Clean Architecture, filtrar temporales |
| 5 | Integración de rutas (en `RoutesConfig.tsx` o equivalente) |
| 6 | Migración de repositorios mock → `apiClient` real |
| 7 | Registro en DI Container |
| 8 | Análisis y generación de backend desde metadata `TODO-INTEGRATION` |
| 9 | Pruebas y compilación (`npm run build`, `dotnet build`) |
| 10 | Reportes (`INTEGRATION_REPORT.md`) |
| 11 | Limpieza |

**Principios innegociables del integration prompt**:
- No asumir — preguntar con opciones (`[A] / [B] / [Otra]`).
- Re-integración segura (no destruir migraciones previas).
- Disciplina de dependencias (nunca instalar sin aprobación).
- Cambios ADITIVOS solamente.

### Flujo end-to-end con diseño

Caso: **"Consulta de recibos pagados"** — feature dentro de la initiative
`customer-self-service`.

```
1. Spec (AI-DLC normal)
   └─► /specs/.../consulta-recibos/requirements.md (EARS R1.1..R3.5)
                                  /design.md
                                  /tasks.md

2. Brief para diseño
   ├─ Link a requirements.md y design.md
   ├─ Datos mock representativos (JSON)
   ├─ Pointer a Guidelines.md (URL raw fija)
   └─ Work item: AB#12345

3. Diseño en Figma
   └─ Iteraciones visuales, consulta via Figma MCP si necesita
      coherencia con código existente

4. Figma Make genera
   ├─ Diseñador pega: brief + URL del Guidelines
   ├─ Figma Make produce ZIP siguiendo Guidelines
   └─ Entrega: ZIP + API_SPECS.md + FIGMA_MAKE_CONTEXT.md

5. Integración (dev en su máquina)
   $ claude
   > /figma-make-integrate ~/Downloads/consulta-recibos.zip
   │
   ├─ Claude Code ejecuta las 11 fases del integration prompt
   ├─ Pregunta al dev en cada decisión ambigua
   ├─ Genera INTEGRATION_REPORT.md
   └─ Deja el código integrado en el repo + tareas pendientes

6. Cierre del ciclo
   ├─ Si la integración reveló R*.* nuevos → actualizar requirements.md
   ├─ TODO-INTEGRATION pendientes → tasks en tasks.md
   ├─ Si hay backend pendiente → spec del feature backend
   └─ PR con: AB#12345, R*.* cubiertas, link a INTEGRATION_REPORT.md
```

### Trazabilidad design ↔ specs

Cada PR de integración de Figma Make debe enlazar:

| Referencia | Cómo |
|---|---|
| Work item de Azure DevOps | `AB#<id>` en commit y PR title |
| Spec del feature | Path a `/specs/.../requirements.md` en PR description |
| EARS cubiertas | Lista `R*.*` en PR description |
| Archivo de Figma | URL del frame específico |
| Proyecto de Figma Make | URL del proyecto Make |
| INTEGRATION_REPORT.md | Path en el PR description |

**PR title sugerido**:
`feat(ui): integrate figma make for consulta-recibos [R3.1, R3.2, R3.5] AB#12345`

### Versionado de los prompts

#### `Guidelines.md`

- Vive en `.ai-dlc/design/Guidelines.md` en `main`.
- Diseño siempre consulta la **URL raw** de `main` (no descarga local):
  `https://dev.azure.com/<org>/<proj>/_git/<repo>?path=/.ai-dlc/design/Guidelines.md&version=GBmain`
- Cambios al Guidelines:
  - PR review obligatorio (Tech lead + un diseñador).
  - Si el cambio es **breaking** (cambio de stack, eliminar librería usada),
    notificar a diseño antes de mergear.
- CI valida que las versiones mencionadas en `Guidelines.md` coincidan
  con `package.json` del repo.

#### `figma-make-integration.md`

- Vive en `.ai-dlc/design/figma-make-integration.md`.
- También en `.claude/commands/figma-make-integrate.md` (referencia o copia).
- Cambios requieren PR review del tech lead.
- Versionar con número (`v2.0`, `v2.1`) en el frontmatter.

### Diferencias por proyecto

Los prompts son **específicos por repo** porque varían:

| Dimensión | Ejemplo de variación |
|---|---|
| **Stack** | React+TS vs Angular vs Blazor vs Svelte |
| **Arquitectura** | Clean Arch vs MVC vs Vertical Slices vs Feature-Based |
| **UI library** | PrimeReact vs Material vs Chakra vs custom |
| **State** | Zustand vs Redux Toolkit vs Context |
| **Convenciones** | `*.entity.ts` vs `*Entity.ts`, `repos/` vs `repositories/` |
| **Backend** | .NET CQRS vs Node Express vs Spring vs Go |
| **Internas** | `@syc/*` u otras librerías privadas de la org |

### Templates compartidos

Para que cada equipo no parta de cero, `.org/templates/design/` contiene:

```
.org/templates/design/
├── react-clean-arch/
│   ├── Guidelines.md.tmpl
│   └── figma-make-integration.md.tmpl
├── angular-ddd/
│   ├── Guidelines.md.tmpl
│   └── figma-make-integration.md.tmpl
├── blazor/
│   └── ...
└── README.md  ← cómo elegir y adaptar template
```

Cada template tiene placeholders `{{STACK_VERSION}}`, `{{UI_LIB}}`, etc.
El tech lead clona el template y lo adapta a su repo.

### Cómo Figma Make encaja en la spec del feature

Una sutileza: cuando un feature involucra UI, su spec puede tener una
sección específica para diseño:

```markdown
## Diseño (en design.md del feature)

### Estado
- Figma: <link al frame>
- Figma Make project: <link al proyecto>
- Última integración: 2026-05-12 (INTEGRATION_REPORT.md#consulta-recibos-v1)

### Componentes esperados (de Figma Make)
- ConsultaRecibosPage (público)
- ReciboCard (common, puro)
- FiltrosForm (forms)
- ExportarRecibosDialog (domain)

### Mocks
- Datos mock en /mocks/recibos.json (espejo del JSON entregado a Figma)
```

Esto cierra el ciclo: la spec **sabe** que ese feature tiene un origen de
diseño, y futuras regeneraciones pueden referenciarlo.

### Comandos clave

#### `/figma-make-integrate <ruta-zip>`

Slash command que ejecuta el prompt `figma-make-integration.md` del repo
actual. Implementación en `.claude/commands/figma-make-integrate.md`:

```markdown
---
description: Integrar ZIP de Figma Make siguiendo el integration prompt del repo
---

Lee `.ai-dlc/design/figma-make-integration.md` y ejecuta las 11 fases para
el ZIP en $ARGUMENTS.

Reglas:
- En cualquier decisión ambigua, PREGUNTA al usuario con opciones [A/B/C/Otra].
- NO ejecutes destructively sin aprobación explícita.
- Genera INTEGRATION_REPORT.md al final.
- Al terminar, recuerda al usuario:
  - Actualizar /specs/.../tasks.md con TODO-INTEGRATION pendientes
  - Crear feature spec del backend si hay endpoints nuevos
  - Linkear el PR al work item de Azure DevOps
```

#### `/figma-brief <feature>`

Slash command que genera el brief para diseño:

```markdown
---
description: Generar brief para diseño desde una spec
---

Para feature $ARGUMENTS:

1. Lee /specs/<feature>/requirements.md y /specs/<feature>/design.md
2. Genera un brief que incluya:
   - Resumen del feature (de overview/requirements)
   - EARS visuales relevantes (R*.* que apliquen a UI)
   - Datos mock representativos (JSON)
   - URL raw fija al Guidelines.md del repo
   - Work item de Azure DevOps (AB#)
3. Imprime el brief listo para copiar al ticket de diseño
4. NO escribas el brief en un archivo — solo imprímelo
```

### Quién es owner de qué

| Artefacto | Owner | Audiencia consumidora |
|---|---|---|
| `Guidelines.md` | Tech lead del repo | Diseño + Figma Make |
| `figma-make-integration.md` | Tech lead del repo | Claude Code (agente) |
| Brief para diseño | Dev que pide el feature | Diseñador asignado |
| ZIP generado | Diseñador asignado | Dev integrador |
| `INTEGRATION_REPORT.md` | Generado automáticamente | PR reviewers, futuros agentes |
| Spec actualizada post-integración | Dev integrador | Equipo + agentes |
| Templates en `.org/templates/design/` | Equipo de plataforma | Tech leads de todos los repos |

### Anti-patrones del flujo de diseño

| Anti-patrón | Síntoma | Mitigación |
|---|---|---|
| Diseño usa Figma Make sin Guidelines | Código generado no encaja con el repo | Diseñadores rechazan briefs sin link a Guidelines |
| Guidelines desactualizados | Stack mencionado ≠ stack real | CI valida versions vs `package.json` |
| Integración manual sin el prompt | Inconsistencias, errores humanos | PR template exige `INTEGRATION_REPORT.md` referenciado |
| Re-generación destructiva | Migraciones manuales se pierden | Integration prompt es explícito sobre "ADITIVOS solamente" — no negociar |
| Dependencias prohibidas se cuelan | Bloat, conflictos | Pipeline valida `package.json` contra lista permitida |
| Diseño inventa endpoints | Backend no existe, frontend roto | `Guidelines.md` exige `API_SPECS.md` con metadata explícita |
| Spec del feature ignora el diseño | Doc desactualizado, doble fuente de verdad | `design.md` del feature tiene sección "Diseño" con links |
| Mismo Guidelines para todos los repos | No funciona — cada repo es distinto | Templates compartidos + adaptación por repo |
| Brief para diseño hecho de memoria | Olvidos, ambigüedad | `/figma-brief` lo genera desde la spec automáticamente |

### Integración con Azure DevOps (especifica para diseño)

- **Work item type "Design Task"** bajo cada User Story que requiera UI.
- Owner: diseñador asignado.
- Estado lifecycle: `New` → `In Design (Figma)` → `In Make (Figma Make)` →
  `Ready for Integration` → `In Integration` → `Done`.
- Service hook: cuando pasa a `Ready for Integration`, notifica al dev del repo.
- Pipeline post-integración: corre tests visuales (si hay) y storybook
  para validar componentes.

---


## Flujo end-to-end (ejemplo completo)

Caso: **"Programa de lealtad para clientes EU"**.

### Día 0 — Cliente solicita

PM crea Epic en Azure Boards: *"Customer Loyalty Program for EU"*.
Tag: `needs-spec`.

### Día 1 — Discovery

Service hook notifica al Architect Agent.
Architect Agent:
1. Lee Epic.
2. Postea comentario con preguntas clarificadoras.
3. Tras respuestas del PM, ejecuta `/initiative-new customer-loyalty-program`.
4. Genera `specs/initiatives/customer-loyalty-program/overview.md`.
5. Convoca agentes consultivos:
   - Compliance Agent revisa GDPR.
   - Cost Agent estima infra.
   - Ops Agent valida capacidad.
6. Abre PR en el **repo de iniciativas** (opcional; ver §6 *Cuándo
   usar Initiative*) con la initiative inicial.
7. Vincula PR al Epic con `AB#<id>`.

### Día 3 — Architecture

Architect consulta `.org/catalog.yaml` si existe (o pregunta al humano
qué servicios están impactados) e identifica el alcance. Genera
`architecture.md` con diagrama mermaid, contratos nuevos en
`.org/contracts/`, decisiones. Actualiza PR.

### Día 5 — Revisión humana

PM, arquitectos, tech leads revisan PR de initiative.
Ajustan, aprueban, mergean.

### Día 6 — Fan-out

Architect ejecuta `/initiative-fanout customer-loyalty-program`:
1. Genera stubs en `features/`:
   - `checkout-integration/requirements.md`
   - `points-engine/requirements.md` (servicio nuevo)
   - `notifications/requirements.md`
   - `analytics-pipeline/requirements.md`
2. Crea **Features** en Azure Boards bajo el Epic.
3. Crea **User Stories** por cada R*.*.
4. Asigna a owners según `teams.yaml`.

### Día 7-30 — Implementación por servicio

Cada equipo en su repo:

```bash
$ cd ~/repos/checkout-api
$ git checkout -b feat/loyalty-integration
$ claude
> /spec-implement loyalty-checkout-integration
```

Service Agent:
1. Lee spec.
2. Implementa T1 (extender evento `order.placed`).
3. Genera tests con `// Derived from R*.*`.
4. Corre tests, lint, typecheck.
5. Commit: `feat(checkout): extend order.placed event [R1.1] AB#12347`
6. Push, abre PR en Azure Repos.
7. PR description sigue plantilla con R*.* y AB# refs.

Reviewer humano:
- Revisa diff focalizado en lógica.
- Verifica tests cubren R*.*.
- Aprueba.

Pipeline corre:
- Validación de spec.
- Tests.
- Build de imagen.
- Push a registry interno.

### Día 31 — Despliegue progresivo

Agente lee `rollout-plan.md`:
- Phase 1: canary 5% en FR.

Dispara pipeline:
```bash
$ az pipelines run --id <pipeline-id> \
    --parameters environment=prod-fr canaryWeight=5
```

Pipeline despliega en OpenShift:
- `oc apply -f deploy/openshift/`
- `oc set route-backends checkout-api checkout-api-v2=5 checkout-api-v1=95`

Agente monitorea métricas. 24h después, si gates OK, propone phase 2.

### Día 45 — Bug reportado

Cliente reporta: *"Mis puntos no aparecen si cambio el email después de la compra"*.

Soporte crea Bug en Azure Boards.
Service hook → Architect Agent → `/bug-triage`.

Architect Agent clasifica como **Tipo B** (spec gap).
Propone nuevo `R6.1` en `points-engine/requirements.md`.

PR de spec → PR de code → deploy. Ciclo cerrado.

---

## Plan de adopción gradual

No tratar de cambiar toda la organización de golpe. Fases:

### Fase 1 — Piloto (1-2 meses)

- **Alcance**: 1 equipo, 1 servicio, 1 feature mediana.
- **Objetivos**:
  - Validar herramientas (Cursor + Claude Code + Azure DevOps).
  - Establecer plantillas (`CLAUDE.md`, rules, slash commands).
  - Medir: tiempo de implementación, defectos, satisfacción del equipo.
- **Output**: playbook concreto + lecciones aprendidas.

### Fase 2 — Equipo completo (2-3 meses)

- **Alcance**: el equipo piloto en todos sus servicios.
- **Añadir**:
  - Integración con Azure DevOps (Flujo A bidireccional).
  - `.org/contracts/` (sólo contratos) cuando aparezca la primera
    dependencia cross-repo. **No** crear el catálogo completo todavía.
  - Métricas dashboard.
- **Capacitación**: workshops internos.

### Fase 3 — División (3-6 meses)

- **Alcance**: 3-5 equipos de la misma división.
- **Añadir**:
  - Architect Agent para coordinación cross-team.
  - Agentes consultivos (Compliance, Ops, Cost).
  - Integración OpenShift validation.
  - **Empaquetado de scripts de validación** (`spec-lint`,
    `spec-traceability`, `verify-deploy-matches-spec`) como paquetes
    npm publicados en **Azure DevOps Artifacts** (feed interno).
- **Gobernanza**: Comité de práctica de AI-DLC.

### Fase 4 — Organización (6-12 meses)

- **Alcance**: toda la organización.
- **Añadir**:
  - Initiatives usadas **consistentemente cuando aplica** (programas
    cross-equipo, multi-repo) — sin forzarlas para features simples
    de un solo repo.
  - Sync bidireccional completo Azure DevOps ↔ specs.
  - Deploy progresivo automatizado guiado por spec.
  - **Distribución completa vía npm**: templates de spec, slash
    commands, reglas de Cursor y prompts de agentes publicados como
    paquetes en Azure DevOps Artifacts. Cada repo declara la versión
    en su `package.json`; `npm update` / Dependabot propagan mejoras.
    Como Claude Code y Cursor leen del filesystem, los paquetes
    aportan los archivos vía init/sync postinstall, no en runtime.
- **Madurez**: métricas estables, cultura asumida.

> **Nota — versionado de la metodología.** Empaquetar requiere que la
> metodología esté estable (no antes de Fase 3). El beneficio es
> versionado SemVer real, rollback trivial y auditoría de qué versión
> usa cada equipo.

### Adopción en proyecto brownfield (código ya en producción)

Las 4 fases arriba asumen adopción **organizacional** progresiva. Un
caso ortogonal y **más común**: un solo proyecto con código ya en
prod que quiere adoptar AI-DLC. No se reverse-engineerea spec de todo
lo existente — sería trabajo masivo de bajo valor para código estable.
El patrón es **estrangulador**:

#### Principios

- **Specs sólo para trabajo nuevo**. El código existente queda
  *grandfathered*. Una nueva feature o bug que toque un módulo legacy
  abre la **primera** spec de ese módulo. No se generan specs
  retroactivas masivamente.
- **Estado `legacy`** (§6 Lifecycle): features que están en prod sin
  spec se declaran `legacy` en un `status.md` mínimo:

  ```yaml
  ---
  feature: checkout-promo-codes
  state: legacy
  owner: "@maria"
  ---

  # Status

  Feature en producción desde 2024-Q3. Permite aplicar códigos
  promocionales en checkout. No tiene spec retroactiva.

  Graduará a `live` cuando alguien la re-toque y escriba spec
  (§15 *Adopción en proyecto brownfield*).
  ```

  Sin `requirements.md`, `design.md`, `tasks.md`, `bugs.md`,
  `amendments.md`. Sólo el mínimo para ser visible en `/spec-status`.

- **Bug fixes en código legacy**: invocan `/bug-triage`. Si la spec
  del módulo no existe (estado `legacy`), el flujo es:
  1. Antes del fix, el agente propone crear un **stub de spec**
     (`requirements.md` mínimo cubriendo el comportamiento observado +
     el comportamiento esperado tras el fix).
  2. Spec se aprueba (1 reviewer).
  3. Feature transiciona `legacy` → `in-progress`.
  4. Fix sigue el flujo normal (test que falla → fix → test verde).
  5. Tras merge, transiciona al estado correspondiente (`live`,
     `partial-deploy-*`).

  Esto es **Tipo B disfrazado**: gap de spec descubierto por un bug.

- **Features nuevas tocando legacy**: igual al patrón anterior — la
  primera feature nueva sobre un módulo legacy abre la spec inicial
  del módulo (no sólo de la feature). La feature nueva cita la spec
  del módulo en sus `R*.*`.

- **Métrica de progreso**: `% de features con spec / total de
  features` por repo. Subir 5-10% por sprint es realista. **No es
  un KPI de presión** — features `legacy` que nunca se vuelven a
  tocar pueden quedar así indefinidamente sin costo.

#### Memoria de sesión ad-hoc al root

Síntoma típico de brownfield con uso previo de AI assistants: archivos
como `NEXT_SESSION_HANDOFF.md`, `SESSION_PROGRESS_<fecha>.md`,
`TEST_FIX_PROGRESS.md`, `TRACE_<bug>.md`, `analisis-<sistema>.md`
acumulados al root. Son **exactamente** lo que `specs/<feature>/`
formaliza (`status.md`, `bugs.md`, notas de design), pero sin
estructura.

Catálogo de patrones que el bootstrap detecta (extensible — agregar
cuando aparezcan casos nuevos):

| Patrón de nombre | Extensión | Tipo probable |
|---|---|---|
| `SESSION_*`, `NEXT_SESSION_*` | `.md` | Handoffs de sesión |
| `*_HANDOFF.md` | `.md` | Handoffs explícitos |
| `TRACE_*`, `analisis-*`, `analysis-*` | `.md` | Análisis de bug |
| `*_PROGRESS.md`, `*_STATUS.md` | `.md` | Progreso parcial |
| `TEST_*`, `DEBUG_*`, `*_NOTES.md` | `.md` | Notas ad-hoc |
| `PLAN_*.md` | `.md` | Plan informal (refactor, mejora) |
| `YYYY-MM-DD-HHMMSS-<slug>.txt` | `.txt` | **Transcript bruto** exportado por Claude Code / OpenCode / Codex CLI |
| `YYYY-MM-DD-<slug>.md` | `.md` | Notas datadas |

> Atención: el catálogo incluye **`.txt`**, no sólo `.md`. Algunos
> clientes AI exportan conversaciones completas a `.txt` con
> timestamp-prefix; suelen ser 50–200 KB y viven al root. Detectarlos
> y proponer archive es default.

Patrones de manejo durante el bootstrap brownfield (el agente
**pregunta** cuál aplica, no decide solo):

| Patrón | Cuándo | Qué hace |
|---|---|---|
| **Archive** | El equipo quiere limpiar root sin re-trabajo | Mover los archivos a `archive/session-history/` tal cual. Cero parsing, cero pérdida de info. Migración a `specs/` queda para cuando se re-toque cada área (alineado con strangler). |
| **Migrate-to-specs** | El equipo tiene tiempo para invertir en estructura | Convertir cada archivo a `specs/<slug>/` retroactivo con state=`legacy` (extraer `status.md` de progress, `bugs.md` de traces, `design.md` de análisis). Requiere decisión: 1 spec por archivo o 1 spec por feature aglutinando varios archivos. |
| **Leave** | Los archivos siguen siendo "vivos" para el equipo | No tocar. AI-DLC y los archivos ad-hoc conviven. Nuevas features sí van a `specs/`. Aceptable como estado transitorio; gradúa a archive/migrate cuando dejen de actualizarse. |

Default recomendado en bootstrap: **archive**. Es reversible, no
introduce decisiones, libera el root, y deja la opción de migrar
después con más contexto.

#### Coexistir con AI infra previa: dos categorías distintas

Lo más común en brownfield no es "repo virgen" — es "repo con 2-3
herramientas AI ya configuradas, mal integradas entre sí, **+ un
intento custom interno del equipo de estandarizarlas**". El bootstrap
distingue **dos categorías** de AI infra previa, porque se tratan
diferente:

##### Categoría A — AI infra de tool externo

Es de la herramienta, no del equipo. El equipo la respeta porque la
herramienta la lee. AI-DLC **convive**, NO reemplaza. Se espejan las
reglas codificables, pero los archivos del tool quedan intactos.

| Archivo / directorio | Origen | Estrategia |
|---|---|---|
| `CLAUDE.md` sustantivo (no boilerplate, >5 KB con reglas del proyecto) | Sesiones previas con Claude Code | **Respetar**. Crear `AGENTS.md` nuevo. Opcionalmente extraer reglas codificables a `stack/constraints.md`/`stack/testing.md` dejando `CLAUDE.md` apuntando a esas reglas. NUNCA sobreescribir. |
| `.cursorrules` | Cursor | **Espejar, no migrar**. Reglas copiadas a `stack/constraints.md`, archivo intacto. |
| `.cursor/plans/*.plan.md` | Cursor "plans" feature | Specs nativas de Cursor. **Dejar por default**. Opcionalmente migrar selectivos a `specs/<slug>/` con `/spec-import-plan <path>`. |
| `.github/chatmodes/*.chatmode.md` | GitHub Copilot chat modes | **Dejar**. AI-DLC no compite. |
| `.copilot-instructions.md`, `.github/copilot-instructions.md` | GitHub Copilot | **Espejar** reglas a `stack/constraints.md`. Dejar archivo. |
| `.windsurfrules`, `.continuerules`, `.aider/`, `.gemini/`, etc. | Windsurf, Continue, Aider, Gemini CLI, otros | Mismo patrón: espejar reglas, dejar archivos. |
| `.agents/skills/<skill>/` ya pobladas | Sesiones previas con skills installer | **Respetar**. Sólo agregar `.agents/skills/README.md` AI-DLC si no existe. |
| `AGENTS.md` previo | Estándar abierto multi-tool | **Sub-protocolo de 4 categorías** (abajo). |

Principio Categoría A: **espejar reglas codificables, no migrar
archivos del tool original**. AI-DLC es tool-agnostic, no
tool-replacing. Un equipo que usa Cursor + Claude + AI-DLC debe poder
seguir usando los tres después del bootstrap.

###### Sub-protocolo `AGENTS.md` previo

`AGENTS.md` es asimétrico con `CLAUDE.md`: lo leen TODAS las tools
agente al arrancar (Claude Code, Cursor, OpenCode, Codex CLI,
Continue, Aider). Si el bootstrap sobreescribe un AGENTS.md previo,
el dev pierde toda la orientación que sus tools tenían. Distinguir
4 sub-categorías:

| Cat | Heurística | Acción default |
|---|---|---|
| **A.1 Boilerplate** | < 500 B, sólo TODOs, headers vacíos. | Reemplazar con el de AI-DLC sin preguntar. |
| **A.2 Partial AI-DLC** | Referencia `.agents/commands/`, `stack/`, `repo-config.yaml`, `Bootstrap`, etc. Adopción AI-DLC previa incompleta. | Modo `--upgrade`: diff + apply incremental. NO reemplazar. |
| **A.3 Otro standard** | Estructurado con otro framework (openai-agents, etc.). No referencia AI-DLC. | **Appended-section con sentinels** (abajo). |
| **A.4 Custom sustantivo** | Prosa libre o estructurado, el equipo lo escribió a mano, no es framework conocido. | **Appended-section con sentinels** (abajo). |

**Estrategia "appended-section"** para A.3 y A.4. El agente NO toca
lo que está arriba en el AGENTS.md previo. Agrega un único bloque
al final con bordes explícitos:

```markdown
[... contenido del equipo intacto ...]

---

<!-- ai-dlc:section-start v=<version> -->
## AI-DLC Protocol

Este repo adopta AI-DLC (v<version>). **Las secciones de arriba
son del equipo y tienen precedencia** para conflictos.

- Slash commands en `.agents/commands/`.
- Stack y convenciones en `stack/`.
- Config operacional en `repo-config.yaml`.
- Protocolo: ver `ai-dlc-methodology.md` §§ 6, 11.

<!-- ai-dlc:section-end -->
```

Justificación:

- Cero merge semántico (el agente NO parsea ni reorganiza).
- Border explícito con sentinels — un `--upgrade` futuro reemplaza
  SOLO ese bloque.
- Precedencia declarada: si el equipo dice "auto-commit" y AI-DLC
  dice "PR-only", la regla del equipo gana.
- Una sola fuente de verdad para las tools (siguen leyendo
  `AGENTS.md`). No hay archivos paralelos.
- Reversible quirúrgicamente: borrar el bloque entre sentinels
  deja AGENTS.md exactamente como estaba.

**Conflictos de protocolo** (caso ortogonal): si el contenido del
AGENTS.md previo tiene reglas operacionales que contradicen el
protocolo AI-DLC (commit format, branch flow, etc.), el agente
**detecta** y **reporta** como OPEN_QUESTION en el plan. NO resuelve
automáticamente. La precedencia declarada en el bloque AI-DLC ya
dice que el equipo gana, pero el dev puede preferir alinear.

Anti-patrón: **merge semántico de AGENTS.md previo** (parsear,
reordenar, redistribuir secciones). Riesgo alto, valor bajo.

##### Categoría B — AI infra custom interna del equipo

Esto es **lo que el equipo construyó internamente intentando
estandarizar prompts, instrucciones para agentes, o spec-driven sin
formalismo**. NO es de ninguna herramienta de tercero — es un intento
propio del equipo de hacer exactamente lo que AI-DLC formaliza. La
acción default es **consolidar en AI-DLC**: el equipo quería esta
estandarización todo el tiempo, AI-DLC la trae más completa.

Heurística para detectarlo (todas deben cumplir):

1. Directorio AI-like al repo que **no aparece en el catálogo de la
   Categoría A**. Ejemplos reales observados: `.ai-integration/`,
   `.team-prompts/`, `ai-docs/`, `prompts/`, `agent-instructions/`,
   `.agents/` parcialmente poblado por el equipo.
2. Contiene `commands/`, `prompts/`, `rules/`, `agents/` con `.md`s
   que son claramente prompts/instrucciones para agentes (no docs
   del producto humano-facing).
3. NO está documentado como dependencia de una herramienta externa
   (no aparece en `package.json`, no hay tool del catálogo A que lo
   lea, está commiteado intencionalmente).

| Categoría B detectada | Migración default propuesta |
|---|---|
| `<dir>/commands/*.md` (slash commands custom) | → `.agents/commands/` AI-DLC con symlinks/wrappers desde `.claude/commands/`, `.cursor/commands/`. Los wrappers existentes se reemplazan por symlinks al canonical AI-DLC. |
| `<dir>/prompts/*.md` (prompts canonical del equipo) | → `examples/<topic>/` (referencia humana) o `.agents/commands/` (si son ejecutables como slash commands). |
| `<dir>/rules/*.md` | Reglas codificables → `stack/constraints.md`. Resto → `examples/`. |
| Planes informales tipo `bootstrap-*.md`, `<feature>.plan.md` (sin estructura R*.*) | Opcional: migrar a `specs/<slug>/` con `/spec-import-plan` (a definir; ver §11). Default: archive a `archive/proto-specs/` hasta que la feature se re-toque. |

**Crítico**: el agente bootstrap **pregunta caso por caso** antes de
consolidar. La heurística da una **recomendación**, no una decisión.
Algunos directorios sospechosos de Categoría B son load-bearing por
una razón no obvia (scripts que los leen, integraciones con CI). Si
el dev confirma "es de un tool/script externo, no tocar" → trato
Categoría A. Si confirma "es nuestro, consolidalo" → migración.

##### Diferencia operativa entre las dos categorías

| | Categoría A (tool externo) | Categoría B (custom interna) |
|---|---|---|
| **Dueño** | El tool (Cursor, Copilot, ...) | El equipo |
| **Quién la lee** | El tool en runtime | Nadie en runtime — sólo refs humanas o de agentes AI |
| **Acción default bootstrap** | Espejar reglas codificables, dejar archivos intactos | Consolidar en AI-DLC vía migración |
| **Anti-patrón asociado** | "Consolidador" que borra archivos del tool | Tratar Categoría B como A — perdés el valor de la consolidación que el equipo quería |
| **Confirmación necesaria** | Implícita (no se toca) | Explícita por dir, caso por caso |

#### Modelo de ejecución del agente bootstrap: X → Y (recomendado)

El agente `/adopt` (§11) puede ejecutarse en dos modelos. El
**default recomendado** es **X → Y**: el agente corre desde la
instalación del template (`X`) operando sobre el repo target (`Y`)
pasado como argumento. Justificación:

1. **Aísla el contexto del agente**. Si el agente corre con `cwd =
   Y`, las tools (Claude Code, Cursor, OpenCode) cargan
   automáticamente el `AGENTS.md`/`CLAUDE.md` previos de `Y` como
   **instrucciones autoritativas** — el bootstrap arranca
   contaminado con reglas del equipo previo, antes de poder
   negociar. En el modelo X → Y, el agente arranca con el protocolo
   AI-DLC autoritativo (cargado desde `X`); el AGENTS.md/CLAUDE.md
   de `Y` entran como **datos a procesar**, no como instrucciones a
   obedecer.
2. **Resuelve chicken-and-egg**. El slash command `/adopt` está
   nativamente en `X` (la instalación del template). No hay que
   instalar infraestructura en `Y` antes de poder bootstrapear.
3. **Multi-repo en una sesión**. Desde una sola sesión abierta en
   `X`, el dev adopta varios repos secuencialmente.
4. **Versionado explícito del template**. `X` tiene su propio
   semver; al aplicar sobre `Y` escribe
   `<target>/.ai-dlc-version` con la versión exacta.

**Path canonical del template**: `~/.syc/ai-dlc/` (per-usuario,
default). Configurable vía env var `AI_DLC_HOME` o flag
`--template-source <path>`. Instalación una sola vez:

```bash
git clone <ado>/syc/ai-dlc-stack-template ~/.syc/ai-dlc
# o cuando exista el CLI:
npx @syc/ai-dlc-init install
```

Adopción de un repo:

```bash
cd ~/.syc/ai-dlc
claude    # o cursor/opencode/codex
# Dentro:
/adopt /Users/picojuanc/repos/<mi-repo>
```

**Modo Y (fallback)**: el dev abre el agente directamente sobre el
repo (`cd ~/repos/<mi-repo>; claude`) y dice *"leé
`<template>/ADOPT.md` y aplicalo a este repo (`.`)"*. Es válido
pero pierde el aislamiento de contexto. Documentar como
limitación.

**Validación crítica en Phase 0**: el agente verifica que `target
≠ template` y que `target` NO sea un subdirectorio de `template`
(no tiene sentido bootstrapear el propio template).

**Compatibilidad con branch protection (v0.16)**: el bootstrap es
**PR-only por diseño**. NUNCA modifica el default branch del target
directamente. Todo lo que el agente escribe va a la rama
`chore/adopt-ai-dlc` (o el nombre que el dev elija en Q4.bis). El
push de esa rama y la apertura del PR son acciones del **dev**, no
del agente. Esto significa que el bootstrap es totalmente compatible
con repos protegidos por branch policies de Azure DevOps / GitHub /
GitLab (require reviewers, build verde, work item linkeado, etc.) —
las policies actúan sobre el PR exactamente como deben. El agente
detecta dinámicamente:

1. **El default branch** (P0.4) via
   `git symbolic-ref refs/remotes/origin/HEAD`. NO asumir `main`.
2. **La rama base del chore** (Q4.bis): default = default branch,
   pero opcionalmente la primera del `promotion_path` si el equipo
   exige promoción para todo cambio.
3. **Branch policies activas** (P1.4 sub-fase): best-effort via
   `az repos policy list` / `gh api .../branches/<X>/protection`
   / `CODEOWNERS` / pipelines requeridos. Reportadas en el resumen
   final (P5.1) para que el dev anticipe los requisitos del PR.

Anti-patrón asociado: ejecutar `/adopt` con `cwd = target` sin
advertir al dev del costo de contexto contaminado por el `AGENTS.md`
previo del repo.

#### Anti-patrones brownfield

| Anti-patrón | Síntoma | Mitigación |
|---|---|---|
| **Reverse-engineering masivo** | Sprint dedicado a "escribir specs de todo lo que ya está en prod" | Specs sólo para código que se va a tocar. Si no se va a tocar, no se documenta. |
| **`legacy` indefinido** | Pasan 18 meses sin que `legacy` se gradúe — no hay presión | Reportar `legacy` como ratio en métricas, sin penalizar. Si una `legacy` no se toca, es porque está estable. |
| **Spec retroactiva post-fix sin verificarse** | Bug fix con stub de spec; nunca nadie verifica que la spec cubra el comportamiento real | Tests `// Derived from R*.*` son obligatorios incluso en stub — verifican que la spec describa lo que pasa. |
| **Confundir `legacy` con `live`** | Features sin spec marcadas `live` directamente | `live` requiere `feature-complete` con spec. Sin spec → `legacy`, no `live`. |
| **Sobreescribir `CLAUDE.md` / `.cursorrules` en bootstrap** | El bootstrap pisa reglas que el equipo ya tenía | Bootstrap respeta lo existente. Espejar a `stack/constraints.md`, no migrar. |
| **"Consolidar" tools borrando archivos del original** | Bootstrap borra `.cursorrules` porque "ya está en `stack/`" | NO consolidar sin OK explícito. AI-DLC convive con Cursor/Copilot/etc. |
| **Migrar masivamente `SESSION_*` y `*HANDOFF*` a `specs/`** | Sprint dedicado a parsear notas viejas y re-estructurarlas | Default: archive. Migrar sólo si el dev lo pide explícitamente. |
| **Tratar AI infra Categoría B como Categoría A** | Bootstrap "respeta" `.ai-integration/`/`.team-prompts/`/etc. del equipo, dejándolos coexistir con AI-DLC duplicado | El equipo construyó esos dirs **queriendo** estandarización — AI-DLC la trae. Categoría B se consolida (con OK por dir). Sólo Categoría A (tools externos: Cursor, Copilot, etc.) se respeta intacta. |
| **Bootstrap "consolidador" agresivo sobre Categoría B sin preguntar** | El agente migra `.team-prompts/` → `.agents/` sin verificar que algún script CI lo lea | Categoría B se confirma **dir por dir**. Heurística da recomendación; dev decide. Si "es nuestro" → consolidar. Si "lo usa otra cosa" → tratar como A. |
| **Merge semántico de `AGENTS.md` previo sustantivo** | El agente parsea, reordena y redistribuye secciones del AGENTS.md previo del equipo; el resultado es un Frankenstein donde no se sabe qué viene de quién | NO interpretar ni reorganizar. Estrategia correcta: **appended-section con sentinels** (sub-protocolo §15 *AGENTS.md previo*). El bloque AI-DLC es el único territorio del bootstrap; fuera = del equipo. |
| **Ejecutar el bootstrap con `cwd = target`** sin advertir al dev | Las tools (Claude/Cursor/OpenCode) cargan AGENTS.md y CLAUDE.md previos del target como instrucciones autoritativas; el agente arranca contaminado | Modo recomendado X → Y: agente corre desde `~/.syc/ai-dlc/` operando sobre target absoluto. Modo Y (cwd = target) es fallback válido pero degradado — reportar al dev. |
| **Bootstrapear el propio template** (target apunta a `~/.syc/ai-dlc/` o subdir) | Confusión del dev; no tiene sentido | Phase 0 P0.0 validation: STOP si `target == template` o `target ⊂ template`. |
| **Asumir que el default branch es `main`** | Algunos repos empresariales trabajan con `master`, `pruebas`, `desarrollo`, `develop`. El agente pisa la rama equivocada o pide checkout que falla | P0.4 detección dinámica via `git symbolic-ref refs/remotes/origin/HEAD` con fallback explícito (preguntar al dev). Confirmar siempre antes de Phase 1. |
| **Modificar el default branch directamente durante el bootstrap** (`git push origin <default>`, `git checkout <default>` para escribir, `git merge` que toque la base) | Rompe branch protection; los repos productivos con branch protection tienen `main` bloqueada por policies — el push falla, mejor que pase, pero el flujo conceptual es incorrecto desde el inicio | Bootstrap PR-only por diseño. El agente escribe SOLO en `chore/adopt-ai-dlc`. El push y el PR son acciones del dev. |

#### Cuando NO es brownfield

Si el equipo arranca un proyecto **nuevo** y quiere AI-DLC desde día
0: NO es brownfield. Se sigue el flujo de §6 (`/spec-new`, etc.) desde
la primera feature. Las Fases 1-4 arriba aplican.

### Upgrade de la metodología en un repo adoptado

Una vez que un repo tiene AI-DLC instalado y la metodología publica
una versión nueva (`vX → vY`), el repo se actualiza sin destruir las
customizaciones del equipo. El mecanismo se apoya en tres piezas:

1. **Manifiesto per-archivo** en `.ai-dlc-version` (introducido v0.21):
   declara `role` por archivo (`owned` / `bracketed` / `template` /
   `user`) y `sha256_at_install` como baseline.
2. **Sentinels** `<!-- ai-dlc:section-start v=<X> -->` ... `<!--
   ai-dlc:section-end -->` envolviendo el contenido AI-DLC dentro de
   archivos compartidos (típicamente `AGENTS.md`). Lo de afuera =
   territorio del usuario, intocable durante upgrade.
3. **Slash command `/adopt --upgrade`** (canonical en `ADOPT.md` del
   template) que ejecuta el protocolo per-archivo.

#### Tabla de roles

| Role | Semántica | Algoritmo de upgrade |
|---|---|---|
| `owned` | AI-DLC manda el contenido. El archivo es 100% AI-DLC. | Si hash actual == baseline → auto-replace con versión nueva. Si divergió → diff prompt al dev con 4 opciones: `take-new` / `keep-mine` / `merge-manual` / `skip`. |
| `bracketed` | Archivo compartido AI-DLC ↔ usuario. Sólo el bloque entre sentinels es de AI-DLC. | Reemplazar SOLO el contenido entre sentinels. Afuera intocable, sea cual sea el hash del archivo completo. |
| `template` | Esqueleto que el usuario llena (ej. `stack/conventions.md`, `repo-config.yaml`). | Additive merge: agregar keys/secciones nuevas del template, NUNCA pisar valores existentes. YAML/JSON additive; markdown skip por default + flag para revisión manual. |
| `user` | Archivos que el usuario crea durante el uso normal (`specs/<feature>/*`, contratos publicados en `.org/`, etc.). | Nunca tocados por `--upgrade`. La ausencia del path en el manifiesto implica `role: user`. |

#### Heurísticas de asignación por path (default cuando el agente registra un archivo nuevo)

| Path | Role default |
|---|---|
| `AGENTS.md`, `CLAUDE.md` | `bracketed` (si el template usa sentinels) o `owned` |
| `repo-config.yaml` | `template` |
| `.agents/commands/*.md`, `ADOPT.md`, `BOOTSTRAP.md`, `BROWNFIELD-CHECKLIST.md` | `owned` |
| `stack/*.md` | `template` |
| `specs/**`, `.org/contracts/**`, `archive/**` | `user` (no van al manifiesto) |
| `.mcp.json` | `template` |

El protocolo detallado del upgrade (qué hace P3.U y P4.U, manejo de
renames, multi-version, manifiestos legacy < v0.21) vive en
`ADOPT.md` del template — sección "Modo `--upgrade` — protocolo
detallado". El methodology declara la semántica; el agente la ejecuta.

#### Anti-patrones

| Anti-patrón | Síntoma | Mitigación |
|---|---|---|
| `take-new` automático en archivos `owned` modificados | Trabajo del usuario destruido sin aviso | Siempre prompt con diff. La decisión es humana |
| Sentinels manipulados por el usuario | Sentinels movidos, duplicados, o borrados — el upgrade no puede operar | El agente detecta y pide arreglar antes de upgrade. NO inferir bordes |
| Modificación fuera de sentinels durante `--upgrade` | El upgrade pisa contenido que era del usuario | Sentinels son contrato. Afuera = del usuario, sea Cat A.1 o A.3/A.4 |
| Upgrade sobre manifiesto legacy (< v0.21) sin migrar | A-ciegas — sin baseline, no se detecta divergencia | Migrar manifiesto primero (P4.U *Migración*), reportar limitación al dev |
| Saltar regeneración del manifiesto tras upgrade | El siguiente upgrade no tiene baseline correcto | El upgrade actualiza `methodology_version`, `applied_at` y todos los `sha256_at_install` |

### Roles necesarios

| Rol | Responsabilidad | FTE estimado |
|---|---|---|
| **AI-DLC Champion** | Owner del proceso, evangeliza | 1 |
| **Platform engineer** | Mantiene `.org/`, MCP servers, scripts | 1-2 |
| **Tech leads por equipo** | Adoptan en sus equipos | 0.2 c/u |
| **Architect (humano)** | Supervisa Architect Agent, decisiones finales | 0.5-1 |

---

## Métricas de éxito

### Métricas de proceso

| Métrica | Cómo medir | Objetivo |
|---|---|---|
| **Cobertura de spec** | % de features con spec en `/specs/` | >90% |
| **Trazabilidad** | % de tests con `// Derived from R*.*` | >85% |
| **Bugs Tipo B** | % de bugs por gap de spec | <20% |
| **Bugs Tipo C** | % de bugs por spec ambigua | <10% |
| **Spec lead time** | Días de spec creada → aprobada | <5 días mediana |
| **Code lead time** | Días de spec aprobada → PR merged | <10 días mediana |

### Métricas de impacto

| Métrica | Cómo medir | Objetivo |
|---|---|---|
| **DORA: deployment frequency** | Despliegues/semana por servicio | +30% vs baseline |
| **DORA: lead time for changes** | Commit → producción | -25% vs baseline |
| **DORA: change failure rate** | % deploys con incidente | -40% vs baseline |
| **DORA: MTTR** | Tiempo medio de recuperación | -30% vs baseline |
| **Satisfacción dev** | Encuesta trimestral | NPS >+30 |
| **Velocidad de onboarding** | Días hasta primer PR mergeado | -50% vs baseline |

### Dashboard sugerido (Azure DevOps Analytics + Grafana)

- Distribución de bugs por tipo (A/B/C/D/E).
- Cobertura de R*.* por servicio.
- Lead time de specs vs code.
- PRs por tipo (spec / implementation / hotfix).
- Costo de IA (tokens, agentes) vs ROI (tiempo ahorrado).

---

## Anti-patrones

### Anti-patrones de spec

| Anti-patrón | Síntoma | Mitigación |
|---|---|---|
| Spec demasiado vaga | Agente improvisa, bugs Tipo B altos | Iterar EARS, exigir NFRs medibles |
| Spec demasiado detallada | Mantenimiento alto, duplica el código | Detalles a `design.md`, no a `requirements.md` |
| Spec sin owner | Nadie actualiza, drift | Owner explícito en frontmatter |
| Spec creada *después* del código | Doc retroactiva, sin valor | Hook que exige spec en PRs de features |
| Initiative obligatoria por defecto | Burocracia para casos simples (1 repo, 1 equipo); retrasa el inicio de features que podrían arrancar ya | Initiative **opcional**. Sólo cuando hay coordinación real cross-equipo. Default: spec de feature en el repo, sin nivel superior. |
| Coordinación cross-repo sin contrato | Specs aisladas en cada repo que no encajan al integrar; retrabajo en la integración | **Contrato versionado** (OpenAPI / AsyncAPI / schema) como acuerdo bilateral, no Initiative como gate. El contrato vive en `.org/contracts/` o se acuerda entre los dos equipos. |
| **Spec contradice otra spec sin resolución explícita** | Dos specs activas declaran shapes incompatibles para el mismo endpoint, o reglas opuestas sobre el mismo módulo; explota en integration tests o en prod meses después | `/spec-new` CLARIFY 3.c ejecuta **conflict scan cross-spec** (§11) antes de PROPOSE. Conflictos detectados se resuelven con una de 4 opciones: alinear / amendment de la otra / coexistir con justificación en `design.md` / `OPEN_QUESTION`. `/spec-verify --cross` ejecuta el scan a demanda. |

### Anti-patrones de agentes

| Anti-patrón | Síntoma | Mitigación |
|---|---|---|
| Agente "que lo sabe todo" | Context overflow, alucinaciones | Especialización + catálogo consultable |
| Skip de revisión humana | Bugs en producción, deuda técnica | Gates obligatorios en puntos clave |
| Agente sin acceso a contratos cross-repo | Alucina endpoints, eventos, schemas | `.org/contracts/` **obligatorio** cuando hay dependencias cross-repo (§9). El resto de `.org/` es opcional. |
| Uso de IA sin estándares por dev | Heterogeneidad, inconsistencia | Reglas Cursor + `CLAUDE.md` versionados |
| **Agente usa jerga AI-DLC sin definir** ("¿firmamos G2?", "ya quedaste en partial-deploy-pruebas", "esto es Tipo B") | El dev nuevo no entiende; pierde confianza en el agente o ejecuta el paso sin saber qué firma. Caso real observado en validación de Neo Estampillas. | §3.18 *Claridad de jerga*: definir términos al primer uso por sesión. Glosario rápido en §3. Ejemplo: *"¿Aprobamos requirements + design firmados? (gate G2 — autoriza pasar a implementación)"* en vez de *"¿Firmamos G2?"*. |

### Anti-patrones de integración

| Anti-patrón | Síntoma | Mitigación |
|---|---|---|
| Specs ↔ Boards desincronizados | Estado confuso, doble fuente de verdad | Sync bidireccional automatizado |
| Pipelines que ignoran specs | Deploy de algo no especificado | Gate de validación en pipeline |
| Secrets en specs | Filtración, no-compliance | Specs referencian secrets por nombre, no valor |
| `.org/contracts/` desactualizado | Integration tests rotos al desmockear, bugs Tipo E falsos | CI valida contratos en cada PR (semver, deprecation paths). |
| `.org/` aspiracional desactualizado (catalog.yaml, policies, ADRs vacíos o viejos) | Architect Agent termina ignorando el catálogo y pregunta al humano | **Aceptable**. El catálogo aspiracional no es crítico (§9); sólo se mantiene si hay un FTE dedicado, y si no lo hay, eliminar antes que tener basura. |

### Anti-patrones de coordinación cross-team

Estos rompen específicamente los principios §3.8-3.11. En una org
grande son los más comunes y los más caros: convierten una metodología
ligera en burocracia con disfraz.

| Anti-patrón | Síntoma | Mitigación |
|---|---|---|
| **Initiative tratada como autoridad** | Features esperan "firma" del PM/arquitecto dueño de la Initiative antes de arrancar; reuniones de gate por iniciativa | La Initiative es **informativa, no autoritativa** (§3.8, §6). Si una iniciativa necesita autoridad real, no es Initiative — es un Epic con gate explícito en el proceso del equipo proveedor. |
| **Contrato firmado en chat / Confluence sin versionar** | "¿Qué dice el contrato?" termina en captura de pantalla de Teams del 2026-04-12; al integrar nadie está seguro de qué se acordó | Contrato versionado en `.org/contracts/` (o repo del proveedor con tag SemVer); chat es notificación, no fuente de verdad (§9, §3.9). |
| **Mock sin owner ni "ready to unmock"** | El mock queda como fixture permanente, se desactualiza, los tests siguen pasando contra realidad ficticia | Cada `D-N` declara `Owner:` del mock y `Ready to unmock:` (condición observable de cuándo desactivarlo). `/spec-status` reporta mocks viejos cuya `D` lleva > N semanas sin avanzar (§6). |
| **Task `blocked` sin `blocked_by`** | Otros devs no saben por qué la task está parada; alguien la mueve a `pending` por confusión y empieza a duplicarla | Regla del Lifecycle: `blocked` **requiere** `blocked_by:` con causa concreta (otra task, una `D-N`, una decisión pendiente). `spec-lint` rechaza la combinación inválida (§6). |
| **Dependencia "pedida en chat" sin work item en el proveedor** | El proveedor olvida que existe; la feature consumidora espera indefinidamente; el mock se vuelve permanente por inercia | El campo `Tracking:` de la `D-N` apunta a un **work item real** en el project del proveedor (§6 paso 3 Contract-First). Si no hay work item, la dependencia no está acordada — sigue `NEGOTIATING`, no `AGREED`. |
| **Amendment registrado como bug Tipo B** (o viceversa) | Métrica de Tipo B contaminada (parece que las specs son malas cuando en realidad cambió la ley); el equipo "aprende" lecciones falsas | `/spec-amend` y `/bug-triage` son herramientas distintas. La distinción está en la tabla de §8 (origen externo vs interno). |
| **Architect Agent "aprobando" contratos** | El Architect Agent propone OpenAPI y el dev lo materializa sin que el otro equipo lo haya visto; al integrar el otro equipo dice "yo no acordé esto" | El Architect Agent **propone y sugiere**; los humanos (tech leads de ambos equipos) aprueban (§7 Architect Agent es orquestador, no autoridad cross-team). El estado `AGREED` requiere confirmación humana del proveedor. |
| **Feature flag olvidado encendido en dev/test pero no en prod** | "Funciona en dev pero no en prod" sin diagnóstico; bugs Tipo D fantasma | `status.md` declara `feature_flag.envs` por ambiente; `/spec-status` reporta divergencias (§6 Lifecycle). En `feature-complete` todos los flags deben estar `OFF` excepto los justificados. |

### Anti-patrones de bugs

| Anti-patrón | Síntoma | Mitigación |
|---|---|---|
| Crear spec nueva por cada bug | Specs fragmentadas | Actualizar spec del feature dueño |
| Fix sin actualizar spec (Tipo B) | Spec miente sobre el sistema | Linter exige spec update si código cambia |
| Todos los bugs tratados como Tipo D | Erosión del SDD | Reservar D para incidentes reales con SLA roto |
| Cerrar Tipo B/C sólo con el `R*.*` | El gap se parcha en esta feature pero el agente vuelve a authorear la misma clase en la siguiente; "déjà vu" en `bugs.md` | Paso 5 de `/bug-triage`: aplicar ratchet harness si el gap es una clase (§8 *Ratchet harness*) |
| Ratchet "by reflex" en cada Tipo B | AGENTS.md, slash-commands y `spec-lint` crecen sin control; agentes saturados de reglas; cada feature pesa más | Sólo ratchetar si el gap es una **clase** detectable por regla. Caso aislado cierra con el `R*.*` sin tocar harness |

---

## Apéndices

### A. Plantilla `requirements.md`

```markdown
---
feature: <slug>
modality: code                           # code | config-only | data-migration | catalog-only | docs-only | refactor-only (§6)
initiative: <initiative-slug>            # opcional — omitir si la feature es self-contained
owner: <team-name>
status: draft | in-review | approved | in-implementation | done
azure_boards:
  feature_id: <work-item-id>
  epic_id: <epic-id>                     # opcional — sólo si la feature pertenece a una Initiative
---

# Feature: <Nombre>

> *(Opcional)* Parte de [Initiative: <name>](<url-al-repo-de-iniciativas>)
> — omitir esta línea si la feature es self-contained.

## Contexto
<por qué este feature existe>

## Stakeholders
- <PM>
- <Tech lead>
- <Compliance/Legal>

## Métricas de éxito
- <KPI 1>
- <KPI 2>

## Requisitos funcionales

### R1 — <Categoría>

**R1.1** WHEN ..., THE SYSTEM SHALL ...
         Tests: unit, integration

**R1.2** ...
         Tests: unit

### R2 — <Categoría>

...

## Requisitos no funcionales

**NFR1** THE SYSTEM SHALL ... (p99 < 500ms)
         Tests: load

## Dependencies                          # omitir si la feature no tiene dependencias externas (§6)

### D1 — <título corto del endpoint / SP / contrato>
- **Tipo**: humana | técnica
- **Estado**: NEGOTIATING | AGREED | IMPLEMENTED | LIVE
- **Contrato**: <path a OpenAPI/AsyncAPI/SQL schema, o tag SemVer>
- **Owner**: <equipo proveedor> / <@persona>
- **Tracking**: <URL al work item en el project ADO del proveedor>
- **ETA**: <informativo>
- **Estrategia**: MOCK | BLOCK | PIN | WORKAROUND
- **Mock**: `mocks/<nombre>.mock.<ext>`
- **Ready to unmock**: <condición observable, p.ej. "endpoint en staging">

## Fuera de scope
- <X>
- <Y>

## Dependencias internas (opcional)
- Depende de: <otra feature de este mismo repo>
- Bloquea: <otra feature>

## OPEN_QUESTIONS (cierran antes de aprobación)
- [ ] <pregunta pendiente> — owner: <@persona>, due: <YYYY-MM-DD>
```

### B. Plantilla `design.md`

```markdown
# Design: <Feature>

## Arquitectura

<diagrama mermaid>

## Componentes

| Componente | Responsabilidad | Lenguaje/Framework |
|---|---|---|
| ... | ... | ... |

## Modelo de datos

<DDL o ER diagram>

## Contratos

### API

<OpenAPI snippet o link>

### Eventos

<AsyncAPI snippet o link>

## Decisiones (ADRs)

> Notación `DEC-N` (no `D-N`, que está reservado para Dependencies en §6).

- DEC-1: <decisión> — Justifica R<x>.<y>
- DEC-2: ...

## Despliegue

### OpenShift
- Namespace: <ns>
- Recursos: <list>
- Manifiestos: `/deploy/openshift/`

### Configuración
| Variable | Origen | Notas |
|---|---|---|

## Seguridad

- Auth: ...
- Datos sensibles: ...
- Threat model: ...

## Observabilidad

- Métricas: ...
- Logs: ...
- Alertas: ...

## Trade-offs

| Opción A | Opción B | Decisión |
|---|---|---|
| ... | ... | ... |
```

### C. Plantilla `tasks.md`

```markdown
# Tasks: <Feature>

## T1 — <Título> [S|M|L]
- **Cubre**: R1.1, R1.2
- **Archivos**:
  - src/...
  - tests/...
- **Acceptance**:
  - [ ] Tests passing
  - [ ] Lint clean
  - [ ] <criterio específico>
- **Azure Boards**: AB#<id>

## T2 — ...
```

### D. Plantilla `status.md`

Formato canónico YAML (definido en §6 *Lifecycle de feature y task*):

```yaml
---
feature: <slug>
state: not-started | in-progress | partial-deploy-<env> | feature-complete | live | cancelled
updated: <YYYY-MM-DD>
updated_by: "@<user>"
feature_flag:                            # omitir esta sección si la feature no tiene flag
  name: <flag-name>
  envs: { pruebas: OFF, qa: OFF, main: OFF }
---

# Status

## Tasks

T1: pending           |
T2: in-progress       | dev @user
T3: blocked           | blocked_by: D1=LIVE
T4: done              | commit a3f2c1 | 2026-05-12
T5: deployed:pruebas  | commit 17fc20 | 2026-05-15
T6: deployed:qa       | commit b22e91 | 2026-05-18

## Dependencies snapshot                 # omitir si la feature no tiene D-N

D1 (<título corto>): AGREED, ETA <fecha>
D2 (<título corto>): NEGOTIATING

## Notas
- <YYYY-MM-DD>: <evento, decisión, comentario>
```

### E. Plantilla de PR description

```markdown
## Resumen
<descripción corta>

## Tipo
- [ ] Spec (docs en /specs/)
- [ ] Implementation (código de producción)
- [ ] Bug fix
- [ ] Hotfix (Tipo D)
- [ ] Amendment (post-aprobación)

## Requirements cubiertos
- R<x>.<y> — <descripción corta>
- R<x>.<z> — <descripción corta>

## Amendments aplicados                  # omitir si no aplica
- AMD-<NNN> — <título corto>

## Tasks completadas
- T<n>

## Work items
- AB#<id>

## Verificación
- [ ] Tests con `// Derived from R*.*`
- [ ] status.md actualizado
- [ ] Spec actualizada si necesario
- [ ] Linter, typecheck verde
- [ ] Pipeline verde
- [ ] Manifiestos OpenShift validados (si aplica)

## Rollout
- Feature flag: <nombre> (off por defecto)
- Plan: ver rollout-plan.md

## Riesgos
- ...
```

### F. Ejemplo de `.org/catalog.yaml` completo

```yaml
metadata:
  version: 1
  updated: 2026-05-14
  owner: team-platform

services:
  - name: checkout-api
    repo: https://dev.azure.com/acme/payments/_git/checkout-api
    azure_devops:
      project: payments
      area_path: Payments\Checkout
      iteration_path: Payments\2026.Q2
    owner: team-payments
    on_call: payments-oncall@acme.com
    tier: 0   # tier 0 = critical
    runtime: node-20
    openshift:
      cluster: ocp-eu-west-1
      namespace: payments-prod
      route: checkout.acme.com
      replicas:
        min: 2
        max: 10
    databases:
      - name: checkout_db
        type: postgres
        region: eu-west-1
        pii: true
    consumes_events:
      - user.created.v1
      - product.priced.v2
    produces_events:
      - order.placed.v2
      - payment.captured.v1
    pii:
      - billing_address
      - payment_method_last4
    compliance:
      - GDPR
      - PCI-DSS
    slos:
      availability: 99.95
      latency_p99_ms: 500
      error_budget_monthly_minutes: 21
```

### G. Recursos y referencias

- **EARS Syntax**: Mavin, A. et al. — *Easy Approach to Requirements Syntax*
- **Spec-Driven Development**: GitHub Spec Kit, AWS Kiro
- **Azure DevOps REST API**: docs.microsoft.com/azure/devops/rest
- **OpenShift CLI**: docs.openshift.com/container-platform/latest/cli_reference/
- **Model Context Protocol (MCP)**: modelcontextprotocol.io
- **Claude Code**: docs.claude.com/en/docs/claude-code
- **Cursor Rules**: cursor.com/docs/rules
- **Figma MCP Server**: figma.com/developers/mcp
- **Figma Make**: figma.com/make
- **Plantillas internas de Guidelines/Integration**: ver `.org/templates/design/`
  de la organización (cada equipo adapta el template de su stack)

### H. Estructura mínima del `Guidelines.md` por repo

> Documento por-repo que diseño usa como contrato para Figma Make.
> Ejemplos reales en repos del stack `React + Clean Arch + .NET 9` están en
> `.org/templates/design/react-clean-arch/Guidelines.md.tmpl`.

Secciones obligatorias:

1. Regla fundamental: NO ASUMAS — PREGUNTA
2. Alcance de generación (frontend/backend, mocks, archivos extra)
3. Stack técnico bloqueado (tabla con versiones)
4. Librerías prohibidas (lista explícita)
5. Dependencias privadas a excluir
6. Componentes UI disponibles
7. Path alias e imports
8. Estructura de carpetas
9. Convenciones de nombres
10. Patrones de código (ejemplos canónicos)
11. Separación lógica/visual
12. Buenas prácticas (a11y, responsive, seguridad)
13. Mocks con metadata `TODO-INTEGRATION`
14. Contexto del backend (para `API_SPECS.md`)
15. Archivos a generar
16. Principios de integración
17. Checklist de entrega

### I. Estructura mínima del `figma-make-integration.md` por repo

Secciones obligatorias:

1. Uso (cómo se invoca)
2. Principios de integración (no asumir, re-integración segura, disciplina de
   dependencias)
3. Fase 1: Validación inicial
4. Fase 2: Verificación de dependencias del proyecto
5. Fase 3: Análisis de integración (TODOs y conflictos)
6. Fase 4: Copiar archivos (con mapeo y filtrado de temporales)
7. Fase 5: Integración de rutas
8. Fase 6: Migración de repositorios (mock → real)
9. Fase 7: Registro en DI Container
10. Fase 8: Análisis y generación de backend desde metadata
11. Fase 9: Pruebas y validación
12. Fase 10: Reportes (`INTEGRATION_REPORT.md`)
13. Fase 11: Limpieza
14. Troubleshooting (errores comunes)
15. Notas importantes (patrones del proyecto, naming, etc.)

---

## Próximos pasos

1. **Revisar este documento** con líderes técnicos, de producto y de diseño.
2. **Identificar el piloto**: equipo, servicio, feature (idealmente uno con
   componente UI para validar el flujo con Figma Make).
3. **Preparar herramientas**:
   - PAT de Azure DevOps con scopes mínimos.
   - Instalación de Cursor + Claude Code en máquinas de desarrolladores.
   - Plantillas de `CLAUDE.md`, rules, slash commands en repo de templates.
   - Acceso a Figma + Figma Make para el equipo de diseño piloto.
4. **Crear `.org/` inicial** con:
   - Catálogo de servicios del equipo piloto (`catalog.yaml`).
   - Templates de `Guidelines.md` y `figma-make-integration.md` por stack.
5. **Crear `.ai-dlc/design/` en el repo piloto** con los prompts ya
   funcionales (adaptados del template).
6. **Definir métricas baseline** (DORA actuales) para comparar después.
7. **Workshop de kickoff** con:
   - Equipo de desarrollo (flujo SDD + Cursor/Claude Code).
   - Equipo de diseño (flujo Figma + Figma Make + Guidelines).
   - Conjunto: cómo se conectan ambos flujos.
8. **Iterar**.

---

> **Documento vivo**. Las versiones futuras incorporarán lecciones del piloto.
> Cambios significativos requieren PR con review de los owners definidos en
> el frontmatter.
