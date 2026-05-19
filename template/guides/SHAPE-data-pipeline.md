# SHAPE-data-pipeline.md — Ingestion / data pipeline

**Aplica cuando**: el repo mueve datos de una fuente externa a un destino, continuamente o en batches. Ejemplos: ingesta de logs de servidor a DB, ETL nightly, stream processing, sync de un sistema legacy.

**No confundir con** modalidad `data-migration` (one-shot, ver §6 methodology). Esto es **continuo o recurrente**.

## Marker

```yaml
description: |
  Data pipeline — ver guides/SHAPE-data-pipeline.md.
  Source(s): <lista>
  Destination: <DB / event bus / archivo>
  Frequency: <continuous | batch-hourly | nightly | on-demand>
```

## Preocupaciones específicas

### Idempotencia (la regla #1)
- Una ejecución repetida **NO debe duplicar registros**.
- Mecanismo: `idempotency_key` por registro (típicamente: hash del source + timestamp, o ID natural de la fuente).
- El destino verifica antes de insertar: "¿ya tengo este key?" → skip o upsert.
- Anti-patrón: pipeline que al reintentar duplica todo.

### Backfill plan
- Si hay bug → ¿cómo se reprocesan los datos viejos?
- Si hay cambio de schema → ¿cómo se re-migra histórico?
- Escenarios típicos:
  - **Replay**: re-leer desde el source con la misma lógica corregida (requiere que el source guarde history).
  - **Reconciliation job**: comparar source vs destination, detectar diferencias, corregir.
  - **Manual backfill script**: one-shot acotado, documentado.
- Documentar el plan **antes** de necesitarlo.

### Ordering y delivery guarantees
- Garantía que tu pipeline ofrece:
  - **At-least-once**: cada registro se entrega ≥1 vez. Combinado con idempotencia = OK.
  - **At-most-once**: cada registro ≤1 vez. Puede haber pérdidas. NO usar sin justificación fuerte.
  - **Exactly-once**: ≥1 vez = 1 vez. Caro de garantizar, requiere coordinación distribuida.
- **Order**: FIFO global, FIFO por partition key, o sin garantía.
- Anti-patrón: asumir exactly-once sin tener mecanismo. Casi siempre es at-least-once + idempotency.

### Schema drift detection
- La fuente puede cambiar el formato **sin avisar** (caso típico: logs de un sistema legacy).
- Detección:
  - Validar schema en cada batch (JSON Schema, Avro, etc.).
  - Si schema cambió: **alarma**, NO silenciosamente ignorar campos nuevos o fallar.
- Política de respuesta:
  - **Strict mode**: schema mismatch → pause pipeline + notificar oncall.
  - **Permissive mode**: ignorar campos desconocidos, loggear warning. Útil para sources que evolucionan rápido pero no críticos.

### Dead letter queue (DLQ)
- Registros que fallan repetidamente (retry exhausted) van a un sink separado.
- Inspección manual para detectar:
  - Bugs del pipeline
  - Datos corruptos del source
  - Edge cases no manejados
- DLQ tiene retention (no es persistente eterno) y monitoring (alertar si crece mucho).

### Monitoring crítico
- **Throughput**: registros / segundo.
- **Lag**: cuán atrás está el pipeline vs el source (importante para streaming).
- **Error rate**: % de registros fallidos.
- **DLQ size**: registros pendientes de inspección.
- **Source availability**: ¿está la fuente respondiendo?

### External schema como dependencia
- La tabla / API / event schema de la fuente externa es una **External Dependency** D-N (§6 methodology) tipo schema.
- Estado: `NEGOTIATING` si no está estable → `AGREED` cuando el owner del source publica/confirma el contrato.
- Mock para tests: snapshot del schema + datos sintéticos.

## Stack files típicos

`stack/pipeline.md` (crear si SHAPE aplica):
```markdown
# Pipeline Configuration

## Sources
- **Source A**: <descripción>
  - Location: <URL / DB / event bus>
  - Schema: <ref a contrato>
  - Frequency: <pull-cron | push-webhook | stream>
  - Owner: <equipo / vendor>

## Destination
- Type: <DB | event bus | file>
- Schema: <ref>
- Idempotency key: <field name>

## Frequency
- <continuous | batch-hourly | nightly | on-demand>
- Cron expression: `<expr>` (si batch)

## Delivery guarantees
- Mode: at-least-once (with idempotency at destination)
- Order: <FIFO global | FIFO por <key> | unordered>

## Backfill strategy
- Mechanism: <replay | reconciliation job | manual script>
- Replay window: <N días / N records>

## Dead letter queue
- Location: <path / table>
- Retention: <N días>
- Alert threshold: > <N> records pending review

## Schema drift policy
- Mode: <strict | permissive>
- Validator: <tool>

## Monitoring
- Throughput dashboard: <link>
- Lag alert: > <N> minutes
- Error rate alert: > <N>%
```

## Anti-patrones críticos

| Anti-patrón | Síntoma | Mitigación |
|---|---|---|
| Pipeline sin idempotency key | Al reintentar se duplican registros | `idempotency_key` declarado en `pipeline.md` + check en destination |
| Asumir exactly-once sin mecanismo | Pérdidas o duplicados aparecen en prod | At-least-once + idempotency es la combinación realista |
| Schema changes sin detección | Drift sale como bug fantasma semanas después | Schema validation en cada batch + alarma en mismatch |
| Sin DLQ — errores se silencian | "El pipeline anda" pero falla 5% de registros | DLQ explícito + alerta de threshold |
| Sin backfill plan documentado | Bug fix se vuelve incidente de 3 días | Backfill plan en `pipeline.md` ANTES de necesitarlo |
| Monitoring sólo de "alive/dead" | Pipeline alive pero lag de 6 horas → datos viejos en producto | Métricas de throughput + lag + error rate + DLQ size |
| External schema sin D-N | "La fuente cambió el formato, no nos avisaron" | Schema = D-N tipo técnica con owner declarado |
