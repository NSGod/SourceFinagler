//
//  VSSteamManager.m
//  Source Finagler
//
//  Created by Mark Douma on 6/13/2010.
//  Copyright © 2010-2012 Mark Douma LLC. All rights reserved.
//


#import <SteamKit/VSSteamManager.h>
#import <SteamKit/VSGame.h>
#import "VSPrivateInterfaces.h"

#import <HLKit/HLKit.h>

#import "MDFolderManager.h"
#import "MDFileManager.h"
#import "MDLaunchManager.h"

#import "MDResource.h"
#import "MDResourceFile.h"


static NSString * const VSGameBundleIdentifiersAndGamesKey						= @"VSGameBundleIdentifiersAndGames";
static NSString * const VSExecutableNamesKey									= @"VSExecutableNames";
	
NSString * const VSGameIDKey				= @"VSGameID";
NSString * const VSGameSupportsAddonsKey	= @"VSGameSupportsAddons";
NSString * const VSGameNameKey				= @"VSGameName";
NSString * const VSGameShortNameKey			= @"VSGameShortName";
NSString * const VSGameLongNameKey			= @"VSGameLongName";
NSString * const VSGameCreatorCodeKey		= @"VSGameCreatorCode";
NSString * const VSGameBundleIdentifierKey	= @"VSGameBundleIdentifier";
NSString * const VSGameInfoPlistKey			= @"VSGameInfoPlist";


static NSString * const VSHalfLife2ExecutableNameKey							= @"hl2_osx";
static NSString * const VSPortal2ExecutableNameKey								= @"portal2_osx";
static NSString * const VSCounterStrikeGlobalOffensiveExecutableNameKey		= @"csgo_osx";


static NSString * const VSHalfLife2USBOverdriveExecutableNameKey							= @"hl2_osx (for USB Overdrive)";
static NSString * const VSPortal2USBOverdriveExecutableNameKey								= @"portal2_osx (for USB Overdrive)";
static NSString * const VSCounterStrikeGlobalOffensiveUSBOverdriveExecutableNameKey		= @"csgo_osx (for USB Overdrive)";


NSString * const VSResourceNameKey									= @"resource";
NSString * const VSGameIconNameKey									= @"game.icns";


NSString * const VSSteamAppsDirectoryNameKey						= @"SteamApps";

static NSString * const VSSourceFinaglerBundleIdentifierKey			= @"com.markdouma.SourceFinagler";

static NSString * const VSSourceFinaglerAgentNameKey					= @"SourceFinaglerAgent.app";

static NSString * const VSSourceFinaglerAgentBundleIdentifierKey		= @"com.markdouma.SourceFinaglerAgent";

static NSString * const VSTimeMachineDatabaseNameKey				= @"Backups.backupdb";

static NSString * const VSSteamLaunchGameURL						= @"steam://run/";


NSString * const VSSourceAddonErrorDomain							= @"com.markdouma.SourceFinagler.SourceAddonErrorDomain";
NSString * const VSSourceAddonGameIDKey								= @"VSSourceAddonGameID";

NSString * const VSSourceAddonFolderNameKey							= @"addons";

static NSString * const VSSourceAddonInfoNameKey					= @"addoninfo.txt";
static NSString * const VSSourceAddonSteamAppIDKey					= @"addonSteamAppID";



static inline NSDictionary *VSMakeLaunchAgentPlist(NSString *jobLabel, NSArray *programArguments, NSString *aWatchPath);

static inline NSString *VSMakeGamePathKey(NSString *gamePath) {
	return [gamePath lowercaseString];
}


#define VS_DEBUG 0


static BOOL locatedSteamApps = NO;

static VSGameLaunchOptions defaultPersistentOptions = VSGameLaunchDefault;


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
		gamePathsAndGames = [[NSMutableDictionary alloc] init];
		runningGamePathsAndGames = [[NSMutableDictionary alloc] init];
		
		NSString *gamesPlist = [[NSBundle bundleForClass:[self class]] pathForResource:@"com.valvesoftware.games" ofType:@"plist"];
		if (gamesPlist) {
			NSDictionary *gamesDic = [NSDictionary dictionaryWithContentsOfFile:gamesPlist];
			gameBundleIdentifiersAndGames = [[gamesDic objectForKey:VSGameBundleIdentifiersAndGamesKey] retain];
			executableNames = [[gamesDic objectForKey:VSExecutableNamesKey] retain];
			
		}
		
		steamAppsRelocationType = VSSteamAppsUnknownRelocation;
		
		sourceFinaglerLaunchAgentStatus = VSSourceFinaglerLaunchAgentStatusUnknown;
		
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


