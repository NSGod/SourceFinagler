//
//  VSGame.h
//  Source Finagler
//
//  Created by Mark Douma on 6/13/2010.
//  Copyright © 2010-2012 Mark Douma LLC. All rights reserved.
//


#import <Foundation/NSObject.h>

@class NSImage, NSString, NSURL, NSDictionary;


typedef NSUInteger VSGameID;


@interface VSGame : NSObject <NSCopying> {
	
	NSString				*executablePath;
	
	NSString				*displayName;
	
	NSImage					*icon;
	
	NSString				*iconPath;
	
	NSDictionary			*infoDictionary;
	
	NSString				*addonsFolderPath;
	
	pid_t					processIdentifier;
	
	VSGameID				gameID;
	
	OSType					creatorCode;
	
	BOOL					isHelped;
	
	BOOL					isRunning;
	
}

/* Indicates the path to the game's executable. */
@property (readonly, retain) NSString *executablePath;

/* Indicates the URL to the game's executable. */
@property (readonly, retain) NSURL *executableURL;

/* Indicates the name of the game, suitable for presentation to the user. */
@property (readonly, retain) NSString *displayName;

/* Returns the icon of the game. */
@property (readonly, retain) NSImage *icon;

/* Returns the path to the icon of the game. */
@property (readonly, retain) NSString *iconPath;

/* A dictionary, constructed from the game's Info.plist file, that contains information about the game */
@property (readonly, retain) NSDictionary *infoDictionary;

/* The path to the game's addons directory, or nil if the game doesn't support addons. */
@property (readonly, retain) NSString *addonsFolderPath;

@property (readonly) VSGameID gameID;

@property (readonly) OSType creatorCode;

/* Indicates whether the game is currently helped. This is observable through KVO. */
@property (readonly) BOOL isHelped;

/* Indicates whether the game is currently running. This is observable through KVO. */
@property (readonly) BOOL isRunning;

/* Indicates the process identifier (pid) of the game. Do not rely on this for comparing processes. Use isEqual: instead. Not all games have a pid. Games without a pid return -1 from this method. */
@property (readonly) pid_t processIdentifier;


- (BOOL)isEqual:(id)anObject;
- (BOOL)isEqualToGame:(VSGame *)game;

@end


