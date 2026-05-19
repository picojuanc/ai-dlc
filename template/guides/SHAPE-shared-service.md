# SHAPE-shared-service.md — Servicio transversal / compartido

**Aplica cuando**: el repo es un servicio que sirve a **>1 consumidor cross-team** o **>1 Initiative**. Ejemplos típicos: base de datos compartida, servicio de autenticación corporativo, agente LLM reusable, plataforma de notificaciones genérica.

**No aplica** si el servicio sirve solo a su propio equipo o a una sola Initiative — es un `service` normal.

> Este archivo es **guía**, no template. Leelo cuando estés definiendo el `stack/` y `repo-config.yaml` del repo. Lo que apliques se materializa en `stack/architecture.md` + `repo-config.yaml`.

## Marker

Marcar explícitamente en `repo-config.yaml`:

```yaml
description: |
  Servicio transversal — sirve a múltiples consumidores cross-team.
  Cambios breaking requieren coordinación con todos los stakeholders[].
```

## Preocupaciones específicas (preguntas que tu spec debe responder)

### Ownership y autoridad
- ¿Quién decide los breaking changes? (proveedor único, pero consumidores múltiples).
- ¿Quién aprueba el contrato? (proveedor decide; consumidores se enteran con anticipación, no votan).
- ¿Cómo se notifica un breaking change? (`.org/contracts/` con `deprecated_at` y `sunset_date`, mínimo 90 días).

### Contratos versionados desde día 1
- **Antes** de que aparezca el primer consumidor, publicar el contrato (`.org/contracts/apis/<name>.openapi.v1.0.0.yaml` o `events/<name>.v1.yaml`).
- SemVer estricto: minor = additive, major = breaking.
- Período de deprecación mínimo 90 días antes de sunset (§9 methodology).

### Capacity y SLO compartido
- Recurso compartido → contención garantizada. Definir SLO desde día 1:
  - p99 latencia
  - throughput máximo sostenido
  - disponibilidad target (99.9? 99.95?)
- Documentar en `stack/architecture.md > SLO`.

### Cross-cutting incidents
- Si el servicio cae, caen **todos** los consumidores.
- Definir **degraded mode**: ¿qué pasa cuando estás al 50% capacidad? ¿Cuando una downstream dependency falla?
- Plan de comunicación en incidentes: a quién avisar primero (oncall del proveedor → oncall de cada consumidor).

### Data ownership (si es servicio de datos)
- Qué tablas pueden escribir los consumidores vs sólo leer.
- Schema migration: ¿quién propone? ¿quién aprueba? ¿cómo se rolean?
- PII / compliance: clasificación de datos, residencia, retención.

## Configuración recomendada

`repo-config.yaml`:
```yaml
repo_type: service
description: |
  Servicio transversal — ver guides/SHAPE-shared-service.md
trackers:
  - name: <proveedor>
    type: azure-devops
    role: owner
    creation_mode: discover-first  # brownfield default
  - name: <consumidor-1>
    type: azure-devops
    role: stakeholder
  - name: <consumidor-2>
    type: azure-devops
    role: stakeholder
  # ... uno por equipo consumidor conocido
```

## Anti-patrones específicos

| Anti-patrón | Por qué | Mitigación |
|---|---|---|
| Evolucionar el schema sin avisar a consumidores | Producción de los consumidores rompe en runtime, sin warning | Contrato versionado + deprecation period 90 días + notificación a `stakeholders[]` |
| Cambio breaking en minor version | Consumidores pinearon en SemVer y no anticipan la ruptura | SemVer estricto: minor = additive only. Breaking = major bump |
| "Es mi servicio, yo decido" sin consultar | Aunque el proveedor decide, ignorar feedback de consumidores erosiona la relación cross-team | Proveedor decide PERO consume input. Stakeholders[] tienen voz |
| SLO definido a posteriori | Incidente con SLA cliente roto → fuga de credibilidad | SLO publicado en `architecture.md` desde día 1, antes del primer consumidor |
| Sin degraded mode definido | Caída total cuando podría haber sido parcial | `stack/architecture.md > Degraded mode` declara qué funciona al 50%, 10%, 0% |
