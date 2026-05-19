# Comando: figma-make-integration

Integra código generado por Figma Make al proyecto Neo Estampillas.

---

## Uso

```bash
# Formato básico
[Describe la ruta del ZIP o carpeta de Figma Make]

# Ejemplo
Tengo una carpeta en C:\Users\orivera\Downloads\consulta-recibos que contiene
código generado por Figma Make para gestión de estampillas.
```

---

## Principios de Integración

### 1. NO ASUMIR NADA — Preguntar con Opciones

En CADA fase, si hay ambigüedad o múltiples opciones posibles:
- **Detenerse y preguntar al usuario** antes de tomar decisiones
- **Ofrecer opciones concretas** (A, B, C...) con breve explicación de cada una
- **Siempre incluir** la opción "Otra solución diferente" para que el usuario proponga alternativas
- **Esperar la decisión** del usuario antes de continuar. No elegir por cuenta propia.

Aplica a: ubicación de archivos, rutas, migración de mocks, generación de backend, resolución de conflictos, cualquier duda técnica.

### 2. RE-INTEGRACIÓN SEGURA (ZIP regenerado)

Si el feature ya fue integrado previamente y se recibe un nuevo ZIP con cambios:
- **NO destruir** código que ya existe en el proyecto y funciona
- **Detectar archivos que ya existen** y preguntar al usuario qué hacer (sobrescribir, mantener, fusionar)
- **Preservar** cualquier migración ya realizada (ej: si un repositorio mock ya fue migrado a apiClient, no revertirlo con el mock del ZIP nuevo)
- **Preservar** registros existentes en DI Container, RoutesConfig, barrel exports
- **Los cambios deben ser ADITIVOS**: agregar lo nuevo sin romper lo existente

### 3. DISCIPLINA DE DEPENDENCIAS

- Si el ZIP trae dependencias no aprobadas: **preguntar al usuario** antes de instalar
- **Nunca instalar automáticamente**. Solo validar, avisar y esperar confirmación
- Si una librería nueva aparece en el ZIP, explicar qué hace y preguntar si se acepta

---

## Descripción

Este comando integra de manera sistemática el código generado por Figma Make al proyecto Neo Estampillas, siguiendo estos pasos:

1. **Validación inicial**: Verifica estructura y dependencias
2. **Verificación del proyecto**: Compara dependencias necesarias vs instaladas
3. **Análisis de integración**: Identifica tareas mediante comentarios TODO
4. **Integración frontend**: Copia archivos, actualiza rutas y tipos
5. **Migración de repositorios**: Conecta repositorios mock al apiClient real
6. **Registro en DI Container**: Agrega nuevos repos/use-cases al container existente
7. **Análisis de backend**: Procesa especificaciones de API
8. **Generación de backend**: Opcionalmente crea estructura Clean Architecture + CQRS
9. **Validación**: Compila frontend y backend
10. **Reportes**: Genera documentación de integración
11. **Limpieza**: Elimina archivos temporales

---

## Proceso Detallado

### Fase 1: Validación Inicial

#### 1.1. Verificación de Ruta

Cuando proporciones la ruta, el comando:

- Valida que el archivo/carpeta exista
- Detecta si es ZIP o carpeta extraída
- Si es ZIP, lo extrae a ubicación temporal