- (void)applicationWillLaunch:(NSNotification *)notification {
#if VS_DEBUG
	NSLog(@"[%@ %@] userInfo == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [notification userInfo]);
#endif
	NSString *appPath = [[notification userInfo] objectForKey:@"NSApplicationPath"];
	
	if ([gamePathsAndGames objectForKey:VSMakeGamePathKey(appPath)] != nil ||
		[executableNames containsObject:[VSMakeGamePathKey(appPath) lastPathComponent]]) {
		
		[self locateSteamApps];
	}
	
	@synchronized(self) {
		if (monitoringGames == NO) return;
		
		VSGame *game = [gamePathsAndGames objectForKey:VSMakeGamePathKey(appPath)];
		if (game == nil) return;
		
		VSGameLaunchOptions options = [self persistentOptionsForGame:game];
		
		if (options == VSGameLaunchNoOptions) options = defaultPersistentOptions;
		
		
		if (options & VSGameLaunchHelpingGame && ![game isHelped]) {
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
	NSString *appPath = [[[notification userInfo] objectForKey:@"NSApplicationPath"] stringByResolvingSymlinksInPath];

	if ([gamePathsAndGames objectForKey:VSMakeGamePathKey(appPath)] != nil ||
		[executableNames containsObject:[VSMakeGamePathKey(appPath) lastPathComponent]]) {
		
		[self locateSteamApps];
	}
}


- (void)applicationDidTerminate:(NSNotification *)notification {
#if VS_DEBUG
//	NSLog(@"[%@ %@] userInfo == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [notification userInfo]);
#endif
	NSString *appPath = [[notification userInfo] objectForKey:@"NSApplicationPath"];
	
	if ([gamePathsAndGames objectForKey:VSMakeGamePathKey(appPath)] != nil ||
		[executableNames containsObject:[VSMakeGamePathKey(appPath) lastPathComponent]]) {
		
		[self locateSteamApps];
	}
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
			
			if ( !([fileManager fileExistsAtPath:fullPath isDirectory:&isDir] && isDir)) {
				continue;
			}
			
			// we're inside /SteamApps/markdouma/ or
			// /SteamApps/common/
			
			NSArray *gameFolderNames = [fileManager contentsOfDirectoryAtPath:fullPath error:&outError];
			
			if (gameFolderNames == nil) {
				continue;
			}
				
			for (NSString *gameFolderName in gameFolderNames) {
				
				NSString *gameFolderFullPath = [fullPath stringByAppendingPathComponent:gameFolderName];
				
				if ( !([fileManager fileExistsAtPath:gameFolderFullPath isDirectory:&isDir] && isDir)) {
					continue;
				}
				
				// inside the game folder, look for "hl2_osx", "csgo_osx", or "portal2_osx"
				
				NSArray *rootContents = [fileManager contentsOfDirectoryAtPath:gameFolderFullPath error:&outError];
				
				if (rootContents == nil) {
					continue;
				}
				
				for (NSString *rootItemName in rootContents) {
					if ([executableNames containsObject:rootItemName]) {
					
						NSString *fullGamePath = [gameFolderFullPath stringByAppendingPathComponent:rootItemName];
						
						VSGame *game = [gamePathsAndGames objectForKey:VSMakeGamePathKey(fullGamePath)];
						
						if (game) {
							[game synchronizeHelped];
							continue;
						}
						NSArray *appInfos = [gameBundleIdentifiersAndGames allValues];
						
						for (NSDictionary *appInfo in appInfos) {
							if ([[appInfo objectForKey:VSGameNameKey] isEqualToString:gameFolderName]) {
								VSGame *game = [VSGame gameWithPath:fullGamePath infoPlist:appInfo];
								if (game) [uniqueNewGames addObject:game];
							}
						}
					}
				}
			}
		}
		
		[localPool release];
		
		
		for (VSGame *newGame in uniqueNewGames) {
			[gamePathsAndGames setObject:newGame forKey:VSMakeGamePathKey([newGame executablePath])];
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
				
				[runningGamePathsAndGames setObject:game forKey:VSMakeGamePathKey([game executablePath])];
				if (delegate && [delegate respondsToSelector:@selector(gameDidLaunch:)]) {
					[delegate gameDidLaunch:game];
				}
			}
		}
		
		NSString *sourceFinaglerDirectory = [folderManager pathForDirectoryWithName:@"Source Finagler" inDirectory:MDApplicationSupportDirectory inDomain:MDUserDomain create:NO error:&outError];
		
		NSString *sourceFinaglerAgentPath = [sourceFinaglerDirectory stringByAppendingPathComponent:VSSourceFinaglerAgentNameKey];
		
		if (sourceFinaglerAgentPath && [fileManager fileExistsAtPath:sourceFinaglerAgentPath isDirectory:&isDir] && isDir) {
			sourceFinaglerLaunchAgentStatus = VSSourceFinaglerLaunchAgentInstalled;
			sourceFinaglerLaunchAgentPath = [sourceFinaglerAgentPath retain];
			
			NSString *sourcePath = [[NSBundle bundleForClass:[self class]] pathForResource:[VSSourceFinaglerAgentNameKey stringByDeletingPathExtension]	ofType:@"app"];
			if (sourcePath == nil) sourcePath = [[NSBundle mainBundle] pathForResource:[VSSourceFinaglerAgentNameKey stringByDeletingPathExtension]	ofType:@"app"];
			if (sourcePath == nil) {
				if ([[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleIdentifierKey] isEqualToString:VSSourceFinaglerBundleIdentifierKey]) {
					NSLog(@"[%@ %@] couldn't locate %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), VSSourceFinaglerAgentNameKey);
				}
			}
			if (sourcePath) {
				NSBundle *sourceBundle = [NSBundle bundleWithPath:sourcePath];
				if (sourceBundle) {
					NSString *sourceVersionString = [sourceBundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
					NSBundle *installedBundle = [NSBundle bundleWithPath:sourceFinaglerLaunchAgentPath];
					if (installedBundle) {
						NSString *installedVersionString = [installedBundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
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
//	NSLog(@"[%@ %@] gamePathsAndGames == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), gamePathsAndGames);
#endif
	
}



- (BOOL)isProposedRelocationPathValid:(NSString *)proposedPath errorDescription:(NSString **)errorDescription {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	BOOL isValid = YES;
	
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
	
	if (steamAppsPath) {
		isOriginalFolder = [proposedPath isEqualToString:steamAppsPath];
	}
	// TODO: these strings should be localized
	if (itemExists && isSteamAppsFolder && !isOriginalFolder && !isOriginalSymbolicLink) {
		if (errorDescription) {
			*errorDescription = @"";
		}
	} else if (itemExists && isSteamAppsFolder && !isOriginalFolder && isOriginalSymbolicLink) {
		if (errorDescription) {
			*errorDescription = [NSString stringWithFormat:@"Cannot choose original %@ shortcut", VSSteamAppsDirectoryNameKey];
		}
		isValid = NO;
	} else if (itemExists && !isSteamAppsFolder) {
		if (errorDescription) {
			*errorDescription = [NSString stringWithFormat:@"Folder must be named \"%@\"", VSSteamAppsDirectoryNameKey];
		}
		isValid = NO;
	} else if (!itemExists) {
		if (errorDescription) {
			*errorDescription = @"Item does not exist";
		}
		isValid = NO;
	} else if (isOriginalFolder) {
		if (errorDescription) {
			*errorDescription = [NSString stringWithFormat:@"Cannot choose original %@ folder", VSSteamAppsDirectoryNameKey];
		}
		isValid = NO;
	}
	
	return isValid;
}



- (BOOL)relocateSteamAppsToPath:(NSString *)aPath error:(NSError **)outError {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	BOOL success = YES;
	if (outError) *outError = nil;
	
	NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
	NSError *localError = nil;
	
	NSDictionary *attributes = nil;
	attributes = [fileManager attributesOfItemAtPath:defaultSteamAppsPath error:&localError];
	
	if ([[attributes fileType] isEqualToString:NSFileTypeSymbolicLink]) {
		// item is a broken symbolic link
		if (![fileManager moveItemAtPath:defaultSteamAppsPath toPath:[[defaultSteamAppsPath stringByAppendingString:@" (Original)"] stringByAssuringUniqueFilename] error:&localError]) {
			NSLog(@"[%@ %@] error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), localError);
			if (outError) *outError = localError;
		}
	} else {
		if ([fileManager fileExistsAtPath:defaultSteamAppsPath]) {
			if (![fileManager moveItemAtPath:defaultSteamAppsPath toPath:[[defaultSteamAppsPath stringByAppendingString:@" (Original)"] stringByAssuringUniqueFilename] error:&localError]) {
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


+ (VSGameLaunchOptions)defaultPersistentOptions {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	VSGameLaunchOptions options = VSGameLaunchDefault;
	
	NSLock *lock = [[NSLock alloc] init];
	[lock lock];
	options = defaultPersistentOptions;
	[lock unlock];
	[lock release];
	return options;
}


+ (void)setDefaultPersistentOptions:(VSGameLaunchOptions)options {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSLock *lock = [[NSLock alloc] init];
	[lock lock];
	defaultPersistentOptions = options;
	[lock unlock];
	[lock release];
}


- (VSGameLaunchOptions)persistentOptionsForGame:(VSGame *)game {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (game == nil) return VSGameLaunchNoOptions;
	
	if (!locatedSteamApps) [self locateSteamApps];
	
	VSGameLaunchOptions launchOptions = VSGameLaunchNoOptions;
	
	@synchronized(self) {
		NSString *bundleIdentifier = [[game infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey];
		if (bundleIdentifier == nil) return VSGameLaunchNoOptions;
		
		launchOptions = [[[NSUserDefaults standardUserDefaults] objectForKey:bundleIdentifier] unsignedIntegerValue];
	}
	return launchOptions;
}


static inline NSString *VSMakeLabelFromBundleIdentifier(NSString *bundleIdentifier) {
	if (bundleIdentifier == nil) return nil;
	NSRange vsRange = [bundleIdentifier rangeOfString:@"com.valvesoftware."];
	if (NSEqualRanges(vsRange, NSMakeRange(NSNotFound, 0))) {
		return nil;
	}
	NSString *gameName = [bundleIdentifier substringFromIndex:vsRange.location + vsRange.length];
	if (gameName == nil) return nil;
	NSString *label = [NSString stringWithFormat:@"%@.%@", VSSourceFinaglerAgentBundleIdentifierKey, gameName];
	return label;
}


- (BOOL)setPersistentOptions:(VSGameLaunchOptions)options forGame:(VSGame *)game error:(NSError **)outError {
#if VS_DEBUG
	NSLog(@"[%@ %@] options == %lu, game == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)options, game);
#endif
	if (game == nil) {
		NSLog(@"[%@ %@] *** ERROR: game == nil!, returning NO", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return NO;
	}
	
	if (outError) *outError = nil;
	
	if (!locatedSteamApps) [self locateSteamApps];
	
	if (options & VSGameLaunchHelpingGame && sourceFinaglerLaunchAgentStatus != VSSourceFinaglerLaunchAgentInstalled) {
		[self installSourceFinaglerLaunchAgentWithError:outError];
	}
	
	@synchronized(self) {
		
		NSString *bundleIdentifier = [[game infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey];
		if (bundleIdentifier == nil) {
			NSLog(@"[%@ %@] *** NOTICE: game.infoDictionary.kCFBundleIdentifierKey == nil!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			return NO;
		}
		
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithUnsignedInteger:options] forKey:bundleIdentifier];
		
		if (options & VSGameLaunchHelpingGame || options == VSGameLaunchNoOptions) {
			NSString *jobLabel = VSMakeLabelFromBundleIdentifier(bundleIdentifier);
			MDLaunchManager *launchManager = [MDLaunchManager defaultManager];
			
			NSDictionary *existingJob = [launchManager jobWithLabel:jobLabel inDomain:MDLaunchUserDomain];
			if (existingJob) {
				
				if (![launchManager removeJobWithLabel:jobLabel inDomain:MDLaunchUserDomain error:outError]) {
					NSLog(@"[%@ %@] failed to remove existing job!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
					return NO;
				}
			}
			
			if (options & VSGameLaunchHelpingGame) {
				
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
				
				
				NSDictionary *launchPlist = VSMakeLaunchAgentPlist(jobLabel, [NSArray arrayWithObjects:launchAgentExecutablePath, [game executablePath], nil], [game executablePath]);
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

- (NSString *)sourceFinaglerLaunchAgentPath {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (!locatedSteamApps) [self locateSteamApps];
    return sourceFinaglerLaunchAgentPath;
}

- (BOOL)installSourceFinaglerLaunchAgentWithError:(NSError **)outError {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	@synchronized(self) {
		
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
			
			NSString *bundleIdentifier = [[game infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey];
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
				NSDictionary *launchPlist = VSMakeLaunchAgentPlist(jobLabel, [NSArray arrayWithObjects:launchAgentExecutablePath, [game executablePath], nil], [game executablePath]);
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
	if (jobLabel == nil || programArguments == nil || aWatchPath == nil) return nil;
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
	if (!locatedSteamApps) [self locateSteamApps];
	return [gamePathsAndGames objectForKey:VSMakeGamePathKey(aPath)];
}

- (NSArray *)games {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (!locatedSteamApps) [self locateSteamApps];
	return [[[gamePathsAndGames allValues] copy] autorelease];
}


- (NSArray *)runningGames {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (!locatedSteamApps) [self locateSteamApps];
	return [[[runningGamePathsAndGames allValues] copy] autorelease];
}



- (BOOL)helpGame:(VSGame *)game forUSBOverdrive:(BOOL)helpForUSBOverdrive updateLaunchAgent:(BOOL)updateLaunchAgent error:(NSError **)outError {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	BOOL success = YES;
	if (outError) *outError = nil;
	
	NSString *path = [game executablePath];
	
	MDFileManager *mdFileManager = [[[MDFileManager alloc] init] autorelease];
	
	NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
	
	OSType creatorCode = [game creatorCode];
	
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:creatorCode],NSFileHFSCreatorCode,
								[NSNumber numberWithUnsignedInt:'APPL'],NSFileHFSTypeCode,
								[NSNumber numberWithBool:YES],MDFileHasCustomIcon, nil];
	
	NSDictionary *infoPlist = [game infoDictionary];
	NSString *errorDescription = nil;
	
	NSData *propertyListData = [NSPropertyListSerialization dataFromPropertyList:infoPlist format:NSPropertyListXMLFormat_v1_0 errorDescription:&errorDescription];
	
	if (propertyListData) {
		NSString *propertyListString = [[[NSString alloc] initWithData:propertyListData encoding:NSUTF8StringEncoding] autorelease];
		if (propertyListString) {
			// old-style 'plst' resources require carriage-returns
			propertyListString = [propertyListString stringByReplacingOccurrencesOfString:@"\n" withString:@"\r"];
		}
		propertyListData = [propertyListString dataUsingEncoding:NSUTF8StringEncoding];
		if (propertyListData) {
			MDResource *plistResource = [[[MDResource alloc] initWithType:'plst'
															 resourceData:propertyListData
															   resourceID:0
															 resourceName:@""
															resourceIndex:1
													   resourceAttributes:0
															   resChanged:YES
																	 copy:NO
																	error:NULL] autorelease];
			if (plistResource) {
				
				MDResourceFile *destFile = [[[MDResourceFile alloc] initForUpdatingWithContentsOfFile:path fork:MDResourceFork error:outError] autorelease];
				
				NSData *iconData = [NSData dataWithContentsOfFile:[game iconPath]];
				
//				if (destFile && iconData) {
				if (destFile) {
					[destFile addResource:plistResource error:outError];
					if (iconData) {
						MDResource *iconResource = [[[MDResource alloc] initWithType:'icns'
																		resourceData:iconData
																		  resourceID:kCustomIconResource
																		resourceName:@""
																	   resourceIndex:1
																  resourceAttributes:0
																		  resChanged:YES
																				copy:NO
																			   error:outError] autorelease];
						if (iconResource == nil) {
							[destFile closeResourceFile];
							return NO;
						}
						if (![destFile addResource:iconResource error:outError]) {
							[destFile closeResourceFile];
							return NO;
						}
					}
				}
				[destFile closeResourceFile];
			}
			
		}
	}
	
	if (![mdFileManager setAttributes:attributes ofItemAtPath:path error:outError]) {
		success = NO;
	}
	
	if (helpForUSBOverdrive) {
		
		NSString *executableName = [path lastPathComponent];
		
		NSString *executableBundleName = nil;
		
		if ([executableName isEqual:VSHalfLife2ExecutableNameKey]) {
			executableBundleName = VSHalfLife2USBOverdriveExecutableNameKey;
			
		} else if ([executableName isEqual:VSPortal2ExecutableNameKey]) {
			executableBundleName = VSPortal2USBOverdriveExecutableNameKey;
			
		} else if ([executableName isEqual:VSCounterStrikeGlobalOffensiveExecutableNameKey]) {
			executableBundleName = VSCounterStrikeGlobalOffensiveUSBOverdriveExecutableNameKey;
			
		}
		if (executableBundleName) executableBundleName = [executableBundleName stringByAppendingPathExtension:@"app"];
		
		NSString *destUSBPath = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:executableBundleName];
		
		BOOL isDir;
		
		if ([fileManager fileExistsAtPath:destUSBPath isDirectory:&isDir] && isDir) {
			if (![fileManager removeItemAtPath:destUSBPath error:outError]) {
				
			}
		}
		
		NSString *sourcePath = [[NSBundle mainBundle] pathForResource:@"hl2_osx" ofType:@"app"];
		if (sourcePath == nil) sourcePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"hl2_osx" ofType:@"app"];
		if (sourcePath == nil) {
			NSLog(@"[%@ %@] could not find hl2_osx.app inside app bundle or framework!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			return NO;
		}
		
		if (![fileManager copyPath:sourcePath toPath:destUSBPath handler:nil]) {
			NSLog(@"[%@ %@] failed to copy hl2_osx.app to destination!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			return NO;
		}
		
		if ([executableName isEqualToString:VSPortal2ExecutableNameKey]) {
			if (![fileManager movePath:[[[destUSBPath stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"MacOS"] stringByAppendingPathComponent:VSHalfLife2ExecutableNameKey]
								toPath:[[[destUSBPath stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"MacOS"] stringByAppendingPathComponent:VSPortal2ExecutableNameKey]
							   handler:nil]) {
				
				NSLog(@"[%@ %@] failed to delete unneeded hl2_osx inside 'portal2_osx (for USB Overdrive).app'!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
				return NO;
			}
		} else if ([executableName isEqualToString:VSCounterStrikeGlobalOffensiveExecutableNameKey]) {
			if (![fileManager movePath:[[[destUSBPath stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"MacOS"] stringByAppendingPathComponent:VSHalfLife2ExecutableNameKey]
								toPath:[[[destUSBPath stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"MacOS"] stringByAppendingPathComponent:VSCounterStrikeGlobalOffensiveExecutableNameKey]
							   handler:nil]) {
				
				NSLog(@"[%@ %@] failed to delete unneeded hl2_osx inside 'csgo_osx (for USB Overdrive).app'!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
				return NO;
			}
		}
		
		NSString *iconPath = [game iconPath];
		if ([fileManager fileExistsAtPath:iconPath isDirectory:&isDir] && !isDir) {
			NSString *destIconPath = [[[destUSBPath stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Resources"] stringByAppendingPathComponent:VSGameIconNameKey];
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
		[mInfoPlist setObject:@"game" forKey:@"CFBundleIconFile"];
		
		[mInfoPlist setObject:@"NSApplication" forKey:@"NSPrincipalClass"];
		[mInfoPlist setObject:@"MainMenu" forKey:@"NSMainNibFile"];
		
		
		if (![mInfoPlist writeToFile:[[destUSBPath stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Info.plist"] atomically:YES]) {
			NSLog(@"[%@ %@] failed to write Info.plist!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			return NO;
		}
		
		if (![fileManager setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSDate date],NSFileModificationDate, nil] ofItemAtPath:destUSBPath error:outError]) {
			NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			return NO;
		}
		
		OSStatus status = LSRegisterURL((CFURLRef)[NSURL fileURLWithPath:destUSBPath], true);
		if (status != noErr) {
			NSLog(@"[%@ %@] LSRegisterURL() returned %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (int)status);
		}
	}
	
	if (updateLaunchAgent) {
		@synchronized(self) {
			if (sourceFinaglerLaunchAgentStatus == VSSourceFinaglerLaunchAgentInstalled) {
				[self setPersistentOptions:VSGameLaunchDefault forGame:game error:outError];
			}
		}
	}
	
	return success;
}


- (BOOL)unhelpGame:(VSGame *)game error:(NSError **)outError {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	BOOL success = YES;
	if (outError) *outError = nil;
	
	NSString *path = [game executablePath];
	
	MDFileManager *mdFileManager = [[[MDFileManager alloc] init] autorelease];
	
	NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
	
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:0],NSFileHFSCreatorCode,
								[NSNumber numberWithUnsignedInt:0],NSFileHFSTypeCode,
								[NSNumber numberWithBool:NO],MDFileHasCustomIcon, nil];
	
	MDResourceFile *resFile = [[[MDResourceFile alloc] initForUpdatingWithContentsOfFile:path fork:MDResourceFork error:outError] autorelease];
	if (resFile == nil) return NO;
	if ([resFile plistResource]) {
		if (![resFile removeResource:[resFile plistResource] error:outError]) {
			NSLog(@"[%@ %@] remove plist resource failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			return NO;
		}
	}
	if ([resFile customIconResource]) {
		if (![resFile removeResource:[resFile customIconResource] error:outError]) {
			NSLog(@"[%@ %@] remove customIconResource resource failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			return NO;
		}
	}
	
	[resFile closeResourceFile];
		
	if (![mdFileManager setAttributes:attributes ofItemAtPath:path error:outError]) {
		success = NO;
	}
	
	NSString *executableName = [path lastPathComponent];
	
	NSString *executableBundleName = nil;
	
	if ([executableName isEqual:VSHalfLife2ExecutableNameKey]) {
		executableBundleName = VSHalfLife2USBOverdriveExecutableNameKey;
		
	} else if ([executableName isEqual:VSPortal2ExecutableNameKey]) {
		executableBundleName = VSPortal2USBOverdriveExecutableNameKey;
		
	} else if ([executableName isEqual:VSCounterStrikeGlobalOffensiveExecutableNameKey]) {
		executableBundleName = VSCounterStrikeGlobalOffensiveUSBOverdriveExecutableNameKey;
		
	}
	if (executableBundleName) executableBundleName = [executableBundleName stringByAppendingPathExtension:@"app"];
	
	NSString *bundledAppPath = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:executableBundleName];
	
	@synchronized(self) {
		if (sourceFinaglerLaunchAgentStatus == VSSourceFinaglerLaunchAgentInstalled) {
			[self setPersistentOptions:VSGameLaunchNoOptions forGame:game error:outError];
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


- (BOOL)launchGame:(VSGame *)game options:(VSGameLaunchOptions)options error:(NSError **)outError {
	if (game == nil) return NO;
	if (outError) *outError = nil;
	
	if (options & VSGameLaunchHelpingGame && ![game isHelped]) {
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



- (BOOL)installAddonAtPath:(NSString *)sourceFilePath method:(VSSourceAddonInstallMethod)installMethod resultingPath:(NSString **)resultingPath resultingGame:(VSGame **)resultingGame overwrite:(BOOL)overwrite error:(NSError **)outError {
#if VS_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (sourceFilePath == nil) {
		if (resultingPath) *resultingPath = nil;
		if (resultingGame) *resultingGame = nil;
		if (outError) *outError = [NSError errorWithDomain:VSSourceAddonErrorDomain code:VSSourceAddonNotAValidAddonFileError userInfo:nil];
		return NO;
	}
	
	if (![[[sourceFilePath pathExtension] lowercaseString] isEqualToString:@"vpk"]) {
		if (resultingPath) *resultingPath = nil;
		if (resultingGame) *resultingGame = nil;
		if (outError) *outError = [NSError errorWithDomain:VSSourceAddonErrorDomain code:VSSourceAddonNotAValidAddonFileError userInfo:nil];
		return NO;
	}
	
	if (resultingPath) *resultingPath = sourceFilePath;
	if (resultingGame) *resultingGame = nil;
	if (outError) *outError = nil;
	
	if (!locatedSteamApps) [self locateSteamApps];
	
	NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
	BOOL isDir;
	
	if (! ([fileManager fileExistsAtPath:sourceFilePath isDirectory:&isDir] && !isDir)) {
		NSLog(@"[%@ %@] item at path (%@) is a folder, not a file!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sourceFilePath);
		if (outError) *outError = [NSError errorWithDomain:VSSourceAddonErrorDomain code:VSSourceAddonNotAValidAddonFileError userInfo:nil];
		return NO;
	}
	
	HKVPKFile *file = [[[HKVPKFile alloc] initWithContentsOfFile:sourceFilePath showInvisibleItems:YES sortDescriptors:nil error:outError] autorelease];
	HKItem *addonInfoItem = [file itemAtPath:VSSourceAddonInfoNameKey];
	
#if VS_DEBUG
//	NSLog(@"[%@ %@] addonInfoItem == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), addonInfoItem);
#endif
	
	
	if (addonInfoItem == nil || ![addonInfoItem isKindOfClass:[HKFile class]] || [addonInfoItem fileType] != HKFileTypeText) {
		NSLog(@"[%@ %@] item at path (%@) does not appear to contain a valid addoninfo.txt file!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sourceFilePath);
		if (outError) *outError = [NSError errorWithDomain:VSSourceAddonErrorDomain code:VSSourceAddonNoAddonInfoFoundError userInfo:nil];
		return NO;
	}
	
	NSString *stringValue = [(HKFile *)addonInfoItem stringValueByExtractingToTempFile:YES];
	if (stringValue == nil) {
		stringValue = [(HKFile *)addonInfoItem stringValue];
	}
	
	if (stringValue == nil) {
		NSLog(@"[%@ %@] could not determine string encoding of addoninfo.txt file!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		if (outError) *outError = [NSError errorWithDomain:VSSourceAddonErrorDomain code:VSSourceAddonAddonInfoUnreadableError userInfo:nil];
		return NO;
	}
	
	
//	NSData *data = [(HKFile *)addonInfoItem data];
	
#if VS_DEBUG
//	NSLog(@"data == %@", data);
#endif
	
	
//#if VS_DEBUG
//	NSLog(@"stringValue == %@", stringValue);
//#endif
	
	NSArray *words = [stringValue componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	NSMutableArray *revisedWords = [NSMutableArray array];
	
	for (NSString *word in words) {
		if (![word isEqualToString:@""]) {
			[revisedWords addObject:word];
		}
	}
	
	
	NSUInteger count = [revisedWords count];
	NSUInteger keyIndex = [revisedWords indexOfObject:VSSourceAddonSteamAppIDKey];
	
#if VS_DEBUG
//	NSLog(@"revisedWords == %@, count == %lu, keyIndex == %lu", revisedWords, count, keyIndex);
#endif
	
	if (keyIndex == NSNotFound || !(keyIndex + 1 < count)) {
		NSLog(@"[%@ %@] failed to find %@ key and/or value in addoninfo.txt in (%@)!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), VSSourceAddonSteamAppIDKey, sourceFilePath);
		NSLog(@"[%@ %@] stringValue == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), stringValue);
		if (outError) *outError = [NSError errorWithDomain:VSSourceAddonErrorDomain code:VSSourceAddonNoGameIDFoundInAddonInfoError userInfo:nil];
		return NO;
	}
	
	NSString *addonSteamAppIDString = [revisedWords objectAtIndex:keyIndex + 1];
	NSInteger addonSteamAppID = [addonSteamAppIDString integerValue];
#if VS_DEBUG
	NSLog(@"addonSteamAppIDString == %@, addonSteamAppID == %ld", addonSteamAppIDString, (long)addonSteamAppID);
#endif
	VSGame *game = nil;
	
	NSArray *allGames = [gamePathsAndGames allValues];
	
	for (VSGame *potentialGame in allGames) {
		if ([potentialGame gameID] == addonSteamAppID) {
			game = potentialGame;
			break;
		}
	}
	
	if (game == nil) {
		NSLog(@"[%@ %@] could not find game for gameID == %ld for (%@)!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (long)addonSteamAppID, sourceFilePath);
		NSLog(@"[%@ %@] stringValue == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), stringValue);
		
		if (outError) *outError = [NSError errorWithDomain:VSSourceAddonErrorDomain
													  code:VSSourceAddonGameNotFoundError
												  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:addonSteamAppID],VSSourceAddonGameIDKey, nil]];
		return NO;
	}
	NSString *addonsFolderPath = [game addonsFolderPath];
	if (addonsFolderPath == nil) {
		NSLog(@"[%@ %@] addonsFolderPath is nil for %@ for (%@)!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), game, sourceFilePath);
		if (outError) *outError = [NSError errorWithDomain:VSSourceAddonErrorDomain code:VSSourceAddonGameNotFoundError userInfo:nil];
		return NO;
	}
	
	NSString *destPath = [addonsFolderPath stringByAppendingPathComponent:[sourceFilePath lastPathComponent]];
	
	if ([destPath isEqualToString:sourceFilePath]) {
		NSLog(@"[%@ %@] source and destination item are the same file; not overwriting!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		if (outError) *outError = [NSError errorWithDomain:VSSourceAddonErrorDomain code:VSSourceAddonSourceFileIsDestinationFileError userInfo:nil];
		return NO;
	}
	
	NSArray *currentAddonFilenames = [fileManager contentsOfDirectoryAtPath:addonsFolderPath error:outError];
	
	if (currentAddonFilenames == nil) {
		return NO;
	}
	
	if (overwrite == NO && [currentAddonFilenames containsObject:[sourceFilePath lastPathComponent]]) {
		NSLog(@"[%@ %@] addons folder already contains an item named '%@' && overwrite == NO; not copying item...", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [sourceFilePath lastPathComponent]);
		return NO;
	}
	if ([currentAddonFilenames containsObject:[sourceFilePath lastPathComponent]]) {
		if (![fileManager removeItemAtPath:destPath error:outError]) {
//			if (outError) *outError = [NSError errorWithDomain:VSSourceAddonErrorDomain code:VSSourceAddonSourceFileIsDestinationFileError userInfo:nil];
			return NO;
		}
	}
	
	if (installMethod == VSSourceAddonInstallByMoving) {
		if (![fileManager moveItemAtPath:sourceFilePath toPath:destPath error:outError]) {
			NSLog(@"[%@ %@] failed to move item!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			return NO;
		}
		
	} else {
		if (![fileManager copyItemAtPath:sourceFilePath toPath:destPath error:outError]) {
			NSLog(@"[%@ %@] failed to copy item!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			return NO;
		}
	}
	
	if (resultingPath) *resultingPath = destPath;
	if (resultingGame) *resultingGame = game;
	return YES;
	
}

	
@end


