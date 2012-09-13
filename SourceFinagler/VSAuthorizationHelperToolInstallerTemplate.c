/*
	File:		VSAuthorizationHelperToolInstaller.c

	Contains:	Tool to install VSAuthorizationHelperToolLib-based privileged helper tools.

	Written by: DTS

	Copyright:	Copyright (c) 2007 Apple Inc. All Rights Reserved.

	
 */

#include <errno.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdbool.h>
#include <assert.h>
#include <stdio.h>
#include <string.h>
#include <limits.h>
#include <sys/stat.h>

// Allows access to path information associated with tool and plist installation
// from VSAuthorizationHelperToolLib.h
#define VS_PRIVATE 1		

#include "VSAuthorizationHelperToolLib.h"

extern char **environ;

static int VSToolRunLaunchCtl(
	bool						junkStdIO, 
	const char					*command, 
	const char					*plistPath
)
	// Handles all the invocations of launchctl by doing the fork() + execve()
	// for proper clean-up. Only two commands are really supported by our
	// implementation; loading and unloading of a job via the plist pointed at 
	// (const char *) plistPath.
{	
	int				err;
	const char *	args[5];
	pid_t			childPID;
	pid_t			waitResult;
	int				status;
	
	// Pre-conditions.
	assert(command != NULL);
	assert(plistPath != NULL);
	
	// Make sure we get sensible logging even if we never get to the waitpid.
	
	status = 0;
	
	// Set up the launchctl arguments.	We run launchctl using StartupItemContext 
	// because, in future system software, launchctl may decide on the launchd 
	// to talk to based on your Mach bootstrap namespace rather than your RUID.
	
	args[0] = "/bin/launchctl";
	args[1] = command;				// "load" or "unload"
	args[2] = "-w";
	args[3] = plistPath;			// path to plist
	args[4] = NULL;

	fprintf(stderr, "launchctl %s %s '%s'\n", args[1], args[2], args[3]);
	
	// Do the standard fork/exec dance.
	
	childPID = fork();
	switch (childPID) {
		case 0:
			// child
			err = 0;
			
			// If we've been told to junk the I/O for launchctl, open 
			// /dev/null and dup that down to stdin, stdout, and stderr.
			
			if (junkStdIO) {
				int		fd;
				int		err2;

				fd = open("/dev/null", O_RDWR);
				if (fd < 0) {
					err = errno;
				}
				if (err == 0) {
					if ( dup2(fd, STDIN_FILENO) < 0 ) {
						err = errno;
					}
				}
				if (err == 0) {
					if ( dup2(fd, STDOUT_FILENO) < 0 ) {
						err = errno;
					}
				}
				if (err == 0) {
					if ( dup2(fd, STDERR_FILENO) < 0 ) {
						err = errno;
					}
				}
				err2 = close(fd);
				if (err2 < 0) {
					err2 = 0;
				}
				if (err == 0) {
					err = err2;
				}
			}
			if (err == 0) {
				err = execve(args[0], (char **) args, environ);
			}
			if (err < 0) {
				err = errno;
			}
			_exit(EXIT_FAILURE);
			break;
		case -1:
			err = errno;
			break;
		default:
			err = 0;
			break;
	}
	
	// Only the parent gets here.  Wait for the child to complete and get its 
	// exit status.
	
	if (err == 0) {
		do {
			waitResult = waitpid(childPID, &status, 0);
		} while ( (waitResult == -1) && (errno == EINTR) );

		if (waitResult < 0) {
			err = errno;
		} else {
			assert(waitResult == childPID);

			if ( ! WIFEXITED(status) || (WEXITSTATUS(status) != 0) ) {
				err = EINVAL;
			}
		}
	}

	fprintf(stderr, "launchctl -> %d %ld 0x%x\n", err, (long) childPID, status);
	
	return err;
}

