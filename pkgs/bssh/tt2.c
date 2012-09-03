#define  _POSIX_C_SOURCE 200112L
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/socket.h>
#include <errno.h>
#include "parser.h"
#define LOGINCONF 512
#define OPTNUM 32
#define EXECCMD_NUM 1024
#define USERATHOST 512
#define OPTOFPORTLEN 16
#define CONFIG_FILE_LEN 512
void err_quit(char *pstr, int quit_val);
int err_return(char *pstr, int return_val);
void ana(char *str1, char *str2, char *str3);
int create(struct login_record *re, char *str);
int usage();
char *userathost(char *str1, char *str2, char *str3);
int main(int argc, char *argv[])
{
    int usfds[2];
    int pid;
    int fpid;
    char usfdsstr[128];
    int len = 0;
    int indicator = 0;
    char *parser = "parser";
    char *parserstr;
    char *config_file_name = "/.bssh_config";
    char *homedir;
    char config_file[CONFIG_FILE_LEN];
    char *bsshconfigstr;
    char *cmdstr_default = "bssh";
    char *cmdstr;
    int sftpindex = 0;
    int execindex = 0;
    int fcount;
    char *execcmd[EXECCMD_NUM];
    char userathost_array[USERATHOST];
    char portopt[OPTOFPORTLEN];
    char *parserstrptr[4];
/*
 * c: bssh or bsftp?
 * f: configure file
 * p: where is the parser
 * l: list the arguments
 */
    char *optstr = "+c:f:hlp:";
    char opt;
    int cindex, findex, lindex, pindex, optc;
    char *optstrptr[OPTNUM];
    struct login_record login_struc;
    char *loginconf = malloc(LOGINCONF * sizeof(*loginconf));
    if (loginconf == NULL)
	err_quit("malloc failed", 1);
    memset(loginconf, 0, LOGINCONF);
    memset(&login_struc, 0, sizeof(login_struc));
    memset(portopt, 0, OPTOFPORTLEN);
    memset(config_file, 0, CONFIG_FILE_LEN);
    cindex = findex = lindex = pindex = -1;
    optc = 0;
    if (setenv("PATH", ".:~/bin:/bin:/sbin:/usr/bin:/usr/sbin", 1) == -1)
	err_quit("setenv PATH failed", 1);
    homedir = getenv("HOME");
    if (homedir == NULL)
	err_quit("get home dir failed", 1);
    if ((strlen(homedir) + strlen(config_file_name)) >= CONFIG_FILE_LEN)
	err_quit("path of config file is too long", 1);
    strcat(config_file, homedir);
    strcat(config_file, config_file_name);

    while ((opt = getopt(argc, argv, optstr)) != -1) {
	switch (opt) {
	case 'c':
	    cindex = optc;
	    optstrptr[cindex] = optarg;
	    optc++;
	    break;
	case 'f':
	    findex = optc;
	    optstrptr[findex] = optarg;
	    optc++;
	    break;
	case 'h':
	    usage();
	    break;
	case 'l':
	    lindex = optc;
	    optc++;
	    break;
	case 'p':
	    pindex = optc;
	    optstrptr[optc] = optarg;
	    optc++;
	    break;
	}
    }

    if (pindex != -1) {
	parserstr = optstrptr[pindex];
	if (access(parserstr, F_OK) == -1) {
	    fprintf(stderr, "%s is not exist\n", parserstr);
	    exit(1);
	}
	if (access(parserstr, X_OK) == -1) {
	    fprintf(stderr, "%s is not executable\n", parserstr);
	    exit(1);
	}
    } else
	parserstr = parser;

    if (findex != -1)
	bsshconfigstr = optstrptr[findex];
    else
	bsshconfigstr = config_file;
    if (access(bsshconfigstr, F_OK) == -1) {
	fprintf(stderr, "%s is not exist\n", bsshconfigstr);
	usage();
    }
    if (access(parserstr, R_OK) == -1) {
	fprintf(stderr, "%s is not readable\n", bsshconfigstr);
	exit(1);
    }


    if (cindex != -1)
	cmdstr = optstrptr[cindex];
    else
	cmdstr = cmdstr_default;
    if (strlen(cmdstr) > 4)
	if (strncmp(cmdstr + strlen(cmdstr) - 5, "bsftp", 5) == 0)
	    sftpindex = 1;


    if (socketpair(AF_UNIX, SOCK_STREAM, 0, usfds) != 0)
	err_quit("sockepair failed", 1);
    pid = fork();
    if (pid == -1)
	err_quit("fork failed", 1);
    else if (!pid) {
	close(usfds[0]);
	sprintf(usfdsstr, "%d", usfds[1]);
	parserstrptr[0] = "parser";
	parserstrptr[1] = bsshconfigstr;
	parserstrptr[2] = usfdsstr;
	parserstrptr[3] = NULL;
	if (execv(parserstr, parserstrptr)
	    == -1)
	    err_quit("exec parser failed", 1);
    } else {
	close(usfds[1]);
	if (lindex != -1)
	    printf("cmd: %s\tconfigfile: %s\n", cmdstr, bsshconfigstr);
	while (1) {
	    len = strlen(loginconf);
	    if (strcmp(loginconf + len - strlen(okstr_ptr), okstr_ptr) !=
		0) {
		if (read(usfds[0], loginconf + len, LOGINCONF - len) < 0)
		    continue;
		continue;
	    }


	    indicator = create(&login_struc, loginconf);
	    if (indicator == 0) {
		all_write_out(usfds[0], nextstr_ptr);
		memset(loginconf, 0, LOGINCONF);
		continue;

	    }
	    if (indicator == 1) {
		if (lindex != -1) {
		    printf("user: \'%s\' ", login_struc.user);
		    printf("passwd: \'%s\' ", login_struc.passwd);
		    printf("rootpasswd: \'%s\' ", login_struc.rootpasswd);
		    printf("ip: %s ", login_struc.ip);
		    printf("port: %s\n", login_struc.port);
		    all_write_out(usfds[0], nextstr_ptr);
		    memset(loginconf, 0, LOGINCONF);
		    continue;
		} else {
		    execindex = 0;
		    if (sftpindex == 1) {
			execcmd[execindex] = "bsftp";
			execindex++;
		    } else {
			execcmd[execindex] = "bssh";
			execindex++;
			if (strlen(login_struc.rootpasswd) != 0) {
			    execcmd[execindex] = "-r";
			    execindex++;
			    execcmd[execindex] = login_struc.rootpasswd;
			    execindex++;
			}
		    }
		    execcmd[execindex] = "-p";
		    execindex++;
		    execcmd[execindex] = login_struc.passwd;
		    execindex++;
		    if (strlen(login_struc.port) != 0) {
			memset(portopt, 0, OPTOFPORTLEN);
			strcat(portopt, "-oPort=");
			strncat(portopt, login_struc.port,
				OPTOFPORTLEN - strlen("-oPort="));
			execcmd[execindex] = portopt;
			execindex++;
		    }

		    execcmd[execindex] =
			userathost(login_struc.user, login_struc.ip,
				   userathost_array);
		    execindex++;
		    for (fcount = optind; argv[fcount]; fcount++) {
			execcmd[execindex] = argv[fcount];
			execindex++;
		    }
		    execcmd[execindex] = NULL;

		    fpid = fork();
		    if (fpid == -1)
			err_quit("fork failed", 1);
		    else if (!fpid)
			execv(cmdstr, execcmd);

		    waitpid(fpid, NULL, 0);
/*		    write(usfds[0], nextstr_ptr, strlen(nextstr_ptr)); */
		    all_write_out(usfds[0], nextstr_ptr);
		    memset(loginconf, 0, LOGINCONF);
		    continue;
		}
	    }
	    if (indicator == 2) {
		if (lindex != -1)
		    exit(0);
		break;
	    }
	}
	free(loginconf);
	exit(0);
    }
    return 0;
}

