//
//  MDProcessManager.m
//  Source Finagler
//
//  Created by Mark Douma on 12/5/2006.
//  Copyright © 2006 Mark Douma. All rights reserved.
//  



#import "MDProcessManager.h"
#import <ApplicationServices/ApplicationServices.h>


NSDictionary *MDInfoForProcessWithBundleIdentifier(NSString *aBundleIdentifier) {
	ProcessSerialNumber psn;
	psn.highLongOfPSN = kNoProcess;
	psn.lowLongOfPSN  = kNoProcess;
	
	while (GetNextProcess(&psn) == noErr) {
		NSDictionary *processInfo = [(NSDictionary *)ProcessInformationCopyDictionary(&psn, kProcessDictionaryIncludeAllInformationMask) autorelease];
//		NSLog(@"processInfo == %@", processInfo);
		if ([[processInfo objectForKey:(NSString *)kCFBundleIdentifierKey] isEqualToString:aBundleIdentifier]) {
			return processInfo;
		}
	}
	return nil;
}

