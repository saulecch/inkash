# Bitácora de uso de IA

Cada uso de IA que termina en el repo se registra aquí (el más reciente arriba).
El objetivo no es justificar el uso, sino demostrar **criterio**:
qué especificaste, qué revisaste y qué rechazaste.

| Campo | Qué escribir |
|---|---|
| Fecha / autor | `2026-10-15 · @usuario` |
| Herramienta | Claude, Copilot, ChatGPT, Big Pickle… |
| Especificación | Qué pediste y con qué restricciones (pegar el prompt o resumirlo) |
| Resultado | Qué devolvió, en una frase |
| Aceptado | Qué quedó en el código y por qué |
| Rechazado / corregido | Qué cambiaste y por qué. **Esta es la columna más importante.** |
| Verificación | Cómo comprobaste que funciona (pruebas, dispositivo) |
| Commit / PR | Enlace |

---

## 2026-10-21 · @saulecch (docente) — S16 y S17 rehechas tras probar la app

- **Herramienta:** Claude (asistente de código).
- **Qué pasó:** la primera versión de S16–S17 pasaba todas las pruebas, pero al **usar** la app el
  docente encontró que no estaba completa: no se podían crear ni editar categorías, las cuentas no
  tenían saldo inicial (la tarjeta decía Q0.00), no se podía editar un movimiento, el formulario
  ofrecía "Ingreso" en modo Gasto y Ajustes era un par de diálogos sin diseño.
- **Lección:** las pruebas verifican lo que se especificó; **no** verifican lo que faltó especificar.
  La revisión con la app en la mano (como usuario) encontró lo que ninguna prueba iba a encontrar.
- **Especificación nueva:** S16 = datos completos (cuentas, categorías y edición con CRUD);
  S17 = sistema de diseño + Ajustes + bienvenida + publicación.
- **Rechazado / corregido durante la revisión:**
  - `TextEditingController used after being disposed`: los diálogos destruían el controller mientras
    la hoja se animaba. Ahora cada hoja es un `StatefulWidget` dueño de su controller.
  - El nombre `Radio` para los tokens chocaba con el widget `Radio` de Flutter: se renombró a `Redondeo`.
  - Invalidar el Inicio desde Ajustes creaba una dependencia circular (el Inicio ya hace `watch`
    de Ajustes): se quitó.
  - Revisión visual con capturas de las pantallas: se corrigieron "Te quedan −Q100.00" (ahora
    "Te pasaste por…"), etiquetas cortadas en la barra y poco contraste en el chip de cuenta.

## 2026-10-15 · @saulecch (docente) — preparación de S14

- **Herramienta:** Claude (asistente de código).
- **Especificación:** "Continuar inkash desde `faea821` en commits pequeños y comentados:
  guardar desde el bottom sheet, leer con AsyncNotifier y estados, API con caché offline,
  ADRs y CI. Dinero en centavos, SQL solo en datasources, sin paquetes innecesarios (sin uuid,
  sin intl), cada commit con pruebas que pasen."
- **Resultado:** commits `s14-01` a `s14-06`.
- **Aceptado:** la estructura por capas, `parseMontoCentavos` sin `double`, el guard de doble
  toque antes del `await`, la migración v1→v2.
- **Rechazado / corregido durante la revisión:**
  - `AppDatabase` leía `databaseFactory` en el **constructor**: las pruebas de widget fallaban
    con "databaseFactory not initialized". Se cambió para resolverlo al **abrir** la base.
  - La prueba de doble toque pasaba en falso porque el botón estaba **fuera de pantalla** y el
    toque no llegaba. Se agregó `ensureVisible` antes de tocar.
  - Riverpod 3 **reintenta solo** los providers con error; eso escondía el estado de error.
    Se desactivó (`retry: (_, _) => null`) y quedó documentado en ADR-0002.
- **Verificación:** `flutter analyze` sin observaciones y `flutter test` en verde en cada commit.
