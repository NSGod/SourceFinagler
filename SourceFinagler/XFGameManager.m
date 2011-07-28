//
//  XFGameManager.m
//  BlackFire
//
//  Created by Mark Douma on 12/28/2009.
//  Copyright (c) 2009 Mark Douma LLC. All rights reserved.
//

#import "XFGameManager.h"
#import <Cocoa/Cocoa.h>
#import <CoreServices/CoreServices.h>



NSString * const XFGameDidLaunchNotification		= @"XFGameDidLaunch";
NSString * const XFGameDidTerminateNotification		= @"XFGameDidTerminate";


NSString * const XFGameVersionKey					= @"Version";

NSString * const XFGameIDKey						= @"GameID";
NSString * const XFGameLongNameKey					= @"LongName";
NSString * const XFGameShortNameKey					= @"ShortName";

NSString * const XFGameIconKey						= @"Icon";
NSString * const XFGameClientServerTypeKey			= @"QStatClientServerType";
NSString * const XFGameMasterServerTypeKey			= @"QStatMasterServerType";

NSString * const XFGameMacAppNameKey				= @"AppName";
NSString * const XFGameMacBundleIdentifierKey		= @"BundleID";
NSString * const XFGameMacArgsKey					= @"Args";
NSString * const XFGameMacArgsOrderKey				= @"ArgsOrder";
NSString * const XFGameMacConnectArgKey				= @"ConnectArg";
NSString * const XFGameMacPasswordArgKey			= @"PasswordArg";
NSString * const XFGameMacOtherArgsKey				= @"OtherArgs";

NSString * const XFGameMacFileCreatorKey			= @"FileCreator";

NSString * const XFGameMacMachOExecutableSizeKey	= @"MachOExecutableSize";

NSString * const XFGameMacDeveloperNotesKey			= @"DeveloperNotes";

NSString * const XFGameMacMultipleEntriesKey		= @"MultipleEntries";

NSString * const XFGameMacIntelPortTypeKey			= @"PortType";

NSString * const XFGameMacIntelCiderPortTypeKey		= @"Cider";


#define XF_COD2_SP @"'CD2S'"
#define XF_COD2_MP @"'CD2M'"
#define XF_COD4_SP @"'CD4S'"
#define XF_COD4_MP @"'CD4M'"
#define XF_RTCW_SP @"'WlfS'"
#define XF_RTCW_MP @"'WlfM'"

#define XF_DEBUG 0

NSDictionary *XFProcessManagerInfoForProcessWithBundleIdentifier(NSString *aBundleIdentifier);


static XFGameManager *sharedManager = nil;

@implementation XFGameManager



+ (XFGameManager *)defaultManager {
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	if (sharedManager == nil) {
//		NSLog(@"[%@ %@] sharedManager == nil", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		sharedManager = [[super allocWithZone:NULL] init];
	}
	return sharedManager;
}


+ (id)allocWithZone:(NSZone *)zone {
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	return [[self defaultManager] retain];
}


- (id)copyWithZone:(NSZone *)zone {
	return self;
}


- (id)retain {
	return self;
}


- (NSUInteger)retainCount {
	return NSUIntegerMax; //denotes an object that cannot be released
}


- (void)release {
	// do nothing
}


- (id)autorelease {
	return self;
}