**Estructura esperada** (Clean Architecture):
```
[feature]/
├── src/
│   ├── domain/
│   │   ├── entities/           # *.entity.ts + index.ts
│   │   ├── interfaces/
│   │   │   └── repositories/   # I*Repository.ts + index.ts
│   │   └── use-cases/          # *UseCase.ts + index.ts
│   ├── infrastructure/
│   │   ├── http/               # apiClient.ts
│   │   ├── dto/                # *DTO.ts + index.ts
│   │   ├── mappers/            # *Mapper.ts + index.ts
│   │   ├── repositories/       # *RepositoryImpl.ts + index.ts
│   │   └── di/                 # container.ts
│   ├── application/
│   │   └── state/              # use*Store.ts
│   ├── presentation/
│   │   ├── components/         # common/, domain/, forms/, layout/
│   │   ├── hooks/
│   │   ├── pages/              # public/, private/
│   │   └── styles/
│   ├── shared/
│   │   ├── constants/
│   │   ├── types/
│   │   └── utils/
│   ├── App.tsx                 # ⚠️ IGNORAR - Solo para pruebas diseño
│   └── main.tsx                # ⚠️ IGNORAR - Solo para pruebas diseño
├── index.html                   # ⚠️ IGNORAR - Solo para pruebas diseño
├── package.json
├── API_SPECS.md                 # ✅ REQUERIDO
├── FIGMA_MAKE_CONTEXT.md        # ✅ Contexto para futuras sesiones
└── README.md
```

**Archivos que se ignorarán durante integración**:
- `src/App.tsx` - Routing temporal (el proyecto tiene RoutesConfig.tsx)
- `src/main.tsx` - Entry point temporal (el proyecto tiene su main.tsx)
- `index.html` - HTML temporal (el proyecto tiene su index.html)
- `src/infrastructure/http/apiClient.ts` - El proyecto ya tiene su apiClient
- `src/infrastructure/di/container.ts` - Se fusionará con el container existente
- `src/shared/utils/logger.ts` - El proyecto ya tiene su logger
- `src/presentation/styles/index.css` - Se revisará manualmente (Tailwind imports)
- `vite.config.ts`, `tsconfig*.json`, `eslint.config.js` - Configuración del proyecto
- `package.json` - Solo se verifican dependencias

#### 1.2. Validación de Dependencias

El comando analiza `package.json` y verifica:

✅ **Dependencias Permitidas** (solo públicas en npm):
- react, react-dom, react-router-dom
- primereact, primeicons
- tailwindcss, @tailwindcss/vite, tw-animate-css
- zustand, immer
- motion
- html2canvas, jspdf, xlsx (opcionales)

⚠️ **Dependencias que NO deben estar** (son privadas del proyecto):
- @syc/edesk-web-client (framework custom, ya instalado en el proyecto)
- @syc/edesk-components (componentes custom, ya instalado)

❌ **Dependencias Prohibidas**:
- axios, ky, superagent
- moment, date-fns, dayjs
- lodash, underscore, ramda
- @mui/material, antd, chakra-ui
- redux, mobx, recoil

**Si encuentra prohibidas**, te preguntará:
```
⚠️  ADVERTENCIA: Dependencias prohibidas encontradas:
  • axios → usar fetch nativo (apiClient.ts del proyecto)
  • moment → usar Intl.DateTimeFormat

¿Deseas continuar? [Y/n]
```

#### 1.3. Validación de Convenciones de Nombres

Verifica que los archivos sigan las convenciones del proyecto:

```bash
# Entidades
domain/entities/*.entity.ts     # ✅ Correcto
domain/entities/*Entity.ts      # ⚠️ Renombrar a *.entity.ts

# Repositorios
infrastructure/repositories/*RepositoryImpl.ts  # ✅ Correcto
infrastructure/repositories/*Repository.ts      # ⚠️ Renombrar a *RepositoryImpl.ts

# DTOs
infrastructure/dto/*DTO.ts      # ✅ Correcto
application/dto/*Dto.ts         # ⚠️ Mover a infrastructure/dto/

# Barrel exports
*/index.ts                      # ✅ Debe existir en cada carpeta
```

#### 1.4. Validación de Comentarios TODO

Busca comentarios de integración:
```bash
TODO-INTEGRATION  # Repositorios mock a migrar, rutas a agregar
```

---

### Fase 2: Verificación de Dependencias del Proyecto

#### 2.1. Análisis de package.json de estampillas.client

Compara dependencias necesarias vs instaladas:

