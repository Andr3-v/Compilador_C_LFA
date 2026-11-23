/*
 * stubs.c — Implementaciones PROVISIONALES de las funciones de Dev 3 y Dev 4
 * (Dueño: Dev 1). Solo se compilan con `make STUBS=1` (por defecto). Cuando
 * semantico.c/interp.c (Dev 3) y arbol.c (Dev 4) estén listos: `make STUBS=0`.
 */
#include <stdio.h>

#include "fases.h"

/* ----------------------------- Dev 3 (stub) ----------------------------- */
int analizar_semantica(Nodo *raiz, FILE *out) {
  (void)raiz;
  fprintf(out, "[stub] Fase 3 pendiente (Dev 3): no se ejecutó el análisis "
               "semántico real.\n");
  return 0;
}

/* ----------------------------- Dev 4 (stub) ----------------------------- */
static void imprimir(const Nodo *n, FILE *out, int nivel) {
  for (int i = 0; i < nivel; i++) fputs("  ", out);
  if (n->token)
    fprintf(out, "%s '%s' (%d:%d)\n", n->nombre, n->token->lexema,
            n->token->linea, n->token->columna);
  else
    fprintf(out, "%s\n", n->nombre);
  for (int i = 0; i < n->nhijos; i++) imprimir(n->hijos[i], out, nivel + 1);
}

void arbol_imprimir_txt(Nodo *raiz, FILE *out) {
  if (raiz) imprimir(raiz, out, 0);
}

static void dot_escapar(const char *s, FILE *out) {
  for (; *s; s++) {
    if (*s == '"' || *s == '\\') fputc('\\', out);
    fputc(*s, out);
  }
}

static int dot_nodo(const Nodo *n, FILE *out, int *sig) {
  int id = (*sig)++;
  fprintf(out, "  n%d [label=\"", id);
  dot_escapar(n->nombre, out);
  if (n->token) {
    fputs("\\n", out);
    dot_escapar(n->token->lexema, out);
  }
  fprintf(out, "\"%s];\n", n->token ? ", shape=box" : "");
  for (int i = 0; i < n->nhijos; i++) {
    int h = dot_nodo(n->hijos[i], out, sig);
    fprintf(out, "  n%d -> n%d;\n", id, h);
  }
  return id;
}

void arbol_exportar_dot(Nodo *raiz, FILE *out) {
  int sig = 0;
  fputs("digraph arbol {\n  node [fontname=\"monospace\"];\n", out);
  if (raiz) dot_nodo(raiz, out, &sig);
  fputs("}\n", out);
}