- (id)init {
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	if (self = [super init]) {
		
		lookupTime = 0.0;
		
		version = 0;
		defaultImage = nil;
		
		games = nil;
		macGames = nil;
		macGameIDs = nil;
		
		runningGames = [[NSMutableArray alloc] init];
		installedGameIDsAndPaths = [[NSMutableDictionary alloc] init];
		
		specialBundleIDs = [[NSArray arrayWithObjects:@"com.aspyr.callofduty2", @"com.aspyr.callofduty4", @"com.aspyr.rtcw", nil] retain];
		
		NSString *gamesPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"Games" ofType:@"plist"];
		NSString *macGamesPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"MacGames" ofType:@"plist"];
		if (gamesPath && macGamesPath) {
			games = [[NSMutableDictionary dictionaryWithContentsOfFile:gamesPath] mutableDeepCopy];
			macGames = [[NSMutableDictionary dictionaryWithContentsOfFile:macGamesPath] mutableDeepCopy];
			if (games && macGames) {
				
				macGameIDs = [[NSMutableDictionary alloc] init];
				
				NSArray *allKeys = [macGames allKeys];
//				NSLog(@"[%@ %@] creating macGameIDs", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
				
				for (NSString *key in allKeys) {
					if ([specialBundleIDs containsObject:key]) {
						NSDictionary *appEntry = [macGames objectForKey:key];
						NSArray *allKeys2 = [appEntry allKeys];
						for (NSString *key2 in allKeys2) {
							NSDictionary *individualAppEntry = [appEntry objectForKey:key2];
							[macGameIDs setObject:individualAppEntry forKey:[NSString stringWithFormat:@"%u", [[individualAppEntry objectForKey:XFGameIDKey] unsignedIntValue]]];
						}
					} else {
//						NSLog(@"[%@ %@] creating regular macGameID", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
						NSDictionary *appEntry = [macGames objectForKey:key];
						[macGameIDs setObject:appEntry forKey:[NSString stringWithFormat:@"%u", [[appEntry objectForKey:XFGameIDKey] unsignedIntValue]]];
						
					}
				}
				
				version = [[games objectForKey:XFGameVersionKey] integerValue];
				
				NSDate *startTime = [NSDate date];
				
				NSString *gameID = nil;
				for (gameID in macGameIDs) {
					NSDictionary *gameInfo = [macGameIDs objectForKey:gameID];
					if (gameInfo) {
#if XF_DEBUG
						NSLog(@"[%@ %@] gameInfo == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), gameInfo);
#endif
						NSString *gameName = [gameInfo objectForKey:XFGameMacAppNameKey];
						NSString *absolutePath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:[gameInfo objectForKey:XFGameMacBundleIdentifierKey]
																												  name:(gameName ? [NSString stringWithFormat:@"%@.app", gameName] : nil)
																											   creator:[gameInfo objectForKey:XFGameMacFileCreatorKey]];
						if (absolutePath) {
#if XF_DEBUG
							NSLog(@"[%@ %@] found %@\n\n", NSStringFromClass([self class]), NSStringFromSelector(_cmd), absolutePath);
#endif
	
							[installedGameIDsAndPaths setObject:absolutePath forKey:gameID];
						} else {
#if XF_DEBUG
							NSLog(@"[%@ %@] no results found\n\n", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
						}
					}
				}
				
				lookupTime = fabs([startTime timeIntervalSinceNow]);
				
//				NSLog(@"[%@ %@] installedGameIDsAndPaths == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), installedGameIDsAndPaths);
				
			}
		}
		
		
		defaultImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"BlackFire" ofType:@"icns"]];
		
		NSArray *runningApps = [[NSWorkspace sharedWorkspace] launchedApplications];
		for (NSDictionary *appInfo in runningApps) {
			NSDictionary *gameInfo = [self infoForMacApplication:appInfo];
			if (gameInfo) {
				[runningGames addObject:gameInfo];
			}
		}
		
		
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationDidLaunch:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationDidTerminate:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
		
	}
	return self;
}


//- (void)dealloc {
////	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//	
//	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
//
//	[defaultImage release];
//	
//	[games release];
//	[macGames release];
//	[macGameIDs release];
//	
//	[runningGames release];
//	
//	[specialBundleIDs release];
//	
//	[installedGameIDsAndPaths release];
//	
//	[super dealloc];
//}

- (NSImage *)defaultImage {
	return defaultImage;
}


- (NSDictionary *)infoForGameID:(XFGameID)gameID {
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	
	NSMutableDictionary *info = [games objectForKey:[NSString stringWithFormat:@"%u", gameID]];
	
	if ([info objectForKey:XFGameIconKey] == nil) {
		NSString *gameName = [info objectForKey:XFGameShortNameKey];
		if (gameName) {
			NSString *iconPath = [[NSBundle bundleForClass:[self class]] pathForResource:[NSString stringWithFormat:@"XF_%@", [gameName uppercaseString]] ofType:@"ICO" inDirectory:@"Icons"];
			
			NSImage *gameIcon = nil;
			
			gameIcon = [[[NSImage alloc] initByReferencingFile:iconPath] autorelease];
						
			if (gameIcon) {
				
			} else {
				gameIcon = defaultImage;
			}
			[info setObject:gameIcon forKey:XFGameIconKey];
		}
		
	}
	
	return info;
}


- (NSString *)longNameForGameID:(XFGameID)gameID {
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	return [[self infoForGameID:gameID] objectForKey:XFGameLongNameKey];
}



