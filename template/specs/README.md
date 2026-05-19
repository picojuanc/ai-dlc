# specs/

> Cada feature de este repo vive en `specs/<feature-slug>/` y sigue la
> estructura del methodology AI-DLC (§6).
>
> Crea una feature con `/spec-new <slug>` — el Service Agent genera la
> estructura completa con entrevista guiada.

## Estructura de una feature

```
specs/<feature-slug>/
├── requirements.md     ← EARS R1.1..R*.* + Dependencies + Tests
├── design.md           ← arquitectura, contratos, decisiones (DEC-N)
├── tasks.md            ← T1..TN (orden estricto)
├── status.md           ← state + lifecycle + commit hashes
├── bugs.md             ← BUG-NNN (taxonomía A/B/C/D/E)
├── amendments.md       ← AMD-NNN (cambios post-aprobación) + HANDOFF-NNN
├── rollout-plan.md     ← fases de despliegue (canary → 50% → 100%)
└── mocks/              ← mocks de servicios externos, opcional
```

## Convenciones obligatorias (§5 + §6 del methodology)

- Requirements **siempre** en formato EARS.
- Cada `R*.*` declara su nivel de test (`Tests: unit, integration` etc.).
- Cada test cita su requirement con `// Derived from R*.*`.
- Cada commit cita su `R*.*` y su work item ADO:
  `feat(scope): T<n> - <desc> [R<x>.<y>] AB#<wi-id>`.
- Tasks **no** se ejecutan fuera de orden; las bloqueadas se resuelven
  primero (o se justifican explícitamente).
- Cambios post-aprobación van por `/spec-amend`, NO por edición directa.

## Lifecycle

El campo `state:` en `status.md` puede ser:
`not-started → spec-approved → in-progress →
partial-deploy-pruebas → partial-deploy-qa → feature-complete →
deployed-prod → done` (con `cancelled` como rama lateral).

Ver §6 del methodology *Lifecycle de feature y task*.
