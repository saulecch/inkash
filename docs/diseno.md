# Sistema de diseño de Inkash (S17-01)

Un sistema de diseño es un conjunto pequeño de **decisiones con nombre** que todas las
pantallas reutilizan. Vive en `lib/theme.dart` (tokens + tema) y `lib/core/ui/` (componentes).

## Tokens

| Token | Valores | Regla |
|---|---|---|
| Colores | `kFondo`, `kSuperficie`, `kBorde`, `kTexto`, `kMuted`, `kLima`, `kPeligro` | Lima = acción principal o algo bueno; rojo = error, exceso o borrar |
| `Espacio` | 4 · 8 · 12 · 16 · 24 · 32 | Nada de 14, 22 o 28 sueltos |
| `Redondeo` | control 12 · tarjeta 20 · hoja 28 | Jerarquía: lo grande se redondea más |
| Tipografía | Space Grotesk (OFL, en `assets/fonts`) con números tabulares | Una familia; cada tamaño tiene un rol en `TextTheme` |

| Estilo | Uso |
|---|---|
| `displayLarge` 52 | La cifra principal del Inicio |
| `headlineSmall` 26 | Título de pestaña |
| `titleLarge` 20 | Títulos de sección y de hojas |
| `titleMedium` 16 | Filas |
| `bodySmall` 12 muted | Contexto y ayudas |

## Componentes (`lib/core/ui/`)

| Componente | Para qué |
|---|---|
| `EncabezadoPagina` | Título + contexto + acción de cada pestaña |
| `Seccion` | Grupo de filas sobre una superficie (Ajustes, Cuentas, Categorías, Metas, Presupuesto) |
| `EstadoVacio` | Sin datos = invitación con una acción |
| `HojaFormulario` + `mostrarHoja` | Hojas inferiores con formulario (título, márgenes, teclado) |
| `TarjetaResumen` | Tarjetas del Inicio |
| `Monto` | Dinero con números tabulares; opcionalmente lima/rojo según el signo |

## Reglas de escritura
- Frases en minúscula inicial, sin MAYÚSCULAS sostenidas ("Te quedan este mes").
- Los botones dicen lo que pasa: "Guardar cambios", "Crear cuenta", "Registrar movimiento".
- Un vacío o un error siempre dice qué hacer después.
