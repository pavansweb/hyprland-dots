#define _GNU_SOURCE
#include <dlfcn.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/socket.h>

static ssize_t (*real_write)(int fd, const void *buf, size_t count) = NULL;
static ssize_t (*real_send)(int sockfd, const void *buf, size_t len, int flags) = NULL;

static void init_real(void) {
    if (!real_write) real_write = dlsym(RTLD_NEXT, "write");
    if (!real_send) real_send = dlsym(RTLD_NEXT, "send");
}

static int should_transform(const char *b, size_t len, char *out, size_t max_out) {
    if (!b || len < 10) return 0;

    const char *prefix = NULL;
    int is_slash = (b[0] == '/');
    const char *cmd = is_slash ? b + 1 : b;

    if (strncmp(cmd, "dispatch workspace ", 19) == 0) {
        prefix = cmd + 19;
    } else if (strncmp(cmd, "dispatch focusworkspaceoncurrentmonitor ", 40) == 0) {
        prefix = cmd + 40;
    }

    if (prefix) {
        // extract workspace target (skip trailing whitespace or newline)
        char ws[64] = {0};
        size_t i = 0;
        while (*prefix && *prefix != '\n' && *prefix != '\r' && i < sizeof(ws) - 1) {
            ws[i++] = *prefix++;
        }
        ws[i] = '\0';
        while (i > 0 && ws[i - 1] == ' ') {
            ws[--i] = '\0';
        }
        if (ws[0] != '\0') {
            snprintf(out, max_out, "%sdispatch hl.dsp.focus({ workspace = \"%s\" })\n",
                     is_slash ? "/" : "", ws);
            return 1;
        }
    }
    return 0;
}

ssize_t write(int fd, const void *buf, size_t count) {
    init_real();
    char modified[256];
    if (should_transform((const char *)buf, count, modified, sizeof(modified))) {
        ssize_t ret = real_write(fd, modified, strlen(modified));
        return (ret > 0) ? (ssize_t)count : ret;
    }
    return real_write(fd, buf, count);
}

ssize_t send(int sockfd, const void *buf, size_t len, int flags) {
    init_real();
    char modified[256];
    if (should_transform((const char *)buf, len, modified, sizeof(modified))) {
        ssize_t ret = real_send(sockfd, modified, strlen(modified), flags);
        return (ret > 0) ? (ssize_t)len : ret;
    }
    return real_send(sockfd, buf, len, flags);
}
