// Demonstrates spawning THREAD_COUNT pthreads and waiting for each to finish.

#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define THREAD_COUNT 4

static void *thread_main(void *arg) {
  // Each worker prints its identifier and exits immediately.
  intptr_t id = (intptr_t)arg;
  printf("Thread %ld says hello!\n", (long)id);
  return NULL;
}

int main(void) {
  // Thread descriptors kept here so main can join later.
  pthread_t threads[THREAD_COUNT];

  // Launch all worker threads, passing their index as an argument.
  for (intptr_t i = 0; i < THREAD_COUNT; ++i) {
    if (pthread_create(&threads[i], NULL, thread_main, (void *)i) != 0) {
      // Report failure and stop if thread creation fails.
      perror("pthread_create");
      return EXIT_FAILURE;
    }
  }

  // Join each thread to ensure orderly shutdown.
  for (int i = 0; i < THREAD_COUNT; ++i) {
    pthread_join(threads[i], NULL);
  }

  return EXIT_SUCCESS;
}