```
📦 Verificando dependencias de Neo Estampillas...

✅ Ya instaladas:
  react: ^19.1.1
  react-dom: ^19.1.1
  react-router-dom: ^7.12.0
  @syc/edesk-web-client: ^1.0.0
  @syc/edesk-components: ^1.0.0
  primereact: ^10.9.7
  primeicons: ^7.0.0
  tailwindcss: ^4.1.18
  @tailwindcss/vite: ^4.1.18
  tw-animate-css: ^1.4.0
  zustand: ^5.0.8
  immer: ^11.1.3
  motion: ^12.27.1

Dependencias adicionales necesarias (si las hay):
  html2canvas: ^1.4.1 ........... ❌ NO INSTALADA
  jspdf: ^3.0.4 ................. ❌ NO INSTALADA

Para instalar las faltantes:
  cd estampillas.client
  npm install html2canvas@^1.4.1 jspdf@^3.0.4
```

**IMPORTANTE**: El comando NO instala automáticamente. Solo valida y avisa.

---

### Fase 3: Análisis de Integración

#### 3.1. Analizar Comentarios TODO

Lista todas las tareas identificadas:

```
📋 Tareas de integración identificadas:

TODO-INTEGRATION (rutas):
  ✓ presentation/pages/public/EstampillasPage.tsx
    → Agregar ruta en RoutesConfig.tsx: 'estampillas' → <EstampillasPage />

TODO-INTEGRATION (repositorios):
  ✓ infrastructure/repositories/EstampillaRepositoryImpl.ts
    → Migrar datos mock a apiClient (usar patrón de EntidadRepositoryImpl existente)

DI Container:
  ✓ Registrar EstampillaRepositoryImpl en infrastructure/di/container.ts
  ✓ Registrar GetEstampillasUseCase en infrastructure/di/container.ts
```

#### 3.2. Verificar Conflictos de Archivos

Detecta archivos que ya existen:

```
⚠️  Conflictos detectados:

  shared/utils/logger.ts ........... YA EXISTE (usar existente)
  shared/utils/formatters.ts ....... YA EXISTE (fusionar si hay nuevas funciones)

Para cada archivo en conflicto, selecciona:
  [O] Overwrite  - Sobrescribir con el nuevo
  [K] Keep       - Mantener el existente
  [M] Merge      - Intentar fusionar
  [R] Rename     - Renombrar el nuevo
  [A] Abort      - Cancelar integración
```

---

### Fase 4: Copiar Archivos

#### 4.1. Filtrar Archivos Temporales

Antes de copiar, el comando automáticamente filtra:

```
🗑️  Ignorando archivos temporales (solo para pruebas de diseño):

✗ src/App.tsx (routing temporal con react-router-dom)
✗ src/main.tsx (entry point temporal)
✗ index.html (HTML temporal)
✗ src/infrastructure/http/apiClient.ts (el proyecto ya tiene uno)
✗ src/infrastructure/di/container.ts (se fusionará con el existente)
✗ src/shared/utils/logger.ts (el proyecto ya tiene uno)
✗ Archivos de configuración (vite, tsconfig, eslint, package.json)
```

#### 4.2. Mapeo de Archivos (Clean Architecture)

El comando mapea la estructura del ZIP a la estructura del proyecto:

