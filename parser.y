/*
 * parser.y — Fase 2: análisis sintáctico (Dueño: Dev 2).
 *
 * *** VERSIÓN PROVISIONAL creada por Dev 1 ***
 * Objetivo: fijar la LISTA DE TOKENS acordada (%token) y permitir compilar y
 * probar el pipeline completo (lexer → parser → semántico) mientras Dev 2
 * escribe la gramática real. La gramática de abajo solo valida:
 *     programa → includes 'int' IDENT '(' ')' bloque
 * con llaves balanceadas y cualquier secuencia de tokens dentro del bloque.
 *
 * Dev 2: reemplazar la sección de reglas por la GLC real. Conservar:
 *   - la lista de %token (con sus alias) y %union { tok; nodo; }
 *   - %locations (yylloc lo llena el lexer con línea/columna)
 *   - la variable global raiz_ast
 */
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "token.h"
#include "ast.h"
#include "diag.h"

int yylex(void);
void yyerror(const char *s);

Nodo *raiz_ast = NULL;
%}

%code requires {
  struct Token;
  struct Nodo;
}

%locations
%define parse.error custom
%define parse.lac full
%expect 0

%union {
  struct Token *tok;
  struct Nodo *nodo;
}

/* ===================== LISTA ÚNICA DE TOKENS (Dev 1 + Dev 2) ============= */
/* El alias entre comillas se usa en los mensajes de error sintáctico. */
%token <tok> KW_INT     "'int'"
%token <tok> KW_FLOAT   "'float'"
%token <tok> KW_CHAR    "'char'"
%token <tok> KW_BOOL    "'bool'"
%token <tok> KW_IF      "'if'"
%token <tok> KW_ELSE    "'else'"
%token <tok> KW_WHILE   "'while'"
%token <tok> KW_FOR     "'for'"
%token <tok> KW_SCANF   "'scanf'"
%token <tok> KW_PRINTF  "'printf'"
%token <tok> KW_RETURN  "'return'"

%token <tok> IDENT      "identificador"
%token <tok> LIT_INT    "literal entero"
%token <tok> LIT_FLOAT  "literal decimal"
%token <tok> LIT_CHAR   "literal char"
%token <tok> LIT_STRING "cadena"
%token <tok> LIT_BOOL   "literal bool"
%token <tok> PP_INCLUDE "#include"

%token <tok> OP_PLUS    "'+'"
%token <tok> OP_MINUS   "'-'"
%token <tok> OP_MUL     "'*'"
%token <tok> OP_DIV     "'/'"
%token <tok> OP_MOD     "'%'"
%token <tok> OP_ASSIGN      "'='"
%token <tok> OP_ADD_ASSIGN  "'+='"
%token <tok> OP_SUB_ASSIGN  "'-='"
%token <tok> OP_MUL_ASSIGN  "'*='"
%token <tok> OP_DIV_ASSIGN  "'/='"
%token <tok> OP_EQ      "'=='"
%token <tok> OP_NE      "'!='"
%token <tok> OP_LT      "'<'"
%token <tok> OP_GT      "'>'"
%token <tok> OP_LE      "'<='"
%token <tok> OP_GE      "'>='"
%token <tok> OP_AND     "'&&'"
%token <tok> OP_OR      "'||'"
%token <tok> OP_NOT     "'!'"
%token <tok> OP_AMP     "'&'"

%token <tok> DELIM_SEMI   "';'"
%token <tok> DELIM_COMMA  "','"
%token <tok> DELIM_LPAREN "'('"
%token <tok> DELIM_RPAREN "')'"
%token <tok> DELIM_LBRACE "'{'"
%token <tok> DELIM_RBRACE "'}'"
/* ========================================================================= */

%type <nodo> programa includes bloque items item tok_otro

/* Al abortar por error, Bison libera los subárboles que quedaron en la pila.
   OJO: Bison también "descarta" el símbolo inicial al aceptar; raiz_ast no se
   libera aquí (lo libera main.c). */
