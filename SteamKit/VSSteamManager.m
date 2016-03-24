//
//  VSSteamManager.m
//  SteamKit
//
//  Created by Mark Douma on 6/13/2010.
//  Copyright (c) 2010-2014 Mark Douma LLC. All rights reserved.
//


#import <SteamKit/VSSteamManager.h>
#import "VSPrivateInterfaces.h"
#import "VSSourceAddonInstallOperation.h"

#import <HLKit/HLKit.h>

#import "MDFolderManager.h"
#import "MDFileManager.h"
#import "MDLaunchManager.h"

#import "MDResource.h"
#import "MDResourceFile.h"
#import "MDFoundationAdditions.h"
#import <sys/syslimits.h>



static NSString * const VSGameBundleIdentifiersAndGamesKey						= @"VSGameBundleIdentifiersAndGames";
static NSString * const VSExecutableNamesKey									= @"VSExecutableNames";
	
static NSString * const VSHalfLife2ExecutableNameKey							= @"hl2_osx";

static NSString * const VSAppManifestPrefixKey						= @"appmanifest_";
static NSString * const VSAppManifestPathExtensionKey				= @"acf";


NSString * const VSSteamAppsDirectoryNameKey						= @"SteamApps";

static NSString * const VSSourceFinaglerBundleIdentifierKey			= @"com.markdouma.SourceFinagler";

static NSString * const VSSourceFinaglerAgentNameKey					= @"SourceFinaglerAgent.app";

static NSString * const VSSourceFinaglerAgentBundleIdentifierKey		= @"com.markdouma.SourceFinaglerAgent";

static NSString * const VSSteamLaunchGameURL						= @"steam://run/";


NSString * const VSErrorDomain										= @"com.markdouma.SteamKit.framework";


/* I hate having to hardcode the path to '/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns', but I couldn't
find another way to get the generic app icon data in the same format as the `.icns` file without extensive coding or using deprecated methods. */

static NSString * const VSGenericApplicationIconPath				= @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns";



static inline NSDictionary *VSMakeLaunchAgentPlist(NSString *jobLabel, NSArray *programArguments, NSString *aWatchPath);

static inline NSString *VSMakeGamePathKey(NSString *gamePath) {
	return [gamePath lowercaseString];
}


#define VS_DEBUG 0


static BOOL locatedSteamApps = NO;

static VSGameOptions defaultPersistentOptions = VSGameOptionsDefault;
static NSLock *defaultPersistentOptionsLock	= nil;

static NSRecursiveLock *gamePathsAndGamesLock = nil;
static NSRecursiveLock *runningGamePathsAndGamesLock = nil;

static NSRecursiveLock *sourceAddonOperationsLock = nil;


// Creating a Singleton Instance
//
// http://developer.apple.com/mac/library/documentation/Cocoa/Conceptual/CocoaFundamentals/CocoaObjects/CocoaObjects.html#//apple_ref/doc/uid/TP40002974-CH4-SW32
//

static VSSteamManager *sharedManager = nil;


@implementation VSSteamManager

@synthesize delegate;
@synthesize monitoringGames;



+ (VSSteamManager *)defaultManager {
	@synchronized(self) {
		if (sharedManager == nil) {
			sharedManager = [[super allocWithZone:NULL] init];
		}
	}
	return sharedManager;
}

+ (id)allocWithZone:(NSZone *)zone {
	return [[self defaultManager] retain];
}

- (id)copyWithZone:(NSZone *)zone {
	return self;
}


- (id)init {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super init])) {
		defaultPersistentOptionsLock = [[NSLock alloc] init];
		
		gamePathsAndGames = [[NSMutableDictionary alloc] init];
		runningGamePathsAndGames = [[NSMutableDictionary alloc] init];
		
		NSString *gamesPlist = [[NSBundle bundleForClass:[self class]] pathForResource:@"com.valvesoftware.games" ofType:@"plist"];
		if (gamesPlist) {
			NSDictionary *gamesDic = [NSDictionary dictionaryWithContentsOfFile:gamesPlist];
			gameBundleIdentifiersAndGames = [[gamesDic objectForKey:VSGameBundleIdentifiersAndGamesKey] retain];
			knownExecutableNames = [[NSSet setWithArray:[gamesDic objectForKey:VSExecutableNamesKey]] retain];
		}
		
		steamAppsRelocationType = VSSteamAppsUnknownRelocation;
		
		sourceFinaglerLaunchAgentStatus = VSSourceFinaglerLaunchAgentStatusUnknown;
		
		sourceAddonOperationQueue = [[NSOperationQueue alloc] init];
		[sourceAddonOperationQueue setMaxConcurrentOperationCount:1];
		
		sourceAddonOperations = [[NSMutableArray alloc] init];
		sourceAddonOperationsLock = [[NSRecursiveLock alloc] init];
		
		gamePathsAndGamesLock = [[NSRecursiveLock alloc] init];
		runningGamePathsAndGamesLock = [[NSRecursiveLock alloc] init];
		
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationWillLaunch:) name:NSWorkspaceWillLaunchApplicationNotification object:nil];
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationDidLaunch:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationDidTerminate:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
	}
	return self;
}

- (id)retain {
	return self;
}

- (NSUInteger)retainCount {
	return NSUIntegerMax; //denotes an object that cannot be released
}

- (oneway void)release {
	// do nothing
}

- (id)autorelease {
	return self;
}


- (void)refreshSteamAppsForWorkspaceNotification:(NSNotification *)notification {
	NSString *appPath = [[[notification userInfo] objectForKey:@"NSApplicationPath"] stringByResolvingSymlinksInPath];

	if ([gamePathsAndGames objectForKey:VSMakeGamePathKey(appPath)] != nil ||
		[knownExecutableNames containsObject:[VSMakeGamePathKey(appPath) lastPathComponent]]) {
		
		[self locateSteamApps];
	}
}


