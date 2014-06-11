//
//  VSPrivateInterfaces.h
//  SteamKit
//
//  Created by Mark Douma on 6/1/2011.
//  Copyright (c) 2010-2014 Mark Douma LLC. All rights reserved.
//

#import <SteamKit/SteamKitDefines.h>
#import <SteamKit/VSGame.h>
#import <SteamKit/VSSourceAddon.h>



STEAMKIT_PRIVATE_EXTERN NSString * const VSGameIDKey;
STEAMKIT_PRIVATE_EXTERN NSString * const VSGameNameKey;
STEAMKIT_PRIVATE_EXTERN NSString * const VSGameShortNameKey;
STEAMKIT_PRIVATE_EXTERN NSString * const VSGameLongNameKey;

STEAMKIT_PRIVATE_EXTERN NSString * const VSGameIconNamesKey;



@interface VSGame ()

+ (id)gameWithExecutableURL:(NSURL *)aURL infoPlist:(NSDictionary *)anInfoPlist appManifestURL:(NSURL *)anAppManifestURL;
- (id)initWithExecutableURL:(NSURL *)aURL infoPlist:(NSDictionary *)anInfoPlist appManifestURL:(NSURL *)anAppManifestURL;


- (void)synchronizeHelped;

/* Indicates the URL to the games's executable. */
@property (retain) NSURL *executableURL;

@property (retain) NSString *displayName;

@property (retain) NSURL *iconURL;

/* Returns the icon of the application. */
@property (retain) NSImage *icon;


@property (retain) NSDictionary *infoDictionary;

@property (retain) NSURL *appManifestURL;

@property (retain) NSURL *sourceAddonsFolderURL;

/* Indicates the process identifier (pid) of the application.  Do not rely on this for comparing processes.  Use isEqual: instead.  Not all applications have a pid.  Applications without a pid return -1 from this method. */
@property (assign) pid_t processIdentifier;


@property (assign) VSGameID	gameID;

@property (assign) OSType creatorCode;


@property (assign) BOOL helped;

@property (assign) BOOL running;


@end



@interface VSSourceAddon ()

@property (retain) NSURL *URL;

@property (assign, getter=isInstalled) BOOL installed;


@end


@class VSSourceAddonInstallOperation;


@interface VSSteamManager ()

- (void)beginProcessingSourceAddonInstallOperationOnMainThread:(VSSourceAddonInstallOperation *)operation;
- (void)finishProcessingSourceAddonInstallOperationOnMainThread:(VSSourceAddonInstallOperation *)operation;

@end






