#ifndef TOKEN_H
#define TOKEN_H
/*
 * token.h — Interfaz congelada del lexer (Dueño: Dev 1). La usan Dev 2 y Dev 4.
 *
 * La LISTA DE TOKENS se declara una sola vez con %token en parser.y; Bison la
 * genera en parser.tab.h (enum yytokentype). Este header la incluye, así Flex
 * y Bison siempre usan los mismos números de token.
 */
#include <stddef.h>
#include <stdio.h>

/* Un token reconocido por el lexer. */
struct Token {
  int tipo;     /* ID del token generado por Bison (KW_INT, IDENT, ...) */
  char *lexema; /* texto original (copia propia) */
  int linea;    /* línea en la que empieza (desde 1) */
  int columna;  /* columna exacta de inicio (desde 1) */
};
typedef struct Token Token;

#include "parser.tab.h" /* enum yytokentype + YYSTYPE/YYLTYPE */

/* ---------------- Tabla de tokens (Fase 1 → tokens.txt) ---------------- */
typedef struct {
  Token *v;   /* arreglo dinámico de tokens en orden de aparición */
  size_t n;   /* número de tokens */
  size_t cap; /* capacidad reservada */
} TablaTokens;

extern TablaTokens tabla_tokens;

void tabla_agregar(int tipo, const char *lexema, int linea, int columna);
void tabla_liberar(void);

/* Nombre del token para tokens.txt y mensajes ("KW_INT", "IDENT", ...). */
const char *nombre_token(int tipo);

/* Escribe la tabla con el formato de la sección 9 del workpath. */
void tokens_escribir(FILE *out);

/* ---------------- API del lexer (implementada en lexer.l) --------------- */
void lexer_iniciar(FILE *entrada); /* reinicia línea/columna y estado     */
int lexer_ejecutar(void);          /* pasada léxica completa; devuelve el
                                      número de errores léxicos            */
int yylex(void);                   /* lo llama Bison: entrega los tokens
                                      ya guardados en tabla_tokens         */
void lexer_liberar(void);

/* Último token entregado al parser (NULL en fin de archivo). Útil para que
   Dev 2 arme el mensaje «se esperaba X y se encontró Y». */
extern Token *token_actual;

#endif
