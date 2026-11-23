# Plan de implementación — Dev 1 (Lexer y driver)

> [!NOTE]
> **Estado (22-nov):** las tareas de código del B1 y del B2 que no dependen de nadie más están **implementadas y verificadas** (incluidas las banderas opcionales `--tokens`, `--tree salida.dot` y `--sem`). La documentación técnica (`README.md`, `docs/INTERFACES.md`, `docs/dev1_seccion_lexica.md`) también está lista.

Fuente: [Workpath_Recortado_Analizador_C_v4.pdf](file:///home/mikedandev/Documentos/Projects/Compilador_C_LFA/docs/Workpath_Recortado_Analizador_C_v4.pdf), secciones 3, 4, 6 (Dev 1), 7, 9 y 10.

**Archivos propios de Dev 1:** `lexer.l`, `main.c`, `token.h`, `diag.h`, `Makefile` (+ `diag.c`, `README.md` y la sección léxica del informe).

---

## 0. Estado actual del repo

| Archivo | Estado | Observaciones |
|---|---|---|
| [token.h](file:///home/mikedandev/Documentos/Projects/Compilador_C_LFA/token.h) | Parcial | Solo tiene el `struct Token`. Falta la **lista de tokens** acordada con Dev 2 y la tabla de tokens (lista dinámica). |
| [diag.h](file:///home/mikedandev/Documentos/Projects/Compilador_C_LFA/diag.h) | Parcial | Falta el nombre del archivo, los contadores por fase, abrir/cerrar `errores.txt`. No existe `diag.c`. |
| [lexer.l](file:///home/mikedandev/Documentos/Projects/Compilador_C_LFA/lexer.l) | Esqueleto | Las acciones están vacías. Faltan reservadas, operadores, delimitadores, char, cadenas, errores LEX. Hay basura `[cite: …]` en los comentarios. El comentario `/* */` multilínea rompe la columna. |
| `main.c`, `Makefile` | Vacíos | — |
| `parser.y`, `ast.h` (Dev 2), `semantico.c`/`symtab.h`/`types.h` (Dev 3), `arbol.c` (Dev 4) | Vacíos | Dependencias externas → uso **stubs** mientras no estén listos. |

> [!WARNING]
> Problemas en el `lexer.l` actual:
> - `YY_USER_ACTION col_num += yyleng;` está bien para reglas de una sola línea, pero en el comentario `/* … */` con saltos de línea la columna y la línea quedan mal. Hay que recalcularlas recorriendo `yytext`.
> - Falta un patrón para *comentario sin cerrar*, *cadena/char sin cerrar* y *número mal formado* (`9abc`).
> - `[0-9]+\.[0-9]+` y `[0-9]+` están bien, pero `9abc` hoy se tokeniza como `LIT_INT` + `IDENT` sin error.

---

## 1. Decisiones de diseño (hay que confirmarlas con Dev 2 el día 1)

### 1.1 Lista única de tokens (`%token`)
La **declara Bison** en `parser.y` (`%token KW_INT …`), que genera `parser.tab.h`. `token.h` incluye `parser.tab.h` y aporta el `struct Token`, la tabla de tokens y `const char *nombre_token(int tipo)` para `tokens.txt`. Así Flex y Bison nunca se desincronizan (riesgo n.º 1 de la sección 10).

| Categoría | Tokens propuestos |
|---|---|
| Reservadas | `KW_INT KW_FLOAT KW_CHAR KW_BOOL KW_IF KW_ELSE KW_WHILE KW_FOR KW_SCANF KW_PRINTF KW_RETURN` |
| Literales | `LIT_INT LIT_FLOAT LIT_CHAR LIT_STRING LIT_BOOL` |
| Identificador / preprocesador | `IDENT` (incluye `main`), `PP_INCLUDE` |
| Aritméticos | `OP_PLUS OP_MINUS OP_MUL OP_DIV OP_MOD` |
| Asignación | `OP_ASSIGN OP_ADD_ASSIGN OP_SUB_ASSIGN OP_MUL_ASSIGN OP_DIV_ASSIGN` |
| Relacionales | `OP_EQ OP_NE OP_LT OP_GT OP_LE OP_GE` |
| Lógicos / otros | `OP_AND OP_OR OP_NOT OP_AMP` (`&` solo en scanf) |
| Delimitadores | `DELIM_SEMI DELIM_COMMA DELIM_LPAREN DELIM_RPAREN DELIM_LBRACE DELIM_RBRACE` |

### 1.2 Conexión lexer ↔ parser con el corte por fase (A8)
Como el lexer debe reportar **todos** sus errores antes de que corra el parser, propongo:

1. Flex genera `int lex_scan(void)` (`#define YY_DECL int lex_scan(void)`).
2. **Pasada léxica completa:** `main.c` llama a `lex_scan()` hasta EOF; cada token se guarda en la `TablaTokens` (tipo, lexema, línea, col, y el valor semántico).
3. Si `errores_lex > 0` → se escribe la nota de fases omitidas y `exit(1)`.
4. Si no, Bison llama a un `yylex()` *wrapper* (en `lexer.l`) que **entrega los tokens desde la tabla**, llena `yylval` y `yylloc` (línea/col para los errores SYN de Dev 2).

Ventaja: una sola lectura del archivo, `tokens.txt` siempre completo y Dev 2 no tiene que cambiar nada (`yylex()` estándar + `%locations`).

### 1.3 Contratos con Dev 2/3/4 (los consume `main.c`)
```c
/* Dev 2 (parser.y / ast.h) */  extern Nodo *raiz_ast;  int yyparse(void);
/* Dev 3 (semantico.c)      */  int  analizar_semantica(Nodo *raiz);   // devuelve n.º de errores SEM
/* Dev 4 (arbol.c)          */  void arbol_imprimir_txt(Nodo *raiz, FILE *out);
                                void arbol_exportar_dot(Nodo *raiz, FILE *out); // opcional
```
Hasta tenerlos, creo `stubs.c` (solo lo compila el Makefile con `make stubs`) para probar el pipeline de punta a punta.

---

## 2. Bloque 1 — Piezas por separado (~40 %)

### T1.1 Repo, carpetas y `Makefile`
- [Makefile](file:///home/mikedandev/Documentos/Projects/Compilador_C_LFA/Makefile) con las reglas:
  - `bison -d -Wall parser.y` → `parser.tab.c/.h`
  - `flex -o lex.yy.c lexer.l`
  - `gcc -Wall -Wextra -std=c11` → binario **`ccheck`**
  - `make test` (corre los 4 casos de `pruebas/` y deja las salidas en `salidas/`), `make dot` (`dot -Tpng`), `make clean`.
- `.gitignore` para los archivos generados (`lex.yy.c`, `parser.tab.*`, `ccheck`, `*.o`).
- **Entregable:** repo que compila.

### T1.2 Interfaces congeladas: `token.h` y `diag.h` (con Dev 2)
- `token.h`: `struct Token` (ya existe), `TablaTokens` (arreglo dinámico + `tabla_agregar`, `tabla_liberar`), `nombre_token()`, `tokens_escribir(FILE*)`.
- `diag.h` + **`diag.c`**:
  - `diag_init(const char *archivo, FILE *errores)` → guarda el nombre para el formato `archivo:línea:col: error[FASE]: mensaje` (A7).
  - `reportar_error(fase, linea, col, fmt, ...)` → variádica (estilo `printf`) para que Dev 2/3 armen «se esperaba X y se encontró Y». Escribe en `errores.txt` y en `stderr`.
  - `diag_cuenta(FaseCompilador)` → contador por fase (lo usa el corte por fase).
- Avisar en el grupo cuando se congelen (máx. 2 días).

### T1.3 Lexer completo en [lexer.l](file:///home/mikedandev/Documentos/Projects/Compilador_C_LFA/lexer.l)
- Reservadas: `int float char bool if else while for scanf printf return` (antes de `IDENT`).
- `true|false` → `LIT_BOOL`; `[0-9]+` → `LIT_INT`; `[0-9]+\.[0-9]+` → `LIT_FLOAT`; `'([^'\\\n]|\\.)'` → `LIT_CHAR`; `\"([^"\\\n]|\\.)*\"` → `LIT_STRING`.
- Operadores de dos caracteres antes que los de uno (`+=` antes de `+`, `==` antes de `=`, `&&` antes de `&`, etc.); Flex ya elige la coincidencia más larga.
- Comentarios `//` y `/* */` ignorados; `#include <x.h>` / `#include "x.h"` → `PP_INCLUDE`; cualquier otro `#…` es un error LEX.
- **Línea/columna:** `YY_USER_ACTION` guarda `tok_col = col_num` y luego `col_num += yyleng`. La función `avanzar_posicion(yytext)` recalcula línea/columna en los comentarios multilínea. Lo verifico el día 1 con un caso de prueba (riesgo de la sección 10).
- Cada token reconocido → `tabla_agregar(tipo, yytext, line_num, tok_col)`.

### T1.4 Tabla de tokens → `tokens.txt`
Formato exacto de la sección 9:
```
# TIPO             LEXEMA     LÍNEA     COL
KW_INT             int        3         5
```
(`printf("%-18s %-10s %-9d %d\n", ...)`).

### T1.5 Errores léxicos con recuperación (A9: reportar todos y seguir leyendo)
| Error | Patrón Flex | Mensaje |
|---|---|---|
| Número mal formado | `[0-9]+(\.[0-9]+)?[a-zA-Z_][a-zA-Z0-9_]*` | `número mal formado '9abc'` |
| Float incompleto | `[0-9]+\.` | `número mal formado '3.'` |
| Cadena sin cerrar | `\"([^"\\\n]|\\.)*` (llega a `\n` o EOF) | `cadena sin cerrar` |
| Char sin cerrar / vacío / largo | `'([^'\\\n]|\\.)*` / `''` / `'..+'` | `literal char inválido` |
| Comentario sin cerrar | `"/*"([^*]|\*+[^*/])*\**` sin `*/` (en EOF) | `comentario sin cerrar` |
| Directiva inválida | `#.*` | `directiva inválida` |
| Carácter inválido | `.` (regla final) | `carácter inválido '@'` |

- **Entregable B1:** `./ccheck pruebas/error_lexico.c` genera `tokens.txt` + los errores LEX correctos (con `stubs.c`).

---

## 3. Bloque 2 — Integración (~30 %)

### T2.1 Driver [main.c](file:///home/mikedandev/Documentos/Projects/Compilador_C_LFA/main.c) — `ccheck entrada.c`
```
abrir entrada.c → crear salidas/ (tokens.txt, arbol.txt, errores.txt)
diag_init(...)
Fase 1: pasada léxica → tokens.txt
  si hay LEX → "Fases sintáctica y semántica omitidas por errores léxicos" → exit 1
Fase 2: yyparse()
  si hay SYN → "Fase semántica omitida por errores sintácticos" → exit 2
  arbol_imprimir_txt(raiz, arbol.txt)   [+ arbol.dot si existe]
Fase 3: analizar_semantica(raiz)  (Dev 3 imprime la interpretación simbólica)
  si hay SEM → exit 3
"Análisis completado sin errores" → exit 0
```
- Si una fase se omite, `arbol.txt` también lo indica (nunca hay resultados de una fase que no se ejecutó).
- Códigos de salida: `0` OK · `1` LEX · `2` SYN · `3` SEM.
- Validación de argumentos (`uso: ccheck <archivo.c>`), error si no se puede abrir el archivo.
- Opcional, solo si sobra tiempo: `--tokens`, `--tree salida.dot`, `--sem`.

### T2.2 Conectar lexer ↔ parser (sesión con Dev 2)
- Wrapper `yylex()` que llena `yylval` (lexema `strdup`) y `yylloc` (`first_line`, `first_column`).
- Compartir con Dev 2 el `nombre_token()` y el lexema para su mensaje «se esperaba ';' y se encontró 'printf'».
- Revisión cruzada de `parser.y` (soy su pareja de respaldo).

### T2.3 Conectar semántico ↔ driver (con Dev 3) y árbol (con Dev 4)
- Sustituir los stubs por las funciones reales; quitar `stubs.c` del build.
- Sesión conjunta (~2 h): `ccheck entrada.c` corre las 3 fases → **meta del B2**.

---

## 4. Bloque 3 — Pruebas, informe y entrega (~30 %)

### T3.1 Sección léxica del informe (se entrega a Dev 4 al inicio del B3)
- Tabla de tokens: categoría, expresión regular y ejemplo.
- **Autómata finito**: AFD de identificadores/reservadas, números (int/float/mal formado) y cadenas; explicar que los tokens son lenguajes regulares (Flex → AFD).
- Ejemplo real de `tokens.txt` y de errores LEX con la recuperación.
- Manejo de línea/columna y el criterio del corte por fase.

### T3.2 Pipeline estable + README
- Correr los 4 casos de Dev 4 (`valido_general.c`, `error_lexico.c`, `error_sintactico.c`, `error_semantico.c`) y casos nuevos; corregir los fallos de integración.
- Probarlo en la PC de otro integrante.
- `README.md`: dependencias **con versiones** (`flex --version`, `bison --version`, `gcc`, `dot`), `make`, `./ccheck entrada.c`, archivos de salida y códigos de salida.
- Apoyar a Dev 4 con las capturas y el video (válido, LEX, SYN, SEM).

---

## 5. Verificación

| Prueba | Resultado esperado |
|---|---|
| `make` limpio | Sin warnings de gcc; Bison con `%expect 0` |
| Caso de columna (día 1): `int  x = 10;` con tabs y un comentario multilínea antes | Línea/columna exactas en `tokens.txt` |
| `error_lexico.c` con `@`, `9abc`, `"hola`, `#define`, `/* …` | Todos reportados, `exit 1`, nota de fases omitidas |
| `error_sintactico.c` | 1 error SYN con línea:col, `exit 2`, nota de semántica omitida |
| `error_semantico.c` | Errores SEM, `exit 3` |
| `valido_general.c` | `tokens.txt`, `arbol.txt`, `errores.txt` («sin errores»), `exit 0` |

---

## 6. Orden de ejecución propuesto
1. `Makefile` + `.gitignore` + `diag.c` + `token.h` + `stubs.c` (y un `parser.y` mínimo provisional con la lista de `%token`, si Dev 2 aún no la sube).
2. `lexer.l` completo + `tokens.txt` + errores LEX.
3. `main.c` con el corte por fase y los códigos de salida.
4. Integración con Dev 2 → Dev 3 → Dev 4.
5. README + sección léxica del informe.

> [!IMPORTANT]
> Puntos para confirmar antes de empezar:
> 1. ¿Aceptas que la lista de tokens se declare con `%token` en `parser.y` y que `token.h` incluya `parser.tab.h` (en lugar de un `enum` propio)? Hay que acordarlo con Dev 2.
> 2. ¿Aceptas el esquema de **pasada léxica completa + `yylex()` que sirve desde la tabla** para cumplir A8/A9?
> 3. ¿Las salidas se escriben en `salidas/` (como dice la estructura de carpetas) o junto al ejecutable?
> 4. ¿Creo los **stubs** y un `parser.y` mínimo provisional para poder compilar sin depender de Dev 2/3/4?
