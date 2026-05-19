---
name: spec-promote
description: Abrir PR de promoción al siguiente ambiente declarado en repo-config.yaml
---

# `/spec-promote <feature-slug> --to <env>` — Abrir PR de promoción

Sigue el protocolo §7 (AGENTS.md). Para feature `<feature-slug>` con destino
`<env>`:

1. **CONTEXT** — verificar:
   - Worktree correcto (`cwd` = `<repo>--<feature-slug>/`) y rama
     actual (§6 Worktree).
   - Estado actual de la feature (`status.md`).
   - **Leer `repo-config.yaml`** (§6 *Configuración del repo*) y
     extraer: `repo_type`, `tracker`, `environments`, `promotion_path`.
     Si el archivo no existe, **parar** y proponer crearlo.
   - **Ambiente destino válido**: `<env>` debe estar presente en
     `environments[].name`. Si no, **parar** y listar los válidos.

2. **PRE-FLIGHT CHECK** — verificar el gate del ambiente destino. Las
   reglas exactas vienen de `environments[<destino>].gate` en
   `repo-config.yaml`. Patrón general:

   **`repo_type: service`** (default SYC: pruebas → qa → main):
   - PR a `pruebas`: tests verdes + spec aprobada + state ≥
     `partial-deploy-pruebas`.
   - PR a `qa`: tests verdes + QA sign-off + state ≥
     `partial-deploy-qa` o `feature-complete`.
   - PR a `main`: state `feature-complete` + `rollout-plan.md` +
     Ops sign-off.

   **`repo_type: library`** (paquete npm/pip/maven, p.ej. pruebas →
   main):
   - PR a `pruebas` (`deploy_trigger: publish-prerelease`): tests
     verdes, version bump prerelease y changelog. NO hay "ambiente"
     — el publish al registry **es** el deploy.
   - PR a `main` (`deploy_trigger: publish-release`): state
     `feature-complete`, QA del consumidor firmó sobre el prerelease,
     release notes y tag firmado.

   **`repo_type: infra`** (sandbox → prod):
   - PR a `sandbox`: `terraform plan` dry-run y revisión.
   - PR a `prod`: state `feature-complete`, `terraform plan` revisado,
     Ops sign-off y ventana de cambio si aplica.

   **`repo_type: frontend-app`**: igual a `service` salvo que también
   considera previews por PR si están declarados.

   Si falta algo, **parar** y reportar qué falta y a quién pedirlo.

3. **CLARIFY** — si la rama destino del PR es ambigua, preguntar cuál.
   Si el feature flag de prod debe ir `OFF` al merge (lo normal),
   confirmar.

4. **PROPOSE** — mostrar branch source/target, resumen del PR (`R*.*`
   cubiertos, `AMD-NNN` aplicados, tasks done, commit count), reviewers
   sugeridos. Si `repo_type: library`: tipo de publish y version bump
   propuesto. **Pedir OK explícito** antes de abrir el PR (§3.16).

5. **EXECUTE** — comando según `tracker` declarado:
   - `tracker: azure-devops` → `az repos pr create ...` (vía MCP de
     ADO o `az` CLI). Linkear work items (`--work-items`).
   - `tracker: github-issues` → `gh pr create --base <target> --head <current> ...`. Linkear issues (`closes #<n>`).
   - `tracker: jira` / `linear` / etc. → análogo.
   - `tracker: none` → `gh pr create` (o equivalente), sin work items.

   Para `repo_type: library`: en lugar de PR a `main` para "release",
   el comando puede ser un workflow de publish (`npm publish`,
   `pnpm publish`, etc.). Confirmar el modo con el dev antes de actuar.

6. **UPDATE STATUS** — cuando el dev confirme merge (o publish para
   library): tasks afectadas → `deployed:<target-env>` (o
   `published:<target>`). Recalcular `state:` (§6 Lifecycle).

7. **CLOSE** — URL del PR/release, qué gates faltan, siguiente paso
   sugerido (usar el siguiente nombre de `promotion_path`, no asumir
   `qa`).