- (NSDictionary *)infoForMacApplication:(NSDictionary *)appInfo {
	NSDictionary *info = nil;
	
	NSString *bundleID = [appInfo objectForKey:@"NSApplicationBundleIdentifier"];
	NSString *appName = [appInfo objectForKey:@"NSApplicationName"];
//	NSLog(@"[%@ %@] bundleID == %@, appName == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), bundleID, appName);
	
	if (bundleID && appName) {
		if ([specialBundleIDs containsObject:bundleID]) {
			NSDictionary *moreAppInfo = XFProcessManagerInfoForProcessWithBundleIdentifier(bundleID);
			if (moreAppInfo) {
				NSString *fileCreator = [moreAppInfo objectForKey:XFGameMacFileCreatorKey];
				if (fileCreator) {
					if ([fileCreator isEqualToString:XF_COD2_SP] || [fileCreator isEqualToString:XF_COD2_MP]) {
						info = [[macGames objectForKey:bundleID] objectForKey:fileCreator];
					} else if ([fileCreator isEqualToString:XF_COD4_SP] || [fileCreator isEqualToString:XF_COD4_MP]) {
						info = [[macGames objectForKey:bundleID] objectForKey:fileCreator];
					} else if ([fileCreator isEqualToString:XF_RTCW_SP] || [fileCreator isEqualToString:XF_RTCW_MP]) {
						info = [[macGames objectForKey:bundleID] objectForKey:fileCreator];
					} else {
						NSLog(@"[%@ %@] unknown fileCreator %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), fileCreator);
						
					}
				}
			}
		} else {
			if ([macGames objectForKey:bundleID]) {
				info = [macGames objectForKey:bundleID];
			} else if ([macGames objectForKey:[NSString stringWithFormat:@"%@.app", appName]]) {
				info = [macGames objectForKey:[NSString stringWithFormat:@"%@.app", appName]];
			} else if ([macGames objectForKey:appName]) {
				info = [macGames objectForKey:appName];
			}
		}
	}
	
	return info;
}



- (void)applicationDidLaunch:(NSNotification *)notification {
	NSLog(@"[%@ %@] info == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [notification userInfo]);
	NSDictionary *gameInfo = [self infoForMacApplication:[notification userInfo]];
	if (gameInfo) {
		[runningGames addObject:gameInfo];
		[[NSNotificationCenter defaultCenter] postNotificationName:XFGameDidLaunchNotification object:nil userInfo:gameInfo];
	}
}


- (void)applicationDidTerminate:(NSNotification *)notification {
	NSLog(@"[%@ %@] info == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [notification userInfo]);
	NSDictionary *gameInfo = [self infoForMacApplication:[notification userInfo]];
	if (gameInfo && [runningGames containsObject:gameInfo]) {
		[runningGames removeObject:gameInfo];
		[[NSNotificationCenter defaultCenter] postNotificationName:XFGameDidTerminateNotification object:nil userInfo:gameInfo];
	}
}



- (NSArray *)runningGames {
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	return [[runningGames copy] autorelease];
}


- (NSArray *)installedGameIDs {
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	return [installedGameIDsAndPaths allKeys];
}


- (void)launchGameID:(XFGameID)gameID {
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	return [self launchGameID:gameID withAddress:nil password:nil];
}


- (void)launchGameID:(XFGameID)gameID withAddress:(NSString *)address {
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	return [self launchGameID:gameID withAddress:address password:nil];
}

- (void)launchGameID:(XFGameID)gameID withAddress:(NSString *)address password:(NSString *)password {
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	NSString *absolutePath = [installedGameIDsAndPaths objectForKey:[NSString stringWithFormat:@"%u", gameID]];
	NSLog(@"[%@ %@] absolutePath == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), absolutePath);
	
	
	if (address) {
		NSBundle *appBundle = [NSBundle bundleWithPath:absolutePath];
		if (appBundle) {
			NSLog(@"[%@ %@] appBundle == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), appBundle);
			
			NSString *executablePath = [appBundle executablePath];
			
			NSMutableArray *arguments = [NSMutableArray array];
			NSDictionary *appEntry = [macGameIDs objectForKey:[NSString stringWithFormat:@"%u", gameID]];
			NSDictionary *args = [appEntry objectForKey:XFGameMacArgsKey];
			NSArray *argsOrder = [appEntry objectForKey:XFGameMacArgsOrderKey];
//			NSInteger argsCount = [argsOrder count];
			
			for (NSString *arg in argsOrder) {
				if ([arg isEqualToString:XFGameMacConnectArgKey] && address) {
					NSString *actualArg = [args objectForKey:arg];
					if (actualArg) {
						[arguments addObject:[NSString stringWithFormat:@"%@ %@", actualArg, address]];
					}
				} else if ([arg isEqualToString:XFGameMacPasswordArgKey]) {
					NSString *actualArg = [args objectForKey:arg];
					if (actualArg) {
						[arguments addObject:[NSString stringWithFormat:@"%@ %@", actualArg, password]];
					}
				}
			}
			[NSTask launchedTaskWithLaunchPath:executablePath arguments:arguments];
			
		}
	} else {
		[[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:absolutePath]];
	}
	
}

- (NSString *)description {
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	return [NSString stringWithFormat:@"%@ , version %ld, %lu games, %lu macGames", [super description], (long)version, (unsigned long)[games count], (unsigned long)[macGames count]];
	
	
}



@end


NSDictionary *XFProcessManagerInfoForProcessWithBundleIdentifier(NSString *aBundleIdentifier) {
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



@implementation NSWorkspace (XFAdditions)


- (BOOL)selectFile:(NSString *)aFile inFileViewerRootedAtPath:(NSString *)aPath activateFileViewer:(BOOL)shouldActivate {
	BOOL success;
	
	if (shouldActivate) {
		success = [self selectFile:aFile inFileViewerRootedAtPath:@""];
	} else {
		NSDictionary *errorMessage = nil;
		NSAppleEventDescriptor *result = nil;
		
		NSAppleScript *revealScript = [[[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:@"tell application \"Finder\" to set newWindow to make new Finder window to ((\"%@\" as POSIX file) as alias)", aFile]] autorelease];
		
		if (revealScript) {
			result = [revealScript executeAndReturnError:&errorMessage];
			
			if (errorMessage) {
				NSLog(@"%@", errorMessage);
				success = NO;
//				NSBeep();
//				
//				NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
//				
//				NSRunAlertPanel([NSString stringWithFormat:NSLocalizedString(@"%@ could not locate the file because the following AppleScript error was encountered.", @""), appName], [NSString stringWithFormat:@"%@",[errorMessage objectForKey:NSAppleScriptErrorMessage]], NSLocalizedString(@"OK", @""), nil, nil);
			} else {
				success = YES;
			}
		} else {
			success = NO;
		}
	}
	
	return success;
}




- (BOOL)selectFilesInFileViewer:(NSArray *)thePaths {
	BOOL success = YES;
	
	NSMutableDictionary *filePaths = [NSMutableDictionary dictionary];
	
	for (NSString *filePath in thePaths) {
		NSString *parentDirectory = [filePath stringByDeletingLastPathComponent];
		
		if ([filePaths objectForKey:parentDirectory] == nil) {
			[filePaths setObject:[NSMutableArray arrayWithObject:filePath] forKey:filePath];
		} else {
			[[filePaths objectForKey:parentDirectory] addObject:filePath];
		}
	}
	
	NSArray *folderPaths = [filePaths allKeys];
	
	for (NSString *folderPath in folderPaths) {
		NSMutableArray *files = [filePaths objectForKey:folderPath];
		
		NSString *applescriptListString = [files applescriptListForStringArray];
		
		NSDictionary *errorMessage = nil;
		NSAppleEventDescriptor *result = nil;
		
		NSAppleScript *script = [[[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:@"set targetFolder to \"%@\" & \"/\"\nset fileList to %@\n\ntell application \"Finder\"\n	activate\n	set finderWindows to every Finder window\n	repeat with i from 1 to (count of finderWindows)\n		set finderWindow to item i of finderWindows\n		try\n			set targetPath to (POSIX path of ((target of finderWindow) as alias))\n			if targetPath = targetFolder then\n				select every item of fileList\n				return\n			end if\n		end try\n	end repeat\n	set newWindow to make new Finder window to (targetFolder as POSIX file)\n	select every item of fileList\nend tell", folderPath, applescriptListString, folderPath]] autorelease];
		
		if (script) {
			result = [script executeAndReturnError:&errorMessage];
			
			if (errorMessage) {
				NSLog(@"%@", errorMessage);
				success = NO;
			}
		}
	}
	
	return success;
}




- (NSImage *)iconForApplicationForURL:(NSURL *)aURL {
	NSImage *image = nil;
	if (aURL) {
		FSRef appRef;
		NSString *appPath = nil;
		OSStatus status = noErr;
		
		status = LSGetApplicationForURL((CFURLRef)aURL, kLSRolesAll, &appRef, NULL);
		if (status == noErr) {
			appPath = [NSString stringWithFSRef:&appRef];
			if (appPath) {
				image = [self iconForFile:appPath];
			}
		}
		
	}
	return image;
}

- (NSString *)absolutePathForAppBundleWithIdentifier:(NSString *)aBundleIdentifier name:(NSString *)aNameWithDotApp creator:(NSString *)creator {
	//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	NSString *absolutePath = nil;
	
	if (aBundleIdentifier || aNameWithDotApp || creator) {
		FSRef fileRef;
		OSType creatorCode = kLSUnknownCreator;
		if (creator) {
			OSType creatorType = NSHFSTypeCodeFromFileType(creator);
			if (creatorType != 0) {
				creatorCode = creatorType;
			}
		}
		
		OSStatus status = noErr;
		
		status = LSFindApplicationForInfo(creatorCode, (aBundleIdentifier ? (CFStringRef)aBundleIdentifier : NULL), (aNameWithDotApp ? (CFStringRef)aNameWithDotApp : NULL), &fileRef, NULL);
		
		if (status == noErr) {
			absolutePath = [NSString stringWithFSRef:&fileRef];
		}
		
	} else {
		
	}
	return absolutePath;
}

@end


@implementation XFGameManager (GameFinaglerAdditions)


- (NSArray *)installedGamePaths {
	return [installedGameIDsAndPaths allValues];
}

- (NSTimeInterval)lookupTime {
    return lookupTime;
}

@end



