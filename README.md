# devlo-caffeinate

App de barra de menú para macOS que mantiene la pantalla despierta por un tiempo elegido. Es una interfaz mínima sobre `caffeinate -d`, con un interruptor adicional para `pmset disablesleep`.

## Qué hace

Al hacer clic en el ícono de la taza aparece un menú con:

- **30 minutos, 1, 2, 3, 4, 5 horas o Infinito**: ejecuta `caffeinate -d` con ese límite de tiempo. El menú muestra cuánto falta y la opción activa queda marcada.
- **Detener**: termina `caffeinate` antes de tiempo.
- **Desactivar reposo del sistema (pmset)**: alterna `pmset -a disablesleep` entre `1` y `0`. Pide la contraseña de administrador en cada cambio. Este ajuste persiste aunque se cierre la app.
- **Salir**: cierra la app y termina `caffeinate` si estaba activo.

La taza se muestra rellena mientras hay algo activo.

## Requisitos

- macOS 13 o superior, Apple Silicon
- Herramientas de línea de comandos de Xcode (`swiftc`)

## Compilar

```bash
./build.sh
```

Genera `CaffeinateBar.app` en la misma carpeta, firmada ad hoc.

## Instalar

```bash
cp -R CaffeinateBar.app /Applications/
```

```bash
open /Applications/CaffeinateBar.app
```

Para que abra al iniciar sesión, agrégala en Ajustes del Sistema → General → Ítems de inicio.

## Estructura

- `main.swift`: toda la app (AppKit, sin dependencias)
- `Info.plist`: metadatos del bundle; `LSUIElement` la oculta del Dock
- `build.sh`: compila, empaqueta y firma