```
ZIP de Figma Make                          →  Neo Estampillas
─────────────────────────────────────────────────────────────────
src/domain/entities/                       →  estampillas.client/src/domain/entities/
src/domain/interfaces/repositories/        →  estampillas.client/src/domain/interfaces/repositories/
src/domain/interfaces/services/            →  estampillas.client/src/domain/interfaces/services/
src/domain/use-cases/                      →  estampillas.client/src/domain/use-cases/
src/domain/validators/                     →  estampillas.client/src/domain/validators/

src/infrastructure/dto/                    →  estampillas.client/src/infrastructure/dto/
src/infrastructure/mappers/                →  estampillas.client/src/infrastructure/mappers/
src/infrastructure/repositories/           →  estampillas.client/src/infrastructure/repositories/

src/application/state/                     →  estampillas.client/src/application/state/
src/application/state/initial-values/      →  estampillas.client/src/application/state/initial-values/
src/application/builders/                  →  estampillas.client/src/application/builders/
src/application/validation/                →  estampillas.client/src/application/validation/
src/application/selectors/                 →  estampillas.client/src/application/selectors/

src/presentation/components/common/        →  estampillas.client/src/presentation/components/common/
src/presentation/components/domain/        →  estampillas.client/src/presentation/components/domain/
src/presentation/components/forms/         →  estampillas.client/src/presentation/components/forms/
src/presentation/components/layout/        →  estampillas.client/src/presentation/components/layout/
src/presentation/hooks/                    →  estampillas.client/src/presentation/hooks/
src/presentation/pages/public/             →  estampillas.client/src/presentation/pages/public/
src/presentation/pages/private/            →  estampillas.client/src/presentation/pages/private/
src/presentation/styles/*.css              →  estampillas.client/src/presentation/styles/ (solo custom-prime.css y theme.css adicionales)

src/shared/constants/                      →  estampillas.client/src/shared/constants/
src/shared/types/                          →  estampillas.client/src/shared/types/
src/shared/utils/validators.ts             →  Fusionar con existente
src/shared/utils/formatters.ts             →  Fusionar con existente
```

**Ejemplo de salida**:
```
📁 Copiando archivos a estampillas.client/src/...

Domain Layer:
✓ domain/entities/Estampilla.entity.ts
✓ domain/entities/index.ts (fusionado con existente)
✓ domain/interfaces/repositories/IEstampillaRepository.ts
✓ domain/interfaces/repositories/index.ts (fusionado)
✓ domain/use-cases/GetEstampillasUseCase.ts
✓ domain/use-cases/index.ts (fusionado)

Infrastructure Layer:
✓ infrastructure/dto/EstampillaDTO.ts
✓ infrastructure/dto/index.ts (fusionado)
✓ infrastructure/mappers/EstampillaMapper.ts
✓ infrastructure/mappers/index.ts (fusionado)
✓ infrastructure/repositories/EstampillaRepositoryImpl.ts
✓ infrastructure/repositories/index.ts (fusionado)

Application Layer:
✓ application/state/useEstampillaStore.ts

Presentation Layer:
✓ presentation/components/common/EstampillaCard.tsx
✓ presentation/components/forms/EstampillaForm.tsx
✓ presentation/hooks/useEstampillas.ts
✓ presentation/pages/public/EstampillasPage.tsx

Shared Layer:
✓ shared/constants/estampilla.constants.ts
✓ shared/types/estampilla.types.ts

20 archivos copiados siguiendo Clean Architecture.
```

#### 4.3. Fusionar Barrel Exports (index.ts)

El proyecto ya tiene barrel exports existentes. Se deben FUSIONAR, no sobrescribir:

```typescript
// domain/entities/index.ts - ANTES
export { EntidadEntity } from './Entidad.entity';
export { TramiteEntity } from './Tramite.entity';

// domain/entities/index.ts - DESPUÉS (fusionado)
export { EntidadEntity } from './Entidad.entity';
export { TramiteEntity } from './Tramite.entity';
// ✨ AGREGADO AUTOMÁTICAMENTE
export { EstampillaEntity } from './Estampilla.entity';
```

---

### Fase 5: Integración de Rutas

#### 5.1. Actualizar RoutesConfig.tsx

El proyecto usa `@syc/edesk-web-client` con `EdeskPublicRoute` y `AppBootstrap`:

```typescript
// estampillas.client/src/RoutesConfig.tsx

import { EdeskPublicRoute } from "@syc/edesk-web-client";
import type { RouteObject } from "react-router-dom";
import { AppBootstrap } from "./presentation/components/bootstrap/AppBootstrap";
import { EstampillasPage } from "./presentation/pages/EstampillasPage";
// ✨ AGREGADO AUTOMÁTICAMENTE
import { NuevoFeaturePage } from "./presentation/pages/public/NuevoFeaturePage";

export const RoutesConfig: RouteObject[] = [{
    element: <EdeskPublicRoute />,
    children: [{
        element: <AppBootstrap><EstampillasPage /></AppBootstrap>,
        path: '/'
    },
    // ✨ AGREGADO AUTOMÁTICAMENTE
    {
        element: <AppBootstrap><NuevoFeaturePage /></AppBootstrap>,
        path: 'nuevo-feature'
    }]
}];
```

