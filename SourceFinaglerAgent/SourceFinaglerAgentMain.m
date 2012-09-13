//
//  SourceFinaglerAgentMain.m
//  Source Finagler
//
//  Created by Mark Douma on 7/11/2010.
//  Copyright © 2010 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <SteamKit/SteamKit.h>

#import "MDLaunchManager.h"


#define VS_DEBUG 1


int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSLog(@"SourceFinaglerAgentMain()");
	
	NSArray *arguments = [[NSProcessInfo processInfo] arguments];
	if ([arguments count] < 2) {
		exit(EXIT_FAILURE);
	}
	
	NSString *gamePath = [arguments objectAtIndex:1];
	
	NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
	BOOL isDir;
	
	if (! ([fileManager fileExistsAtPath:gamePath isDirectory:&isDir] && !isDir)) {
		NSLog(@"no game found at %@, exiting...", gamePath);
		exit(EXIT_SUCCESS);
	}
	
	VSSteamManager *steamManager = [VSSteamManager defaultManager];
	
	NSArray *games = [steamManager games];
	
	NSLog(@"games == %@", games);
	
	VSGame *game = [steamManager gameWithPath:gamePath];
	
	NSError *outError = nil;
	
	if (game && ![game isHelped]) {
		if (![steamManager helpGame:game forUSBOverdrive:YES updateLaunchAgent:NO error:&outError]) {
			NSLog(@"failed to help game!");
			
		}
	}
	
    [pool release];
    return 0;
}


