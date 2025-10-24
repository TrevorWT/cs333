#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/sysmacros.h>
#include <time.h>
#include <unistd.h>

int main(int argc, char **argv) {
  struct stat sb;

  // printf("arg count: %i\n", argc);

  if (argc <= 1) {
    printf("Usage: ./mystat <filename1> ... <filenameN>\n");
    return 0;
  }

  for (int i = 1; i < argc; i++) {
    if (lstat(argv[i], &sb) == -1) {
        fprintf(stderr, "*** Failed to stat file '%s', skipping.\n",
        argv[i]);
        fprintf(stderr,
        "***  File '%s', does not exist or we done have access.\n",
        argv[i]);
        fprintf(stderr,
        "*** Could not stat file: No such file or directory.\n");
    } else {

      printf("File: %s\n", argv[i]);

      printf("  File type:                ");

      switch (sb.st_mode & S_IFMT) {
        case S_IFBLK: printf("block device\n"); break;
        case S_IFCHR: printf("character device\n"); break;
        case S_IFDIR: printf("directory\n"); break;
        case S_IFIFO: printf("FIFO/pipe\n"); break;
        //case S_IFLNK: printf("symlink\n"); break;
        case S_IFREG: printf("regular file\n"); break;
        case S_IFSOCK: printf("socket\n"); break;

        case S_IFLNK:
          char link_target[PATH_MAX];
          char resolved_target[PATH_MAX];
          ssize_t len = readlink(argv[i], link_target, sizeof(link_target) - 1);
          if (len != -1) { link_target[len] = '\0'; }
          if (realpath(link_target, resolved_target) != NULL) { printf("Symbolic link -> %s\n", resolved_target); }
          else { printf("Symbolic link - with dangling destination\n"); }
          break;
        default:
          printf("unknown?\n");
          break;
      }

      printf("I-node number:            %ju\n", (uintmax_t)sb.st_ino);
      printf("Mode:                     %jo (octal)\n",(uintmax_t)sb.st_mode);
      printf("Link count:               %ju\n", (uintmax_t)sb.st_nlink);
      printf("Ownership:                UID=%ju   GID=%ju\n",(uintmax_t)sb.st_uid, (uintmax_t)sb.st_gid);
      printf("Preferred I/O block size: %jd bytes\n",(intmax_t)sb.st_blksize);
      printf("File size:                %jd bytes\n",(intmax_t)sb.st_size);
      printf("Blocks allocated:         %jd\n", (intmax_t)sb.st_blocks);
      printf("Last status change:       %s", ctime(&sb.st_ctime));
      printf("Last file access:         %s", ctime(&sb.st_atime));
      printf("Last file modification:   %s", ctime(&sb.st_mtime));
      printf("ID of containing device:  [%x,%x]\n", major(sb.st_dev),minor(sb.st_dev));
      printf("Device ID number:         %lu\n", (unsigned long)sb.st_dev);
    }
  }
  return 0;
}