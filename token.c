/* token.c — Tabla de tokens y escritura de tokens.txt (Dueño: Dev 1). */
#include "token.h"

#include <stdlib.h>
#include <string.h>

TablaTokens tabla_tokens = {NULL, 0, 0};

static char *duplicar(const char *s) {
  size_t n = strlen(s) + 1;
  char *p = malloc(n);
  if (!p) {
    fprintf(stderr, "ccheck: sin memoria\n");
    exit(EXIT_FAILURE);
  }
  memcpy(p, s, n);
  return p;
}

void tabla_agregar(int tipo, const char *lexema, int linea, int columna) {
  if (tabla_tokens.n == tabla_tokens.cap) {
    size_t cap = tabla_tokens.cap ? tabla_tokens.cap * 2 : 128;
    Token *v = realloc(tabla_tokens.v, cap * sizeof *v);
    if (!v) {
      fprintf(stderr, "ccheck: sin memoria\n");
      exit(EXIT_FAILURE);
    }
    tabla_tokens.v = v;
    tabla_tokens.cap = cap;
  }
  Token *t = &tabla_tokens.v[tabla_tokens.n++];
  t->tipo = tipo;
  t->lexema = duplicar(lexema);
  t->linea = linea;
  t->columna = columna;
}

void tabla_liberar(void) {
  for (size_t i = 0; i < tabla_tokens.n; i++) free(tabla_tokens.v[i].lexema);
  free(tabla_tokens.v);
  tabla_tokens.v = NULL;
  tabla_tokens.n = tabla_tokens.cap = 0;
}

const char *nombre_token(int tipo) {
  switch (tipo) {
  /* Palabras reservadas */
  case KW_INT: return "KW_INT";
  case KW_FLOAT: return "KW_FLOAT";
  case KW_CHAR: return "KW_CHAR";
  case KW_BOOL: return "KW_BOOL";
  case KW_IF: return "KW_IF";
  case KW_ELSE: return "KW_ELSE";
  case KW_WHILE: return "KW_WHILE";
  case KW_FOR: return "KW_FOR";
  case KW_SCANF: return "KW_SCANF";
  case KW_PRINTF: return "KW_PRINTF";
  case KW_RETURN: return "KW_RETURN";
  /* Identificadores, literales y directivas */
  case IDENT: return "IDENT";
  case LIT_INT: return "LIT_INT";
  case LIT_FLOAT: return "LIT_FLOAT";
  case LIT_CHAR: return "LIT_CHAR";
  case LIT_STRING: return "LIT_STRING";
  case LIT_BOOL: return "LIT_BOOL";
  case PP_INCLUDE: return "PP_INCLUDE";
  /* Operadores aritméticos */
  case OP_PLUS: return "OP_PLUS";
  case OP_MINUS: return "OP_MINUS";
  case OP_MUL: return "OP_MUL";
  case OP_DIV: return "OP_DIV";
  case OP_MOD: return "OP_MOD";
  /* Asignación */
  case OP_ASSIGN: return "OP_ASSIGN";
  case OP_ADD_ASSIGN: return "OP_ADD_ASSIGN";
  case OP_SUB_ASSIGN: return "OP_SUB_ASSIGN";
  case OP_MUL_ASSIGN: return "OP_MUL_ASSIGN";
  case OP_DIV_ASSIGN: return "OP_DIV_ASSIGN";
  /* Relacionales */
  case OP_EQ: return "OP_EQ";
  case OP_NE: return "OP_NE";
  case OP_LT: return "OP_LT";
  case OP_GT: return "OP_GT";
  case OP_LE: return "OP_LE";
  case OP_GE: return "OP_GE";
  /* Lógicos y dirección */
  case OP_AND: return "OP_AND";
  case OP_OR: return "OP_OR";
  case OP_NOT: return "OP_NOT";
  case OP_AMP: return "OP_AMP";
  /* Delimitadores */
  case DELIM_SEMI: return "DELIM_SEMI";
  case DELIM_COMMA: return "DELIM_COMMA";
  case DELIM_LPAREN: return "DELIM_LPAREN";
  case DELIM_RPAREN: return "DELIM_RPAREN";
  case DELIM_LBRACE: return "DELIM_LBRACE";
  case DELIM_RBRACE: return "DELIM_RBRACE";
  }
  return "DESCONOCIDO";
}

void tokens_escribir(FILE *out) {
  /* Ancho de la columna LEXEMA: mínimo 10 (formato del workpath) o el
     lexema más largo, para que la tabla quede alineada. */
  int ancho = 10;
  for (size_t i = 0; i < tabla_tokens.n; i++) {
    int len = (int)strlen(tabla_tokens.v[i].lexema);
    if (len > ancho) ancho = len;
  }
  /* "LÍNEA" ocupa 6 bytes en UTF-8 (5 caracteres visibles): se rellena a 10. */
  fprintf(out, "%-18s %-*s %-10s %s\n", "# TIPO", ancho, "LEXEMA", "LÍNEA",
          "COL");
  for (size_t i = 0; i < tabla_tokens.n; i++) {
    const Token *t = &tabla_tokens.v[i];
    fprintf(out, "%-18s %-*s %-9d %d\n", nombre_token(t->tipo), ancho,
            t->lexema, t->linea, t->columna);
  }
}
