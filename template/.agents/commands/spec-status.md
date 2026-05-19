---
name: spec-status
description: Resumen legible del estado de la feature (read-only)
---

# `/spec-status <feature-slug>` — Resumen legible del estado (read-only)

Para feature `<feature-slug>`, leer (sin modificar nada):

- `requirements.md` → contar `R*.*` totales, agrupar por estado.
- `tasks.md` + `status.md` → done / in-progress / pending / blocked
  (con causa).
- `bugs.md` → bugs abiertos por tipo (A/B/C/D/E).
- (si existe) `amendments.md` → últimos `AMD-NNN` y `HANDOFF-NNN`.
- Sección `Dependencies` de `requirements.md` → `D-N` y su estado (§6).
- Última ejecución de tests por nivel con cuántos `R*.*` cubre cada
  nivel.

Producir un resumen humano con: progreso global de `R*.*`, tasks
completadas vs pendientes vs bloqueadas y causa, cobertura de tests
**por nivel** (no sólo global), bugs abiertos con tipo, amendments
recientes, y **siguiente paso sugerido**.

Pensado para retomar trabajo tras una pausa (límite de tokens, fin de
jornada, handoff). **NO escribe nada**.
