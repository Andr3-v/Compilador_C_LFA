#ifndef DIAG_H
#define DIAG_H
/*
 * diag.h — Interfaz congelada de diagnósticos (Dueño: Dev 1). La usan todos.
 *
 * Un solo formato de error para las tres fases (decisión A7):
 *     archivo:línea:col: error[FASE]: mensaje
 * Cada error se escribe en errores.txt y en stderr, y se cuenta por fase
 * para que main.c aplique el corte por fase (decisión A8).
 */
#include <stdio.h>

typedef enum { LEX, SYN, SEM } FaseCompilador;

/* Configura el nombre del archivo fuente y el destino (errores.txt). */
void diag_init(const char *archivo, FILE *errores);

/* Función única para reportar errores. Acepta formato estilo printf:
     reportar_error(SYN, l, c, "se esperaba %s y se encontró '%s'", a, b); */
void reportar_error(FaseCompilador fase, int linea, int columna,
                    const char *formato, ...)
    __attribute__((format(printf, 4, 5)));

/* Línea informativa (sin formato de error) en errores.txt y stdout.
   Ej.: «Fases sintáctica y semántica omitidas por errores léxicos». */
void diag_nota(const char *formato, ...) __attribute__((format(printf, 1, 2)));

int diag_cuenta(FaseCompilador fase); /* errores reportados en esa fase */
int diag_total(void);                 /* errores de todas las fases     */

#endif
