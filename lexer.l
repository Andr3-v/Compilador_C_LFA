%{
#include "token.h"
#include "diag.h"
#include <string.h>

int line_num = 1;
int col_num = 1;

// Esta macro actualiza la columna ANTES de ejecutar la acción de cualquier regla[cite: 5, 12].
#define YY_USER_ACTION col_num += yyleng;
%}

%option noyywrap

%%

"int"       { /* Retornar token KW_INT */ }
"float"     { /* Retornar token KW_FLOAT */ }
    /* ... añadir el resto de reservadas: char, bool, if, else, while, for, scanf, printf, return ... */

"true"|"false"         { /* Retornar LIT_BOOL */ }
[0-9]+                 { /* Retornar LIT_INT */ }
[0-9]+\.[0-9]+         { /* Retornar LIT_FLOAT */ }
[a-zA-Z_][a-zA-Z0-9_]* { /* Retornar IDENT */ }

\n          { line_num++; col_num = 1; }
[ \t\r]+    { /* Ignorar espacios; YY_USER_ACTION ya sumó las columnas */ }

"//".*      { /* Ignorar comentarios de una línea[cite: 5] */ }
"/*"([^*]|\*+[^*/])*\*+"/" {
    /* Ignorar comentarios multilínea. Deberás iterar sobre yytext para ajustar line_num y col_num si hay saltos de línea internos[cite: 5]. */
}

#include[ \t]+<[a-zA-Z0-9_]+\.h>   { /* Reconocer include estándar[cite: 2, 5] */ }
#include[ \t]+\"[a-zA-Z0-9_]+\.h\" { /* Reconocer include local[cite: 2, 5] */ }
#.*         { reportar_error(LEX, line_num, col_num - yyleng, "Directiva inválida"); }

.           {
    // Regla final: atrapa caracteres inválidos, reporta y sigue leyendo[cite: 5].
    reportar_error(LEX, line_num, col_num - yyleng, "Carácter inválido");
}

%%