#### 5.2. Preguntar Tipo de Ruta

```
¿Dónde agregar estas rutas?

  [1] Rutas públicas (EdeskPublicRoute)
      Sin autenticación requerida

  [2] Rutas protegidas
      Requiere autenticación

Selección: [1-2]
```

---

### Fase 6: Migración de Repositorios (Mock → HTTP Real)

#### 6.1. Detectar Estado de Repositorios

⚠️ **RE-INTEGRACIÓN**: Si un repositorio ya fue migrado a apiClient en una integración anterior,
NO revertirlo con la versión mock del ZIP nuevo. Preguntar al usuario qué hacer.

```
📊 Analizando repositorios...

Repositorios con DATOS MOCK detectados (nuevos):
  ✓ infrastructure/repositories/EstampillaRepositoryImpl.ts
    - Usa: const MOCK_DATA = [...]

Repositorios YA MIGRADOS (no sobrescribir):
  ✓ infrastructure/repositories/EntidadRepositoryImpl.ts → ya usa apiClient
```

#### 6.2. Migrar Repositorios

El proyecto ya tiene `apiClient.ts` en `infrastructure/http/`. La migración consiste en:

1. Reemplazar MOCK_DATA por llamadas a `apiClient`
2. Agregar mappers (DTO → Entity)
3. Considerar encriptación de IDs (usando crypto utils del proyecto)

**Patrón de referencia** (EntidadRepositoryImpl.ts existente):
```typescript
// infrastructure/repositories/EstampillaRepositoryImpl.ts - MIGRADO
import type { IEstampillaRepository } from '@/domain/interfaces/repositories/IEstampillaRepository';
import type { EstampillaEntity } from '@/domain/entities/Estampilla.entity';
import { EstampillaMapper } from '@/infrastructure/mappers/EstampillaMapper';
import { apiClient } from '@/infrastructure/http/apiClient';
import type { EstampillaDTO } from '@/infrastructure/dto/EstampillaDTO';

export class EstampillaRepositoryImpl implements IEstampillaRepository {
  async getAll(): Promise<EstampillaEntity[]> {
    const dtos = await apiClient.get<EstampillaDTO[]>('/estampillas');
    return EstampillaMapper.toDomainList(dtos);
  }

  async getById(id: string): Promise<EstampillaEntity | null> {
    const dto = await apiClient.get<EstampillaDTO>(`/estampillas/${encodeURIComponent(id)}`);
    if (!dto) return null;
    return EstampillaMapper.toDomain(dto);
  }
}
```

**Opciones para migración**:
```
¿Migrar repositorios ahora?

  [1] Migrar a apiClient (recomendado si el backend ya existe)
      • Elimina datos mock
      • Usa apiClient.get/post/patch/delete
      • Agrega mappers

  [2] Dejar datos mock temporalmente
      • Mantener comentarios TODO-INTEGRATION
      • Migrar cuando el backend esté listo
      • El frontend sigue funcionando con mocks

Selección: [1-2]
```

---

### Fase 7: Registro en DI Container

#### 7.1. Actualizar container.ts existente

Agregar nuevos repositorios y use cases al DI container del proyecto:

