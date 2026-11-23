%{
/*
 * lexer.l — Fase 1: análisis léxico (Dueño: Dev 1).
 *
 * - Reconoce el subconjunto de C del workpath (A3, A4, A5, A13).
 * - Cuenta línea y columna de inicio de cada token (columna desde 1; un
 *   tabulador cuenta como 1 columna; un carácter UTF-8 cuenta como 1).
 * - Guarda cada token en tabla_tokens (para tokens.txt).
 * - Reporta TODOS los errores léxicos y sigue leyendo (A9).
 *
 * Flujo: main.c llama a lexer_ejecutar() (pasada completa). Si no hubo
 * errores léxicos, Bison llama a yylex(), que entrega los tokens ya
 * guardados en la tabla con yylval/yylloc llenos.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "token.h"
#include "diag.h"

/* La función de escaneo generada por Flex se llama lex_scan(); el nombre
   yylex() queda libre para el wrapper que usa Bison (ver abajo). */
#define YY_DECL int lex_scan(void)
int lex_scan(void);

static int line_num = 1; /* posición actual del cursor */
static int col_num = 1;
static int tok_line = 1; /* posición de inicio del token actual */
static int tok_col = 1;

/* Avanza línea/columna sobre el texto reconocido. Sirve para cualquier regla,
   incluidos comentarios multilínea. Los bytes de continuación UTF-8
   (10xxxxxx) no suman columna. */
static void avanzar(const char *s, int n) {
  for (int i = 0; i < n; i++) {
    unsigned char c = (unsigned char)s[i];
    if (c == '\n') {
      line_num++;
      col_num = 1;
    } else if ((c & 0xC0) != 0x80) {
      col_num++;
    }
  }
}

/* ¿El literal (cadena o char) termina con su comilla de cierre sin escapar? */
static int literal_cerrado(const char *s, int n, char comilla) {
  int i = 1;
  while (i < n) {
    if (s[i] == '\\') { i += 2; continue; }
    if (s[i] == comilla) return i == n - 1;
    i++;
  }
  return 0;
}

/* Se ejecuta ANTES de la acción de cada regla: guarda el inicio del token
   y avanza el cursor. */
#define YY_USER_ACTION                                                         \
  tok_line = line_num;                                                         \
  tok_col = col_num;                                                           \
  avanzar(yytext, yyleng);

/* Registra el token en la tabla y lo devuelve. */
#define TOK(t)                                                                 \
  do {                                                                         \
    tabla_agregar((t), yytext, tok_line, tok_col);                             \
    return (t);                                                                \
  } while (0)

/* Reporta un error léxico en la posición de inicio del lexema. */
#define ERROR_LEX(...) reportar_error(LEX, tok_line, tok_col, __VA_ARGS__)
%}

%option noyywrap nounput noinput never-interactive 8bit

/* Resto de una línea con directiva inválida: se descarta. */
%x DIRECTIVA

DIG     [0-9]
LET     [a-zA-Z_]
ID      {LET}({LET}|{DIG})*
ARCH    [a-zA-Z0-9_/]+\.h

%%

 /* ------------------------- Directivas (A13) ------------------------- */
"#"[ \t]*"include"[ \t]*("<"{ARCH}">"|\"{ARCH}\")   { TOK(PP_INCLUDE); }

"#"[ \t]*{LET}*  {
    if (strstr(yytext, "include"))
      ERROR_LEX("#include mal formado: se esperaba <nombre.h> o \"nombre.h\"");
    else
      ERROR_LEX("directiva no soportada '%s' (solo se admite #include)", yytext);
    BEGIN(DIRECTIVA);
}
<DIRECTIVA>[^\n]+   { /* se ignora el resto de la línea */ }
<DIRECTIVA>\n       { BEGIN(INITIAL); }

 /* --------------------------- Comentarios --------------------------- */
"//"[^\n]*                          { /* comentario de una línea */ }
"/*"([^*]|\*+[^*/])*\*+"/"          { /* comentario multilínea: avanzar()
                                         ya ajustó línea y columna */ }
"/*"([^*]|\*+[^*/])*\**             { ERROR_LEX("comentario sin cerrar"); }

 /* ------------------------ Palabras reservadas ----------------------- */
"int"       { TOK(KW_INT); }
"float"     { TOK(KW_FLOAT); }
"char"      { TOK(KW_CHAR); }
"bool"      { TOK(KW_BOOL); }
"if"        { TOK(KW_IF); }
"else"      { TOK(KW_ELSE); }
"while"     { TOK(KW_WHILE); }
"for"       { TOK(KW_FOR); }
"scanf"     { TOK(KW_SCANF); }
"printf"    { TOK(KW_PRINTF); }
"return"    { TOK(KW_RETURN); }
"true"|"false"  { TOK(LIT_BOOL); }

 /* ---------------------------- Literales ---------------------------- */
{DIG}+\.{DIG}+      { TOK(LIT_FLOAT); }
{DIG}+              { TOK(LIT_INT); }
 /* Cualquier número seguido de letras, dígitos o puntos que no encaje en las
    dos reglas anteriores (9abc, 3., 1.2.3, 3.14f, 0x1F) está mal formado.
    Con igual longitud gana la regla válida porque aparece antes. */
{DIG}({DIG}|{LET}|\.)*  { ERROR_LEX("número mal formado '%s'", yytext); }
\.{DIG}+({DIG}|{LET}|\.)*  {
    ERROR_LEX("número mal formado '%s': falta la parte entera", yytext);
}

\'([^'\\\n]|\\.)\'      { TOK(LIT_CHAR); }
\'([^'\\\n]|\\.)*\\?\'?    {
    if (!literal_cerrado(yytext, yyleng, '\''))
      ERROR_LEX("literal char sin cerrar");
    else if (yyleng == 2)
      ERROR_LEX("literal char vacío ''");
    else
      ERROR_LEX("literal char con más de un carácter %s", yytext);
}