void err_quit(char *pstr, int quit_val)
{
    if (pstr != NULL)
	fprintf(stderr, "%s: %s\n", pstr, strerror(errno));
    exit(quit_val);
}

int err_return(char *pstr, int return_val)
{
    if (pstr != NULL)
	fprintf(stderr, "%s: %s\n", pstr, strerror(errno));
    return return_val;
}

int usage(void)
{
    printf("NAME\n");
    printf
	("    tt2 - one to two or more managemente platform from linux to linuxes\n\n");
    printf("SYNOPSIS\n");
    printf("    tt2 [-c cmd] [-p parser] [-f config] argments\n\n");
    printf("DESCRIPTION\n");
    printf
	("\tArguments are commands that will be transfered to bssh or bsftp\n");
    printf("\t-c\tbssh or bsftp? default cmd is bssh\n");
    printf
	("\t-f\tpath of the config file. the default file is ~/.bssh_config\n");
    printf("\t-h\tdisplay this help and exit\n");
    printf("\t-p\tpath of the parser\n\n");
    printf("AUTHOR\n");
    printf("Writen by NingXibo.\n\n");
    printf("REPORTING BUGS\n");
    printf("Report bugs to <ningxibo@gmail.com>.\n");
    exit(1);
}

void ana(char *str1, char *str2, char *str3)
{
    int i, j;
    for (i = 0; str1[i] != '\n'; i++)
	str2[i] = str1[i];
    str2[i] = 0;
    j = 0;
    for (i++; str1[i] != '\n'; i++) {
	str3[j] = str1[i];
	j++;
    }
    str3[j] = 0;
}

int create(struct login_record *re, char *str)
{
    char in[32];
    char data[255];
    int i = 0;
    int j = 0;
    ana(str, in, data);
    i = atoi(in);
    j = strlen(data);
    switch (i) {
    case USER_RET:
	strncpy(re->user, data, j);
	re->user[j] = 0;
	return 0;
    case PASSWD_RET:
	strncpy(re->passwd, data, j);
	re->passwd[j] = 0;
	return 0;
    case ROOTPASSWD_RET:
	strncpy(re->rootpasswd, data, j);
	re->rootpasswd[j] = 0;
	return 0;
    case IP_RET:
	strncpy(re->ip, data, strlen(data));
	re->ip[j] = 0;
	return 1;
    case PORT_RET:
	strncpy(re->port, data, j);
	re->port[j] = 0;
	return 0;
    case END_RET:
	return 2;
    }
}

char *userathost(char *str1, char *str2, char *str3)
{
    int i, j;
    i = strlen(str1);
    j = strlen(str2);
    strncpy(str3, str1, i);
    strncpy(str3 + i, "@", 1);
    strncpy(str3 + i + 1, str2, j);
    str3[i + j + 1] = 0;
    return str3;
}

int all_write_out(int fds, char *str)
{
    int i = 0;
    i = write(fds, str, strlen(str));
    if (i < strlen(str))
	if (i < 0)
	    return all_write_out(fds, str);
	else
	    return all_write_out(fds, str + i);
    return i;
}
