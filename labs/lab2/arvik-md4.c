#define _POSIX_C_SOURCE 200809L

#include <stdio.h>
#include <getopt.h>
#include <stdlib.h>
#include <stdbool.h>
#include <md4.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/stat.h>
#include <time.h>
#include "header.h" // replace in final

// -rw-rw-r--
#ifndef ARVIK_CREATE_MODE
#  define ARVIK_CREATE_MODE 0664
#endif

// Usage: arvik-md4 <options> [-f archive-file] [member [...]]
// Exactly one of -x, -c, -t, or -V must be present.
// member... are optional filenames (for -c).

static void usage(const char *prog);
static void die(int code, const char *msg);
static int writeAll(int fd, const void *buf, size_t len);
static int createArchive(int outFd, int memberCount, char **members, bool verbose);
static int openArchiveForWrite(const char *path);
static int openArchiveForRead(const char *path);
static int tableOfContents(int inFd, bool verbose);

static void usage(const char *prog) {
	fprintf(stderr,
		"Usage: %s -[cxtvVf:h] archive-file file...\n"
		"\t-c           create a new archive file\n"
		"\t-x           extract members from an existing archive file\n"
		"\t-t           show the table of contents of archive file\n"
		"\t-f filename  name of archive file to use\n"
		"\t-V           Validate the md4 values for the header and data\n"
		"\t-v           verbose output\n"
		"\t-h           show help text\n",
		prog);

	exit(EXIT_SUCCESS);
}

static void die(int code, const char *msg) {
	fputs(msg, stderr);
	exit(code);
}

static int writeAll(int fd, const void *buf, size_t len) {
	const unsigned char *p;
	ssize_t n;

	p = (const unsigned char *) buf;
	while (len) {
		n = write(fd, p, len);
		if (n < 0) {
			if (errno == EINTR) {
				continue;
			}
			return -1;
		}
		p += (size_t) n;
		len -= (size_t) n;
	}
	return 0;
}

