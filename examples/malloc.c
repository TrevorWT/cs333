#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <string.h>

int main(void) {
    printf("%zu\n", sizeof(char));   // sizeof returns size_t; char is always 1 byte


    const char *src = "hello";
    char *copy = strdup(src);       // or _strdup(src) on MSVC
    if (!copy) { perror("strdup"); return 1; }

    printf("%s\n", copy);
    free(copy);                     // always free
    return 0;
}
