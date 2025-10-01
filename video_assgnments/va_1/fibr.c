// gcc -Wall fibr.c -o ../target/fibr

#include <stdio.h>
#include <stdlib.h>

unsigned long fib(unsigned long);

unsigned long fib(unsigned long n) {
    if (n <=1) { return n; }
    else { return fib(n -1) + fib(n-2); }

}

int main(int argc, char *argv[]) {

    if (argc < 2 ) {
        printf("Must give value on command line\n");
        exit(EXIT_FAILURE);
    }

    unsigned long n = 0;

    n = atol(argv[1]); //askii to long

    if (n > 93 || n < 1) {
        printf("Enter a number between 1 and 93 (inclusive)\n");
        exit(EXIT_FAILURE);
    }

    printf("%6d: %lu\n", 0, 0ul); // %6d prints the first argument as a integer in a field that's 6 characters wide, right-aligned
    printf("%6d: %lu\n", 1, 1ul); // %lu Prints the second argument (0ul) as an unsigned long integer

    for (int i = 2; i <= n; i++) { printf("%6d: %lu\n", i, fib(i)); }

    return(EXIT_SUCCESS);
}