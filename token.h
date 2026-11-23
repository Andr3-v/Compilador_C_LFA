#ifndef TOKEN_H
#define TOKEN_H

typedef struct {
  int tipo;     // ID token generardo enn Bison
  char *lexema; // texto original
  int linea;    // linea que aparece
  int columna;  // columna exacta de inicio
} Token;

#endif