```typescript
// infrastructure/di/container.ts - ACTUALIZADO

// ✨ AGREGADO: Nuevos imports
import { EstampillaRepositoryImpl } from '@/infrastructure/repositories';
import {
  GetEstampillasUseCase as GetEstampillasUseCaseClass,
} from '@/domain/use-cases';

class DIContainer {
  // ... repositorios existentes ...

  // ✨ AGREGADO
  private _estampillaRepository?: EstampillaRepositoryImpl;
  private _getEstampillasUseCase?: GetEstampillasUseCaseClass;

  // ✨ AGREGADO
  get estampillaRepository(): EstampillaRepositoryImpl {
    if (!this._estampillaRepository) {
      this._estampillaRepository = new EstampillaRepositoryImpl();
    }
    return this._estampillaRepository;
  }

  get getEstampillasUseCase(): GetEstampillasUseCaseClass {
    if (!this._getEstampillasUseCase) {
      this._getEstampillasUseCase = new GetEstampillasUseCaseClass(
        this.estampillaRepository
      );
    }
    return this._getEstampillasUseCase;
  }

  reset(): void {
    // ... resets existentes ...
    // ✨ AGREGADO
    this._estampillaRepository = undefined;
    this._getEstampillasUseCase = undefined;
  }
}
```

---

### Fase 8: Análisis de Backend (TODO-INTEGRATION + API_SPECS.md)

#### 8.1. Extraer Metadata de los TODO-INTEGRATION

Los repositorios mock generados por Figma Make incluyen comentarios TODO-INTEGRATION
con metadata estructurada (HTTP method, ruta, Response, Backend Query/Command, Controller).

Extraer esta metadata para generar el backend automáticamente:

```
📄 Analizando TODO-INTEGRATION en repositorios mock...

Metadata extraída de EstampillaRepositoryImpl.ts:
  • getAll   → GET  /api/estampillas  → Query GetAllEstampillasQuery
  • getById  → GET  /api/estampillas/{id} → Query GetEstampillaByIdQuery
  • create   → POST /api/estampillas → Command CreateEstampillaCommand
  • update   → PATCH /api/estampillas/{id} → Command UpdateEstampillaCommand
  • delete   → DELETE /api/estampillas/{id} → Command DeleteEstampillaCommand

📄 Verificando API_SPECS.md para validaciones y reglas adicionales...
  • Validaciones: nombre requerido, max 100 chars
  • DTOs: EstampillaDto con campos id, nombre, estado, fechaCreacion

Patrón del proyecto (Clean Architecture + CQRS):
  • Controllers heredan de BaseApiController
  • Usan ISessionCryptoService para encriptar/desencriptar
  • Commands/Queries con MediatR → Result<T>
  • Repositorios con Dapper + Stored Procedures
  • Registro en Program.cs (AddScoped)
```

#### 8.2. Opciones de Implementación Backend

```
¿Implementar backend ahora?

  [1] Generar estructura completa
      • Domain/Entities/Estampilla.cs
      • Domain/Interfaces/IEstampillaRepository.cs
      • Application/Features/Estampillas/Commands/
      • Application/Features/Estampillas/Queries/
      • Application/Common/Models/EstampillaDtos.cs
      • Infrastructure/Persistence/Repositories/EstampillaRepository.cs
      • Presentation/Controllers/EstampillasController.cs
      • Registro en Program.cs

  [2] Solo crear placeholders con TODOs

  [3] Guardar specs para después
      • Copiar API_SPECS.md a docs/

Selección: [1-3]
```

**Si seleccionas [1]** - Genera siguiendo los patrones EXACTOS del proyecto:

