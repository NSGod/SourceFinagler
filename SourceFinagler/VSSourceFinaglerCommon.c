/*
	File:		VSSourceFinaglerCommon.c

	Contains:	Declarations code common to the app and the tool.

	Written by: DTS

	Copyright:	Copyright (c) 2007 Apple Inc. All Rights Reserved.

	
*/

#include "VSSourceFinaglerCommon.h"

/*
	I originally generated the "SampleAuthorizationPrompts.strings" file by running 
	the following command in Terminal.	genstrings doesn't notice that the 
	CFCopyLocalizedStringFromTableInBundle is commented out, which is good for 
	my purposes.
	
	$ genstrings VSSourceFinaglerCommon.c -o en.lproj

	CFCopyLocalizedStringFromTableInBundle(CFSTR("GetUIDsPrompt"),			"SampleAuthorizationPrompts", b, "prompt included in authorization dialog for the GetUIDs command")
	CFCopyLocalizedStringFromTableInBundle(CFSTR("LowNumberedPortsPrompt"), "SampleAuthorizationPrompts", b, "prompt included in authorization dialog for the LowNumberedPorts command")
*/

/*
	IMPORTANT
	---------
	This array must be exactly parallel to the kSampleCommandProcs array 
	in "sourcefinaglerd.c".
*/

const VSCommandSpec kSampleCommandSet[] = {
	{	kVSGetVersionCommand,				// commandName
		NULL,									// rightName		   -- never authorize
		NULL,									// rightDefaultRule	   -- not applicable if rightName is NULL
		NULL,									// rightDescriptionKey -- not applicable if rightName is NULL
		NULL									// userData
	},

	{	kVSGetUIDsCommand,					// commandName
		kVSGetUIDsRightName,					// rightName
		"allow",								// rightDefaultRule	   -- by default, anyone can acquire this right
		"GetUIDsPrompt",						// rightDescriptionKey -- key for custom prompt in "SampleAuthorizationPrompts.strings
		NULL									// userData
	},

	{	kSampleLowNumberedPortsCommand,			// commandName
		kSampleLowNumberedPortsRightName,		// rightName
		"default",								// rightDefaultRule	   -- by default, you have to have admin credentials (see the "default" rule in the authorization policy database, currently "/etc/authorization")
		"LowNumberedPortsPrompt",				// rightDescriptionKey -- key for custom prompt in "SampleAuthorizationPrompts.strings
		NULL									// userData
	},

	{	NULL,									// the array is null terminated
		NULL, 
		NULL, 
		NULL,
		NULL
	}
};
