---
name: spec-implement
description: Avanzar la siguiente task con pre-flight check
---

# `/spec-implement <feature-slug>` — Avanzar la siguiente task

Sigue el protocolo §7 (AGENTS.md). Para feature `<feature-slug>`:

1. **CONTEXT** — leer `status.md`, `tasks.md`, `requirements.md`,
   `design.md`, y `dependencies`/`amendments` si existen.

2. **PRE-FLIGHT CHECK** — reportar al dev:
   - **`stack/` completo**: si algún archivo aún tiene `TODO`, **parar**
     y proponer completar `stack/` primero (AGENTS.md § Bootstrap).
   - **Worktree correcto**: `cwd` es `<repo>--<feature-slug>/` y la
     rama activa es `feat/<feature-slug>` (§6 Worktree). Si no
     coinciden, **parar** y proponer moverse al worktree correcto.
   - Spec aprobada (`status.md` lo confirma; si no, **parar**).
   - Última task `done` y commit hash.
   - Cuál es la siguiente task `pending` (no `blocked`).
   - ¿Hay tasks `blocked` que el dev quizá quiera revisar antes
     (`blocked_by`: dependencia, decisión humana, etc.)?
   - ¿Tests del último deploy verdes? Si no, **parar** y reportar.
   - ¿Commits desde el último update de `status.md`? Si sí, preguntar
     si integrarlos al lifecycle (§7 reglas operacionales).
   - ¿`state` declarado coincide con la derivación del Lifecycle (§6)?
     Si no, decirlo.

3. **CLARIFY** — si la siguiente task tiene ambigüedad, depende de una
   `D-N` aún no `AGREED`, o requiere decisión humana (naming, migration
   risk, breaking change), **preguntar antes de tocar código** (§3.12).

4. **PROPOSE** — explicar archivos a crear/modificar (respetando
   `stack/architecture.md` y `stack/patterns.md`), tests a escribir
   (con `// Derived from R*.*` según `stack/testing.md`), nivel de
   riesgo. **Pedir OK explícito si la task es M/L o toca código
   compartido**.

   **Si la task implica instalar dependencias nuevas** (modificar
   `package.json`, `pyproject.toml`, `*.csproj`, etc.), antes de
   ejecutar `npm install` / `pip install` / etc.:
   - Listar cada dep nueva: nombre, versión, propósito (qué `R*.*`
     cubre).
   - Reportar licencia y resultado de `npm audit` / `pip-audit` /
     equivalente.
   - Cruzar con `stack/constraints.md` (¿prohibida?) y
     `stack/security.md` (¿compatible con políticas?).
   - **Pedir OK explícito** del dev. NO instalar sin OK — una dep
     puede estar prohibida por licencia (AGPL/SSPL), vuln conocida
     sin parche, o policy empresarial. Ver AGENTS.md *Dependencias
     nuevas*.

5. **EXECUTE**: tests primero, código que pase tests (respetando
   `stack/constraints.md`), linter, typecheck, iterar hasta verde.

6. **UPDATE STATUS** — `status.md`: task → `done` o `deployed:<env>`
   con commit hash y fecha (§6 Lifecycle). Actualizar `state` si cambia.

7. **CLOSE** — reportar qué se hizo (task ID, R*.* cubiertos, commit
   hash), qué quedó pendiente, siguiente paso sugerido. Si la siguiente
   task podría avanzarse, **preguntar antes de continuar** — NO
   auto-avanzar (§3.16).