%destructor { if ($$ != raiz_ast) nodo_liberar($$); } <nodo>

%start programa

%%

programa
  : includes KW_INT IDENT DELIM_LPAREN DELIM_RPAREN bloque {
      $$ = nodo_nuevo("programa", @2.first_line, @2.first_column);
      nodo_agregar($$, $1);
      nodo_agregar($$, nodo_hoja($2));
      nodo_agregar($$, nodo_hoja($3));
      nodo_agregar($$, nodo_hoja($4));
      nodo_agregar($$, nodo_hoja($5));
      nodo_agregar($$, $6);
      raiz_ast = $$;
    }
  ;

includes
  : %empty              { $$ = nodo_nuevo("includes", 1, 1); }
  | includes PP_INCLUDE { $$ = $1; nodo_agregar($$, nodo_hoja($2)); }
  ;

bloque
  : DELIM_LBRACE items DELIM_RBRACE {
      $$ = nodo_nuevo("bloque", @1.first_line, @1.first_column);
      nodo_agregar($$, nodo_hoja($1));
      nodo_agregar($$, $2);
      nodo_agregar($$, nodo_hoja($3));
    }
  ;

items
  : %empty      { $$ = nodo_nuevo("items", 0, 0); }
  | items item  { $$ = $1; nodo_agregar($$, $2); }
  ;

item
  : bloque    { $$ = $1; }
  | tok_otro  { $$ = $1; }
  ;

/* Cualquier token salvo llaves y #include (provisional). */
tok_otro
  : KW_INT { $$ = nodo_hoja($1); } | KW_FLOAT { $$ = nodo_hoja($1); }
  | KW_CHAR { $$ = nodo_hoja($1); } | KW_BOOL { $$ = nodo_hoja($1); }
  | KW_IF { $$ = nodo_hoja($1); } | KW_ELSE { $$ = nodo_hoja($1); }
  | KW_WHILE { $$ = nodo_hoja($1); } | KW_FOR { $$ = nodo_hoja($1); }
  | KW_SCANF { $$ = nodo_hoja($1); } | KW_PRINTF { $$ = nodo_hoja($1); }
  | KW_RETURN { $$ = nodo_hoja($1); }
  | IDENT { $$ = nodo_hoja($1); } | LIT_INT { $$ = nodo_hoja($1); }
  | LIT_FLOAT { $$ = nodo_hoja($1); } | LIT_CHAR { $$ = nodo_hoja($1); }
  | LIT_STRING { $$ = nodo_hoja($1); } | LIT_BOOL { $$ = nodo_hoja($1); }
  | OP_PLUS { $$ = nodo_hoja($1); } | OP_MINUS { $$ = nodo_hoja($1); }
  | OP_MUL { $$ = nodo_hoja($1); } | OP_DIV { $$ = nodo_hoja($1); }
  | OP_MOD { $$ = nodo_hoja($1); } | OP_ASSIGN { $$ = nodo_hoja($1); }
  | OP_ADD_ASSIGN { $$ = nodo_hoja($1); } | OP_SUB_ASSIGN { $$ = nodo_hoja($1); }
  | OP_MUL_ASSIGN { $$ = nodo_hoja($1); } | OP_DIV_ASSIGN { $$ = nodo_hoja($1); }
  | OP_EQ { $$ = nodo_hoja($1); } | OP_NE { $$ = nodo_hoja($1); }
  | OP_LT { $$ = nodo_hoja($1); } | OP_GT { $$ = nodo_hoja($1); }
  | OP_LE { $$ = nodo_hoja($1); } | OP_GE { $$ = nodo_hoja($1); }
  | OP_AND { $$ = nodo_hoja($1); } | OP_OR { $$ = nodo_hoja($1); }
  | OP_NOT { $$ = nodo_hoja($1); } | OP_AMP { $$ = nodo_hoja($1); }
  | DELIM_SEMI { $$ = nodo_hoja($1); } | DELIM_COMMA { $$ = nodo_hoja($1); }
  | DELIM_LPAREN { $$ = nodo_hoja($1); } | DELIM_RPAREN { $$ = nodo_hoja($1); }
  ;

