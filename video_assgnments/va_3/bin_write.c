// used to create a binary file of data

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include "bin_file.h"

int main(void) {
    bin_file_t students[] = {
        {0, 3.99, "Trevor", "Thompson"},
        {0, 4.00, "Shea", "Slagle"},
        {0, 3.95, "David", "Carlen"},
        {0, 1.89, "Donald", "Trump"}
    };
    int nelms = sizeof(students) /sizeof(bin_file_t); //number of elements
    int ofd = -1;

    // Set file permissions
    mode_t old_mode = 0; // store old umask
    old_mode = umask(0); // set new umask so we can control permissions
    ofd = open(FILE_NAME, // open file for writing
        O_WRONLY | O_TRUNC | O_CREAT, // flags
        S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH); // mode
    //chmod(FILE_NAME, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH); // Or chmod

    if(ofd < 0) {
        perror("Cannot open " FILE_NAME " for output\n");
        exit(EXIT_FAILURE);
    }
    for(int i = 0; i < nelms; ++i) {
        students[i].id = i;
        write(ofd, &(students[i]), sizeof(bin_file_t));
    }

    close(ofd);
    umask(old_mode); // restore old umask
    return(EXIT_SUCCESS);
}
