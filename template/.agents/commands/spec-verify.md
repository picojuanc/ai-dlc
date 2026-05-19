---
name: spec-verify
description: Auditar cobertura R*.* ↔ tests, gaps y drift (read-only)
---

# `/spec-verify <feature-slug>` — Auditar cobertura R*.* ↔ tests (read-only)

Sigue el protocolo §7 (AGENTS.md). Para feature `<feature-slug>`:

1. **CONTEXT** — leer `requirements.md`, `tasks.md`, `status.md`,
   `mocks/`, `tests/` del repo.

2. **CHECKS** — reportar (no escribir):
   - `R*.*` sin `Tests:` declarado (§5 regla 6 del methodology).
   - `R*.*` con `Tests:` declarado pero **niveles no cubiertos**.
   - Tests con `// Derived from R*.*` cuyo `R*.*` ya no existe en
     `requirements.md` (tests huérfanos por Amendment).
   - Tasks `done` sin commit hash en `status.md`.
   - `D-N` en `NEGOTIATING` con > 10 días desde el draft (§6 SLAs).
   - `D-N` en `AGREED` con > 6 semanas sin pasar a `IMPLEMENTED`.
   - Tasks `blocked` > 4 semanas sin decisión `BLOCK`/`WORKAROUND`/
     `cancel` (§6 SLAs).
   - Mocks sin `Ready to unmock` o sin owner declarado.
   - Drift entre `state:` declarado y derivación del Lifecycle (§6).
   - `OPEN_QUESTIONS` sin owner o sin `due` (§5 regla 7); o vencidos.
   - Feature con `feature_flag.main == ON` > 90 días al 100% sin task
     de limpieza propuesta (§6 *Limpieza de feature flags*).
   - **Ajuste por modalidad** (§6): si `modality: catalog-only`,
     omitir checks de `design.md` y `tasks.md`; si `docs-only`, omitir
     checks de tests; etc.
   - **Stack drift**: si algún archivo viola convenciones de
     `stack/patterns.md` o reglas de `stack/constraints.md`, reportar.

3. **CLOSE** — lista de gaps por categoría, sugerencia de fix concreta
   para cada uno. Si todo verde: confirmar que la feature cumple
   condiciones de promoción y sugerir `/spec-promote`.
