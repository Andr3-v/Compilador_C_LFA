#ifndef AST_H
#define AST_H
/*
 * ast.h — Interfaz del árbol de derivación (Dueño: Dev 2).
 *
 * *** VERSIÓN PROVISIONAL creada por Dev 1 para poder compilar e integrar el
 * driver. Dev 2 puede reemplazarla; solo se pide conservar el tipo Nodo y la
 * variable raiz_ast, que usan main.c, el semántico (Dev 3) y arbol.c (Dev 4).
 *
 * Campos según la sección 3 del workpath: {nombre, token, hijos, línea, col, tipo}.
 */
#include "token.h"

typedef struct Nodo {
  char *nombre;         /* no terminal ("programa", "bloque"...) o nombre del token */
  Token *token;         /* != NULL solo en las hojas (terminales) */
  struct Nodo **hijos;  /* hijos en orden de la producción */
  int nhijos;
  int cap;
  int linea, col;       /* posición en el fuente */
  int tipo;             /* tipo semántico; lo llena Dev 3 (types.h) */
} Nodo;

extern Nodo *raiz_ast; /* la deja yyparse() al terminar sin errores */

Nodo *nodo_nuevo(const char *nombre, int linea, int col);
Nodo *nodo_hoja(Token *t);
void nodo_agregar(Nodo *padre, Nodo *hijo);
void nodo_liberar(Nodo *n);

#endif
