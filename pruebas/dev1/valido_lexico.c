#include <stdio.h>
#include "util.h"

int main() {
    int suma = 10;
    float prom = 2.5;
    char letra = 'a';
    bool ok = false;
    for (int i = 0; i < 3; i += 1) {
        suma = suma + i * 2 % 3;
    }
    while (suma > 0) { suma -= 1; }
    if (ok == false) { printf("Suma = %d\n", suma); } else { scanf("%f", &prom); }
    return 0;
}
