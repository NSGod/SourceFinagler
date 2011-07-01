/*
	File:       sourcefinaglerd.c

    Contains:   Helper tool side of the example of how to use VSAuthorizationHelperToolLib.

    Written by: DTS

    Copyright:  Copyright (c) 2007 Apple Inc. All Rights Reserved.

    
 */
 
#include <netinet/in.h>
#include <stdio.h>
#include <sys/socket.h>
#include <unistd.h>

#include <CoreServices/CoreServices.h>

#include "VSAuthorizationHelperToolLib.h"

#include "VSSourceFinaglerCommon.h"



/////////////////////////////////////////////////////////////////
#pragma mark ***** Get Version Command

static OSStatus DoGetVersion(
	AuthorizationRef			auth,
    const void *                userData,
	CFDictionaryRef				request,
	CFMutableDictionaryRef      response,
    aslclient                   asl,
    aslmsg                      aslMsg
)
    // Implements the kVSGetVersionCommand.  Returns the version number of 
    // the helper tool.
{	
	OSStatus					retval = noErr;
	CFNumberRef					value;
    static const int kCurrentVersion = 17;          // something very easy to spot
	
	// Pre-conditions
	
	assert(auth != NULL);
    // userData may be NULL
	assert(request != NULL);
	assert(response != NULL);
    // asl may be NULL
    // aslMsg may be NULL
	
    // Add them to the response.
    
	value = CFNumberCreate(NULL, kCFNumberIntType, &kCurrentVersion);
	if (value == NULL) {
		retval = coreFoundationUnknownErr;
    } else {
        CFDictionaryAddValue(response, CFSTR(kVSGetVersionResponse), value);
	}
	
	if (value != NULL) {
		CFRelease(value);
	}

	return retval;
}

/////////////////////////////////////////////////////////////////
#pragma mark ***** Get UIDs Command

static OSStatus DoGetUID(
	AuthorizationRef			auth,
    const void *                userData,
	CFDictionaryRef				request,
	CFMutableDictionaryRef      response,
    aslclient                   asl,
    aslmsg                      aslMsg
)
    // Implements the kVSGetUIDsCommand.  Gets the process's three UIDs and 
    // adds them to the response dictionary.
{	
	OSStatus					retval = noErr;
    int                         err;
	uid_t						euid;
	uid_t						ruid;
	CFNumberRef					values[2];
	long long					tmp;
	
	// Pre-conditions
	
	assert(auth != NULL);
    // userData may be NULL
	assert(request != NULL);
	assert(response != NULL);
    // asl may be NULL
    // aslMsg may be NULL
	
    // Get the UIDs.
    
	euid = geteuid();
	ruid = getuid();
	
	err = asl_log(asl, aslMsg, ASL_LEVEL_DEBUG, "euid=%ld, ruid=%ld", (long) euid, (long) ruid);
    assert(err == 0);
	
    // Add them to the response.
    
	tmp = euid;
	values[0] = CFNumberCreate(NULL, kCFNumberLongLongType, &tmp);
	tmp = ruid;
	values[1] = CFNumberCreate(NULL, kCFNumberLongLongType, &tmp);
	
	if ( (values[0] == NULL) || (values[1] == NULL) ) {
		retval = coreFoundationUnknownErr;
    } else {
        CFDictionaryAddValue(response, CFSTR(kVSGetUIDsRealUIDResponse), values[0]);
        CFDictionaryAddValue(response, CFSTR(kVSGetUIDsEffectiveUIDResponse), values[1]);
	}
	
	if (values[0] != NULL) {
		CFRelease(values[0]);
	}
	if (values[1] != NULL) {
		CFRelease(values[1]);
	}

	return retval;
}

/////////////////////////////////////////////////////////////////
#pragma mark ***** Low-Numbered Ports Command