```
🏗️  Generando backend (Clean Architecture + CQRS)...

Patrones detectados del proyecto existente:
  • Namespace: estampillas.server.[Layer].[...]
  • Entities: private constructor + static Create() factory
  • Interfaces: Task<T> con CancellationToken
  • Commands: record types con IRequest<Result<T>>
  • Handlers: try/catch con ILogger + Result.Failure()
  • Controllers: BaseApiController + ISessionCryptoService
  • Controllers: HandleEncryptedResult con proyección anónima
  • Repositories: mock data (TODO para Dapper + SPs)
  • DTOs: clases con propiedades auto-get/set
  • Result<T>: ya existe en Application/Common/Models/

Domain Layer:
  ✓ Domain/Entities/Estampilla.cs
  ✓ Domain/Interfaces/IEstampillaRepository.cs

Application Layer:
  ✓ Application/Common/Models/EstampillaDtos.cs
  ✓ Application/Features/Estampillas/Queries/GetEstampillas/GetEstampillasQuery.cs
  ✓ Application/Features/Estampillas/Queries/GetEstampillas/GetEstampillasQueryHandler.cs
  ✓ Application/Features/Estampillas/Queries/GetEstampillaById/GetEstampillaByIdQuery.cs
  ✓ Application/Features/Estampillas/Queries/GetEstampillaById/GetEstampillaByIdQueryHandler.cs

Infrastructure Layer:
  ✓ Infrastructure/Persistence/Repositories/EstampillaRepository.cs

Presentation Layer:
  ✓ Presentation/Controllers/EstampillasController.cs

Program.cs:
  ✓ Agregado: .AddScoped<IEstampillaRepository, EstampillaRepository>()

⚠️  Tareas pendientes:
  1. Implementar stored procedures en PostgreSQL
  2. Reemplazar mock data en Repository por Dapper + SPs
  3. Agregar FluentValidation validators si se necesitan
```

---

### Fase 9: Pruebas y Validación

#### 9.1. Compilación Frontend

```bash
cd estampillas.client
npm run build
```

```
🔨 Compilando TypeScript (tsc -b && vite build)...

✓ Sin errores de tipos
✓ Build exitoso
```

#### 9.2. Compilación Backend (si se generó)

```bash
cd estampillas.server
dotnet build
```

```
🔨 Compilando .NET...

✓ Sin errores de compilación
✓ Build exitoso
```

---

### Fase 10: Reportes

#### 10.1. Generar Reporte de Integración

Se crea `INTEGRATION_REPORT.md`:

```markdown
# Reporte de Integración: [Nombre del Feature]

**Fecha**: [fecha]
**Origen**: [ruta del ZIP]

## Archivos Integrados

### Frontend (estampillas.client/src/)

**Domain**:
- domain/entities/Estampilla.entity.ts
- domain/interfaces/repositories/IEstampillaRepository.ts
- domain/use-cases/GetEstampillasUseCase.ts

**Infrastructure**:
- infrastructure/dto/EstampillaDTO.ts
- infrastructure/mappers/EstampillaMapper.ts
- infrastructure/repositories/EstampillaRepositoryImpl.ts

**Application**:
- application/state/useEstampillaStore.ts

**Presentation**:
- presentation/components/common/EstampillaCard.tsx
- presentation/hooks/useEstampillas.ts
- presentation/pages/public/EstampillasPage.tsx

**Shared**:
- shared/types/estampilla.types.ts

### Backend (estampillas.server/) - si se generó
[Lista de archivos]

## Archivos Modificados (existentes)

- estampillas.client/src/RoutesConfig.tsx (ruta agregada)
- estampillas.client/src/infrastructure/di/container.ts (repos + use cases registrados)
- estampillas.client/src/domain/entities/index.ts (barrel export fusionado)
- estampillas.client/src/domain/interfaces/repositories/index.ts (fusionado)
- estampillas.client/src/domain/use-cases/index.ts (fusionado)
- estampillas.client/src/infrastructure/dto/index.ts (fusionado)
- estampillas.client/src/infrastructure/mappers/index.ts (fusionado)
- estampillas.client/src/infrastructure/repositories/index.ts (fusionado)
- estampillas.server/Program.cs (si se generó backend)

## Tareas Pendientes

### Frontend
- [ ] Verificar que no hay dependencias adicionales por instalar
- [ ] Probar navegación a la nueva ruta
- [ ] Verificar estados: loading, error, vacío
- [ ] Ajustar estilos si es necesario

### Backend (si se generó)
- [ ] Crear stored procedures en PostgreSQL
- [ ] Reemplazar mock data por Dapper + SPs en Repository
- [ ] Agregar FluentValidation validators
- [ ] Probar endpoints en Swagger

### Migración de Repositorios (si quedaron con mocks)
- [ ] Migrar datos mock a apiClient cuando backend esté listo
- [ ] Considerar encriptación de IDs con crypto utils
```

