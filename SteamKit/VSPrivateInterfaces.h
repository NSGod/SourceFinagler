//
//  VSPrivateInterfaces.h
//  Source Finagler
//
//  Created by Mark Douma on 6/1/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//

#import <SteamKit/SteamKitDefines.h>
#import <SteamKit/VSGame.h>


@interface VSGame ()

+ (id)gameWithPath:(NSString *)aPath infoPlist:(NSDictionary *)anInfoPlist;
- (id)initWithPath:(NSString *)aPath infoPlist:(NSDictionary *)anInfoPlist;


- (void)synchronizeHelped;

@property (retain) NSString *executablePath;

/* Indicates the URL to the games's executable. */
@property (retain) NSURL *executableURL;

@property (retain) NSString *displayName;

@property (retain) NSString *iconPath;

/* Returns the icon of the application. */
@property (retain) NSImage *icon;


@property (retain) NSDictionary *infoDictionary;

@property (retain) NSString	*addonsFolderPath;

/* Indicates the process identifier (pid) of the application.  Do not rely on this for comparing processes.  Use isEqual: instead.  Not all applications have a pid.  Applications without a pid return -1 from this method. */
@property (assign) pid_t processIdentifier;


@property (assign) VSGameID	gameID;

@property (assign) OSType creatorCode;


@property (assign, setter=setHelped:) BOOL isHelped;

@property (assign, setter=setRunning:) BOOL isRunning;


@end
