/*
	File:		VSSourceFinaglerCommon.h

	Contains:	Declarations common to the app and the tool.

	Written by: DTS

	Copyright:	Copyright (c) 2007 Apple Inc. All Rights Reserved.

	
*/

#ifndef _VSSourceFinaglerCommon_H
#define _VSSourceFinaglerCommon_H

#include "VSAuthorizationHelperToolLib.h"

/////////////////////////////////////////////////////////////////

// Commands supported by this sample


// "GetVersion" gets the version of the helper tool.  This never requires authorization.

#define kVSGetVersionCommand				"GetVersion"

// authorization right name (none)

// request keys (none)

// response keys

#define kVSGetVersionResponse				"VSVersion"			// CFNumber




// "GetUIDs" gets the important process UIDs (RealUID and EffectiveUID) of the helper tool.

#define kVSGetUIDsCommand					"GetUIDs"

// authorization right name

#define kVSGetUIDsRightName					"com.markdouma.SourceFinagler.GetUIDs"

// request keys (none)

// response keys

#define kVSGetUIDsRealUIDResponse			"VSRealUID"			// CFNumber
#define kVSGetUIDsEffectiveUIDResponse		"VSEffectiveUID"	// CFNumber




// "LowNumberedPorts" asks the helper tool to open some low-numbered ports on our behalf.

#define kSampleLowNumberedPortsCommand		"LowNumberedPorts"

	// authorization right name

#define kSampleLowNumberedPortsRightName	"com.markdouma.SourceFinagler.LowNumberedPorts"

// request keys

#define kSampleLowNumberedPortsForceFailure "ForceFailure"				// CFBoolean (optional, presence implies true)

// response keys (none, descriptors for the ports are in kVSDescriptorArrayKey, 
// the number of descriptors should be kNumberOfLowNumberedPorts)

#define kNumberOfLowNumberedPorts			3

// The kSampleCommandSet is used by both the app and the tool to communicate the set of 
// supported commands to the VSAuthorizationHelperToolLib module.

extern const VSCommandSpec kSampleCommandSet[];

#endif



