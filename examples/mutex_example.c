// Demonstrates protecting a shared counter with a pthread mutex.

#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define THREAD_COUNT 4
#define ITERATIONS 500000

// Shared state guarded by counter_lock. Only touch shared_counter when holding
// the mutex to keep updates atomic across threads.
static long shared_counter = 0;
static pthread_mutex_t counter_lock = PTHREAD_MUTEX_INITIALIZER;

static void *worker(void *arg) {
  // Accumulate locally to reduce time spent holding the mutex.
  long local_total = 0;
  for (int i = 0; i < ITERATIONS; ++i) {
    ++local_total;
  }

  // Serialize access to shared_counter so updates do not interleave.
  if (pthread_mutex_lock(&counter_lock) != 0) {
    perror("pthread_mutex_lock");
    pthread_exit((void *)EXIT_FAILURE);
  }

  shared_counter += local_total;

  if (pthread_mutex_unlock(&counter_lock) != 0) {
    perror("pthread_mutex_unlock");
    pthread_exit((void *)EXIT_FAILURE);
  }

  printf("Thread %ld contributed %ld; counter now %ld\n", (long)arg,
         local_total, shared_counter);

  return NULL;
}

int main(void) {
  pthread_t threads[THREAD_COUNT];

  // Spawn workers; each receives its index as an opaque pointer.
  for (intptr_t i = 0; i < THREAD_COUNT; ++i) {
    if (pthread_create(&threads[i], NULL, worker, (void *)i) != 0) {
      perror("pthread_create");
      return EXIT_FAILURE;
    }
  }

  // Wait for every worker to finish so the shared counter converges.
  for (int i = 0; i < THREAD_COUNT; ++i) {
    void *status = NULL;
    if (pthread_join(threads[i], &status) != 0) {
      perror("pthread_join");
      return EXIT_FAILURE;
    }
    if (status == (void *)EXIT_FAILURE) {
      fprintf(stderr, "worker %d exited with failure\n", i);
      return EXIT_FAILURE;
    }
  }

  if (shared_counter != THREAD_COUNT * ITERATIONS) {
    fprintf(stderr, "unexpected counter value: %ld\n", shared_counter);
    return EXIT_FAILURE;
  }

  printf("All threads done; final counter: %ld\n", shared_counter);

  if (pthread_mutex_destroy(&counter_lock) != 0) {
    perror("pthread_mutex_destroy");
    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
}
