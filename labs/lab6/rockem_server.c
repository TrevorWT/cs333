#include <sys/types.h>
#include <sys/socket.h>
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
#include "rockem_hdr.h"

#define LISTENQ 100

void process_connection(int sockfd, void *buf, int n);
void *thread_get(void *p);
void *thread_put(void *p);
void *thread_dir(void *p);
void *server_commands(void *p);
void current_connections_inc(void);
void current_connections_dec(void);
unsigned int current_connections_get(void);
void server_help(void);

static short is_verbose = 0;
static int usleep_time = 0;
static long tcount = 0;
static int current_connections = 0;
static pthread_mutex_t connections_mutex = PTHREAD_MUTEX_INITIALIZER;

int main(int argc, char *argv[]) {
    int listenfd = 0;
    int sockfd = 0;
    int n = 0;
    char buf[MAXLINE] = {'\0'};
    socklen_t clilen;
    struct sockaddr_in cliaddr;
    struct sockaddr_in servaddr;
    short ip_port = DEFAULT_SERVER_PORT;
    pthread_t cmd_thread;

	{
		int opt = 0;

		while ((opt = getopt(argc, argv, SERVER_OPTIONS)) != -1) {
			switch (opt) {
			case 'p':
				ip_port = (short) atoi(optarg);
				break;
			case 'u':
				usleep_time += 1000;
				break;
			case 'v':
				is_verbose++;
				break;
			case 'h':
				fprintf(stderr, "%s ...\n\tOptions: %s\n"
						, argv[0], SERVER_OPTIONS);
				fprintf(stderr, "\t-p #\t\tport on which the server will listen (default %hd)\n"
						, DEFAULT_SERVER_PORT);
				fprintf(stderr, "\t-u\t\tnumber of thousands of microseconds the server will sleep between "
						"read/write calls (default %d)\n"
						, usleep_time);
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

    listenfd = socket(AF_INET, SOCK_STREAM, 0);
    if (listenfd < 0) {
        perror("socket creation failed");
        exit(EXIT_FAILURE);
    }

    memset(&servaddr, 0, sizeof(servaddr));
    servaddr.sin_family = AF_INET;
    servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
    servaddr.sin_port = htons(ip_port);

    if (bind(listenfd, (struct sockaddr *)&servaddr, sizeof(servaddr)) < 0) {
        perror("bind failed");
        close(listenfd);
        exit(EXIT_FAILURE);
    }

    if (listen(listenfd, LISTENQ) < 0) {
        perror("listen failed");
        close(listenfd);
        exit(EXIT_FAILURE);
    }

    {
        char hostname[256] = {'\0'};
        struct hostent *host_entry = NULL;
        char *IPbuffer = NULL;
        memset(hostname, 0, sizeof(hostname));
        gethostname(hostname, sizeof(hostname));
        host_entry = gethostbyname(hostname);
        IPbuffer = inet_ntoa(*((struct in_addr*) host_entry->h_addr_list[0]));
        fprintf(stdout, "Hostname: %s\n", hostname);
        fprintf(stdout, "IP:       %s\n", IPbuffer);
        fprintf(stdout, "Port:     %d\n", ip_port);
		fprintf(stdout, "verbose     %d\n", is_verbose);
		fprintf(stdout, "usleep_time %d\n", usleep_time);
    }

    if (pthread_create(&cmd_thread, NULL, server_commands, NULL) != 0)
        perror("pthread_create for server_commands failed");

    clilen = sizeof(cliaddr);
    for ( ; ; ) {
        sockfd = accept(listenfd, (struct sockaddr *)&cliaddr, &clilen);
        if (sockfd < 0) {
            perror("accept failed");
            continue;
        }

        memset(buf, 0, sizeof(buf));

        if ((n = read(sockfd, buf, sizeof(cmd_t))) == 0) {
            fprintf(stdout, "EOF found on client connection socket, closing connection.\n");
            close(sockfd);
        }
        else {
            if (is_verbose) fprintf(stdout, "Connection from client: <%s>\n", buf);
            process_connection(sockfd, buf, n);
        }

    printf("Closing listen socket\n");
    close(listenfd);
    return(EXIT_SUCCESS);
    }
}

void process_connection(int sockfd, void *buf, int n) {
    cmd_t *cmd = (cmd_t *) malloc(sizeof(cmd_t));
    int ret;
    pthread_t tid;
    pthread_attr_t attr;
    pthread_attr_init(&attr);
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);

    memcpy(cmd, buf, sizeof(cmd_t));
    cmd->sock = sockfd;
    if (is_verbose) fprintf(stderr, "Request from client: <%s> <%s>\n", cmd->cmd, cmd->name);

    if (strcmp(cmd->cmd, CMD_GET) == 0) {
        ret = pthread_create(&tid, &attr, thread_get, (void *) cmd);
        if (ret < 0) {
            fprintf(stderr, "ERROR: pthread_create failed %d\n", __LINE__);
            close(sockfd);
            free(cmd);
        }
    }
    else if (strcmp(cmd->cmd, CMD_PUT) == 0) {
        ret = pthread_create(&tid, &attr, thread_put, (void *) cmd);
        if (ret < 0) {
            fprintf(stderr, "ERROR: pthread_create failed %d\n", __LINE__);
            close(sockfd);
            free(cmd);
        }
    }
    else if (strcmp(cmd->cmd, CMD_DIR) == 0) {
        ret = pthread_create(&tid, &attr, thread_dir, (void *) cmd);
        if (ret < 0) {
            fprintf(stderr, "ERROR: pthread_create failed %d\n", __LINE__);
            close(sockfd);
            free(cmd);
        }
    }
    else {
        fprintf(stderr, "ERROR: unknown command >%s< %d\n", cmd->cmd, __LINE__);
        close(sockfd);
        free(cmd);
    }
    pthread_attr_destroy(&attr);
}

void *server_commands(void *p) {
    char cmd[80] = {'\0'};
    char *ret_val = NULL;
    pthread_detach(pthread_self());

    server_help();
    for ( ; ; ) {
        fputs(">> ", stdout);
        fflush(stdout);
        ret_val = fgets(cmd, sizeof(cmd), stdin);
        if (ret_val == NULL) break;
		cmd[strlen(cmd) - 1] = '\0';

        if (strlen(cmd) == 0) continue;
        else if (strcmp(cmd, SERVER_CMD_EXIT) == 0) break;
        else if (strcmp(cmd, SERVER_CMD_COUNT) == 0) {
            printf("total connections   %lu\n", tcount);
            printf("current connections %u\n", current_connections_get());
            printf("verbose             %d\n", is_verbose);
			printf("usleep_time         %d\n", usleep_time);
        }
        else if (strcmp(cmd, SERVER_CMD_VPLUS) == 0) {
            is_verbose++;
            printf("verbose set to %d\n", is_verbose);
        }
        else if (strcmp(cmd, SERVER_CMD_VMINUS) == 0) {
            is_verbose--;
            if (is_verbose < 0) is_verbose = 0;
            printf("verbose set to %d\n", is_verbose);
        }
        else if (strcmp(cmd, SERVER_CMD_UPLUS) == 0) {
			usleep_time += USLEEP_INCREMENT;
            printf("usleep_time set to %d\n", usleep_time);
        }
        else if (strcmp(cmd, SERVER_CMD_UMINUS) == 0) {
			usleep_time -= USLEEP_INCREMENT;
            if (usleep_time < 0) usleep_time = 0;
            printf("usleep_time set to %d\n", usleep_time);
        }
        else if (strcmp(cmd, SERVER_CMD_HELP) == 0) server_help();
        else {
            printf("command not recognized >>%s<<\n", cmd);
        }
    }
    exit(EXIT_SUCCESS);
}

void server_help(void) {
    printf("available commands are:\n");
    printf("\t%s : show the total connection count "
           "and number current connection\n"
           , SERVER_CMD_COUNT);
    printf("\t%s    : increment the is_verbose flag (current %d)\n"
           , SERVER_CMD_VPLUS, is_verbose);
    printf("\t%s    : decrement the is_verbose flag (current %d)\n"
           , SERVER_CMD_VMINUS, is_verbose);

    printf("\t%s    : increment the usleep_time variable (by %d, currently %d)\n"
           , SERVER_CMD_UPLUS, USLEEP_INCREMENT, usleep_time);
    printf("\t%s    : decrement the usleep_time variable (by %d, currently %d)\n"
           , SERVER_CMD_UMINUS, USLEEP_INCREMENT, usleep_time);

    printf("\t%s  : exit the server process\n"
           , SERVER_CMD_EXIT);
    printf("\t%s  : show this help\n"
           , SERVER_CMD_HELP);
}

void *thread_get(void *p) {
    cmd_t *cmd = (cmd_t *) p;
    int fd = 0;
    ssize_t bytes_read = 0;
    char buffer[MAXLINE] = {'\0'};
    current_connections_inc();

    if (is_verbose)
        fprintf(stderr, "Sending %s to client\n", cmd->name);

    fd = open(cmd->name, O_RDONLY);
    if (fd < 0) {
        perror("file open failed");
        close(cmd->sock);
        free(cmd);
        current_connections_dec();
        pthread_exit((void *) EXIT_FAILURE);
    }

    memset(buffer, 0, sizeof(buffer));
    while ((bytes_read = read(fd, buffer, sizeof(buffer))) > 0) {
        if (write(cmd->sock, buffer, bytes_read) < 0) {
            perror("write to socket failed");
            break;
        }
        if (usleep_time > 0) usleep(usleep_time);
        memset(buffer, 0, sizeof(buffer));
    }

    close(fd);
    close(cmd->sock);
    free(cmd);
    current_connections_dec();
    pthread_exit((void *) EXIT_SUCCESS);
}

void *thread_put(void *p) {
    cmd_t *cmd = (cmd_t *) p;
    int fd = 0;
    ssize_t bytes_read = 0;
    char buffer[MAXLINE] = {'\0'};
    current_connections_inc();

    if (is_verbose)
        fprintf(stderr, "VERBOSE: Receiving %s from client\n", cmd->name);

    fd = open(cmd->name, O_WRONLY | O_CREAT | O_TRUNC, S_IRUSR | S_IWUSR);
    if (fd < 0) {
        perror("file open failed");
        close(cmd->sock);
        free(cmd);
        current_connections_dec();
        pthread_exit((void *) EXIT_FAILURE);
    }

    memset(buffer, 0, sizeof(buffer));
    while ((bytes_read = read(cmd->sock, buffer, sizeof(buffer))) > 0) {
        if (write(fd, buffer, bytes_read) < 0) {
            perror("write to file failed");
            break;
        }
        if (usleep_time > 0) usleep(usleep_time);
        memset(buffer, 0, sizeof(buffer));
    }
    close(fd);
    close(cmd->sock);
    free(cmd);
    current_connections_dec();
    pthread_exit((void *) EXIT_SUCCESS);
}

void *thread_dir(void *p) {
    cmd_t *cmd = (cmd_t *) p;
    FILE *fp = NULL;
    char buffer[MAXLINE] = {'\0'};

    current_connections_inc();

    fp = popen(CMD_DIR_POPEN, "r");
    if (fp == NULL) {
        perror("popen failed");
        close(cmd->sock);
        free(cmd);
        current_connections_dec();
        pthread_exit((void *) EXIT_FAILURE);
    }

    memset(buffer, 0, sizeof(buffer));
    while (fgets(buffer, sizeof(buffer), fp) != NULL) {
        if (write(cmd->sock, buffer, strlen(buffer)) < 0) {
            perror("write to socket failed");
            break;
        }
        if (usleep_time > 0) usleep(usleep_time);
        memset(buffer, 0, sizeof(buffer));
    }

    pclose(fp);
    close(cmd->sock);
    free(cmd);

    current_connections_dec();

    pthread_exit((void *) EXIT_SUCCESS);
}

void current_connections_inc(void) {
    pthread_mutex_lock(&connections_mutex);
    current_connections++;
    tcount++;
    pthread_mutex_unlock(&connections_mutex);
}

void current_connections_dec(void) {
    pthread_mutex_lock(&connections_mutex);
    current_connections--;
    pthread_mutex_unlock(&connections_mutex);
}

unsigned int current_connections_get(void) {
    return current_connections;
}
