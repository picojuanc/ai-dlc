---
name: spec-handoff
description: Transferir ownership de una feature a otro dev (rotación, baja)
---

# `/spec-handoff <feature-slug> --to <@user>` — Transferir ownership

Sigue el protocolo §7 (AGENTS.md). Para feature `<feature-slug>` con destino
`<@new-owner>`:

1. **CONTEXT** — leer `requirements.md`, `status.md`, `amendments.md`,
   `bugs.md`, commits recientes del worktree y `OPEN_QUESTIONS`.

2. **CLARIFY** — preguntar: handoff total o parcial; dev saliente
   sigue accesible; conversaciones abiertas con equipos proveedores
   de `D-N` que sólo el dev saliente conocía.

3. **GENERATE RESUMEN** — producir resumen ejecutable para el new
   owner (mostrar primero, NO escribir aún): problema y motivación;
   estado actual de tasks; `D-N` activas con último contacto conocido;
   bugs abiertos; amendments aplicados; pre-flight check obvio;
   `OPEN_QUESTIONS` con owner/due; riesgos.

4. **EXECUTE** — tras OK del dev saliente y, si está accesible, del
   new owner:
   - Actualizar `owner:` en frontmatter de `requirements.md`.
   - Re-asignar work items en el tracker declarado en
     `repo-config.yaml` (si `tracker: azure-devops`, vía
     `az boards work-item update --assigned-to`; si `github-issues`,
     vía `gh`; si `none`, omitir este paso).
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

   - `D-N` cuyo `Tracking:` apuntaba a una conversación personal del
     saliente: marcar como `NEGOTIATING-stale` (§6 SLAs) y proponer
     reabrir el contacto desde el nuevo owner.

5. **CLOSE** — entregar al new owner: path del worktree, link al
   resumen, acciones inmediatas sugeridas, confirmación de que el dev
   saliente puede ejecutar `git worktree remove` tras OK explícito.

Un handoff **NO** es un Amendment ni un bug — es un evento de
ownership. El prefijo `HANDOFF-` lo distingue de `AMD-` y no contamina
métricas.
