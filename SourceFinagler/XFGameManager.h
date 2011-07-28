//
//  XFGameManager.h
//  BlackFire
//
//  Created by Mark Douma on 12/28/2009.
//  Copyright (c) 2009 Mark Douma LLC. All rights reserved.
//

#import "XFObject.h"

@class NSImage;


extern NSString * const XFGameDidLaunchNotification;
extern NSString * const XFGameDidTerminateNotification;



extern NSString * const XFGameVersionKey;
extern NSString * const XFGameIDKey;				// NSNumber(XFGameID)
extern NSString * const XFGameLongNameKey;			// NSString
extern NSString * const XFGameShortNameKey;			// NSString
extern NSString * const XFGameIconKey;				// NSImage
extern NSString * const XFGameClientServerTypeKey;	// NSString
extern NSString * const XFGameMasterServerTypeKey;	// NSString

// MacGames

extern NSString * const XFGameMacAppNameKey;
extern NSString * const XFGameMacBundleIdentifierKey;
extern NSString * const XFGameMacArgsKey;
extern NSString * const XFGameMacArgsOrderKey;
extern NSString * const XFGameMacConnectArgKey;
extern NSString * const XFGameMacPasswordArgKey;
extern NSString * const XFGameMacOtherArgsKey;

extern NSString * const XFGameMacFileCreatorKey;

extern NSString * const XFGameMacMachOExecutableSizeKey;

extern NSString * const XFGameMacDeveloperNotesKey;

extern NSString * const XFGameMacMultipleEntriesKey;

extern NSString * const XFGameMacIntelPortTypeKey;
extern NSString * const XFGameMacIntelCiderPortTypeKey;

// Keys for information dictionary
// Every dictionary has the ID key.  Not every dictionary has the others.
//extern NSString * const BFGameMacAppPathsKey;     // NSArray(NSString)



@interface XFGameManager : XFObject {
	
	NSTimeInterval			lookupTime;
	
	NSInteger				version;
	NSImage					*defaultImage;
	
	// games key is the game ID, object has the keys identified by constants below
	// macGames contains the same dictionaries, and uses the uppercase string of the app path as its key
	NSMutableDictionary		*games;
	NSMutableDictionary		*macGames;
	NSMutableDictionary		*macGameIDs;
	
	NSMutableArray			*runningGames;
	
	// the following is for Aspyr games where both the single player and multiplayer
	// have the same bundle identifier, and are differentiated using the creator code
	NSArray					*specialBundleIDs;
	
	// the following is a dictionary whose keys are NSStrings of the gameIDs of the games installed on the
	// user's Mac, and whose values are NSStrings of the full path to those applications.
	NSMutableDictionary		*installedGameIDsAndPaths;
}

+ (XFGameManager *)defaultManager;
- (NSDictionary *)infoForGameID:(XFGameID)gameID;
- (NSString *)longNameForGameID:(XFGameID)gameID;
- (NSDictionary *)infoForMacApplication:(NSDictionary *)appInfo;
- (NSImage *)defaultImage;

- (NSArray *)runningGames;
- (NSArray *)installedGameIDs;

- (void)launchGameID:(XFGameID)gameID;
- (void)launchGameID:(XFGameID)gameID withAddress:(NSString *)address;
- (void)launchGameID:(XFGameID)gameID withAddress:(NSString *)address password:(NSString *)password;

@end

@interface XFGameManager (GameFinaglerAdditions)
- (NSArray *)installedGamePaths;
- (NSTimeInterval)lookupTime;
@end

@interface NSWorkspace (XFAdditions)
- (BOOL)selectFile:(NSString *)aFile inFileViewerRootedAtPath:(NSString *)aPath activateFileViewer:(BOOL)shouldActivate;
- (BOOL)selectFilesInFileViewer:(NSArray *)filePaths;
- (NSImage *)iconForApplicationForURL:(NSURL *)aURL;
- (NSString *)absolutePathForAppBundleWithIdentifier:(NSString *)aBundleIdentifier name:(NSString *)aNameWithDotApp creator:(NSString *)creator;
@end