- (void)applicationWillLaunch:(NSNotification *)notification {
#if VS_DEBUG
	NSLog(@"[%@ %@] userInfo == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [notification userInfo]);
#endif
	[self refreshSteamAppsForWorkspaceNotification:notification];
	
	@synchronized(self) {
		if (monitoringGames == NO) return;
		
		NSString *appPath = [[[notification userInfo] objectForKey:@"NSApplicationPath"] stringByResolvingSymlinksInPath];
		
		VSGame *game = [gamePathsAndGames objectForKey:VSMakeGamePathKey(appPath)];
		if (game == nil) return;
		
		VSGameOptions options = [self persistentOptionsForGame:game];
		
		if (options == VSGameOptionsDoNotHelpGame) options = defaultPersistentOptions;
		
		if (options & VSGameOptionsHelpGame && ![game isHelped]) {
			NSError *outError = nil;
			if (![self helpGame:game forUSBOverdrive:YES updateLaunchAgent:NO error:&outError]) {
				NSLog(@"[%@ %@] failed to help game!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			}
		}
	}
}


- (void)applicationDidLaunch:(NSNotification *)notification {
#if VS_DEBUG
	NSLog(@"[%@ %@] userInfo == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [notification userInfo]);
#endif
	[self refreshSteamAppsForWorkspaceNotification:notification];
}


- (void)applicationDidTerminate:(NSNotification *)notification {
#if VS_DEBUG
//	NSLog(@"[%@ %@] userInfo == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [notification userInfo]);
#endif
	[self refreshSteamAppsForWorkspaceNotification:notification];
}


- (NSString *)defaultSteamAppsPath {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (!locatedSteamApps) [self locateSteamApps];
	return defaultSteamAppsPath;
}


- (NSString *)steamAppsPath {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (!locatedSteamApps) [self locateSteamApps];
	return steamAppsPath;
}


- (VSSteamAppsRelocationType)steamAppsRelocationType {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (!locatedSteamApps) [self locateSteamApps];
	return steamAppsRelocationType;
}

static NSUInteger locateSteamAppsCount = 0;

- (void)locateSteamApps {
	@synchronized(self) {
#if VS_DEBUG
	NSLog(@"[%@ %@] locateSteamAppsCount == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)locateSteamAppsCount);
#endif
		locateSteamAppsCount++;
		
		timeToLocateSteamApps = 0.0;
		steamAppsRelocationType = VSSteamAppsUnknownRelocation;
		
		[defaultSteamAppsPath release];
		defaultSteamAppsPath = nil;
		
		[steamAppsPath release];
		steamAppsPath = nil;
		
		sourceFinaglerLaunchAgentStatus = VSSourceFinaglerLaunchAgentStatusUnknown;
		
		[sourceFinaglerLaunchAgentPath release];
		sourceFinaglerLaunchAgentPath = nil;
		
		NSDate *startTime = [NSDate date];
		
		MDFolderManager *folderManager = [MDFolderManager defaultManager];
		NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
		BOOL isDir;
		NSError *outError = nil;
		
		NSString *appSupportFolder = [folderManager pathForDirectory:MDApplicationSupportDirectory inDomain:MDUserDomain error:&outError];
		if (appSupportFolder == nil) {
			NSLog(@"[%@ %@] failed to locate Application Support folder!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			return;
		}
		
		defaultSteamAppsPath = [[[appSupportFolder stringByAppendingPathComponent:@"Steam"] stringByAppendingPathComponent:VSSteamAppsDirectoryNameKey] retain];
		
		NSDictionary *attributes = [fileManager attributesOfItemAtPath:defaultSteamAppsPath error:&outError];
		
		if ([[attributes fileType] isEqualToString:NSFileTypeSymbolicLink]) {
			// exists and is symlink
			steamAppsRelocationType = VSSteamAppsSymlinkRelocation;
			
			steamAppsPath = [defaultSteamAppsPath stringByResolvingSymlinksInPath];
			
			if ([steamAppsPath isEqualToString:defaultSteamAppsPath]) {
				// broken symlink
				steamAppsPath = nil;
			} else {
				steamAppsPath = [steamAppsPath retain];
			}
		} else if (attributes) {
			// exists and is original folder
			steamAppsRelocationType = VSSteamAppsNoRelocation;
			steamAppsPath = [defaultSteamAppsPath retain];
		} else {
			// doesn't exist
		}
		
		if (steamAppsPath == nil) {
			NSLog(@"[%@ %@] steamAppsPath does not exist...", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			return;
		}
		
		if ( !([fileManager fileExistsAtPath:steamAppsPath isDirectory:&isDir] && isDir)) {
			NSLog(@"[%@ %@] steamAppsPath doesn't exist, or exists, but is a file, not a folder!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			return;
		}
		
		NSMutableArray *uniqueNewGames = [NSMutableArray array];
		
		
		NSAutoreleasePool *localPool = [[NSAutoreleasePool alloc] init];
		
		NSArray *shallowSubpaths = [fileManager contentsOfDirectoryAtPath:steamAppsPath error:&outError];
		
		if (shallowSubpaths == nil) {
			NSLog(@"[%@ %@] failed to get shallowSubpaths; error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), outError);
			[localPool release];
			return;
		}
		
		for (NSString *shallowSubpath in shallowSubpaths) {
			NSString *fullPath = [steamAppsPath stringByAppendingPathComponent:shallowSubpath];
			
			// If it's not a folder, skip it
			if ( !([fileManager fileExistsAtPath:fullPath isDirectory:&isDir] && isDir)) {
				continue;
			}
			
			// we're inside
			// 
			// /SteamApps/common/
			//			or
			// /SteamApps/<username>/
			//
			// Get a list of the shallow subpaths here to find the folder for each game
			
			
			NSArray *gameFolderFilenames = [fileManager contentsOfDirectoryAtPath:fullPath error:&outError];
			
			if (gameFolderFilenames == nil) {
				continue;
			}
			
			for (NSString *gameFolderFilename in gameFolderFilenames) {
				
				NSString *gameFolderFullPath = [fullPath stringByAppendingPathComponent:gameFolderFilename];
				
				// Since we're only concerned with paths that represent folders, skip any full paths that represent files
				
				if ( !([fileManager fileExistsAtPath:gameFolderFullPath isDirectory:&isDir] && isDir)) {
					continue;
				}
				// Now, inside the game folder, get a shallow list of filenames and look for any filenames that match
				// the known executable names (currently "hl2_osx", "csgo_osx", and "portal2_osx")
				
				NSArray *rootContents = [fileManager contentsOfDirectoryAtPath:gameFolderFullPath error:&outError];
				
				if (rootContents == nil) {
					continue;
				}
				
				for (NSString *rootItemName in rootContents) {
					if ([knownExecutableNames containsObject:rootItemName]) {
					
						NSString *fullGamePath = [gameFolderFullPath stringByAppendingPathComponent:rootItemName];
						
						VSGame *game = [gamePathsAndGames objectForKey:VSMakeGamePathKey(fullGamePath)];
						
						if (game) {
							[game synchronizeHelped];
							continue;
						}
						NSArray *appInfos = [gameBundleIdentifiersAndGames allValues];
						
						for (NSDictionary *appInfo in appInfos) {
							if ([[appInfo objectForKey:VSGameNameKey] isEqualToString:gameFolderFilename] || [[appInfo objectForKey:VSGameLongNameKey] isEqualToString:gameFolderFilename]) {
								
								// search to see if this app has an "upgraded" app manifest file
								
								NSNumber *gameID = [appInfo objectForKey:VSGameIDKey];
								NSString *manifestName = [[VSAppManifestPrefixKey stringByAppendingString:[NSString stringWithFormat:@"%@", gameID]] stringByAppendingPathExtension:VSAppManifestPathExtensionKey];
								NSURL *appManifestURL = nil;
								NSString *appManifestPath = [steamAppsPath stringByAppendingPathComponent:manifestName];
								if ([fileManager fileExistsAtPath:appManifestPath isDirectory:&isDir] && !isDir) {
									appManifestURL = [NSURL fileURLWithPath:appManifestPath];
								}
								
								VSGame *game = [VSGame gameWithExecutableURL:[NSURL fileURLWithPath:fullGamePath] infoPlist:appInfo appManifestURL:appManifestURL];
								if (game) [uniqueNewGames addObject:game];
							}
						}
					}
				}
			}
		}
		
		[localPool release];
		
		
		for (VSGame *newGame in uniqueNewGames) {
			[gamePathsAndGames setObject:newGame forKey:VSMakeGamePathKey(newGame.executableURL.path)];
		}
		
		
		NSMutableArray *foundRunningGames = [NSMutableArray array];
		
		NSArray *installedGamePaths = [gamePathsAndGames allKeys];
		
		NSArray *launchedApps = [[NSWorkspace sharedWorkspace] launchedApplications];
		
		for (NSDictionary *launchedApp in launchedApps) {
			NSString *gamePath = [[launchedApp objectForKey:@"NSApplicationPath"] stringByResolvingSymlinksInPath];
			
			if ([installedGamePaths containsObject:VSMakeGamePathKey(gamePath)]) {
				VSGame *game = [gamePathsAndGames objectForKey:VSMakeGamePathKey(gamePath)];
				[game setProcessIdentifier:[[launchedApp objectForKey:@"NSApplicationProcessIdentifier"] intValue]];
				[foundRunningGames addObject:[gamePathsAndGames objectForKey:VSMakeGamePathKey(gamePath)]];
			}
		}
		
		NSMutableArray *previousRunningGames = [[[runningGamePathsAndGames allValues] mutableCopy] autorelease];
		
		NSArray *allGames = [gamePathsAndGames allValues];
		
		for (VSGame *game in allGames) {
			BOOL presentInBefore = [previousRunningGames containsObject:game];
			BOOL presentInAfter = [foundRunningGames containsObject:game];
			
			if (presentInBefore && !presentInAfter) {
				// terminated
				
				[game setRunning:NO];
				[game setProcessIdentifier:-1];
				[runningGamePathsAndGames removeObjectsForKeys:[runningGamePathsAndGames allKeysForObject:game]];
				if (delegate && [delegate respondsToSelector:@selector(gameDidTerminate:)]) {
					[delegate gameDidTerminate:game];
				}
				
			} else if (!presentInBefore && presentInAfter) {
				// newly running
				
				[game setRunning:YES];
				
				[runningGamePathsAndGames setObject:game forKey:VSMakeGamePathKey(game.executableURL.path)];
				if (delegate && [delegate respondsToSelector:@selector(gameDidLaunch:)]) {
					[delegate gameDidLaunch:game];
				}
			}
		}
		
		/* Source Finagler Launch Agent */
		NSString *sourceFinaglerDirectory = [folderManager pathForDirectoryWithName:@"Source Finagler" inDirectory:MDApplicationSupportDirectory inDomain:MDUserDomain create:NO error:&outError];
		
		NSString *sourceFinaglerAgentPath = [sourceFinaglerDirectory stringByAppendingPathComponent:VSSourceFinaglerAgentNameKey];
		
		if (sourceFinaglerAgentPath && [fileManager fileExistsAtPath:sourceFinaglerAgentPath isDirectory:&isDir] && isDir) {
			sourceFinaglerLaunchAgentStatus = VSSourceFinaglerLaunchAgentInstalled;
			sourceFinaglerLaunchAgentPath = [sourceFinaglerAgentPath retain];
			
			NSString *sourcePath = [[NSBundle bundleForClass:[self class]] pathForResource:[VSSourceFinaglerAgentNameKey stringByDeletingPathExtension]	ofType:@"app"];
			if (sourcePath == nil) sourcePath = [[NSBundle mainBundle] pathForResource:[VSSourceFinaglerAgentNameKey stringByDeletingPathExtension]	ofType:@"app"];
			if (sourcePath == nil) {
				if ([[[NSBundle mainBundle] objectForInfoDictionaryKey:(id)kCFBundleIdentifierKey] isEqualToString:VSSourceFinaglerBundleIdentifierKey]) {
					NSLog(@"[%@ %@] couldn't locate %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), VSSourceFinaglerAgentNameKey);
				}
			}
			if (sourcePath) {
				NSBundle *sourceBundle = [NSBundle bundleWithPath:sourcePath];
				if (sourceBundle) {
					NSString *sourceVersionString = [sourceBundle objectForInfoDictionaryKey:(id)kCFBundleVersionKey];
					
					/* Because of NSBundle's caching mechanism, we can't use NSBundle to accurately inquire for info 
					 about a bundle if we've modified that bundle externally on the file system.
					 
					 For example, let's say we create an NSBundle for the installed SourceFinaglerAgent.app bundle, to
					 check its CFBundleVersion to see whether we need to update it to the current version. If we find
					 that the installed version is 203, and our source version is 250, we then proceed to replace the 
					 installed version. Despite the fact that we've updated the installed version, the next time we
					 create an NSBundle for the installed SourceFinaglerAgent.app bundle, it will return a cached 
					 instance of the first one, which won't provide accurate info the second time around.
					 
					 For this reason, we use CFBundleCopyInfoDictionaryInDirectory(), which bypasses the caching mechanism of NSBundle.
					 
					 See: http://www.cocoabuilder.com/archive/cocoa/120448-nsbundle-bundlewithpath-avoiding-the-cache.html */
					
					
					NSDictionary *installedBundleInfo = [(NSDictionary *)CFBundleCopyInfoDictionaryInDirectory((CFURLRef)[NSURL fileURLWithPath:sourceFinaglerLaunchAgentPath]) autorelease];
					if (installedBundleInfo) {
						NSString *installedVersionString = [installedBundleInfo objectForKey:(id)kCFBundleVersionKey];
						NSInteger sourceVersion = [sourceVersionString integerValue];
						NSInteger installedVersion = [installedVersionString integerValue];
						
						if (sourceVersion > installedVersion) {
							sourceFinaglerLaunchAgentStatus = VSSourceFinaglerLaunchAgentUpdateNeeded;
						}
					}
				}
			}
		} else {
			sourceFinaglerLaunchAgentStatus = VSSourceFinaglerLaunchAgentNotInstalled;
		}
		
		
		timeToLocateSteamApps = fabs([startTime timeIntervalSinceNow]);
#if VS_DEBUG
		NSLog(@"[%@ %@] timeToLocateSteamApps == %.7f sec (%.4f ms)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), timeToLocateSteamApps, timeToLocateSteamApps * 1000.0);
#endif
		
		locatedSteamApps = YES;
	}
	
#if VS_DEBUG
	static const NSString * const VSDescriptions[] = {
		@"VSSourceFinaglerLaunchAgentStatusUnknown",
		@"VSSourceFinaglerLaunchAgentNotInstalled",
		@"VSSourceFinaglerLaunchAgentInstalled",
		@"VSSourceFinaglerLaunchAgentUpdateNeeded",
	};
	
	NSLog(@"[%@ %@] gamePathsAndGames == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), gamePathsAndGames);
	NSLog(@"[%@ %@] sourceFinaglerLaunchAgentPath == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sourceFinaglerLaunchAgentPath);
	NSLog(@"[%@ %@] sourceFinaglerLaunchAgentStatus == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), VSDescriptions[sourceFinaglerLaunchAgentStatus]);
	
#endif
	
}



- (BOOL)isProposedRelocationPathValid:(NSString *)proposedPath errorDescription:(NSString **)errorDescription {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (errorDescription) *errorDescription = nil;
	
	NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
	BOOL isDir;
	
	BOOL itemExists				= NO;
	BOOL isSteamAppsFolder		= NO;
	BOOL isOriginalFolder		= NO;
	BOOL isOriginalSymbolicLink	= NO;
	
	isOriginalSymbolicLink = [proposedPath isEqualToString:defaultSteamAppsPath];
	
	itemExists = [fileManager fileExistsAtPath:proposedPath];
	isSteamAppsFolder = [fileManager fileExistsAtPath:proposedPath isDirectory:&isDir] && isDir &&
						[[proposedPath lastPathComponent] isEqualToString:VSSteamAppsDirectoryNameKey];
	
	if (steamAppsPath) isOriginalFolder = [proposedPath isEqualToString:steamAppsPath];
	
	if (itemExists && isSteamAppsFolder && !isOriginalFolder && !isOriginalSymbolicLink) {
		if (errorDescription) *errorDescription = @"";
		return YES;
		
	} else if (itemExists && isSteamAppsFolder && !isOriginalFolder && isOriginalSymbolicLink) {
		if (errorDescription) *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Cannot choose original %@ shortcut", @""), VSSteamAppsDirectoryNameKey];
		return NO;
		
	} else if (itemExists && !isSteamAppsFolder) {
		if (errorDescription) *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Folder must be named \"%@\"", @""), VSSteamAppsDirectoryNameKey];
		return NO;
		
	} else if (!itemExists) {
		if (errorDescription) *errorDescription = NSLocalizedString(@"Item does not exist", @"");
		return NO;
		
	} else if (isOriginalFolder) {
		if (errorDescription) *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Cannot choose original %@ folder", @""), VSSteamAppsDirectoryNameKey];
		return NO;
	}
	return NO;
}



- (BOOL)relocateSteamAppsToPath:(NSString *)aPath error:(NSError **)outError {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	BOOL success = YES;
	
	// in case we haven't fully implemented NSError reporting at all levels:
	if (outError) *outError = nil;
	
	NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
	NSError *localError = nil;
	
	NSDictionary *attributes = [fileManager attributesOfItemAtPath:defaultSteamAppsPath error:&localError];
	
	if ([[attributes fileType] isEqualToString:NSFileTypeSymbolicLink]) {
		// item is a broken symbolic link
		if (![fileManager moveItemAtPath:defaultSteamAppsPath toPath:[[defaultSteamAppsPath stringByAppendingString:NSLocalizedString(@" (Original)", @"")] stringByAssuringUniqueFilename] error:&localError]) {
			NSLog(@"[%@ %@] error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), localError);
			if (outError) *outError = localError;
		}
	} else {
		if ([fileManager fileExistsAtPath:defaultSteamAppsPath]) {
			if (![fileManager moveItemAtPath:defaultSteamAppsPath toPath:[[defaultSteamAppsPath stringByAppendingString:NSLocalizedString(@" (Original)", @"")] stringByAssuringUniqueFilename] error:&localError]) {
				NSLog(@"[%@ %@] error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), localError);
				if (outError) *outError = localError;
			}
		}
	}
	
	if (![fileManager fileExistsAtPath:defaultSteamAppsPath]) {
		if ([fileManager createSymbolicLinkAtPath:defaultSteamAppsPath withDestinationPath:aPath error:&localError]) {
			[self locateSteamApps];
		} else {
			NSLog(@"[%@ %@] error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), localError);
			success = NO;
		}
	}
	return success;
}


+ (VSGameOptions)defaultPersistentOptions {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	VSGameOptions options = VSGameOptionsDefault;
	
	[defaultPersistentOptionsLock lock];
	options = defaultPersistentOptions;
	[defaultPersistentOptionsLock unlock];
	
	return options;
}


+ (void)setDefaultPersistentOptions:(VSGameOptions)options {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[defaultPersistentOptionsLock lock];
	defaultPersistentOptions = options;
	[defaultPersistentOptionsLock unlock];
}


- (VSGameOptions)persistentOptionsForGame:(VSGame *)game {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSParameterAssert(game != nil);
	
	if (!locatedSteamApps) [self locateSteamApps];
	
	VSGameOptions launchOptions = VSGameOptionsDoNotHelpGame;
	
	@synchronized(self) {
		NSString *bundleIdentifier = [[game infoDictionary] objectForKey:(id)kCFBundleIdentifierKey];
		if (bundleIdentifier == nil) return VSGameOptionsDoNotHelpGame;
		
		launchOptions = [[[NSUserDefaults standardUserDefaults] objectForKey:bundleIdentifier] unsignedIntegerValue];
	}
	return launchOptions;
}


static inline NSString *VSMakeLabelFromBundleIdentifier(NSString *bundleIdentifier) {
	NSCParameterAssert(bundleIdentifier != nil);
	
	NSString *gameName = nil;
	NSRange vsRange = [bundleIdentifier rangeOfString:@"com.valvesoftware."];
	if (vsRange.location != NSNotFound) {
		gameName = [bundleIdentifier substringFromIndex:vsRange.location + vsRange.length];
	} else {
		// not a valve game, just use pathExtension
		gameName = [bundleIdentifier pathExtension];
	}
	NSString *label = [NSString stringWithFormat:@"%@.%@", VSSourceFinaglerAgentBundleIdentifierKey, gameName];
	return label;
}


- (BOOL)setPersistentOptions:(VSGameOptions)options forGame:(VSGame *)game error:(NSError **)outError {
#if VS_DEBUG
	NSLog(@"[%@ %@] options == %lu, game == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)options, game);
#endif
	NSParameterAssert(game != nil);
	
	// in case we haven't fully implemented NSError reporting at all levels:
	if (outError) *outError = nil;
	
	if (!locatedSteamApps) [self locateSteamApps];
	
	if (options & VSGameOptionsHelpGame && sourceFinaglerLaunchAgentStatus != VSSourceFinaglerLaunchAgentInstalled) {
		[self installSourceFinaglerLaunchAgentWithError:outError];
	}
	
	@synchronized(self) {
		
		NSString *bundleIdentifier = [[game infoDictionary] objectForKey:(id)kCFBundleIdentifierKey];
		if (bundleIdentifier == nil) {
			NSLog(@"[%@ %@] *** NOTICE: game.infoDictionary.kCFBundleIdentifierKey == nil!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			return NO;
		}
		
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithUnsignedInteger:options] forKey:bundleIdentifier];
		
		if (options & VSGameOptionsHelpGame || options == VSGameOptionsDoNotHelpGame) {
			NSString *jobLabel = VSMakeLabelFromBundleIdentifier(bundleIdentifier);
			MDLaunchManager *launchManager = [MDLaunchManager defaultManager];
			
			NSDictionary *existingJob = [launchManager jobWithLabel:jobLabel inDomain:MDLaunchUserDomain];
			if (existingJob) {
				
				if (![launchManager removeJobWithLabel:jobLabel inDomain:MDLaunchUserDomain error:outError]) {
					NSLog(@"[%@ %@] failed to remove existing job!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
					return NO;
				}
			}
			
			if (options & VSGameOptionsHelpGame) {
				
				NSBundle *sourceFinaglerAgentBundle = [NSBundle bundleWithPath:sourceFinaglerLaunchAgentPath];
				if (sourceFinaglerAgentBundle == nil) {
					NSLog(@"[%@ %@] *** ERROR: [NSBundle bundleWithPath:sourceFinaglerLaunchAgentPath] returned nil! (sourceFinaglerLaunchAgentPath == %@)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sourceFinaglerLaunchAgentPath);
					return NO;
				}
				
				NSString *launchAgentExecutablePath = [sourceFinaglerAgentBundle executablePath];
				if (launchAgentExecutablePath == nil) {
					NSLog(@"[%@ %@] *** ERROR: [sourceFinaglerAgentBundle executablePath] returned nil!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
					return NO;
				}
				
				NSDictionary *launchPlist = VSMakeLaunchAgentPlist(jobLabel, [NSArray arrayWithObjects:launchAgentExecutablePath, game.executableURL.path, nil], game.executableURL.path);
				if (launchPlist == nil) {
					NSLog(@"[%@ %@] *** ERROR: VSMakeLaunchAgentPlist() returned nil!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
					return NO;
				}
				
				if (![launchManager submitJobWithDictionary:launchPlist inDomain:MDLaunchUserDomain error:outError]) {
					NSLog(@"[%@ %@] failed to submit job!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
					return NO;
				}
			}
		}
	}
	return YES;
}

- (VSSourceFinaglerLaunchAgentStatus)sourceFinaglerLaunchAgentStatus {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (!locatedSteamApps) [self locateSteamApps];
    return sourceFinaglerLaunchAgentStatus;
}


- (BOOL)installSourceFinaglerLaunchAgentWithError:(NSError **)outError {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	@synchronized(self) {
		
		// in case we haven't fully implemented NSError reporting at all levels:
		if (outError) *outError = nil;
		
		// To minimize the amount of hard-coding of paths that we do, we (obviously) define the names of items above as constants,
		// and use NSBundle to handle obtaining the paths at runtime.
		
		NSString *sourcePath = [[NSBundle bundleForClass:[self class]] pathForResource:[VSSourceFinaglerAgentNameKey stringByDeletingPathExtension]	ofType:@"app"];
		if (sourcePath == nil) sourcePath = [[NSBundle mainBundle] pathForResource:[VSSourceFinaglerAgentNameKey stringByDeletingPathExtension]	ofType:@"app"];
		if (sourcePath == nil) {
			NSLog(@"[%@ %@] couldn't locate %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), VSSourceFinaglerAgentNameKey);
			return NO;
		}
		
		if (!locatedSteamApps) [self locateSteamApps];
		
		MDFolderManager *folderManager = [MDFolderManager defaultManager];
		NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
		
		NSString *sourceFinaglerDirectory = [folderManager pathForDirectoryWithName:@"Source Finagler" inDirectory:MDApplicationSupportDirectory inDomain:MDUserDomain create:YES error:outError];
		
		if (sourceFinaglerDirectory == nil) {
			NSLog(@"[%@ %@] failed to create Source Finagler application support directory!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			return NO;
		}
		
		NSString *sourceFinaglerAgentPath = [sourceFinaglerDirectory stringByAppendingPathComponent:VSSourceFinaglerAgentNameKey];
		
		[fileManager removeItemAtPath:sourceFinaglerAgentPath error:NULL];
		
		if (![fileManager copyItemAtPath:sourcePath toPath:sourceFinaglerAgentPath error:outError]) {
			NSLog(@"[%@ %@] failed to copy %@ to %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), VSSourceFinaglerAgentNameKey, sourceFinaglerAgentPath);
			return NO;
		}
		
		NSArray *allGames = [gamePathsAndGames allValues];
		
		NSBundle *sourceFinaglerAgentBundle = [NSBundle bundleWithPath:sourceFinaglerAgentPath];
		NSString *launchAgentExecutablePath = [sourceFinaglerAgentBundle executablePath];
		
		for (VSGame *game in allGames) {
			if (![game isHelped]) continue;
			
			NSString *bundleIdentifier = [[game infoDictionary] objectForKey:(id)kCFBundleIdentifierKey];
			if (bundleIdentifier == nil) continue;
			
			NSString *jobLabel = VSMakeLabelFromBundleIdentifier(bundleIdentifier);
			MDLaunchManager *launchManager = [MDLaunchManager defaultManager];
			
			NSDictionary *existingJob = [launchManager jobWithLabel:jobLabel inDomain:MDLaunchUserDomain];
			if (existingJob) {
				if (![launchManager removeJobWithLabel:jobLabel inDomain:MDLaunchUserDomain error:outError]) {
					NSLog(@"[%@ %@] failed to remove existing job!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
					return NO;
				}
			}
			
			if (launchAgentExecutablePath) {
				NSDictionary *launchPlist = VSMakeLaunchAgentPlist(jobLabel, [NSArray arrayWithObjects:launchAgentExecutablePath, game.executableURL.path, nil], game.executableURL.path);
				if (launchPlist == nil) return NO;
				if (![launchManager submitJobWithDictionary:launchPlist inDomain:MDLaunchUserDomain error:outError]) {
					NSLog(@"[%@ %@] failed to submit job!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
					return NO;
				}
			}
		}
	}
	[self locateSteamApps];
	return YES;
}

#define VS_SOURCE_FINAGLER_AGENT_THROTTLE_INTERVAL 2

static inline NSDictionary *VSMakeLaunchAgentPlist(NSString *jobLabel, NSArray *programArguments, NSString *aWatchPath) {
	NSCParameterAssert(jobLabel != nil && programArguments != nil && aWatchPath != nil);
	return [NSDictionary dictionaryWithObjectsAndKeys:jobLabel,NSStringFromLaunchJobKey(LAUNCH_JOBKEY_LABEL),
			programArguments, NSStringFromLaunchJobKey(LAUNCH_JOBKEY_PROGRAMARGUMENTS),
			[NSNumber numberWithBool:NO], NSStringFromLaunchJobKey(LAUNCH_JOBKEY_RUNATLOAD), 
			[NSNumber numberWithInteger:VS_SOURCE_FINAGLER_AGENT_THROTTLE_INTERVAL], NSStringFromLaunchJobKey(LAUNCH_JOBKEY_THROTTLEINTERVAL),
			[NSArray arrayWithObject:aWatchPath], NSStringFromLaunchJobKey(LAUNCH_JOBKEY_WATCHPATHS), nil];
}


- (BOOL)updateSourceFinaglerLaunchAgentWithError:(NSError **)outError {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	BOOL success = [self uninstallSourceFinaglerLaunchAgentWithError:outError];
	if (success) [self installSourceFinaglerLaunchAgentWithError:outError];
	return success;
}


- (BOOL)uninstallSourceFinaglerLaunchAgentWithError:(NSError **)outError {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	@synchronized(self) {
		
		// in case we haven't fully implemented NSError reporting at all levels:
		if (outError) *outError = nil;
		
		if (!locatedSteamApps) [self locateSteamApps];
		
		NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
		
		if (![fileManager removeItemAtPath:sourceFinaglerLaunchAgentPath error:outError]) {
			NSLog(@"[%@ %@] failed to remove SourceFinaglerAgent!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			return NO;
		}
		
		MDLaunchManager *launchManager = [MDLaunchManager defaultManager];
		
		NSArray *gameBundleIdentifiers = [gameBundleIdentifiersAndGames allKeys];
		
		for (NSString *bundleIdentifier in gameBundleIdentifiers) {
			NSString *jobLabel = VSMakeLabelFromBundleIdentifier(bundleIdentifier);
			if (jobLabel == nil) continue;
			NSDictionary *job = [launchManager jobWithLabel:jobLabel inDomain:MDLaunchUserDomain];
			if (job) [launchManager removeJobWithLabel:jobLabel inDomain:MDLaunchUserDomain error:outError];
		}
	}
	[self locateSteamApps];
	return YES;
}


- (VSGame *)gameWithPath:(NSString *)aPath {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSParameterAssert(aPath != nil);
	if (!locatedSteamApps) [self locateSteamApps];
	return [gamePathsAndGames objectForKey:VSMakeGamePathKey(aPath)];
}


- (VSGame *)gameWithGameID:(VSGameID)anID {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (!locatedSteamApps) [self locateSteamApps];
	for (VSGame *game in self.games) {
		if (game.gameID == anID) return game;
	}
	return nil;
}


- (NSArray *)games {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (!locatedSteamApps) [self locateSteamApps];
	
	NSArray *games = nil;
	[gamePathsAndGamesLock lock];
	games = [[gamePathsAndGames allValues] copy];
	[gamePathsAndGamesLock unlock];
	
	return [games autorelease];
}


- (NSArray *)runningGames {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (!locatedSteamApps) [self locateSteamApps];
	
	NSArray *runningGames = nil;
	[runningGamePathsAndGamesLock lock];
	runningGames = [[runningGamePathsAndGames allValues] copy];
	[runningGamePathsAndGamesLock unlock];
	
	return [runningGames autorelease];
}



- (BOOL)helpGame:(VSGame *)game forUSBOverdrive:(BOOL)helpForUSBOverdrive updateLaunchAgent:(BOOL)updateLaunchAgent error:(NSError **)outError {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSParameterAssert(game != nil);
	
	BOOL success = YES;
	
	// in case we haven't fully implemented NSError reporting at all levels:
	if (outError) *outError = nil;
	
	NSString *executablePath = game.executableURL.path;
	
	MDFileManager *mdFileManager = [[[MDFileManager alloc] init] autorelease];
	
	NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
	
	NSDictionary *infoPlist = [game infoDictionary];
	NSString *errorDescription = nil;
	
	NSData *propertyListData = [NSPropertyListSerialization dataFromPropertyList:infoPlist format:NSPropertyListXMLFormat_v1_0 errorDescription:&errorDescription];
	
	if (propertyListData == nil) {
		NSLog(@"[%@ %@] propertyListData == nil! errorDescription == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), errorDescription);
		
		if (outError && errorDescription) {
			*outError = [NSError errorWithDomain:VSErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:errorDescription,NSLocalizedDescriptionKey, nil]];
		}
		return NO;
	}
	
	NSString *propertyListString = [[[NSString alloc] initWithData:propertyListData encoding:NSUTF8StringEncoding] autorelease];
	if (propertyListString) {
		// old-style 'plst' resources require carriage-returns
		propertyListString = [propertyListString stringByReplacingOccurrencesOfString:@"\n" withString:@"\r"];
	}
	propertyListData = [propertyListString dataUsingEncoding:NSUTF8StringEncoding];
	
	if (propertyListData == nil) {
		if (outError) *outError = nil;
		NSLog(@"[%@ %@] failed to convert propertyListData!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return NO;
	}
	
	MDResource *plistResource = [[[MDResource alloc] initWithType:'plst'
													 resourceData:propertyListData
													   resourceID:0
													 resourceName:@""
													resourceIndex:1
											   resourceAttributes:0
													   resChanged:YES
															 copy:NO
															error:outError] autorelease];
	if (plistResource == nil) {
		NSLog(@"[%@ %@] failed to create plistResource! error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (outError ? *outError : nil));
		return NO;
	}
	
	MDResourceFile *resourceFile = [[[MDResourceFile alloc] initForUpdatingWithContentsOfFile:executablePath fork:MDResourceFork error:outError] autorelease];
	
	if (resourceFile == nil) {
		NSLog(@"[%@ %@] failed to create resource file! error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (outError ? *outError : nil));
		return NO;
	}
	
	if (![resourceFile addResource:plistResource error:outError]) {
		[resourceFile closeResourceFile];
		return NO;
	}
	
	// Note: we only want to add a custom resource icon if the game has an icon that is in `icns` format. For some games who only have a Windows .ico file we should ignore or try generic app icon.
	
	NSString *iconDataPath = nil;
	NSData *iconData = nil;
	BOOL hasCustomIcon = NO;
	
	if ([[[game.iconURL.path pathExtension] lowercaseString] isEqualToString:@"icns"]) {
		// we can use the game's .icns file data
		iconDataPath = game.iconURL.path;
		
	} else {
		/* If we don't have ICNS data, try to use the generic application icon data.
		 
		 I hate having to hardcode the path to '/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns', but I couldn't
		 find another way to get the generic app icon data in the same format as the `.icns` file without extensive coding or using deprecated methods. */
		
		if ([fileManager fileExistsAtPath:VSGenericApplicationIconPath]) iconDataPath = VSGenericApplicationIconPath;
	}
	
	if (iconDataPath) iconData = [NSData dataWithContentsOfFile:iconDataPath];
	
	if (iconData) {
		MDResource *iconResource = [[[MDResource alloc] initWithType:kIconFamilyType
														resourceData:iconData
														  resourceID:kCustomIconResource
														resourceName:@""
													   resourceIndex:1
												  resourceAttributes:0
														  resChanged:YES
																copy:NO
															   error:outError] autorelease];
		
		if (iconResource) {
			if ([resourceFile addResource:iconResource error:outError]) {
				hasCustomIcon = YES;
			} else {
				// don't consider failing to add custom resource a complete error, but do keep track for the custom icon file flag
				NSLog(@"[%@ %@] failed to add iconResource; error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (outError ? *outError : nil));
			}
		}
	}
	[resourceFile closeResourceFile];
	
	
	OSType creatorCode = [game creatorCode];
	
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:creatorCode],NSFileHFSCreatorCode,
								[NSNumber numberWithUnsignedInt:'APPL'],NSFileHFSTypeCode,
								[NSNumber numberWithBool:hasCustomIcon],MDFileHasCustomIcon, nil];
	
	if (![mdFileManager setAttributes:attributes ofItemAtPath:executablePath error:outError]) {
		success = NO;
	}
	
	if (helpForUSBOverdrive) {
		
		NSString *executableName = [executablePath lastPathComponent];
		
		NSString *executableBundleName = [executableName stringByAppendingString:NSLocalizedString(@" (for USB Overdrive).app", @"")];
		
		NSString *destUSBPath = [[executablePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:executableBundleName];
		
		BOOL isDir;
		
		if ([fileManager fileExistsAtPath:destUSBPath isDirectory:&isDir] && isDir) {
			if (![fileManager removeItemAtPath:destUSBPath error:outError]) {
				
			}
		}
		
		NSString *sourcePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"hl2_osx" ofType:@"app"];
		if (sourcePath == nil) {
			NSLog(@"[%@ %@] could not find 'hl2_osx.app' inside framework!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			return NO;
		}
		
		if (![fileManager copyPath:sourcePath toPath:destUSBPath handler:nil]) {
			NSLog(@"[%@ %@] failed to copy hl2_osx.app to destination!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			return NO;
		}
		
		// the current bundle's executable name is 'hl2_osx', so we may need to rename it to corresponding app
		
		if (![executableName isEqualToString:VSHalfLife2ExecutableNameKey]) {
			NSString *executableMacOSPath = [[destUSBPath stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"MacOS"];
			
			if (![fileManager movePath:[executableMacOSPath stringByAppendingPathComponent:VSHalfLife2ExecutableNameKey]
								toPath:[executableMacOSPath stringByAppendingPathComponent:executableName]
							   handler:nil]) {
				
				NSLog(@"[%@ %@] failed to rename 'hl2_osx' to '%@'!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), executableName);
				return NO;
			}
		}
		
		NSString *iconPath = game.iconURL.path;
		
		if ([fileManager fileExistsAtPath:iconPath isDirectory:&isDir] && !isDir) {
			NSString *destIconPath = [[[destUSBPath stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Resources"] stringByAppendingPathComponent:[iconPath lastPathComponent]];
			if ([fileManager fileExistsAtPath:destIconPath isDirectory:&isDir] && !isDir) {
				if (![fileManager removeItemAtPath:destIconPath	error:outError]) {
					NSLog(@"[%@ %@] failed to remove item at %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), destIconPath);
					return NO;
				}
			}
			if (![fileManager copyPath:iconPath toPath:destIconPath handler:nil]) {
				NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
				return NO;
			}
		}
		
		NSString *creatorCodeString = [infoPlist objectForKey:@"CFBundleSignature"];
		NSString *PkgInfoString = [@"APPL" stringByAppendingString:creatorCodeString];
		if (![PkgInfoString writeToFile:[[destUSBPath stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"PkgInfo"] atomically:YES	encoding:NSUTF8StringEncoding error:outError]) {
			NSLog(@"[%@ %@] failed to write PkgInfo file!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			return NO;
		}
		
		NSMutableDictionary *mInfoPlist = [[infoPlist mutableCopy] autorelease];
		if (iconPath) [mInfoPlist setObject:[[iconPath lastPathComponent] stringByDeletingPathExtension] forKey:@"CFBundleIconFile"];
		
		[mInfoPlist setObject:@"NSApplication" forKey:@"NSPrincipalClass"];
		[mInfoPlist setObject:@"MainMenu" forKey:@"NSMainNibFile"];
		
		
		if (![mInfoPlist writeToFile:[[destUSBPath stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Info.plist"] atomically:YES]) {
			NSLog(@"[%@ %@] failed to write Info.plist!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			return NO;
		}
		
		// touch the app bundle for Launch Services
		if (![fileManager setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSDate date],NSFileModificationDate, nil] ofItemAtPath:destUSBPath error:outError]) {
			NSLog(@"[%@ %@] NOTICE: failed to touch item at \"%@\"!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), destUSBPath);
		}
		
		OSStatus status = LSRegisterURL((CFURLRef)[NSURL fileURLWithPath:destUSBPath], true);
		if (status != noErr) {
			NSLog(@"[%@ %@] LSRegisterURL() returned %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (int)status);
		}
	}
	
	if (updateLaunchAgent) {
		@synchronized(self) {
			if (sourceFinaglerLaunchAgentStatus == VSSourceFinaglerLaunchAgentInstalled) {
				[self setPersistentOptions:VSGameOptionsHelpGame forGame:game error:outError];
			}
		}
	}
	
	return success;
}


- (BOOL)unhelpGame:(VSGame *)game error:(NSError **)outError {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSParameterAssert(game != nil);
	
	BOOL success = YES;
	
	// in case we haven't fully implemented NSError reporting at all levels:
	if (outError) *outError = nil;
	
	NSString *executablePath = game.executableURL.path;
	
	MDResourceFile *resourceFile = [[[MDResourceFile alloc] initForUpdatingWithContentsOfFile:executablePath fork:MDResourceFork error:outError] autorelease];
	if (resourceFile == nil) return NO;
	
	if ([resourceFile plistResource]) {
		if (![resourceFile removeResource:[resourceFile plistResource] error:outError]) {
			NSLog(@"[%@ %@] remove plist resource failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			[resourceFile closeResourceFile];
			return NO;
		}
	}
	if ([resourceFile customIconResource]) {
		if (![resourceFile removeResource:[resourceFile customIconResource] error:outError]) {
			NSLog(@"[%@ %@] remove customIconResource resource failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			[resourceFile closeResourceFile];
			return NO;
		}
	}
	
	[resourceFile closeResourceFile];
		
	MDFileManager *mdFileManager = [[[MDFileManager alloc] init] autorelease];
	
	NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
	
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:0],NSFileHFSCreatorCode,
								[NSNumber numberWithUnsignedInt:0],NSFileHFSTypeCode,
								[NSNumber numberWithBool:NO],MDFileHasCustomIcon, nil];
	
	if (![mdFileManager setAttributes:attributes ofItemAtPath:executablePath error:outError]) {
		success = NO;
	}
	
	NSString *executableName = [executablePath lastPathComponent];
	
	NSString *executableBundleName = [executableName stringByAppendingString:NSLocalizedString(@" (for USB Overdrive).app", @"")];
	
	NSString *bundledAppPath = [[executablePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:executableBundleName];
	
	@synchronized(self) {
		if (sourceFinaglerLaunchAgentStatus == VSSourceFinaglerLaunchAgentInstalled) {
			[self setPersistentOptions:VSGameOptionsDoNotHelpGame forGame:game error:outError];
		}
	}
	
	BOOL isDir;
	
	if ([fileManager fileExistsAtPath:bundledAppPath isDirectory:&isDir] && isDir) {
		if (![fileManager removeItemAtPath:bundledAppPath error:outError]) {
			return NO;
		}
	}
	return YES;
}


- (BOOL)launchGame:(VSGame *)game options:(VSGameOptions)options error:(NSError **)outError {
	NSParameterAssert(game != nil);
	
	// in case we haven't fully implemented NSError reporting at all levels:
	if (outError) *outError = nil;
	
	if (options & VSGameOptionsHelpGame && ![game isHelped]) {
		if (![self helpGame:game forUSBOverdrive:YES updateLaunchAgent:NO error:outError]) return NO;
	}
	
	NSURL *URL = [NSURL URLWithString:[VSSteamLaunchGameURL stringByAppendingFormat:@"%lu", (unsigned long)[game gameID]]];
	if (URL) {
		if (![[NSWorkspace sharedWorkspace] openURL:URL]) {
			NSLog(@"[%@ %@] openURL: failed for %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), URL);
			return NO;
		}
	}
	return YES;
}


- (void)installSourceAddon:(VSSourceAddon *)sourceAddon usingMethod:(VSSourceAddonInstallMethod)installMethod {
#if VS_DEBUG
	NSLog(@"[%@ %@]   %@  ", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sourceAddon.fileName);
#endif
	NSParameterAssert(sourceAddon != nil);
	
	VSSourceAddonInstallOperation *operation = [[VSSourceAddonInstallOperation alloc] initWithSourceAddon:sourceAddon installMethod:installMethod];
	if (operation) {
		
		[sourceAddonOperationsLock lock];
		
		VSSourceAddonInstallOperation *lastOperation = [sourceAddonOperations lastObject];
		
		if (lastOperation) [operation addDependency:lastOperation];
		
		[sourceAddonOperations addObject:operation];
		
		[sourceAddonOperationsLock unlock];
		
		[sourceAddonOperationQueue addOperation:operation];
		
		[operation release];
	}
	
}


- (void)beginProcessingSourceAddonInstallOperationOnMainThread:(VSSourceAddonInstallOperation *)operation {
#if VS_DEBUG
	NSLog(@"[%@ %@]   %@  ", NSStringFromClass([self class]), NSStringFromSelector(_cmd), operation.sourceAddon.fileName);
#endif
	if ([delegate respondsToSelector:@selector(willInstallSourceAddon:)]) {
		
		[[operation retain] autorelease];
		
		[delegate willInstallSourceAddon:operation.sourceAddon];
	}
}


- (void)finishProcessingSourceAddonInstallOperationOnMainThread:(VSSourceAddonInstallOperation *)operation {
#if VS_DEBUG
	NSLog(@"[%@ %@]   %@  ", NSStringFromClass([self class]), NSStringFromSelector(_cmd), operation.sourceAddon.fileName);
//	NSLog(@"[%@ %@] sourceAddon == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), operation.sourceAddon);
#endif
	[[operation retain] autorelease];
	
	[sourceAddonOperationsLock lock];
	
	[sourceAddonOperations removeObject:operation];
	
	[sourceAddonOperationsLock unlock];
	
	VSSourceAddon *sourceAddon = operation.sourceAddon;
	
	if (sourceAddon.isInstalled) {
		if ([delegate respondsToSelector:@selector(didInstallSourceAddon:)]) {
			[delegate didInstallSourceAddon:sourceAddon];
		}
	} else {
		if ([delegate respondsToSelector:@selector(didFailToInstallSourceAddon:)]) {
			[delegate didFailToInstallSourceAddon:sourceAddon];
		}
	}
	
}


@end