\"([^"\\\n]|\\.)*\"     { TOK(LIT_STRING); }
\"([^"\\\n]|\\.)*\\?    { ERROR_LEX("cadena sin cerrar"); }

 /* -------------------------- Identificadores ------------------------- */
{ID}        { TOK(IDENT); }

 /* --------------------------- Operadores ----------------------------- */
"+="        { TOK(OP_ADD_ASSIGN); }
"-="        { TOK(OP_SUB_ASSIGN); }
"*="        { TOK(OP_MUL_ASSIGN); }
"/="        { TOK(OP_DIV_ASSIGN); }
"=="        { TOK(OP_EQ); }
"!="        { TOK(OP_NE); }
"<="        { TOK(OP_LE); }
">="        { TOK(OP_GE); }
"&&"        { TOK(OP_AND); }
"||"        { TOK(OP_OR); }
"+"         { TOK(OP_PLUS); }
"-"         { TOK(OP_MINUS); }
"*"         { TOK(OP_MUL); }
"/"         { TOK(OP_DIV); }
"%"         { TOK(OP_MOD); }
"="         { TOK(OP_ASSIGN); }
"<"         { TOK(OP_LT); }
">"         { TOK(OP_GT); }
"!"         { TOK(OP_NOT); }
"&"         { TOK(OP_AMP); }

 /* -------------------------- Delimitadores --------------------------- */
";"         { TOK(DELIM_SEMI); }
","         { TOK(DELIM_COMMA); }
"("         { TOK(DELIM_LPAREN); }
")"         { TOK(DELIM_RPAREN); }
"{"         { TOK(DELIM_LBRACE); }
"}"         { TOK(DELIM_RBRACE); }

 /* ------------------------ Espacios en blanco ------------------------ */
[ \t\r\f\v]+    { /* avanzar() ya sumó las columnas */ }
\n              { /* avanzar() ya sumó la línea */ }

 /* ------------------- Regla final: carácter inválido ----------------- */
 /* Un carácter UTF-8 de varios bytes (ñ, ¿, á...) se reporta una sola vez. */
[\300-\377][\200-\277]*  { ERROR_LEX("carácter inválido '%s'", yytext); }
.                        { ERROR_LEX("carácter inválido '%s'", yytext); }

%%

Token *token_actual = NULL;
static size_t siguiente = 0; /* índice del próximo token para el parser */

void lexer_iniciar(FILE *entrada) {
  line_num = col_num = 1;
  tok_line = tok_col = 1;
  siguiente = 0;
  token_actual = NULL;
  yyrestart(entrada);
  BEGIN(INITIAL);
}

int lexer_ejecutar(void) {
  while (lex_scan() != 0) {
    /* cada token ya quedó registrado en tabla_tokens */
  }
  return diag_cuenta(LEX);
}

/* yylex() para Bison: entrega los tokens de la tabla y llena yylval
   (puntero al Token) y yylloc (línea/columna para errores sintácticos). */
int yylex(void) {
  if (siguiente >= tabla_tokens.n) {
    token_actual = NULL;
    yylloc.first_line = yylloc.last_line = line_num;
    yylloc.first_column = yylloc.last_column = col_num;
    return 0; /* fin de archivo */
  }
  Token *t = &tabla_tokens.v[siguiente++];
  token_actual = t;
  yylval.tok = t;
  yylloc.first_line = yylloc.last_line = t->linea;
  yylloc.first_column = t->columna;
  yylloc.last_column = t->columna + (int)strlen(t->lexema) - 1;
  return t->tipo;
}

void lexer_liberar(void) { yylex_destroy(); }
