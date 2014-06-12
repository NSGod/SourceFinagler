//
//  SourceFinaglerAgentMain.m
//  Source Finagler
//
//  Created by Mark Douma on 7/11/2010.
//  Copyright © 2010 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SteamKit/SteamKit.h>


#define VS_DEBUG 1


int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
#if VS_DEBUG
	NSLog(@"SourceFinaglerAgentMain()");
#endif
	
	
	NSArray *arguments = [[NSProcessInfo processInfo] arguments];
	
#if VS_DEBUG
	NSLog(@"arguments == %@", arguments);
#endif
	
	if ([arguments count] < 2) {
		[pool release];
		exit(EXIT_FAILURE);
	}
	
	NSString *gamePath = [arguments objectAtIndex:1];
	
	NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
	BOOL isDir;
	
	if (! ([fileManager fileExistsAtPath:gamePath isDirectory:&isDir] && !isDir)) {
		NSLog(@"no game found at %@, exiting...", gamePath);
		[pool release];
		exit(EXIT_SUCCESS);
	}
	
	VSSteamManager *steamManager = [VSSteamManager defaultManager];
	
//#if VS_DEBUG
//	NSArray *games = steamManager.games;
//	NSLog(@"games == %@", games);
//#endif
	
	VSGame *game = [steamManager gameWithPath:gamePath];
	
	NSError *outError = nil;
	
	if (game && ![game isHelped]) {
		if (![steamManager helpGame:game forUSBOverdrive:YES updateLaunchAgent:NO error:&outError]) {
			NSLog(@" *** ERROR: failed to help game! error == %@", outError);
		} else {
			NSLog(@"helping game at %@", game.executableURL.path);
		}
	}
	
    [pool release];
    return 0;
}