static int createArchive(int outFd, int memberCount, char **members, bool verbose) {
	// Always start with the tag
	if (writeAll(outFd, ARVIK_TAG, strlen(ARVIK_TAG)) < 0) {
		perror("write tag");
		return CREATE_FAIL;
	}

	if (memberCount == 0) return 0;

	// NEXT STEP: for each member → build fixed-width header, stream data while MD4'ing, write footer.
	for(int i = 0; i < memberCount; ++i) {
		// File I/O
		int memberFd;
		struct stat st;
		unsigned char buf[4096];
		ssize_t n;

		// Header
		arvik_header_t hdr;
		const char *filename;
		int nameLen;

		// MD4 for header
		MD4_CTX ctx_hdr;
		unsigned char md4_hdr_bin[MD4_DIGEST_LENGTH];
		char md4_hdr_hex[MD4_DIGEST_LENGTH * 2];

		// MD4 for data
		MD4_CTX ctx_data;
		unsigned char md4_data_bin[MD4_DIGEST_LENGTH];
		char md4_data_hex[MD4_DIGEST_LENGTH * 2];

		// Footer
		arvik_footer_t ftr;

		// Loop index
		int j;

		memberFd = open(members[i], O_RDONLY);
		if (memberFd < 0) {
			perror(members[i]);
			return CREATE_FAIL;
		}

		if (fstat(memberFd, &st) < 0) {
			perror("fstat");
			close(memberFd);
			return CREATE_FAIL;
		}

		memset(&hdr, ' ', sizeof(hdr));
		filename = members[i];
		nameLen = strlen(filename);

		if (nameLen > ARVIK_NAME_LEN - 1) nameLen = ARVIK_NAME_LEN - 1;
		memcpy(hdr.arvik_name, filename, nameLen);
		hdr.arvik_name[nameLen] = ARVIK_NAME_TERM;

		/* Write numbers directly, then clear the null terminator */
		sprintf(hdr.arvik_date, "%ld", st.st_mtime);
		hdr.arvik_date[strlen(hdr.arvik_date)] = ' ';

		sprintf(hdr.arvik_uid, "%d", st.st_uid);
		hdr.arvik_uid[strlen(hdr.arvik_uid)] = ' ';

		sprintf(hdr.arvik_gid, "%d", st.st_gid);
		hdr.arvik_gid[strlen(hdr.arvik_gid)] = ' ';

		sprintf(hdr.arvik_mode, "%o", st.st_mode);
		hdr.arvik_mode[strlen(hdr.arvik_mode)] = ' ';

		sprintf(hdr.arvik_size, "%ld", st.st_size);
		hdr.arvik_size[strlen(hdr.arvik_size)] = ' ';

		memcpy(hdr.arvik_term, ARVIK_TERM, sizeof(hdr.arvik_term));

		MD4Init(&ctx_hdr);
		MD4Update(&ctx_hdr, (unsigned char*)&hdr, sizeof(hdr));
		MD4Final(md4_hdr_bin, &ctx_hdr);

		// Convert binary MD4 to hex string (no 0x prefix)
		for (j = 0; j < MD4_DIGEST_LENGTH; j++) {
			static const char hex[] = "0123456789abcdef";
			md4_hdr_hex[j * 2] = hex[(md4_hdr_bin[j] >> 4) & 0xF];
			md4_hdr_hex[j * 2 + 1] = hex[md4_hdr_bin[j] & 0xF];
		}

		// Write the header
		if (writeAll(outFd, &hdr, sizeof(hdr)) < 0) {
			perror("write header");
			close(memberFd);
			return CREATE_FAIL;
		}
		// Stream file data while computing MD4
		MD4Init(&ctx_data);

		while ((n = read(memberFd, buf, sizeof(buf))) > 0) {
			MD4Update(&ctx_data, buf, (size_t)n);
			if (writeAll(outFd, buf, (size_t)n) < 0) {
				perror("write data");
				close(memberFd);
				return CREATE_FAIL;
			}
		}

		if (n < 0) {
			perror("read member");
			close(memberFd);
			return CREATE_FAIL;
		}

		MD4Final(md4_data_bin, &ctx_data);

		// Convert data MD4 to hex
		for (j = 0; j < MD4_DIGEST_LENGTH; j++) {
			static const char hex[] = "0123456789abcdef";
			md4_data_hex[j * 2] = hex[(md4_data_bin[j] >> 4) & 0xF];
			md4_data_hex[j * 2 + 1] = hex[md4_data_bin[j] & 0xF];
		}

		close(memberFd);

		memcpy(ftr.md4sum_header, md4_hdr_hex, MD4_DIGEST_LENGTH * 2); // Header MD4 checksum
		memcpy(ftr.md4sum_data, md4_data_hex, MD4_DIGEST_LENGTH * 2); // Data MD4 checksum
		memcpy(ftr.arvik_term, ARVIK_TERM, sizeof(ftr.arvik_term)); // Terminator

		if (writeAll(outFd, &ftr, sizeof(ftr)) < 0) {
			perror("write footer");
			return CREATE_FAIL;
		}

		if (verbose) fprintf(stderr, "added %s\n", members[i]);
	}

	return 0;
}

static int openArchiveForWrite(const char *path) {
	struct stat st;
	int existed;
	int flags;
	int fd;

	if (!path) return STDOUT_FILENO;

	existed = (stat(path, &st) == 0);
	flags = O_WRONLY | O_TRUNC;

	if (existed) {
		fd = open(path, flags);
	} else {
		// ensure perms = 0664 regardless of umask
		fd = open(path, O_WRONLY | O_CREAT | O_TRUNC, ARVIK_CREATE_MODE);
		if (fd >= 0) {
			// In case umask interfered, force perms
			(void)fchmod(fd, ARVIK_CREATE_MODE);
		}
	}

	if (fd < 0) {
		fprintf(stderr, "Cannot open '%s' for write: %s\n", path ? path : "<stdout>", strerror(errno));
	}
	return fd;
}

static int openArchiveForRead(const char *path) {
	int fd;

	if (!path) return STDIN_FILENO;
	fd = open(path, O_RDONLY);
	if (fd < 0) fprintf(stderr, "Cannot open '%s' for read: %s\n", path, strerror(errno));
	return fd;
}