static int VSToolCopyFileOverwriting(
	const char					*sourcePath, 
	mode_t						destMode, 
	const char					*destPath
)
	// Our own version of a file copy. This routine will either handle
	// the copy of the tool binary or the plist file associated with
	// that binary. As the function name suggests, it writes over any 
	// existing file pointed to by (const char *) destPath.
{
	int			err;
	int			junk;
	int			sourceFD;
	int			destFD;
	char		buf[65536];
	
	// Pre-conditions.
	assert(sourcePath != NULL);
	assert(destPath != NULL);
	
	(void) unlink(destPath);
	
	destFD = -1;
	
	err = 0;
	sourceFD = open(sourcePath, O_RDONLY);
	if (sourceFD < 0) {
		err = errno;
	}
	
	if (err == 0) {
		destFD = open(destPath, O_CREAT | O_EXCL | O_WRONLY, destMode);
		if (destFD < 0) {
			err = errno;
		}
	}
	
	if (err == 0) {
		ssize_t bytesReadThisTime;
		ssize_t bytesWrittenThisTime;
		ssize_t bytesWritten;
		
		do {
			bytesReadThisTime = read(sourceFD, buf, sizeof(buf));
			if (bytesReadThisTime < 0) {
				err = errno;
			}
			
			bytesWritten = 0;
			while ( (err == 0) && (bytesWritten < bytesReadThisTime) ) {
				bytesWrittenThisTime = write(destFD, &buf[bytesWritten], bytesReadThisTime - bytesWritten);
				if (bytesWrittenThisTime < 0) {
					err = errno;
				} else {
					bytesWritten += bytesWrittenThisTime;
				}
			}

		} while ( (err == 0) && (bytesReadThisTime != 0) );
	}
	
	// Clean up.
	
	if (sourceFD != -1) {
		junk = close(sourceFD);
		assert(junk == 0);
	}
	if (destFD != -1) {
		junk = close(destFD);
		assert(junk == 0);
	}

	fprintf(stderr, "copy '%s' %#o '%s' -> %d\n", sourcePath, (int) destMode, destPath, err);
	
	return err;
}

static int VSToolInstallCommand(
	const char *				bundleID, 
	const char *				toolSourcePath, 
	const char *				plistSourcePath
)
	// Heavy lifting function for handling all the necessary steps to install a
	// helper tool in the correct location, with the correct permissions,
	// and call launchctl in order to load it as a current job.
{
	int			err;
	char		toolDestPath[PATH_MAX];
	char		plistDestPath[PATH_MAX];
	struct stat	sb;
    static const mode_t kDirectoryMode  = ACCESSPERMS & ~(S_IWGRP | S_IWOTH);
    static const mode_t kExecutableMode = ACCESSPERMS & ~(S_IWGRP | S_IWOTH);
    static const mode_t kFileMode       = DEFFILEMODE & ~(S_IWGRP | S_IWOTH);
	
	// Pre-conditions.
	assert(bundleID != NULL);
	assert(toolSourcePath != NULL);
	assert(plistSourcePath != NULL);
	
	(void) snprintf(toolDestPath,  sizeof(toolDestPath),  kVSToolPathFormat,  bundleID);
	(void) snprintf(plistDestPath, sizeof(plistDestPath), kVSPlistPathFormat, bundleID);

    // Stop the helper tool if it's currently running.

	(void) VSToolRunLaunchCtl(true, "unload", plistDestPath);

    // Create the PrivilegedHelperTools directory.  The owner will be "root" because 
    // we're running as root (our EUID is 0).  The group will be "admin" because 
    // it's inherited from "/Library".  The permissions will be rwxr-xr-x because 
    // of kDirectoryMode combined with our umask.

	err = mkdir(kVSToolDirPath, kDirectoryMode);
	if (err < 0) {
		err = errno;
	}
    fprintf(stderr, "mkdir '%s' %#o -> %d\n", kVSToolDirPath, kDirectoryMode, err);
	if ( (err == 0) || (err == EEXIST) ) {
		err = stat(kVSToolDirPath, &sb);
		if (err < 0) {
			err = errno;
		}
    }
    
    // /Library/PrivilegedHelperTools may have come from a number of places:
    //
    // A. We may have just created it.  In this case it will be 
    //    root:admin rwxr-xr-x.
    //
    // B. It may have been correctly created by someone else.  By definition, 
    //    that makes it root:wheel rwxr-xr-x.
    //
    // C. It may have been created (or moved here) incorrectly (or maliciously) 
    //    by someone else.  In that case it will be u:g xxxxxxxxx, where u is 
    //    not root, or root:g xxxxwxxwx (that is, root-owned by writeable by 
    //    someone other than root).
    //
    // In case A, we want to correct the group.  In case B, we want to do 
    // nothing.  In case C, we want to fail.

    if (err == 0) {
        if ( (sb.st_uid == 0) && (sb.st_gid == 0) ) {
            // case B -- do nothing
        } else if ( (sb.st_uid == 0) && (sb.st_gid != 0) && ((sb.st_mode & ALLPERMS) == kDirectoryMode) ) {
            // case A -- fix the group ID
            // 
            // This is safe because /Library is sticky and the file is owned 
            // by root, which means that only root can move it.  Also, we 
            // don't have to worry about malicious files existing within the 
            // directory because its only writeable by root.

            err = chown(kVSToolDirPath, -1, 0);
            if (err < 0) {
                err = errno;
            }
            fprintf(stderr, "chown -1:0 '%s' -> %d\n", kVSToolDirPath, err);
        } else {
            fprintf(stderr, "bogus perms on '%s' %d:%d %o\n", kVSToolDirPath, (int) sb.st_uid, (int) sb.st_gid, (int) sb.st_mode);
            err = EPERM;
        }
	}

    // Then create the known good copy.  The ownership and permissions 
    // will be set appropriately, as described in the comments for mkdir. 
    // We don't have to worry about atomicity because this tool won't be 
    // looked at until our plist is installed.

	if (err == 0) {
		err = VSToolCopyFileOverwriting(toolSourcePath, kExecutableMode, toolDestPath);
	}

    // For the plist, our caller has created the file in /tmp and we just copy it 
    // into the correct location.  This ensures that the file is complete 
    // and valid before anyone starts looking at it and will also overwrite 
	// any existing file with this new version.
    // 
	// Since we have to read/write in the file byte by byte to make sure that 
	// the file is complete we are rolling our own 'copy'. This clearly is 
	// ignoring atomicity since we do not roll back to the state of 'what was 
	// previously there' if there is an error; rather, whatever has been 
	// written up to that point of granular failure /is/ the state of the 
	// plist file.

	if (err == 0) {
		err = VSToolCopyFileOverwriting(plistSourcePath, kFileMode, plistDestPath);
	}
	
    // Use launchctl to load our job.  The plist file starts out disabled, 
    // so we pass "-w" to enable it permanently.

	if (err == 0) {
		err = VSToolRunLaunchCtl(false, "load", plistDestPath);
	}
	
	return err;
}

