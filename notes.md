# Notes

## Compile C code
    gcc -Wall file.c -o ../target/outputName

## Compress file
### Create
    tar cvfa ${LOGNAME}_fib.tar.gz *.c

### Validate
    tar tvfa ${LOGNAME}_fib.tar.gz

## New libraries
### gmp
    Compilation flag: -lgmp
    #include <gmp.h>
    Allows for new number variables that are arbetrary length.
