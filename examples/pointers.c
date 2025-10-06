#include <stdio.h>

int main() {
  int x = 42;
  int *ptr = &x; // Pointer ptr to the address of x

  printf("Value: %d\n", x);
  printf("Pointer: %p\n", ptr);
  printf("Value via pointer: %d\n", *ptr);

  return 0;
}

