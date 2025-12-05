#include <sys/types.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/uio.h>
#include <unistd.h>
#include <pthread.h>
#include <getopt.h>
#include "rockem_hdr.h"

static short is_verbose = 0;
static int usleep_time = 0;

static char ip_addr[50] = {DEFAULT_IP};
static short ip_port = DEFAULT_SERVER_PORT;

int get_socket(char *, int);
void get_file(char *);
void put_file(char *);
void *thread_get(void *);
void *thread_put(void *);
void list_dir(void);

int main(int argc, char *argv[]) {
    cmd_t cmd;
    int i;

    memset(&cmd, 0, sizeof(cmd_t));
	{
		int opt = 0;

		while ((opt = getopt(argc, argv, CLIENT_OPTIONS)) != -1) {
			switch (opt) {
			case 'i':
				strncpy(ip_addr, optarg, sizeof(ip_addr) - 1);
				ip_addr[sizeof(ip_addr) - 1] = '\0';
				break;
			case 'p':
				ip_port = (short) atoi(optarg);
				break;
			case 'c':
				strncpy(cmd.cmd, optarg, sizeof(cmd.cmd) - 1);
				cmd.cmd[sizeof(cmd.cmd) - 1] = '\0';
				break;
			case 'v':
				is_verbose++;
				break;
			case 'u':
				usleep_time += 1000;
				break;
			case 'h':
				fprintf(stderr, "%s ...\n\tOptions: %s\n"
						, argv[0], CLIENT_OPTIONS);
				fprintf(stderr, "\t-i str\t\tIPv4 address of the server (default %s)\n"
						, ip_addr);
				fprintf(stderr, "\t-p #\t\tport on which the server will listen (default %hd)\n"
						, DEFAULT_SERVER_PORT);
				fprintf(stderr, "\t-c str\t\tcommand to run (one of %s, %s, or %s)\n"
						, CMD_GET, CMD_PUT, CMD_DIR);
				fprintf(stderr, "\t-u\t\tnumber of thousands of microseconds the client will sleep between read/write calls (default %d)\n"
						, 0);
				fprintf(stderr, "\t-v\t\tenable verbose output. Can occur more than once to increase output\n");
				fprintf(stderr, "\t-h\t\tshow this rather lame help message\n");
				exit(EXIT_SUCCESS);
				break;
			default:
				fprintf(stderr, "*** Oops, something strange happened <%s> ***\n", argv[0]);
				break;
			}
		}
    }

    if (is_verbose)
        fprintf(stderr, "Command to server: <%s> %d\n", cmd.cmd, __LINE__);

    if (strcmp(cmd.cmd, CMD_GET) == 0) {
        pthread_t tid;
        for (i = optind; i < argc; i++)
            if (pthread_create(&tid, NULL, thread_get, (void *) argv[i]) != 0) {
                perror("pthread_create failed");
            }
    }
    else if (strcmp(cmd.cmd, CMD_PUT) == 0) {
        pthread_t tid;
        for (i = optind; i < argc; i++)
            if (pthread_create(&tid, NULL, thread_put, (void *) argv[i]) != 0) {
                perror("pthread_create failed");
            }
    }
    else if (strcmp(cmd.cmd, CMD_DIR) == 0) list_dir();

    else {
        fprintf(stderr, "ERROR: unknown command >%s< %d\n", cmd.cmd, __LINE__);
        exit(EXIT_FAILURE);
    }
    pthread_exit(NULL);
}

int get_socket(char * addr, int port) {
    int sockfd;
    struct sockaddr_in servaddr;

    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) {
        perror("socket creation failed");
        exit(EXIT_FAILURE);
    }

    memset(&servaddr, 0, sizeof(servaddr));
    servaddr.sin_family = AF_INET;
    servaddr.sin_port = htons(port);

    if (inet_pton(AF_INET, addr, &servaddr.sin_addr) <= 0) {
        perror("invalid address / address not supported");
        close(sockfd);
        exit(EXIT_FAILURE);
    }

    if (connect(sockfd, (struct sockaddr *)&servaddr, sizeof(servaddr)) < 0) {
        perror("connection to server failed");
        close(sockfd);
        exit(EXIT_FAILURE);
    }

    return(sockfd);
}

