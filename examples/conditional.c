/* gcc -Wall -DDEBUG conditional.c -o ../target/conditional_debug
 * conditional.c
 *
 * Demonstrates a small pattern for conditional debug printing in C.
 * - Define DEBUG at compile time (gcc -DDEBUG) to enable debug prints.
 * - Define NDEBUG at compile time (gcc -DNDEBUG) to disable assert().
 *
 * Compile:
 *   gcc -Wall examples/conditional.c -o target/conditional
 *   gcc -Wall -DDEBUG examples/conditional.c -o target/conditional_debug
 *
 */

#include <assert.h>
#include <stdio.h>

/*
 * Conditional debug macro. When DEBUG is defined, DPRINT behaves like fprintf
 * to stderr and prepends file/line info. When DEBUG is not defined, it
 * compiles to a no-op.
 */
#ifdef DEBUG
#define DPRINT(...)                                                            \
  do {                                                                         \
    /* print: DEBUG:<file>:<func>:<line>: */                                   \
    fprintf(stderr, "DEBUG:%s:%s:%d: ", __FILE__, __func__, __LINE__);         \
    fprintf(stderr, __VA_ARGS__);                                              \
  } while (0)
#else
#define DPRINT(...)                                                            \
  do {                                                                         \
  } while (0)
#endif

int factorial(int n) {
  DPRINT("enter factorial(%d)\n", n);
  if (n <= 1) {
    DPRINT("base case %d -> 1\n", n);
    return 1;
  }
  int res = n * factorial(n - 1);
  DPRINT("return %d for factorial(%d)\n", res, n);
  return res;
}

int main(void) {
  int n = 5;

  printf("factorial(%d) = %d\n", n, factorial(n));

  DPRINT("about to run assert(n > 0)\n");
  /* assert is disabled if compiled with -DNDEBUG */
  assert(n > 0);

  printf("program finished\n");
  return 0;
}
