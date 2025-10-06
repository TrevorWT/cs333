/*
 * env_example.c
 *
 * Minimal examples for reading and using environment variables in C.
 * Shows:
 *  - getenv() and checking for NULL
 *  - parsing integers safely with strtol()
 *  - parsing simple booleans
 *  - using setenv() to set a variable in the process environment
 *
 * Build:
 *   gcc -Wall examples/env_example.c -o target/env_example
 *
 * Example runs (zsh/bash):
 *   MYAPP_TIMEOUT=10 MYAPP_VERBOSE=1 ./target/env_example
 *   export MYAPP_TIMEOUT=7; export MYAPP_VERBOSE=true; ./target/env_example
 */

#include <errno.h>
#include <pwd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>

/* parse integer from string with basic validation */
static int parse_int(const char *s, long *out) {
  if (!s)
    return 0;
  errno = 0;
  char *end = NULL;
  long val = strtol(s, &end, 10);
  if (errno != 0)
    return 0; /* overflow/underflow */
  if (end == s || *end != '\0')
    return 0; /* not a pure integer */
  *out = val;
  return 1;
}

/* parse boolean-ish values: "1", "0", "true", "false" (case-insensitive) */
static int parse_bool(const char *s, int *out) {
  if (!s)
    return 0;
  if (strcmp(s, "1") == 0) {
    *out = 1;
    return 1;
  }
  if (strcmp(s, "0") == 0) {
    *out = 0;
    return 1;
  }
  /* case-insensitive compare for true/false */
  if (strcasecmp(s, "true") == 0) {
    *out = 1;
    return 1;
  }
  if (strcasecmp(s, "false") == 0) {
    *out = 0;
    return 1;
  }
  return 0;
}

int main(void) {
  /* defaults */
  long timeout = 5; /* seconds */
  int verbose = 0;

  const char *s_timeout = getenv("MYAPP_TIMEOUT");
  if (parse_int(s_timeout, &timeout)) {
    /* parsed into timeout */
  } else if (s_timeout) {
    fprintf(stderr,
            "warning: MYAPP_TIMEOUT='%s' is not a valid integer, using default "
            "%ld\n",
            s_timeout, timeout);
  }

  const char *s_verbose = getenv("MYAPP_VERBOSE");
  if (!parse_bool(s_verbose, &verbose) && s_verbose) {
    fprintf(stderr,
            "warning: MYAPP_VERBOSE='%s' not recognized, using default %d\n",
            s_verbose, verbose);
  }

  /* demonstrate setting an env var in-process */
  if (setenv("MYAPP_SEEN", "1", 1) != 0) {
    perror("setenv");
  }

  printf("Configuration:\n");
  printf("  MYAPP_TIMEOUT = %ld\n", timeout);
  printf("  MYAPP_VERBOSE = %d\n", verbose);

  /* show that MYAPP_SEEN is now visible via getenv */
  printf("  MYAPP_SEEN = %s\n", getenv("MYAPP_SEEN"));

  /* Show LOGNAME (env) with sensible fallbacks */
  const char *logname = getenv("LOGNAME");
  if (!logname)
    logname = getlogin();
  if (!logname) {
    struct passwd *pw = getpwuid(getuid());
    if (pw)
      logname = pw->pw_name;
  }
  if (!logname)
    logname = "(unknown)";
  printf("  LOGNAME = %s\n", logname);

  /* example of conditional behavior */
  if (verbose) {
    printf("verbose: extra debug info...\n");
  }

  printf("running with timeout %ld seconds...\n", timeout);

  return 0;
}
