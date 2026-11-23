/* diag.c — Impresor único de errores (Dueño: Dev 1). */
#include "diag.h"

#include <stdarg.h>

static const char *archivo_fuente = "entrada.c";
static FILE *destino = NULL;
static int cuentas[3] = {0, 0, 0};

static const char *nombre_fase(FaseCompilador fase) {
  switch (fase) {
  case LEX: return "LEX";
  case SYN: return "SYN";
  case SEM: return "SEM";
  }
  return "???";
}

void diag_init(const char *archivo, FILE *errores) {
  if (archivo) archivo_fuente = archivo;
  destino = errores;
  cuentas[LEX] = cuentas[SYN] = cuentas[SEM] = 0;
}

static void emitir(FILE *out, FaseCompilador fase, int linea, int columna,
                   const char *formato, va_list ap) {
  fprintf(out, "%s:%d:%d: error[%s]: ", archivo_fuente, linea, columna,
          nombre_fase(fase));
  vfprintf(out, formato, ap);
  fputc('\n', out);
}

void reportar_error(FaseCompilador fase, int linea, int columna,
                    const char *formato, ...) {
  va_list ap;
  if (fase >= LEX && fase <= SEM) cuentas[fase]++;

  va_start(ap, formato);
  emitir(stderr, fase, linea, columna, formato, ap);
  va_end(ap);

  if (destino) {
    va_start(ap, formato);
    emitir(destino, fase, linea, columna, formato, ap);
    va_end(ap);
    fflush(destino);
  }
}

void diag_nota(const char *formato, ...) {
  va_list ap;
  va_start(ap, formato);
  vfprintf(stdout, formato, ap);
  va_end(ap);
  fputc('\n', stdout);

  if (destino) {
    va_start(ap, formato);
    vfprintf(destino, formato, ap);
    va_end(ap);
    fputc('\n', destino);
    fflush(destino);
  }
}

int diag_cuenta(FaseCompilador fase) {
  return (fase >= LEX && fase <= SEM) ? cuentas[fase] : 0;
}

int diag_total(void) { return cuentas[LEX] + cuentas[SYN] + cuentas[SEM]; }
