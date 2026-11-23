# Interfaces entre módulos y guía de integración

Responsable del documento: **Dev 1** (lexer y driver). Si alguien necesita
cambiar una interfaz, lo avisa en el grupo y lo aprueban su dueño y quienes la
usan (workpath, sección 3).

## 1. Decisiones tomadas por Dev 1

| # | Decisión | Motivo |
|---|---|---|
| D1 | La **lista de tokens** se declara una sola vez con `%token` en `parser.y`. `token.h` incluye el `parser.tab.h` que genera Bison. | Flex y Bison no pueden desincronizarse (riesgo n.º 1 del workpath). |
| D2 | **Pasada léxica completa** antes del parser: `lexer_ejecutar()` recorre todo el archivo y guarda los tokens en `tabla_tokens`. Después, el `yylex()` que llama Bison **entrega los tokens desde la tabla**. | Cumple A8 (con errores léxicos no corre el parser) y A9 (el lexer reporta todos sus errores). El archivo se lee una sola vez y `tokens.txt` siempre queda completo. |
| D3 | Flex genera `lex_scan()` (`YY_DECL`); el nombre `yylex()` queda libre para el wrapper. | Dev 2 usa el `yylex()` estándar sin cambiar nada. |
| D4 | `%locations`: el lexer llena `yylloc` (línea/col de inicio) para cada token. | Los errores SYN salen con línea y columna exactas. |
| D5 | `reportar_error()` acepta formato estilo `printf`. | Dev 2 y Dev 3 arman sus mensajes sin `sprintf` intermedio. |
| D6 | Las salidas van a `salidas/` (o a la carpeta de `-o`). | Estructura de carpetas del workpath. |
| D7 | Columnas: empiezan en 1; un tabulador = 1 columna; un carácter UTF-8 = 1 columna. | Regla simple y verificable (`pruebas/dev1/columnas.c`). |
| D8 | `parser.y`, `ast.h` y `stubs.c` **provisionales** para integrar desde ya. | Nadie se queda esperando el módulo de otro. |

## 2. `token.h` (Dev 1) — lo usan Dev 2 y Dev 4

```c
struct Token { int tipo; char *lexema; int linea; int columna; };
typedef struct Token Token;

extern TablaTokens tabla_tokens;          // todos los tokens en orden
const char *nombre_token(int tipo);       // "KW_INT", "IDENT", ...
extern Token *token_actual;               // último token entregado al parser
```

### Lista de tokens (congelada)

| Categoría | Token | Lexema |
|---|---|---|
| Reservadas | `KW_INT KW_FLOAT KW_CHAR KW_BOOL KW_IF KW_ELSE KW_WHILE KW_FOR KW_SCANF KW_PRINTF KW_RETURN` | `int float char bool if else while for scanf printf return` |
| Literales | `LIT_INT` `LIT_FLOAT` `LIT_CHAR` `LIT_STRING` `LIT_BOOL` | `10` `3.14` `'a'` `"hola\n"` `true/false` |
| Identificador | `IDENT` | `suma`, `main` (main **no** es reservada) |
| Directiva | `PP_INCLUDE` | `#include <stdio.h>` / `#include "util.h"` (lexema completo) |
| Aritméticos | `OP_PLUS OP_MINUS OP_MUL OP_DIV OP_MOD` | `+ - * / %` |
| Asignación | `OP_ASSIGN OP_ADD_ASSIGN OP_SUB_ASSIGN OP_MUL_ASSIGN OP_DIV_ASSIGN` | `= += -= *= /=` |
| Relacionales | `OP_EQ OP_NE OP_LT OP_GT OP_LE OP_GE` | `== != < > <= >=` |
| Lógicos / dirección | `OP_AND OP_OR OP_NOT OP_AMP` | `&& \|\| ! &` |
| Delimitadores | `DELIM_SEMI DELIM_COMMA DELIM_LPAREN DELIM_RPAREN DELIM_LBRACE DELIM_RBRACE` | `; , ( ) { }` |

Notas:
- El `-` unario y el binario son el mismo token (`OP_MINUS`); la gramática los distingue.
- Los lexemas de `LIT_CHAR` y `LIT_STRING` incluyen las comillas y las secuencias de escape sin procesar (`'\n'`, `"x = %d\n"`). Dev 3 lee el formato de `printf` desde ahí.

## 3. `diag.h` (Dev 1) — lo usan todos

```c
typedef enum { LEX, SYN, SEM } FaseCompilador;
void reportar_error(FaseCompilador fase, int linea, int columna, const char *fmt, ...);
int  diag_cuenta(FaseCompilador fase);
```
Formato único: `entrada.c:7:12: error[SYN]: se esperaba ';' y se encontró 'printf'`.
Se escribe en `errores.txt` y en `stderr`, y se cuenta por fase. **Nadie debe
imprimir errores por su cuenta**: siempre `reportar_error()`.

## 4. Lo que Dev 2 debe conservar en `parser.y`

```bison
%code requires { struct Token; struct Nodo; }
%locations
%union { struct Token *tok; struct Nodo *nodo; }
%token <tok> KW_INT "'int'" ...      /* la lista completa de tokens, con sus alias */
%expect 0
Nodo *raiz_ast;                       /* raíz del árbol al terminar sin errores */
```
- Cada terminal llega como `Token *` (`$1->lexema`, `$1->linea`, `$1->columna`); `@1` también tiene la posición.
- Los alias entre comillas (`"'int'"`, `"identificador"`) ya se usan en el mensaje
  «se esperaba X y se encontró Y» del `yyreport_syntax_error` provisional; Dev 2 puede reutilizarlo tal cual.
- `%destructor { if ($$ != raiz_ast) nodo_liberar($$); } <nodo>` evita fugas al abortar.
  (Bison también descarta el símbolo inicial al aceptar, por eso se excluye `raiz_ast`).
- Si Dev 2 reemplaza `ast.h`, debe conservar `Nodo`, `raiz_ast`, `nodo_liberar()` y los campos
  `nombre`, `token`, `hijos`, `nhijos`, `linea`, `col`, `tipo` (los usan main.c, Dev 3 y Dev 4).
  Si mueve las funciones del árbol a un `ast.c`, hay que agregarlo a `SRC` en el Makefile.

## 5. Funciones que llama `main.c` (`fases.h`)

```c
int  analizar_semantica(Nodo *raiz, FILE *out); // Dev 3: devuelve n.º de errores SEM;
                                                //        interpretación simbólica en `out`
void arbol_imprimir_txt(Nodo *raiz, FILE *out); // Dev 4: arbol.txt
void arbol_exportar_dot(Nodo *raiz, FILE *out); // Dev 4: arbol.dot
```

## 6. Pasos de integración

1. **Dev 2:** reemplazar la sección de reglas de `parser.y` por la GLC real (sección 4 de este documento). `make` debe mostrar 0 conflictos.
2. **Dev 3:** implementar `analizar_semantica()` en `semantico.c`/`interp.c` (sin `main` propio).
3. **Dev 4:** implementar `arbol_imprimir_txt()` y `arbol_exportar_dot()` en `arbol.c`.
4. Cuando los tres existan: `make clean && make STUBS=0`. Si solo falta uno, se puede
   copiar su función provisional de `stubs.c` temporalmente.
5. `make test` con los 4 casos mínimos de `pruebas/` (válido, léxico, sintáctico, semántico).
