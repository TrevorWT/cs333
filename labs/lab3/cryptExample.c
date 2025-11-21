#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <crypt.h>

// gcc -Wall -o cryptExample cryptExample.c -lcrypt

int main(void) {

  char *hash = "$y$j6T$gB9b.BcGvyNbhO6LcxnyX8vF9krYuMRPM8G2ZrFwhxYhacG6uEogvEPHYZep8Iaw$R2tuaLUUvpuq5m240iCBBWwKk53MX4uCxNpkD1/DujA";
  char *password = "password123";
  struct crypt_data data;

  
  memset(&data, 0, sizeof(data)); // Initialize all fields to 0

  // crypt_rn(password, salt, crypt_data_struct, sizeof_crypt_data)
  char *result = crypt_rn(password, hash, &data, sizeof(data));

  if (result == NULL) {
    perror("crypt_rn failed");
    return 1;
  }

  // Compare the computed hash with the expected hash
  if (strcmp(result, hash) == 0) {
    printf("Password matches!\n");
  } else {
    printf("Password does not match.\n");
  }

  return 0;
}