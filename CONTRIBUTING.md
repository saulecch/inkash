# Cómo trabajamos en Inkash

## Flujo (GitHub Flow)
1. Todo empieza con un **issue** en el tablero (GitHub Projects).
2. Rama desde `main` actualizada: `git switch main && git pull && git switch -c feat/12-guardar-gasto`
   - Prefijos: `feat/` · `fix/` · `docs/` · `chore/` · `test/`, + número de issue.
3. Commits pequeños y frecuentes (ver formato abajo).
4. `git push -u origin <rama>` y abrir **Pull Request** hacia `main`.
5. El **CI** corre `flutter analyze` + `flutter test`. Si está rojo, no se integra.
6. **Otra persona** revisa (code review) y aprueba.
7. Merge (squash) y se borra la rama.

`main` está **protegida**: nadie hace `push` directo, ni el Tech Lead.

## Mensajes de commit (Conventional Commits)
```
<tipo>(<alcance>): <qué hace, en imperativo>

<por qué, si no es obvio>
```
Ejemplos:
- `feat(home): leer movimientos desde SQLite`
- `fix(form): evitar doble guardado con doble toque`
- `test(tipo-cambio): cubrir timeout de la API`
- `docs(adr): ADR-0003 caché del tipo de cambio`

## Uso de IA
Permitido como **par**, con bitácora: `docs/bitacora-ia.md`.
"La IA lo escribió" no es una explicación válida en el code review ni en la defensa.
