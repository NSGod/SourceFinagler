//
//  VSSteamManager.h
//  Steam Kit
//
//  Created by Mark Douma on 6/13/2010.
//  Copyright © 2010-2014 Mark Douma LLC. All rights reserved.
//


#import <Foundation/NSObject.h>
#import <SteamKit/SteamKitDefines.h>
#import <SteamKit/VSGame.h>


@class NSString, NSError, NSDictionary, NSMutableDictionary, NSArray;
@class VSSourceAddon;


@protocol VSSteamManagerDelegate <NSObject>

@optional

- (void)gameDidLaunch:(VSGame *)game;
- (void)gameDidTerminate:(VSGame *)game;


- (void)didInstallSourceAddon:(VSSourceAddon *)sourceAddon;
- (void)didFailToInstallSourceAddon:(VSSourceAddon *)sourceAddon;

@end


enum {
	VSGameLaunchNoOptions						= 0,
	VSGameLaunchHelpingGame						= 1 << 0,
	VSGameLaunchDefault							= VSGameLaunchHelpingGame
};
typedef NSUInteger VSGameLaunchOptions;

enum {
	VSSteamAppsUnknownRelocation	= 0,
	VSSteamAppsNoRelocation			= 1,
	VSSteamAppsSymlinkRelocation	= 2
};
typedef NSUInteger VSSteamAppsRelocationType;

enum {
	VSSourceFinaglerLaunchAgentInstalled			= 0,
	VSSourceFinaglerLaunchAgentUpdateNeeded			= 1,
	VSSourceFinaglerLaunchAgentNotInstalled			= 2,
	VSSourceFinaglerLaunchAgentStatusUnknown		= 3
};
typedef NSUInteger VSSourceFinaglerLaunchAgentStatus;



@interface VSSteamManager : NSObject {
	
@private
	NSString									*defaultSteamAppsPath;
	
	NSString									*steamAppsPath;
	
	VSSteamAppsRelocationType					steamAppsRelocationType;
	
	NSDictionary								*gameBundleIdentifiersAndGames;
	NSSet										*knownExecutableNames;
	
	NSMutableDictionary							*gamePathsAndGames;
	NSMutableDictionary							*runningGamePathsAndGames;
	
	
	id <VSSteamManagerDelegate>					delegate;						// non-retained
	
	
	VSSourceFinaglerLaunchAgentStatus			sourceFinaglerLaunchAgentStatus;
	NSString									*sourceFinaglerLaunchAgentPath;
	
	
	NSTimeInterval								timeToLocateSteamApps;
	
	BOOL										monitoringGames;
	
}

/* Get the shared instance of VSSteamManager. This method will create an instance of VSSteamManager if it has not been created yet. You should not attempt to instantiate instances of VSSteamManager yourself, and you should not attempt to subclass VSSteamManager. */

+ (VSSteamManager *)defaultManager; // singleton


@property (assign) id <VSSteamManagerDelegate> delegate;


/*		SteamApps folder relocation		*/

- (NSString *)defaultSteamAppsPath;

- (NSString *)steamAppsPath;

- (VSSteamAppsRelocationType)steamAppsRelocationType;

- (BOOL)isProposedRelocationPathValid:(NSString *)proposedPath errorDescription:(NSString **)errorDescription;
- (BOOL)relocateSteamAppsToPath:(NSString *)aPath error:(NSError **)outError;


/*		Games		*/

@property (readonly, copy) NSArray *games;

@property (readonly, copy) NSArray *runningGames;


- (VSGame *)gameWithPath:(NSString *)aPath;
- (VSGame *)gameWithGameID:(VSGameID)anID;


@property (assign) BOOL monitoringGames;


+ (VSGameLaunchOptions)defaultPersistentOptions;
+ (void)setDefaultPersistentOptions:(VSGameLaunchOptions)options;

- (VSGameLaunchOptions)persistentOptionsForGame:(VSGame *)game;
- (BOOL)setPersistentOptions:(VSGameLaunchOptions)options forGame:(VSGame *)game error:(NSError **)outError;


- (BOOL)helpGame:(VSGame *)game forUSBOverdrive:(BOOL)yorn updateLaunchAgent:(BOOL)updateLaunchAgent error:(NSError **)outError;
- (BOOL)unhelpGame:(VSGame *)game error:(NSError **)outError;

- (BOOL)launchGame:(VSGame *)game options:(VSGameLaunchOptions)options error:(NSError **)outError;



/* Source Finagler Launch Agent */

@property (readonly, assign) VSSourceFinaglerLaunchAgentStatus sourceFinaglerLaunchAgentStatus;
@property (readonly, copy) NSString *sourceFinaglerLaunchAgentPath;


- (BOOL)installSourceFinaglerLaunchAgentWithError:(NSError **)outError;
- (BOOL)updateSourceFinaglerLaunchAgentWithError:(NSError **)outError;
- (BOOL)uninstallSourceFinaglerLaunchAgentWithError:(NSError **)outError;

@end


enum {
	VSSourceAddonInstallByMoving	= 1,
	VSSourceAddonInstallByCopying	= 2
};
typedef NSUInteger VSSourceAddonInstallMethod;




@interface VSSteamManager (VSSourceAddonAdditions)

// raises an exception if sourceAddon == nil
- (void)installSourceAddon:(VSSourceAddon *)sourceAddon usingMethod:(VSSourceAddonInstallMethod)installMethod;

@end



@interface VSSteamManager (VSOtherAppsHelperAdditions)

// force a refresh
- (void)locateSteamApps;

@end


STEAMKIT_EXTERN NSString * const VSSteamAppsDirectoryNameKey;


STEAMKIT_EXTERN NSString * const VSSourceAddonFolderNameKey;



