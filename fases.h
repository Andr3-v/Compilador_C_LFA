#ifndef FASES_H
#define FASES_H
/*
 * fases.h — Contratos que consume el driver main.c (Dueño: Dev 1).
 *
 * Cada función la implementa el dueño de su módulo. Mientras no existan,
 * stubs.c da versiones provisionales (make STUBS=1, el valor por defecto).
 *
 *   Dev 2 (parser.y): int yyparse(void);  Nodo *raiz_ast;   (ver ast.h)
 *   Dev 3 (semantico.c / interp.c): analizar_semantica()
 *   Dev 4 (arbol.c): arbol_imprimir_txt(), arbol_exportar_dot()
 */
#include <stdio.h>

#include "ast.h"

/* Fase 3. Recorre el árbol, reporta los errores con reportar_error(SEM, ...),
   imprime la interpretación simbólica en `out` (la pantalla) y devuelve el
   número de errores semánticos encontrados. */
int analizar_semantica(Nodo *raiz, FILE *out);

/* Árbol de derivación en texto con sangrías (arbol.txt). */
void arbol_imprimir_txt(Nodo *raiz, FILE *out);

/* Árbol en formato Graphviz (arbol.dot); reutiliza el mismo recorrido. */
void arbol_exportar_dot(Nodo *raiz, FILE *out);

#endif