---

### Fase 11: Limpieza

```
🧹 Limpiando archivos temporales...

✓ Carpeta temporal de extracción eliminada
✓ ZIP original conservado
✓ FIGMA_MAKE_CONTEXT.md del ZIP descartado (ya tiene la info en API_SPECS.md)
```

---

### Mensaje Final

```
🎉 Integración completada exitosamente!

📊 Resumen:
  • Frontend: [N] archivos integrados
  • Backend: [N] archivos generados (si aplica)
  • Rutas: [N] agregadas a RoutesConfig.tsx
  • DI Container: [N] repos + [N] use cases registrados
  • Barrel exports: [N] archivos fusionados

📄 Reportes:
  • INTEGRATION_REPORT.md (raíz del proyecto)

⚡ Próximos pasos:
  1. Verificar dependencias y compilar (npm run build)
  2. Completar backend si se necesita
  3. Probar integración completa
```

---

## Troubleshooting

### Error: "Dependencias prohibidas encontradas"
**Causa**: El ZIP incluye axios, moment, u otras librerías no permitidas.
**Solución**: Continuar y reemplazar manualmente, o regenerar con Figma Make.

### Error: "No se encontró API_SPECS.md"
**Causa**: Falta el archivo de especificaciones.
**Solución**: Crear manualmente o contactar al equipo de diseño.

### Error: "Convención de nombres incorrecta"
**Causa**: Archivos no siguen las convenciones del proyecto.
**Solución**: El comando ofrece renombrar automáticamente:
- `EstampillaEntity.ts` → `Estampilla.entity.ts`
- `EstampillaRepository.ts` → `EstampillaRepositoryImpl.ts`
- `application/dto/*` → `infrastructure/dto/*`

### Error: "Conflictos de archivos"
**Causa**: Archivos ya existen en el proyecto.
**Solución**: Elegir opción (overwrite, keep, merge, rename).

### Error: "Compilación TypeScript falla"
**Causas comunes**:
- Imports con paths relativos en vez de alias `@/*`
- Tipos faltantes
- Barrel exports no actualizados

**Solución**:
```bash
npm run build    # Ver errores específicos
```

### Error: "DTOs en ubicación incorrecta"
**Causa**: Figma Make generó DTOs en `application/dto/` en vez de `infrastructure/dto/`.
**Solución**: El comando detecta esto y mueve automáticamente.

---

## Notas Importantes

1. **No instala dependencias automáticamente** - Solo valida y avisa.

2. **Fusiona barrel exports** - No sobrescribe index.ts existentes.

3. **Registra en DI Container** - Agrega repos y use cases al container.ts existente.

4. **Encriptación de IDs** - En producción, los IDs vienen encriptados del backend.
   Los repositorios mock usan strings planos. Al migrar, usar `safeDecryptField()` y
   `encryptField()` de `@/infrastructure/crypto/cryptoUtils`.

5. **RoutesConfig.tsx** - Las rutas se envuelven con `AppBootstrap`:
   ```tsx
   {
     element: <AppBootstrap><NuevaPagina /></AppBootstrap>,
     path: 'nueva-ruta'
   }
   ```

6. **Backend - Patrones a seguir**:
   - Controllers: heredar `BaseApiController`, inyectar `ISessionCryptoService`
   - Usar `HandleEncryptedResult` para respuestas con IDs encriptados
   - Commands: `record` types con `IRequest<Result<T>>`
   - Handlers: `try/catch` con `ILogger` y `Result.Failure()`
   - Registrar repositorios en `Program.cs` con `AddScoped`

7. **JSON naming policy** - El backend usa `CamelCase`:
   - C# `Nombre` → JSON `nombre`
   - C# `IdEntidadPry` → JSON `idEntidadPry`

---

**Última actualización**: 2026-03-16
**Versión**: 2.0 - Neo Estampillas (Alineado con arquitectura real)