static int tableOfContents(int inFd, bool verbose){
	char tag[11];  // ARVIK_TAG is 10 bytes + null terminator for safety
	ssize_t n;

	// Read and verify the tag
	n = read(inFd, tag, strlen(ARVIK_TAG));
	if (n < (ssize_t)strlen(ARVIK_TAG)) {
		if (n == 0) {
			fprintf(stderr, "Empty archive\n");
		} else {
			fprintf(stderr, "Incomplete archive tag\n");
		}
		return TOC_FAIL;
	}

	if (memcmp(tag, ARVIK_TAG, strlen(ARVIK_TAG)) != 0) {
		fprintf(stderr, "Bad archive tag\n");
		return BAD_TAG;
	}

	// Loop through members
	while (1) {
		arvik_header_t hdr;
		arvik_footer_t ftr;
		off_t fileSize;
		char filename[ARVIK_NAME_LEN + 1];
		int i;

		// Try to read a header
		n = read(inFd, &hdr, sizeof(hdr));
		if (n == 0) {
			// End of archive - normal exit
			break;
		}
		if (n < (ssize_t)sizeof(hdr)) {
			fprintf(stderr, "Incomplete header\n");
			return TOC_FAIL;
		}

		// Verify header terminator
		if (memcmp(hdr.arvik_term, ARVIK_TERM, sizeof(hdr.arvik_term)) != 0) {
			fprintf(stderr, "Bad header terminator\n");
			return TOC_FAIL;
		}

		// Extract filename (it's space-padded, terminated with '<')
		for (i = 0; i < ARVIK_NAME_LEN && hdr.arvik_name[i] != ARVIK_NAME_TERM; i++) {
			filename[i] = hdr.arvik_name[i];
		}
		filename[i] = '\0';

		// Parse file size
		fileSize = atol(hdr.arvik_size);

		// Print the entry (verbose or short format)
		if (verbose) {
			// Long format: mode uid gid size date filename
			time_t mtime = atol(hdr.arvik_date);
			struct tm *tm = localtime(&mtime);
			char dateStr[32];
			mode_t mode = strtol(hdr.arvik_mode, NULL, 8);
			uid_t uid = atoi(hdr.arvik_uid);
			gid_t gid = atoi(hdr.arvik_gid);

			strftime(dateStr, sizeof(dateStr), "%b %e %R %Y", tm);
			printf("%06o %5d %5d %8ld %s %s\n", mode, uid, gid, (long)fileSize, dateStr, filename);
		} else {
			// Short format: just filename
			printf("%s\n", filename);
		}

		// Skip over file data
		if (lseek(inFd, fileSize, SEEK_CUR) < 0) {
			perror("lseek data");
			return TOC_FAIL;
		}

		// Skip over footer
		n = read(inFd, &ftr, sizeof(ftr));
		if (n < (ssize_t)sizeof(ftr)) {
			fprintf(stderr, "Incomplete footer\n");
			return TOC_FAIL;
		}
	}

	return 0;
}







































int main(int argc, char *argv[]) {
  int opt;
	bool extract = false;
	bool create = false;
	bool table = false;
	bool validate = false;
	bool verbose = false;
	int action = 0;
	char *archiveFile = NULL;

	if (argc < 2) die(NO_ACTION_GIVEN, "No action given.\n");

	while ((opt = getopt(argc, argv, "xcthvVf:")) != -1) {
		switch (opt) {
		case 'x':
			extract = true;
			break;
		case 'c':
			create = true;
			break;
		case 't':
			table = true;
			break;
		case 'h':
			usage(argv[0]);
			break;
		case 'v':
			verbose = true;
			break;
		case 'V':
			validate = true;
			break;
		case 'f':
			archiveFile = optarg;
			break;
		default:
			die(INVALID_CMD_OPTION, "Usage: ./arvik-md4 cxtvVf:h\n");
		}
	}

	action = extract + create + table + validate;
	if (action != 1) die(INVALID_CMD_OPTION, "Exactly one of -x, -c, -t, or -V must be specified.\n");

	if (create) {
		int outFd = openArchiveForWrite(archiveFile);
		int memberCount;
		char **members;
		int rc;

		if (outFd < 0) return CREATE_FAIL;

		memberCount = argc - optind;
		members = argv + optind;
		rc = createArchive(outFd, memberCount, members, verbose);

		// Only close if it's not stdout
		if (archiveFile && outFd >= 0) close(outFd);
		return (rc == 0) ? EXIT_SUCCESS : rc;
	}

	if (table) {
		int inFd = openArchiveForRead(archiveFile);
		int rc;

		if (inFd < 0) return TOC_FAIL;
		rc = tableOfContents(inFd, verbose);

		if (archiveFile && inFd >= 0) close(inFd);
		return (rc == 0) ? EXIT_SUCCESS : rc;
	}


exit(EXIT_SUCCESS);
}