static int VSToolEnableCommand(
	const char					*bundleID
)
	// Utility function to call through to VSToolRunLaunchCtl in order to load a job
	// given by the path contructed from the (const char *) bundleID.
{
	int		err;
	char	plistPath[PATH_MAX];
	
	// Pre-condition.
	assert(bundleID != NULL);
	
	(void) snprintf(plistPath, sizeof(plistPath), kVSPlistPathFormat, bundleID);
	err = VSToolRunLaunchCtl(false, "load", plistPath);

	return err;
}

int main(int argc, char **argv)
{
	int err;
	
	// Print our PID so that the app can avoid creating zombies.

	fprintf(stdout, kVSAntiZombiePIDToken1 "%ld" kVSAntiZombiePIDToken2 "\n", (long) getpid());
	fflush(stdout);

    // On the client side, AEWP only gives a handle to stdout, so we dup stdout 
    // downto stderr for the rest of this tool.  This ensures that all our output 
	// makes it to the client.

	err = dup2(STDOUT_FILENO, STDERR_FILENO);
	if (err < 0) {
		err = errno;
	} else {
		err = 0;
	}

    // Set up the standard umask.  The goal here is to be robust in the 
	// face of common environmental changes, not to resist a malicious attack.
	// Also sync the RUID to the 0 because launchctl keys off the RUID (at least 
	// on 10.4.x).

	if (err == 0) {
		(void) umask(S_IWGRP | S_IWOTH);
		
        err = setuid(0);
        if (err < 0) {
            fprintf(stderr, "setuid\n");
            err = EINVAL;
        }
	}
	
	if ( (err == 0) && (argc < 2) ) {
		fprintf(stderr, "usage\n");
		err = EINVAL;
	}

	// The first argument is the command.  Switch off that and extract the 
	// remaining arguments and pass them to our command routines.
	
	if (err == 0) {
		if ( strcmp(argv[1], kVSInstallToolInstallCommand) == 0 ) {
			if (argc == 5) {
				err = VSToolInstallCommand(argv[2], argv[3], argv[4]);
			} else {
				fprintf(stderr, "usage3\n");
				err = EINVAL;
			}
		} else if ( strcmp(argv[1], kVSInstallToolEnableCommand) == 0 ) {
			if (argc == 3) {
				err = VSToolEnableCommand(argv[2]);
			} else {
				fprintf(stderr, "usage4\n");
				err = EINVAL;
			}
		} else {
			fprintf(stderr, "usage2\n");
			err = EINVAL;
		}
	}

	// Write "oK" to stdout and quit.  The presence of the "oK" on the last 
	// line of output is used by the calling code to detect success.
	
	if (err == 0) {
		fprintf(stderr, kVSInstallToolSuccess "\n");
    } else {
		fprintf(stderr, kVSInstallToolFailure "\n", err);
	}
	
	return (err == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}