static OSStatus OpenAndBindDescAndAppendToArray(
	uint16_t					port,               // in host byte order
	CFMutableArrayRef			descArray,
    aslclient                   asl,
    aslmsg                      aslMsg
)
    // A helper routine for DoGetLowNumberedPorts.  Opens a TCP port and 
    // stashes the resulting descriptor in descArray.
{
	OSStatus                    retval;
	int							err;
	int							desc;
	CFNumberRef					descNum;
	
	// Pre-conditions
	
	assert(port != 0);
	assert(descArray != NULL);
    // asl may be NULL
    // aslMsg may be NULL
	
	descNum = NULL;
	
    retval = noErr;
	desc = socket(AF_INET, SOCK_STREAM, 0);
    if (desc < 0) {
        retval = VSErrnoToOSStatus(errno);
    }
	if (retval == noErr) {
		descNum = CFNumberCreate(NULL, kCFNumberIntType, &desc);
		if (descNum == NULL) {
			retval = coreFoundationUnknownErr;
		}
	}
	if (retval == 0) {
		struct sockaddr_in addr;

		memset(&addr, 0, sizeof(addr));
		addr.sin_len    = sizeof(addr);
		addr.sin_family = AF_INET;
		addr.sin_port   = htons(port);
		
        static const int kOne = 1;

        err = setsockopt(desc, SOL_SOCKET, SO_REUSEADDR, (void *)&kOne, sizeof(kOne));
        if (err < 0) {
            retval = VSErrnoToOSStatus(errno);
        }

        if (retval == noErr) {
            err = bind(desc, (struct sockaddr *) &addr, sizeof(addr));
            if (err < 0) {
                retval = VSErrnoToOSStatus(errno);
            }
        }
	}
	if (retval == noErr) {
		CFArrayAppendValue(descArray, descNum);
	}
    if (retval == noErr) {
        err = asl_log(asl, aslMsg, ASL_LEVEL_DEBUG, "Opened port %u", (unsigned int) port);
    } else {
        errno = VSOSStatusToErrno(retval);                         // so that %m can pick it up
        err = asl_log(asl, aslMsg, ASL_LEVEL_ERR, "Failed to open port %u: %m", (unsigned int) port);
    }
    assert(err == 0);
	
	// Clean up.
	
	if ( (retval != noErr) && (desc != -1) ) {
		err = close(desc);
		assert(err == 0);
	}
	if (descNum != NULL) {
		CFRelease(descNum);
	}
	
	return retval;
}

static OSStatus DoGetLowNumberedPorts(
	AuthorizationRef			auth,
    const void *                userData,
	CFDictionaryRef				request,
	CFMutableDictionaryRef      response,
    aslclient                   asl,
    aslmsg                      aslMsg
)
    // Implements the kSampleLowNumberedPortsCommand.  Opens three low-numbered ports 
    // and adds them to the descriptor array in the response dictionary.
{	
	OSStatus					retval = noErr;
	CFMutableArrayRef			descArray = NULL;
	
	// Pre-conditions
    
	assert(auth != NULL);
    // userData may be NULL
	assert(request != NULL);
	assert(response != NULL);
    // asl may be NULL
    // aslMsg may be NULL
	
	descArray = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
	if (descArray == NULL) {
		retval = coreFoundationUnknownErr;
	}
	
	if (retval == noErr) {
		retval = OpenAndBindDescAndAppendToArray(140, descArray, asl, aslMsg);
	}
	if (retval == noErr) {
		retval = OpenAndBindDescAndAppendToArray(131, descArray, asl, aslMsg);
	}
	if (retval == noErr) {
        if ( CFDictionaryContainsKey(request, CFSTR(kSampleLowNumberedPortsForceFailure)) ) {
            retval = VSErrnoToOSStatus( EADDRINUSE );
        } else {
            retval = OpenAndBindDescAndAppendToArray(132, descArray, asl, aslMsg);
        }
	}
	 
	if (retval == noErr) {
        CFDictionaryAddValue(response, CFSTR(kVSDescriptorArrayKey), descArray);
	}
	
    // Clean up.
    
	if (retval != noErr) {
		VSCloseDescriptorArray(descArray);
	}
	if (descArray != NULL) {
		CFRelease(descArray);
	}
	
	return retval;
}

/////////////////////////////////////////////////////////////////
#pragma mark ***** Tool Infrastructure

/*
    IMPORTANT
    ---------
    This array must be exactly parallel to the kSampleCommandSet array 
    in "VSSourceFinaglerCommon.c".
*/

static const VSCommandProc kSampleCommandProcs[] = {
    DoGetVersion,
    DoGetUID,
    DoGetLowNumberedPorts,
    NULL
};


int main(int argc, char **argv) {
    // Go directly into VSAuthorizationHelperToolLib code.
	
    // IMPORTANT
    // VSHelperToolMain doesn't clean up after itself, so once it returns 
    // we must quit.
    
	return VSHelperToolMain(kSampleCommandSet, kSampleCommandProcs);
}



