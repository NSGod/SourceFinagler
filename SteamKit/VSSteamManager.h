//
//  VSSteamManager.h
//  SteamKit
//
//  Created by Mark Douma on 6/13/2010.
//  Copyright (c) 2010-2014 Mark Douma LLC. All rights reserved.
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


- (void)willInstallSourceAddon:(VSSourceAddon *)sourceAddon;
- (void)didInstallSourceAddon:(VSSourceAddon *)sourceAddon;
- (void)didFailToInstallSourceAddon:(VSSourceAddon *)sourceAddon;

@end


enum {
	VSGameOptionsDoNotHelpGame					= 0UL << 0,
	VSGameOptionsHelpGame						= 1UL << 0,
//	VSGameOptionsHelpGameForUSBOverdrive		= 1UL << 1,
//	VSGameOptionsUpdateLaunchAgent				= 1UL << 2,
	VSGameOptionsDefault						= VSGameOptionsDoNotHelpGame,
};
typedef NSUInteger VSGameOptions;

enum {
	VSSteamAppsUnknownRelocation	= 0,
	VSSteamAppsNoRelocation			= 1,
	VSSteamAppsSymlinkRelocation	= 2
};
typedef NSUInteger VSSteamAppsRelocationType;

enum {
	VSSourceFinaglerLaunchAgentStatusUnknown		= 0,
	VSSourceFinaglerLaunchAgentNotInstalled			= 1,
	VSSourceFinaglerLaunchAgentInstalled			= 2,
	VSSourceFinaglerLaunchAgentUpdateNeeded			= 3,
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
	
	NSOperationQueue							*sourceAddonOperationQueue;
	NSMutableArray								*sourceAddonOperations;
	
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


+ (VSGameOptions)defaultPersistentOptions;
+ (void)setDefaultPersistentOptions:(VSGameOptions)options;

- (VSGameOptions)persistentOptionsForGame:(VSGame *)game;
- (BOOL)setPersistentOptions:(VSGameOptions)options forGame:(VSGame *)game error:(NSError **)outError;


- (BOOL)helpGame:(VSGame *)game forUSBOverdrive:(BOOL)yorn updateLaunchAgent:(BOOL)updateLaunchAgent error:(NSError **)outError;
- (BOOL)unhelpGame:(VSGame *)game error:(NSError **)outError;

- (BOOL)launchGame:(VSGame *)game options:(VSGameOptions)options error:(NSError **)outError;



/* Source Finagler Launch Agent */

@property (readonly, assign) VSSourceFinaglerLaunchAgentStatus sourceFinaglerLaunchAgentStatus;


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

/*	Success or failure of the installation of a source addon is reported through the following methods of
	the `<VSSteamManagerDelegate>` protocol defined above:
 
 - (void)willInstallSourceAddon:(VSSourceAddon *)sourceAddon;
 - (void)didInstallSourceAddon:(VSSourceAddon *)sourceAddon;
 - (void)didFailToInstallSourceAddon:(VSSourceAddon *)sourceAddon;
 
 This method will raise an exception if `sourceAddon` is nil.
 
 */
- (void)installSourceAddon:(VSSourceAddon *)sourceAddon usingMethod:(VSSourceAddonInstallMethod)installMethod;

@end



@interface VSSteamManager (VSOtherAppsHelperAdditions)

// force a refresh
- (void)locateSteamApps;

@end


/*!
 @const      VSErrorDomain
 @abstract   Error domain for NSError values stemming from the SteamKit framework.
 @discussion This error domain is used as the domain for all NSError instances stemming from the SteamKit framework.
 */

STEAMKIT_EXTERN NSString * const VSErrorDomain;


STEAMKIT_EXTERN NSString * const VSSteamAppsDirectoryNameKey;



