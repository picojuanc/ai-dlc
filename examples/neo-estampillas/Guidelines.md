# Neo Estampillas — Guidelines para Figma Make

> Este archivo debe copiarse al proyecto de Figma Make en `guidelines/Guidelines.md`.
> La IA lo leerá automáticamente antes de cada generación.
> El diseñador solo necesita describir el feature; las reglas técnicas ya están aquí.

---

## 1. REGLA FUNDAMENTAL: NO ASUMAS — PREGUNTA

Si algo no está claro en los requisitos del feature, DEBES:
1. Describir qué no está definido.
2. Presentar 2-3 opciones viables con explicación breve.
3. Incluir siempre "Otra solución diferente".
4. ESPERAR la decisión del usuario antes de continuar.

Nunca inventes datos, campos, flujos o lógica que no se hayan especificado.

---

## 2. ALCANCE DE GENERACIÓN

- SOLO código frontend: React + TypeScript
- NO generar backend (.cs, .sql, .csproj, Controllers/, Repositories/ en C#)
- Usar DATOS MOCK en todos los repositorios para que sea funcional sin backend
- Generar `API_SPECS.md` documentando los endpoints que el frontend necesita
- Generar `FIGMA_MAKE_CONTEXT.md` con contexto del feature para futuras sesiones

---

## 3. STACK TÉCNICO (BLOQUEADO)

| Categoría | Tecnología | Versión |
|-----------|-----------|---------|
| Framework | React + TypeScript (strict) | 19.1.1 + 5.9.3 |
| Build | Vite + @vitejs/plugin-react-swc | 7.1.7 |
| Routing | React Router DOM | 7.12.0 |
| UI | PrimeReact + PrimeIcons | ^10.9.7 + ^7.0.0 |
| Estilos | Tailwind CSS + @tailwindcss/vite + tw-animate-css | ^4.1.18 + ^1.4.0 |
| Estado | Zustand + Immer | ^5.0.8 + ^11.1.3 |
| Animaciones | motion (framer-motion) | ^12.27.1 |
| HTTP | fetch() nativo | — |
| Fechas | Intl.DateTimeFormat / Intl.NumberFormat | nativo |

### Librerías opcionales (pre-aprobadas, solo si el feature lo requiere):
- html2canvas ^1.4.1, jspdf ^3.0.4, xlsx ^0.18.5

### CUALQUIER OTRA LIBRERÍA → PROHIBIDA

Si crees que necesitas algo no listado:
1. Explica qué problema resuelve
2. Explica por qué NO se puede con el stack actual
3. ESPERA aprobación explícita

### Librerías explícitamente PROHIBIDAS (NO usar bajo ninguna circunstancia):

| Categoría | Prohibidas |
|-----------|-----------|
| HTTP | axios, ky, superagent |
| Fechas | moment, date-fns, dayjs |
| Utilidades | lodash, underscore |
| UI | Material-UI (@mui), Ant Design, Chakra UI, Bootstrap, shadcn/ui |
| Estado | Redux, MobX, Recoil, Context API (para estado global) |
| Formularios | react-hook-form, formik |

### Dependencias privadas (NO incluir, se agregan al integrar al proyecto real):
- @syc/edesk-web-client
- @syc/edesk-components

---

## 4. COMPONENTES UI DISPONIBLES (PrimeReact)

Usa EXCLUSIVAMENTE estos componentes para la interfaz:

| Necesidad | Componente | Import |
|-----------|-----------|--------|
| Botones | `Button` | `primereact/button` |
| Campo de texto | `InputText` | `primereact/inputtext` |
| Campo numérico | `InputNumber` | `primereact/inputnumber` |
| Textarea | `InputTextarea` | `primereact/inputtextarea` |
| Checkbox | `Checkbox` | `primereact/checkbox` |
| Lista desplegable | `Dropdown` | `primereact/dropdown` |
| Selector múltiple | `MultiSelect` | `primereact/multiselect` |
| Calendario | `Calendar` | `primereact/calendar` |
| Tabla de datos | `DataTable` + `Column` | `primereact/datatable`, `primereact/column` |
| Modal/Diálogo | `Dialog` | `primereact/dialog` |
| Notificación | `Toast` | `primereact/toast` |
| Mensaje | `Message` | `primereact/message` |
| Spinner | `ProgressSpinner` | `primereact/progressspinner` |
| Tabs | `TabView` + `TabPanel` | `primereact/tabview` |
| Tarjeta | `Card` | `primereact/card` |
| Panel | `Panel` | `primereact/panel` |
| Sidebar | `Sidebar` | `primereact/sidebar` |
| Iconos | PrimeIcons | `<i className="pi pi-[nombre]" />` |
| Tag/Badge | `Tag` | `primereact/tag` |
| Tooltip | `Tooltip` | `primereact/tooltip` |

Docs: https://primereact.org/

---

## 5. PATH ALIAS OBLIGATORIO

Todos los imports internos DEBEN usar `@/*` que mapea a `./src/*`:

```typescript
// CORRECTO
import { EntidadEntity } from '@/domain/entities/Entidad.entity';
import type { ITramiteRepository } from '@/domain/interfaces/repositories/ITramiteRepository';

// INCORRECTO — NUNCA usar rutas relativas largas
import { EntidadEntity } from '../../../domain/entities/Entidad.entity';
```

---

## 6. ESTRUCTURA DE CARPETAS (Clean Architecture)

```
src/
├── domain/                          # Lógica de negocio pura (sin dependencias externas)
│   ├── entities/                    # [Nombre].entity.ts + index.ts
│   ├── interfaces/repositories/     # I[Nombre]Repository.ts + index.ts
│   ├── use-cases/                   # [Action][Feature]UseCase.ts + index.ts
│   └── validators/                  # (si aplica)
├── infrastructure/                   # Implementaciones externas
│   ├── http/apiClient.ts            # Cliente HTTP centralizado (fetch)
│   ├── dto/                         # [Nombre]DTO.ts + index.ts
│   ├── mappers/                     # [Nombre]Mapper.ts + index.ts
│   ├── repositories/                # [Nombre]RepositoryImpl.ts + index.ts (MOCK)
│   └── di/container.ts              # DI Container (Singleton)
├── application/                      # Lógica de aplicación
│   ├── state/                       # use[Feature]Store.ts (Zustand + Immer)
│   │   └── initial-values/          # [seccion].initial.ts + index.ts
│   ├── selectors/                   # [feature]Selectors.ts (cálculos derivados)
│   └── builders/                    # [feature]Builders.ts (DTOs complejos)
├── presentation/                     # Capa de UI
│   ├── components/
│   │   ├── common/                  # Componentes agnósticos (SOLO props + callbacks)
│   │   ├── domain/                  # Componentes específicos del feature
│   │   ├── forms/                   # Formularios
│   │   └── layout/                  # Layouts
│   ├── hooks/                       # use[Feature].ts (orquestación)
│   ├── pages/public/ | private/     # [Nombre]Page.tsx
│   └── styles/                      # index.css, theme.css, custom-prime.css
└── shared/                           # Utilidades compartidas
    ├── constants/                   # [feature].constants.ts
    ├── types/                       # [nombre].types.ts
    └── utils/                       # logger.ts, validators.ts, formatters.ts
```

---

## 7. CONVENCIONES DE NOMBRES (ESTRICTAS)

| Elemento | Convención | Ejemplo |
|----------|-----------|---------|
| Entidad | `[Nombre].entity.ts` | `Recibo.entity.ts` |
| Interface repo | `I[Nombre]Repository.ts` | `IReciboRepository.ts` |
| DTO | `[Nombre]DTO.ts` (en `infrastructure/dto/`) | `ReciboDTO.ts` |
| Mapper | `[Nombre]Mapper.ts` | `ReciboMapper.ts` |
| Repositorio impl | `[Nombre]RepositoryImpl.ts` | `ReciboRepositoryImpl.ts` |
| Use case | `[Action][Feature]UseCase.ts` | `GetRecibosUseCase.ts` |
| Store (Zustand) | `use[Feature]Store.ts` | `useAutodeclaracionStore.ts` |
| Hook | `use[Feature].ts` | `useAutodeclaracion.ts` |
| Página | `[Nombre]Page.tsx` | `AutodeclaracionPage.tsx` |
| Constantes | `[feature].constants.ts` | `autodeclaracion.constants.ts` |
| Tipos | `[nombre].types.ts` | `autodeclaracion.types.ts` |

### Reglas adicionales:
- **Barrel exports**: `index.ts` en CADA carpeta con múltiples archivos
- **IDs de entidades**: siempre tipo `string` (en producción vienen encriptados)
- **Type imports**: usar `import type { ... }` para interfaces y tipos

---

## 8. PATRONES DE CÓDIGO

### Entidad de dominio
```typescript
// domain/entities/Ejemplo.entity.ts
export class EjemploEntity {
  constructor(
    public readonly id: string,
    public readonly nombre: string,
    public readonly activa: boolean = true
  ) {}

  static create(data: { id: string; nombre: string; activa?: boolean }): EjemploEntity {
    return new EjemploEntity(data.id, data.nombre, data.activa ?? true);
  }

  equals(other: EjemploEntity): boolean {
    return this.id === other.id;
  }
}
```

### Interface de repositorio
```typescript
// domain/interfaces/repositories/IEjemploRepository.ts
import type { EjemploEntity } from '@/domain/entities/Ejemplo.entity';

export interface IEjemploRepository {
  getAll(): Promise<EjemploEntity[]>;
  getById(id: string): Promise<EjemploEntity | null>;
}
```

### Use Case
```typescript
// domain/use-cases/GetEjemplosUseCase.ts
import type { IEjemploRepository } from '@/domain/interfaces/repositories/IEjemploRepository';
import type { EjemploEntity } from '@/domain/entities/Ejemplo.entity';
import { logger } from '@/shared/utils/logger';

export class GetEjemplosUseCase {
  constructor(private readonly repository: IEjemploRepository) {}

  async execute(): Promise<EjemploEntity[]> {
    try {
      return await this.repository.getAll();
    } catch (error) {
      logger.error('GetEjemplosUseCase', 'Error al obtener datos:', error);
      throw new Error('No se pudieron cargar los datos');
    }
  }
}
```

### DTO
```typescript
// infrastructure/dto/EjemploDTO.ts
export interface EjemploDTO {
  id: string;       // string porque en producción viene encriptado
  nombre: string;
  activa: boolean;
}
```

### Mapper
```typescript
// infrastructure/mappers/EjemploMapper.ts
import { EjemploEntity } from '@/domain/entities/Ejemplo.entity';
import type { EjemploDTO } from '@/infrastructure/dto/EjemploDTO';

export class EjemploMapper {
  static toDomain(dto: EjemploDTO): EjemploEntity {
    return EjemploEntity.create({ id: dto.id, nombre: dto.nombre, activa: dto.activa });
  }

  static toDTO(entity: EjemploEntity): EjemploDTO {
    return { id: entity.id, nombre: entity.nombre, activa: entity.activa };
  }

  static toDomainList(dtos: EjemploDTO[]): EjemploEntity[] {
    return dtos.map(d => this.toDomain(d));
  }
}
```

### Repositorio (MOCK con metadata de integración)
```typescript
// infrastructure/repositories/EjemploRepositoryImpl.ts
import type { IEjemploRepository } from '@/domain/interfaces/repositories/IEjemploRepository';
import { EjemploEntity } from '@/domain/entities/Ejemplo.entity';

const MOCK_DATA = [
  EjemploEntity.create({ id: '1', nombre: 'Ejemplo 1', activa: true }),
  EjemploEntity.create({ id: '2', nombre: 'Ejemplo 2', activa: true }),
];

export class EjemploRepositoryImpl implements IEjemploRepository {
  /* TODO-INTEGRATION: getAll
     HTTP: GET /api/ejemplos
     Response: EjemploDTO[]
     Backend: Query GetAllEjemplosQuery → IRequest<Result<IEnumerable<EjemploDto>>>
     Handler: GetAllEjemplosQueryHandler (usa IEjemploRepository.GetAllAsync)
     Controller: EjemplosController.GetAll() → HandleEncryptedResult
     Notas: IDs se encriptan con ISessionCryptoService en el controller
  */
  async getAll(): Promise<EjemploEntity[]> {
    await new Promise(r => setTimeout(r, 500));
    return [...MOCK_DATA].filter(e => e.activa);
  }

  /* TODO-INTEGRATION: getById
     HTTP: GET /api/ejemplos/{id}
     Params: id (string encriptado)
     Response: EjemploDTO
     Backend: Query GetEjemploByIdQuery(int Id) → IRequest<Result<EjemploDto>>
  */
  async getById(id: string): Promise<EjemploEntity | null> {
    await new Promise(r => setTimeout(r, 300));
    return MOCK_DATA.find(item => item.id === id) ?? null;
  }
}
```

### DI Container
```typescript
// infrastructure/di/container.ts
import { EjemploRepositoryImpl } from '@/infrastructure/repositories';
import { GetEjemplosUseCase as GetEjemplosUseCaseClass } from '@/domain/use-cases';

class DIContainer {
  private static instance: DIContainer;
  private _ejemploRepo?: EjemploRepositoryImpl;
  private _getEjemplos?: GetEjemplosUseCaseClass;

  private constructor() {}

  static getInstance(): DIContainer {
    if (!DIContainer.instance) DIContainer.instance = new DIContainer();
    return DIContainer.instance;
  }

  get ejemploRepository(): EjemploRepositoryImpl {
    return this._ejemploRepo ??= new EjemploRepositoryImpl();
  }

  get getEjemplosUseCase(): GetEjemplosUseCaseClass {
    return this._getEjemplos ??= new GetEjemplosUseCaseClass(this.ejemploRepository);
  }

  reset(): void {
    this._ejemploRepo = undefined;
    this._getEjemplos = undefined;
  }
}

export const container = DIContainer.getInstance();
```

### Store Zustand
```typescript
// application/state/useEjemploStore.ts
import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';
import type { EjemploEntity } from '@/domain/entities';
import { container } from '@/infrastructure/di/container';
import { logger } from '@/shared/utils/logger';

interface EjemploStore {
  items: EjemploEntity[];
  loading: boolean;
  error: string | null;
  fetchAll: () => Promise<void>;
  reset: () => void;
}

const initialState = {
  items: [] as EjemploEntity[],
  loading: false,
  error: null as string | null,
};

export const useEjemploStore = create<EjemploStore>()(
  immer((set) => ({
    ...initialState,
    fetchAll: async () => {
      set((s) => { s.loading = true; s.error = null; });
      try {
        const items = await container.getEjemplosUseCase.execute();
        set((s) => { s.items = items; });
      } catch (err) {
        const msg = err instanceof Error ? err.message : 'Error desconocido';
        logger.error('useEjemploStore', msg);
        set((s) => { s.error = msg; });
      } finally {
        set((s) => { s.loading = false; });
      }
    },
    reset: () => set(initialState),
  }))
);
```

### Hook de orquestación
```typescript
// presentation/hooks/useEjemplo.ts
import { useCallback } from 'react';
import { useEjemploStore } from '@/application/state/useEjemploStore';

export const useEjemplo = () => {
  const items = useEjemploStore((s) => s.items);
  const loading = useEjemploStore((s) => s.loading);
  const error = useEjemploStore((s) => s.error);
  const fetchAll = useEjemploStore((s) => s.fetchAll);

  const handleRefresh = useCallback(() => {
    fetchAll();
  }, [fetchAll]);

  return { items, loading, error, handleRefresh };
};
```

### Cliente HTTP
```typescript
// infrastructure/http/apiClient.ts
import { logger } from '@/shared/utils/logger';

const basePath = import.meta.env.VITE_BASE_PATH || '';
const API_BASE_URL = `${basePath}/api`;

export class ApiError extends Error {
  constructor(
    public status: number,
    public statusText: string,
    message?: string,
    public data?: unknown
  ) {
    super(message || `API Error: ${status} ${statusText}`);
    this.name = 'ApiError';
  }
}

async function request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const url = `${API_BASE_URL}${endpoint}`;
  const config: RequestInit = {
    credentials: 'include',
    headers: { 'Content-Type': 'application/json', ...options.headers },
    ...options,
  };
  const response = await fetch(url, config);
  if (!response.ok) {
    let msg = response.statusText;
    let data: unknown = null;
    try {
      data = await response.json();
      msg = (data as { error?: string })?.error ?? msg;
    } catch { /* ignore */ }
    throw new ApiError(response.status, response.statusText, msg, data);
  }
  if (response.status === 204) return null as T;
  return response.json();
}

export const apiClient = {
  get: <T>(ep: string, opt?: RequestInit) => request<T>(ep, { ...opt, method: 'GET' }),
  post: <T>(ep: string, data?: unknown, opt?: RequestInit) =>
    request<T>(ep, { ...opt, method: 'POST', body: data ? JSON.stringify(data) : undefined }),
  patch: <T>(ep: string, data?: unknown, opt?: RequestInit) =>
    request<T>(ep, { ...opt, method: 'PATCH', body: data ? JSON.stringify(data) : undefined }),
  put: <T>(ep: string, data?: unknown, opt?: RequestInit) =>
    request<T>(ep, { ...opt, method: 'PUT', body: data ? JSON.stringify(data) : undefined }),
  delete: <T>(ep: string, opt?: RequestInit) => request<T>(ep, { ...opt, method: 'DELETE' }),
};
```

### Logger seguro
```typescript
// shared/utils/logger.ts
export const logger = {
  error(tag: string, message?: string, ..._ignored: unknown[]): void {
    console.error(`[${tag}] ${typeof message === 'string' && message.trim() ? message : 'Error interno'}`);
  },
  warn(_tag: string, ..._args: unknown[]): void {},
  debug(_tag: string, ..._args: unknown[]): void {},
};
```

### Utilidades compartidas
```typescript
// shared/utils/formatters.ts
export const formatters = {
  currency: (v: number) =>
    new Intl.NumberFormat('es-CO', {
      style: 'currency',
      currency: 'COP',
      minimumFractionDigits: 0,
    }).format(v),
  date: (iso: string) =>
    new Intl.DateTimeFormat('es-CO', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    }).format(new Date(iso)),
  shortDate: (iso: string) =>
    new Intl.DateTimeFormat('es-CO', {
      year: 'numeric',
      month: 'short',
      day: '2-digit',
    }).format(new Date(iso)),
};

// shared/utils/validators.ts
export const validators = {
  isRequired: (v: unknown) => v !== null && v !== undefined && String(v).trim() !== '',
  isEmail: (v: string) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v),
  maxLength: (v: string, max: number) => v.length <= max,
  isPositive: (v: number) => v > 0,
};
```

---

## 9. SEPARACIÓN LÓGICA / VISUAL (CRÍTICO)

Los diseñadores iterarán frecuentemente sobre la capa visual.
La lógica de negocio NO debe estar mezclada en los componentes visuales.

### Regla: Los componentes en `common/` SOLO reciben props + callbacks. CERO lógica.

```typescript
// CORRECTO — Componente puro, un diseñador puede modificarlo sin riesgo
interface CardProps {
  nombre: string;
  valor: string;
  estado: string;
  onEdit?: () => void;
}
export const MiCard: FC<CardProps> = ({ nombre, valor, estado, onEdit }) => (
  <Card title={nombre}>
    <p>{valor}</p>
    <span>{estado}</span>
    {onEdit && <Button label="Editar" onClick={onEdit} />}
  </Card>
);
```

```typescript
// INCORRECTO — NUNCA hacer esto en componentes visuales
export const MiCard = ({ id }: { id: string }) => {
  const { items } = useStore();                      // !! lógica acoplada
  const item = items.find(e => e.id === id);         // !! búsqueda en componente
  const handleSave = async () => { await api(...); } // !! HTTP en componente
  return <Card>...</Card>;
};
```

### Dónde va cada cosa:
| Qué | Dónde |
|-----|-------|
| Lógica de datos/negocio | `domain/use-cases/` y `application/state/` |
| Orquestación de acciones | `presentation/hooks/` |
| Presentación visual | `presentation/components/` (solo props + callbacks) |
| Páginas | `presentation/pages/` (conectan hooks con componentes) |

---

## 10. BUENAS PRÁCTICAS OBLIGATORIAS

### Accesibilidad (WCAG 2.1 AA)
- Botones e inputs con `aria-label` descriptivo
- Inputs con `<label htmlFor>` asociado
- ProgressSpinner con `aria-label="Cargando..."`
- Mensajes de error con `role="alert" aria-live="polite"`
- Iconos decorativos con `aria-hidden="true"`
- Navegación funcional por teclado (Enter/Space)

### Responsive (mobile-first)
- Breakpoints: móvil (375px) → tablet (768px) → desktop (1024px+)
- Clases Tailwind: `flex-col md:flex-row`, `grid-cols-1 md:grid-cols-2 lg:grid-cols-3`
- DataTables con `responsiveLayout="scroll"`
- Touch targets mínimo 44x44px en móvil
- Contenedor principal: `max-w-[1024px] mx-auto px-4`

### Seguridad
- Sanitizar inputs del usuario (trim)
- Validar datos en formularios antes de enviar
- NO usar `dangerouslySetInnerHTML`
- NO loguear datos sensibles
- NO hardcodear tokens, URLs absolutas ni credenciales

### Optimización
- `useMemo` para cálculos derivados costosos
- `useCallback` para funciones pasadas como props
- `React.memo` para componentes que no deben re-renderizar innecesariamente
- `React.lazy` + `Suspense` para páginas grandes
- Animaciones con `motion` (`AnimatePresence`) para transiciones suaves

### Código limpio
- Sin `any` en TypeScript — siempre tipos explícitos
- Nombres descriptivos (`handleReciboDelete`, `isFormValid`, NO `handleClick`, `flag`)
- Funciones pequeñas con una responsabilidad
- Mensajes de error amigables para el usuario

---

## 11. MOCKS CON METADATA PARA INTEGRACIÓN

Cada método de repositorio mock DEBE incluir un comentario `TODO-INTEGRATION` con este formato:

```typescript
/* TODO-INTEGRATION: [nombreMetodo]
   HTTP: [METHOD] /api/[recurso]
   Params: [parámetros si aplica]
   Body: [tipo del body si aplica]
   Response: [Nombre]DTO | [Nombre]DTO[]
   Backend: [Query|Command] [NombreQuery|Command] → IRequest<Result<[tipo]>>
   Handler: [NombreHandler] (usa I[Nombre]Repository.[metodo])
   Controller: [Nombre]Controller.[metodo]() → HandleEncryptedResult
   Notas: [notas adicionales, ej: IDs encriptados con ISessionCryptoService]
*/
```

Esta metadata permite generar automáticamente el backend (Controllers, Commands, Queries, DTOs en C#).

---

## 12. CONTEXTO DEL BACKEND (para API_SPECS.md)

El proyecto backend usa:
- ASP.NET Core 9.0 con Clean Architecture + CQRS (MediatR)
- PostgreSQL con stored procedures + Dapper
- `BaseApiController` + `ISessionCryptoService` + `HandleEncryptedResult`
- Namespace: `estampillas.server.[Layer].[...]`
- JSON con camelCase naming policy
- IDs encriptados en tránsito (string en frontend ↔ int en backend)

Incluir esta información en `API_SPECS.md` para que el equipo backend sepa qué construir.

---

## 13. ARCHIVOS DE CONFIGURACIÓN

### package.json (SOLO dependencias públicas)
```json
{
  "name": "[nombre-feature]",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "lint": "eslint .",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^19.1.1",
    "react-dom": "^19.1.1",
    "react-router-dom": "^7.12.0",
    "primereact": "^10.9.7",
    "primeicons": "^7.0.0",
    "tailwindcss": "^4.1.18",
    "@tailwindcss/vite": "^4.1.18",
    "tw-animate-css": "^1.4.0",
    "zustand": "^5.0.8",
    "immer": "^11.1.3",
    "motion": "^12.27.1"
  },
  "devDependencies": {
    "@eslint/js": "^9.36.0",
    "@types/node": "^24.6.0",
    "@types/react": "^19.1.16",
    "@types/react-dom": "^19.1.9",
    "@vitejs/plugin-react-swc": "^4.2.2",
    "eslint": "^9.36.0",
    "eslint-plugin-react-hooks": "^5.2.0",
    "eslint-plugin-react-refresh": "^0.4.22",
    "globals": "^16.4.0",
    "typescript": "~5.9.3",
    "typescript-eslint": "^8.45.0",
    "vite": "^7.1.7"
  }
}
```

### Estilos (presentation/styles/index.css)
```css
@import 'tailwindcss';
@import 'primereact/resources/themes/lara-light-cyan/theme.css';
@import 'primereact/resources/primereact.min.css';
@import 'primeicons/primeicons.css';
@import './theme.css';
@import './custom-prime.css';
```

### Archivos temporales standalone
- `src/App.tsx`: BrowserRouter + Routes temporal (se reemplaza al integrar)
- `src/main.tsx`: createRoot + StrictMode + App
- `index.html`: HTML básico con `<div id="root">`

---

## 14. ARCHIVOS QUE DEBE GENERAR (además del código)

| Archivo | Descripción |
|---------|------------|
| `API_SPECS.md` | Endpoints, DTOs, validaciones, contexto backend |
| `FIGMA_MAKE_CONTEXT.md` | Contexto del feature para futuras sesiones |
| `package.json` | Solo dependencias públicas npm |
| `README.md` | Setup y uso del proyecto standalone |

---

## 15. PRINCIPIOS DE INTEGRACIÓN

Este código se integra a un proyecto en producción. Reglas innegociables:

1. **Sin fricción**: El código debe encajar como pieza de rompecabezas. Seguir EXACTAMENTE la estructura y convenciones definidas aquí. NO inventar patrones nuevos.

2. **Re-generación segura**: Si el feature ya fue integrado y se re-genera con cambios, el nuevo código NO debe romper lo existente. Mantener mismos nombres de archivos, clases e interfaces. Cambios ADITIVOS solamente.

3. **Disciplina de dependencias**: SOLO las librerías listadas. Si necesitas otra, pregunta con justificación y espera aprobación.

---

## CHECKLIST DE ENTREGA

Antes de entregar el ZIP, verificar:

- [ ] Estructura Clean Architecture completa con barrel exports (`index.ts`)
- [ ] Solo dependencias públicas npm (NO @syc/*)
- [ ] Imports con `@/*`, no rutas relativas largas
- [ ] Repositorios con datos MOCK + comentarios `TODO-INTEGRATION`
- [ ] `API_SPECS.md` y `FIGMA_MAKE_CONTEXT.md` presentes
- [ ] Funciona con `npm install && npm run dev`
- [ ] NO contiene archivos .cs, .sql, .csproj
- [ ] Componentes en `common/` son puros (solo props, sin hooks/stores)
- [ ] Sin `any` en TypeScript
- [ ] Accesibilidad: aria-labels, role="alert", labels con htmlFor
- [ ] Responsive: mobile-first con clases Tailwind
- [ ] NO usa librerías prohibidas (MUI, axios, date-fns, react-hook-form, etc.)
