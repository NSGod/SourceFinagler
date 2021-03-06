//
//  VSGame.m
//  SteamKit
//
//  Created by Mark Douma on 6/13/2010.
//  Copyright (c) 2010-2014 Mark Douma LLC. All rights reserved.
//


#import <SteamKit/VSGame.h>
#import <SteamKit/VSSteamManager.h>
#import "VSPrivateInterfaces.h"


NSString * const VSGameIDKey						= @"VSGameID";
static NSString * const VSGameSupportsAddonsKey		= @"VSGameSupportsAddons";
NSString * const VSGameNameKey						= @"VSGameName";
NSString * const VSGameShortNameKey					= @"VSGameShortName";
NSString * const VSGameLongNameKey					= @"VSGameLongName";
static NSString * const VSGameCreatorCodeKey		= @"VSGameCreatorCode";
static NSString * const VSGameInfoPlistKey			= @"VSGameInfoPlist";


static NSString * const VSResourceNameKey			= @"resource";
NSString * const VSGameIconNamesKey					= @"VSGameIconNames";

static NSString * const VSGameSourceAddonFolderName	= @"addons";


#define VS_DEBUG 0

@implementation VSGame

@synthesize gameID;
@synthesize executableURL;
@synthesize icon;
@synthesize iconURL;
@synthesize displayName;
@synthesize infoDictionary;
@synthesize appManifestURL;
@synthesize creatorCode;
@synthesize sourceAddonsFolderURL;
@synthesize processIdentifier;
@synthesize helped;
@synthesize running;

@dynamic hasUpgradedLocation;


+ (id)gameWithExecutableURL:(NSURL *)aURL infoPlist:(NSDictionary *)anInfoPlist appManifestURL:(NSURL *)anAppManifestURL {
	return [[[[self class] alloc] initWithExecutableURL:aURL infoPlist:anInfoPlist appManifestURL:anAppManifestURL] autorelease];
}


- (id)initWithExecutableURL:(NSURL *)aURL infoPlist:(NSDictionary *)anInfoPlist appManifestURL:(NSURL *)anAppManifestURL {
	if (aURL && anInfoPlist && (self = [super init])) {
		helped = NO;
		executableURL = [aURL retain];
		appManifestURL = [anAppManifestURL retain];
		creatorCode = [[anInfoPlist objectForKey:VSGameCreatorCodeKey] unsignedIntValue];
		infoDictionary = [[anInfoPlist objectForKey:VSGameInfoPlistKey] retain];
		gameID = [[anInfoPlist objectForKey:VSGameIDKey] unsignedIntegerValue];
		displayName = [[infoDictionary objectForKey:(NSString *)kCFBundleNameKey] retain];
		
		NSString *shortFolderName = [anInfoPlist objectForKey:VSGameShortNameKey];
		NSArray *iconFilenames = [anInfoPlist objectForKey:VSGameIconNamesKey];
		
		NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
		BOOL isDir;
		
		if (shortFolderName) {
			
			for (NSString *iconFilename in iconFilenames) {
				NSString *possibleIconPath = [NSString pathWithComponents:
											  [NSArray arrayWithObjects:[executableURL.path stringByDeletingLastPathComponent],
											   shortFolderName,
											   VSResourceNameKey,
											   iconFilename, nil]];
				
				if ([fileManager fileExistsAtPath:possibleIconPath isDirectory:&isDir] && !isDir) {
					
					self.iconURL = [NSURL fileURLWithPath:[NSString pathWithComponents:
														   [NSArray arrayWithObjects:[executableURL.path stringByDeletingLastPathComponent],
															shortFolderName,
															VSResourceNameKey,
															iconFilename, nil]]];
					break;
				}
			}
		}
		
		self.icon = [[[NSImage alloc] initByReferencingURL:iconURL] autorelease];
		
		if (icon == nil) {
			NSLog(@"[%@ %@] failed to create image from file at == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), iconURL.path);
		}
		
		if ([[anInfoPlist objectForKey:VSGameSupportsAddonsKey] boolValue]) {
			NSURL *addonsURL = [NSURL fileURLWithPath:[NSString pathWithComponents:
													   [NSArray arrayWithObjects:[executableURL.path stringByDeletingLastPathComponent],
														shortFolderName,
														VSGameSourceAddonFolderName, nil]]];
			
			if ([fileManager fileExistsAtPath:addonsURL.path isDirectory:&isDir] && isDir) {
				self.sourceAddonsFolderURL = addonsURL;
			}
		}
		[self synchronizeHelped];
	}
	return self;
}


- (id)copyWithZone:(NSZone *)zone {
	NSLog(@"[%@ %@] why is this being called?", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	VSGame *copy = (VSGame *)[[[self class] allocWithZone:zone] init];
	copy.gameID = gameID;
	copy.creatorCode = creatorCode;
	copy.executableURL = executableURL;
	copy.icon = icon;
	copy.iconURL = iconURL;
	copy.displayName = displayName;
	copy.helped = helped;
	copy.infoDictionary = infoDictionary;
	copy.sourceAddonsFolderURL = sourceAddonsFolderURL;
	copy.appManifestURL = appManifestURL;
	copy.running = running;
	return copy;
}



- (void)dealloc {
	[executableURL release];
	[icon release];
	[iconURL release];
	[displayName release];
	[infoDictionary release];
	[sourceAddonsFolderURL release];
	[appManifestURL release];
	[super dealloc];
}


- (void)synchronizeHelped {
#if VS_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	BOOL isDir;
	
	NSError *outError = nil;
	
	if ( !([fileManager fileExistsAtPath:executableURL.path	isDirectory:&isDir] && !isDir)) {
		NSLog(@"[%@ %@] no file exists at %@!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), executableURL.path);
		[fileManager release];
		return;
	}
	
	NSDictionary *attributes = [fileManager attributesOfItemAtPath:executableURL.path error:&outError];
	if (attributes == nil) {
		NSLog(@"[%@ %@] failed to get attributes of item at path == %@; error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), executableURL.path, outError);
		[fileManager release];
		return;
	}
	self.helped = ([attributes fileHFSCreatorCode] != 0);
	
	[fileManager release];
}


- (BOOL)hasUpgradedLocation {
	return appManifestURL != nil;
}


- (NSString *)description {
	NSMutableString *description = [NSMutableString stringWithFormat:@"%@ -", [super description]];
	
	[description appendFormat:@" %@", displayName];
	[description appendFormat:@", gameID == %lu",  (unsigned long)gameID];
//	[description appendFormat:@", iconPath == %@", iconPath];
//	[description appendFormat:@", path == %@", path];
	[description appendFormat:@", isHelped == %@", (helped ? @"YES" : @"NO")];
	[description appendFormat:@", isRunning == %@", (running ? @"YES" : @"NO")];
	[description appendFormat:@", hasUpgradedLocation == %@", (self.hasUpgradedLocation ? @"YES" : @"NO")];
	[description appendFormat:@", sourceAddonsFolderURL == %@", sourceAddonsFolderURL];
	return description;
}


- (BOOL)isEqual:(id)anObject {
	if ([anObject isKindOfClass:[self class]]) {
		return [self isEqualToGame:anObject];
	}
//	return NO;
	return [super isEqual:anObject];
}


- (BOOL)isEqualToGame:(VSGame *)otherGame {
#if VS_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return (gameID == otherGame.gameID &&
			([executableURL.path isEqualToString:otherGame.executableURL.path] || [[executableURL.path lowercaseString] isEqualToString:[otherGame.executableURL.path lowercaseString]]) &&
			self.hasUpgradedLocation == otherGame.hasUpgradedLocation);
}

@end