void get_file(char *file_name) {
    cmd_t cmd;
    int sockfd;
    int fd;
    ssize_t bytes_read;
    char buffer[MAXLINE];

    strcpy(cmd.cmd, CMD_GET);
    if (is_verbose) fprintf(stderr, "next file: <%s> %d\n", file_name, __LINE__);

    strcpy(cmd.name, file_name);
    if (is_verbose) fprintf(stderr, "get from server: %s %s %d\n", cmd.cmd, cmd.name, __LINE__);

    sockfd = get_socket(ip_addr, ip_port);

    if (write(sockfd, &cmd, sizeof(cmd_t)) < 0) {
        perror("write to socket failed");
        close(sockfd);
        return;
    }

    fd = open(file_name, O_WRONLY | O_CREAT | O_TRUNC, S_IRUSR | S_IWUSR);
    if (fd < 0) {
        perror("file open failed");
        close(sockfd);
        return;
    }

    memset(buffer, 0, sizeof(buffer));
    while ((bytes_read = read(sockfd, buffer, sizeof(buffer))) > 0) {
        if (write(fd, buffer, bytes_read) < 0) {
            perror("write to file failed");
            break;
        }
        if (usleep_time > 0) sleep(usleep_time);
        memset(buffer, 0, sizeof(buffer));
    }
    close(fd);
    close(sockfd);
}

void put_file(char *file_name) {
    cmd_t cmd;
    int sockfd;
    int fd;
    ssize_t bytes_read;
    char buffer[MAXLINE];

    strcpy(cmd.cmd, CMD_PUT);
    if (is_verbose) fprintf(stderr, "next file: <%s> %d\n", file_name, __LINE__);
    strcpy(cmd.name, file_name);
    if (is_verbose) fprintf(stderr, "put to server: %s %s %d\n", cmd.cmd, cmd.name, __LINE__);
    sockfd = get_socket(ip_addr, ip_port);

    if (write(sockfd, &cmd, sizeof(cmd_t)) < 0) {
        perror("write to socket failed");
        close(sockfd);
        return;
    }

    fd = open(file_name, O_RDONLY);
    if (fd < 0) {
        perror("file open failed");
        close(sockfd);
        return;
    }

    memset(buffer, 0, sizeof(buffer));
    while ((bytes_read = read(fd, buffer, sizeof(buffer))) > 0) {
        if (write(sockfd, buffer, bytes_read) < 0) {
            perror("write to socket failed");
            break;
        }
        if (usleep_time > 0) usleep(usleep_time);
        memset(buffer, 0, sizeof(buffer));
    }
    close(fd);
    close(sockfd);
}

void list_dir(void) {
    cmd_t cmd;
    int sockfd;
    ssize_t bytes_read;
    char buffer[MAXLINE];
    strcpy(cmd.cmd, CMD_DIR);
    printf("dir from server: %s \n", cmd.cmd);
    sockfd = get_socket(ip_addr, ip_port);

    if (write(sockfd, &cmd, sizeof(cmd_t)) < 0) {
        perror("write to socket failed");
        close(sockfd);
        return;
    }

    memset(buffer, 0, sizeof(buffer));
    while ((bytes_read = read(sockfd, buffer, sizeof(buffer))) > 0) {
        if (write(STDOUT_FILENO, buffer, bytes_read) < 0) {
            perror("write to stdout failed");
            break;
        }
        if (usleep_time > 0) usleep(usleep_time);
        memset(buffer, 0, sizeof(buffer));
    }
    close(sockfd);
}

void *thread_get(void *info) {
    char *file_name = (char *) info;
    pthread_detach(pthread_self());
    get_file(file_name);
    pthread_exit(NULL);
}

void *thread_put(void *info) {
    char *file_name = (char *) info;
    pthread_detach(pthread_self());
    put_file(file_name);
    pthread_exit(NULL);
}
