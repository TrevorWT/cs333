// gcc -Wall -pthread -o threads threads.c

#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

// Global variables for work distribution
int runs = 8;           // Total number of tasks to complete
int thread_count = 4;   // Number of threads to use
int next_run = 0;       // Next task to be assigned
pthread_mutex_t run_mutex = PTHREAD_MUTEX_INITIALIZER;

// Thread function
void* thread_function(void* arg) {
    int thread_id = *(int*)arg;

    while (1) {
        // Lock mutex to safely get next task
        pthread_mutex_lock(&run_mutex);

        if (next_run >= runs) {
            // No more tasks left
            pthread_mutex_unlock(&run_mutex);
            break;
        }

        // Claim this task
        int my_run = next_run;
        next_run++;

        pthread_mutex_unlock(&run_mutex);

        // Do the work (print thread ID and run number)
        printf("Thread %d: executing run %d\n", thread_id, my_run);

        // Simulate some work
        sleep(1);
    }

    printf("Thread %d: finished\n", thread_id);
    return NULL;
}

int main() {
    // Allocate arrays
    pthread_t* threads = malloc(thread_count * sizeof(pthread_t));
    int* thread_ids = malloc(thread_count * sizeof(int));

    // Create threads
    for (int i = 0; i < thread_count; i++) {
        thread_ids[i] = i;
        pthread_create(&threads[i], NULL, thread_function, &thread_ids[i]);
    }

    // Wait for all threads to finish
    for (int i = 0; i < thread_count; i++) {
        pthread_join(threads[i], NULL);
    }

    printf("\nAll work complete: %d runs across %d threads\n", runs, thread_count);

    // Clean up
    free(threads);
    free(thread_ids);
    pthread_mutex_destroy(&run_mutex);

    return 0;
}
