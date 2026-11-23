#ifndef DIAG_H
#define DIAG_H

typedef enum { LEX, SYN, SEM } FaseCompilador;

// funcion unica para reportar reportar errores de manera centralizada
void reportar_error(FaseCompilador fase, int linea, int columna,
                    const char *mensaje);

#endif