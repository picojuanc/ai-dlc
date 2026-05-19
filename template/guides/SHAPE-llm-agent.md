# SHAPE-llm-agent.md — Servicio LLM-powered como producto

**Aplica cuando**: el repo es un servicio que en runtime invoca un LLM (Claude, GPT, Gemini, modelo on-prem, etc.) para tomar decisiones, generar contenido, clasificar, o analizar. El LLM es **parte del producto**, no del proceso de desarrollo.

**No confundir con** los agentes del proceso AI-DLC (Architect Agent, Service Agent, consultive agents). Esos son herramientas del *cómo se construye*; este guide es para *qué se construye* cuando lo que construís usa un LLM.

## Marker

```yaml
description: |
  Servicio LLM-powered. Ver guides/SHAPE-llm-agent.md.
  Provider: <Claude | OpenAI | local | ...>
  Model: <claude-opus-4-7 | gpt-5 | ...>
```

## Preocupaciones específicas

### Prompt como asset versionable
- **Prompts viven en archivos versionados**, no hardcoded en código. Ej.: `prompts/pattern-detection/v3.md`.
- Cambios de prompt = cambios de comportamiento del sistema. Deben pasar por PR + eval + review.
- Frontmatter del prompt: `version`, `model`, `eval_baseline`, `last_updated`, `owner`.
- Anti-patrón: prompts inlineados como string literals en `.ts` / `.py` sin versionado.

### Model lock y plan de upgrade
- Documentar **qué modelo está en prod** y **por qué**.
- Plan de upgrade del modelo:
  1. Eval del modelo nuevo contra baseline (mismo set de inputs).
  2. Comparar outputs (objective metrics o human eval).
  3. Si pasa: feature flag / canary deploy (5% → 25% → 100%).
  4. Rollback plan si métricas se degradan.
- Anti-patrón: `gpt-4` → `gpt-5` el lunes porque salió, sin eval ni canary.

### Eval suite
- Set de inputs canónicos con outputs esperados (o criterios de evaluación).
- Tipos:
  - **Regression**: outputs que ya funcionaban deben seguir funcionando.
  - **Edge cases**: inputs raros que el sistema debe manejar.
  - **Failure modes**: inputs que deben rechazarse o caer en fallback.
- Corre en CI antes de mergear cambios de prompt o cambios de modelo.
- Anti-patrón: "lo probé manualmente con 3 ejemplos, anda" = no eval suite.

### Logging y observability
- **Loggear todos los outputs del LLM** (con `request_id`, prompt usado, model, timestamp).
- Razones: audit, debugging, ground truth para fine-tuning, detección de drift.
- Cuidado con **PII**: si el input al LLM tenía PII, el log también. Decidir retention + access policy.

### Fallback y resilience
- ¿Qué pasa si el LLM está caído?
- ¿Qué pasa si responde algo sin sentido (output malformado)?
- ¿Qué pasa si tarda > N segundos?
- Patrones comunes:
  - **Model fallback**: provider primario falla → secundario (otra cloud).
  - **Rule-based fallback**: LLM falla → respuesta determinística simple.
  - **Cached response**: para queries repetidas.
  - **Timeout estricto** + cancelación.

### Cost management
- LLMs consumen tokens. Tokens cuestan dinero.
- Tracking por request: tokens-in, tokens-out, cost.
- Presupuesto mensual + alertas al 50% / 80% / 100%.
- Optimizaciones: caching de respuestas, prompt compaction, modelo más chico para tareas simples.

### PII y data leakage
- **Qué datos NO pueden entrar al prompt** (DNI, credenciales, salud, etc.) — política explícita.
- Redaction antes de mandar al provider externo.
- Si usás provider externo (OpenAI/Anthropic), revisar contrato: ¿usan tus datos para training?

## Stack files típicos

`stack/llm.md` (crear si SHAPE aplica):
```markdown
# LLM Configuration

## Provider
<Anthropic | OpenAI | Azure OpenAI | local Ollama | ...>

## Model
- **Primary**: <model-id>
- **Fallback**: <model-id-secondary>
- **Last upgraded**: <YYYY-MM-DD>
- **Upgrade plan**: ver `eval/` + canary policy

## Prompts
- Repo path: `prompts/`
- Versioning: SemVer en frontmatter de cada prompt.
- Review process: PR con eval results before merge.

## Eval baseline
- Path: `eval/baseline.yaml`
- CI step: <name>

## PII / Data policy
- Allowed in prompt: <lista>
- Forbidden: <lista — DNI, credenciales, etc.>
- Redaction: <herramienta o regex>
```

`stack/security.md` adiciones:
- LLM logging retention
- PII redaction policy
- Provider data agreement (¿usan tus datos para training?)

## Anti-patrones críticos

| Anti-patrón | Síntoma | Mitigación |
|---|---|---|
| Prompt hardcoded en código | Cambiar comportamiento del agente requiere code change + deploy | Prompts en `prompts/<name>/vN.md`, cargados dinámicamente |
| Deploy de modelo nuevo sin eval | "gpt-5 acaba de salir, lo activamos" → outputs cambian, casos edge rompen | Eval contra baseline + canary deploy |
| Sin eval suite | "Funciona porque lo probé en chat" | Set canónico de inputs + outputs esperados en CI |
| Logging sin redaction de PII | Logs llenos de datos sensibles → riesgo compliance | Redaction antes de loggear |
| Sin fallback cuando el LLM falla | Provider tiene un outage → tu producto cae completo | Fallback explícito declarado en design |
| Cost sin tracking | Factura mensual sorpresa | Tracking por request + alertas |
| Modelo elegido sin medir | "Usamos GPT-5 porque es lo último" sin comparar con alternativas | Eval contra >1 modelo, elegir según métrica del producto |
