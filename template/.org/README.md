# .org/ — catálogo organizacional

> Esta carpeta es **opcional** (§9 del methodology). Sólo tiene sentido
> si este repo coordina con otros repos del mismo equipo o team project
> y necesita publicar contratos / políticas / ADRs compartidos.
>
> Si tu repo es self-contained (no expone contratos hacia afuera),
> puedes **borrar esta carpeta** sin perder funcionalidad.

## Contenido típico

```
.org/
├── contracts/          ← OBLIGATORIO cuando hay dependencias cross-repo (§9)
│   ├── <service>-v1.openapi.yaml
│   └── <event>-v1.asyncapi.yaml
├── catalog.yaml        ← opcional: inventario de servicios
├── policies/           ← opcional: políticas org (PII, auth standards)
├── decisions/          ← opcional: ADRs cross-repo
└── templates/          ← opcional: templates compartidos de specs / agents
```

## Cuándo publicar un contrato aquí

Cualquier `D-N` cross-team que llegue a estado `AGREED` (§6 del
methodology) debe tener su contrato versionado en `.org/contracts/`. Es
el único requisito **obligatorio** del catálogo.

## Si trabajas en una org real

Lo normal es que `.org/` sea un repo separado (`<org>-platform/`) y este
repo lo consuma como submódulo, paquete o vía registry. La carpeta
local sirve para arrancar — luego se migra al repo central cuando haya
más de un servicio que la consuma.
