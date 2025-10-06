#include <stdio.h>
#include <string.h>

// string is a null-terminated array of characters

int main() {
  char *str1;
  char str2[] = "Hello, World!";

  str1 = strdup(str2); // Duplicate str2 into str1

}