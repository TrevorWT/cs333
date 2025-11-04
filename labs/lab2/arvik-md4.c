
#include <stdio.h>
#include <getopt.h>
#include <stdlib.h>
#include <stdbool.h>
#include <md4.h>
#include "header.h" // replace in final 

// Useage: arvik-md4 <options> [-f archive-file] [member [...]]
// Exactly one of -x, -c, -t, or -V must be present.
// member... are optional filenames (for -c).
static void usage(const char *prog, int exitStatus) {
  fprintf(stderr,
         "Usage: %s [-h] [-v] [-f archive] [-x | -c | -t | -V] [member...]\n"
          "  -x           Extract members from arvik file.\n"
          "  -c           Create an arvik style archive file.\n"
          "  -t           Show table of contents.\n"
          "  -h           Show the help text and exit.\n"
          "  -v           Verbose processing.\n"
          "  -V           Validate the md4 value for header and data.\n"
          "  -f <file>    Specify the name of the arvik file on which to operate.\n",
          prog);

	switch (exitStatus) {
		case 0: exit(EXIT_SUCCESS);
		case 1: exit(EXIT_FAILURE);
	}

}

int main(int argc, char *argv[]) {
  int opt;
	bool extract = false;
	bool create = false;
	bool table = false;
	bool verbose = false;

	if (argc < 2) usage(argv[0], 1);

	{
		while ((opt = getopt(argc, argv, "xcthvVf:")) != -1) {
			switch (opt) {
			case 'x':
				extract = true;
				printf("%i\n", extract);
				break;
			case 'c':
				create = true;
				printf("%i\n", create);
				break;
			case 't':
				table = true;
				printf("%i\n", table);
				break;
			case 'h':
				usage(argv[0], 0);
				break;
			case 'v':
				verbose = true;
				printf("%i\n", verbose);
				break;
			case 'V':
				break;
			case 'f':
				break;
			}
		}
	}


	exit(EXIT_SUCCESS);
}