%%

/* ------------------------- Errores sintácticos ------------------------- */

/* Copia el nombre del símbolo quitando las comillas dobles del alias. */
static void nombre_simbolo(yysymbol_kind_t k, char *buf, size_t n) {
  const char *s = (k == YYSYMBOL_YYEOF) ? "fin de archivo" : yysymbol_name(k);
  size_t len = strlen(s);
  if (len >= 2 && s[0] == '"' && s[len - 1] == '"') { s++; len -= 2; }
  if (len >= n) len = n - 1;
  memcpy(buf, s, len);
  buf[len] = '\0';
}

/* Mensaje explicativo: «se esperaba X y se encontró Y» (sin modo pánico). */
static int yyreport_syntax_error(const yypcontext_t *ctx) {
  enum { MAX_ESP = 4 };
  yysymbol_kind_t esperados[YYNTOKENS];
  int total = yypcontext_expected_tokens(ctx, esperados, YYNTOKENS);
  int n = total < MAX_ESP ? total : MAX_ESP; /* solo se listan los primeros */
  const YYLTYPE *loc = yypcontext_location(ctx);

  char lista[256] = "";
  for (int i = 0; i < n; i++) {
    char nom[64];
    nombre_simbolo(esperados[i], nom, sizeof nom);
    if (i > 0) strncat(lista, (i == n - 1 && total <= MAX_ESP) ? " o " : ", ",
                       sizeof lista - strlen(lista) - 1);
    strncat(lista, nom, sizeof lista - strlen(lista) - 1);
  }
  if (total > MAX_ESP) strncat(lista, ", ...", sizeof lista - strlen(lista) - 1);

  char encontrado[80];
  if (yypcontext_token(ctx) == YYSYMBOL_YYEOF || !token_actual)
    snprintf(encontrado, sizeof encontrado, "fin de archivo");
  else
    snprintf(encontrado, sizeof encontrado, "'%s'", token_actual->lexema);

  if (n > 0)
    reportar_error(SYN, loc->first_line, loc->first_column,
                   "se esperaba %s y se encontró %s", lista, encontrado);
  else
    reportar_error(SYN, loc->first_line, loc->first_column,
                   "token inesperado %s", encontrado);
  return 0;
}

void yyerror(const char *s) {
  reportar_error(SYN, yylloc.first_line, yylloc.first_column, "%s", s);
}

/* -------------- Construcción del árbol (provisional, Dev 2) ------------- */

Nodo *nodo_nuevo(const char *nombre, int linea, int col) {
  Nodo *n = calloc(1, sizeof *n);
  if (!n) { fprintf(stderr, "ccheck: sin memoria\n"); exit(EXIT_FAILURE); }
  n->nombre = malloc(strlen(nombre) + 1);
  if (!n->nombre) { fprintf(stderr, "ccheck: sin memoria\n"); exit(EXIT_FAILURE); }
  strcpy(n->nombre, nombre);
  n->linea = linea;
  n->col = col;
  return n;
}

Nodo *nodo_hoja(Token *t) {
  Nodo *n = nodo_nuevo(nombre_token(t->tipo), t->linea, t->columna);
  n->token = t;
  return n;
}

void nodo_agregar(Nodo *padre, Nodo *hijo) {
  if (padre->nhijos == padre->cap) {
    int cap = padre->cap ? padre->cap * 2 : 4;
    Nodo **h = realloc(padre->hijos, (size_t)cap * sizeof *h);
    if (!h) { fprintf(stderr, "ccheck: sin memoria\n"); exit(EXIT_FAILURE); }
    padre->hijos = h;
    padre->cap = cap;
  }
  padre->hijos[padre->nhijos++] = hijo;
}

void nodo_liberar(Nodo *n) {
  if (!n) return;
  for (int i = 0; i < n->nhijos; i++) nodo_liberar(n->hijos[i]);
  free(n->hijos);
  free(n->nombre);
  free(n);
}
