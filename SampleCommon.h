/*
	File:       SampleCommon.h

    Contains:   Sample-specific declarations common to the app and the tool.

    Written by: DTS

    Copyright:  Copyright (c) 2007 Apple Inc. All Rights Reserved.

    
*/

#ifndef _SAMPLECOMMON_H
#define _SAMPLECOMMON_H

#include "BetterAuthorizationSampleLib.h"

/////////////////////////////////////////////////////////////////

// Commands supported by this sample


// "GetVersion" gets the version of the helper tool.  This never requires authorization.

#define kSampleGetVersionCommand        "GetVersion"

    // authorization right name (none)
    
    // request keys (none)
    
    // response keys
    
	#define kSampleGetVersionResponse			"Version"                   // CFNumber


// "GetUIDs" gets the important process UIDs (RUID and EUID) of the helper tool.

#define kSampleGetUIDsCommand           "GetUIDs"

    // authorization right name
    
    #define	kSampleUIDRightName					"com.example.BetterAuthorizationSample.GetUIDs"

    // request keys (none)
    
    // response keys
    
	#define kSampleGetUIDsResponseRUID			"RUID"                      // CFNumber
	#define kSampleGetUIDsResponseEUID			"EUID"                      // CFNumber


// "LowNumberedPorts" asks the helper tool to open some low-numbered ports on our behalf.

#define kSampleLowNumberedPortsCommand		"LowNumberedPorts"

    // authorization right name

    #define	kSampleLowNumberedPortsRightName	"com.example.BetterAuthorizationSample.LowNumberedPorts"
	
    // request keys
    
    #define kSampleLowNumberedPortsForceFailure	"ForceFailure"              // CFBoolean (optional, presence implies true)
    
    // response keys (none, descriptors for the ports are in kBASDescriptorArrayKey, 
	// the number of descriptors should be kNumberOfLowNumberedPorts)

	#define kNumberOfLowNumberedPorts			3

// The kSampleCommandSet is used by both the app and the tool to communicate the set of 
// supported commands to the BetterAuthorizationSampleLib module.

extern const BASCommandSpec kSampleCommandSet[];

#endif
