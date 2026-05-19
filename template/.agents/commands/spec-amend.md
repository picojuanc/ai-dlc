---
name: spec-amend
description: Cambio de spec post-aprobación (cliente, regulación, negocio)
---

# `/spec-amend <feature-slug> --reason "<motivo>"` — Cambio de spec post-aprobación

Para feature `<feature-slug>` con motivo `<motivo>`:

1. **CONTEXT** — leer `requirements.md`, `tasks.md`, `status.md` y
   `amendments.md` (si existe) de la feature.
2. **ALCANCE** — identificar qué `R*.*` y tasks están potencialmente
   afectadas (proponer, NO decidir en solitario). Confirmar con el
   usuario el alcance final del cambio.
3. **WORKTREE/RAMA** — preparar el espacio aislado **antes de tocar
   ningún archivo** (§6 *Worktree, ramas y flujo de promoción*,
   convención `amend/...`):
   - **Numerar el amendment**: elegir el siguiente `AMD-NNN` leyendo
     `amendments.md` (si no existe, `AMD-001`). Reservar el número
     para la rama y los commits.
   - **Determinar rama base** según `status.md`:
     - Feature aún en desarrollo (state ≠ `deployed:*`/`live`,
       worktree `feat/<slug>` vivo): trabajar **sobre la misma**
       `feat/<slug>` — sólo verificar `cwd` y continuar.
     - Feature ya mergeada (state `deployed:<env>` o `live`,
       worktree borrado): crear rama nueva desde el ambiente vivo.
   - **Proponer** y pedir OK antes de ejecutar (acción reversible
     pero observable, §3.16):
     ```bash
     git worktree add -b amend/<feature-slug>/AMD-NNN \
       ../<repo>--amend-<feature-slug>-<NNN> \
       origin/<base-branch>
     ```
   - **Verificar** que el `cwd` quedó en el worktree/rama correcta
     **antes** de editar nada. Editar directo sobre `main` (o
     cualquier rama de ambiente) es un anti-patrón (§11 *Amendments*).
4. **EDITAR `requirements.md`**:
   - `R*.*` que dejan de aplicar se marcan ~~tachadas~~ (no se borran).
   - `R*.*` que cambian se reescriben in-place.
   - `R*.*` nuevas se añaden con la siguiente numeración disponible.
5. **EDITAR `tasks.md`**: tasks que dejan de aplicar → `cancelled`;
   tasks que cambian → modificadas; tasks nuevas → al final, ordenadas
   por dependencia.
6. **REGISTRAR** el evento en `amendments.md` (crear si no existe) con
   el `AMD-NNN` reservado en el paso 3:

   ```
   ## AMD-NNN — <título corto> (<fecha>)
   - Motivo: <descripción + fuente: cliente / legal / negocio>
   - Autor: <quién lo dictó> vía <quién lo registró>
   - R*.* afectadas: <lista>
   - Tasks afectadas: <lista>
   - PR de spec: !<id>
   - PR de implementación: !<id>
   ```

7. Los commits posteriores citan `AMD-NNN` además de `R*.*`.

Un Amendment **NO** es un bug Tipo B. Tipo B son cosas que estaban mal
desde el inicio; un Amendment es un evento nuevo posterior a la
aprobación. Mantener la distinción mejora la métrica de calidad de
spec authoring.
