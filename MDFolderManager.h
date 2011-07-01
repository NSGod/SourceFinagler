//
//  MDFolderManager.h
//  Font Finagler
//
//  Created by Mark Douma on 11/16/2006.
//  Copyright © 2006-2011 Mark Douma. All rights reserved.
//



#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>

#ifndef _CS_DARWIN_USER_CACHE_DIR	/* provided so compiler doesn't balk when using 10.3.9 or 10.4u SDKs */
#define	_CS_DARWIN_USER_CACHE_DIR		65538
#endif

#ifndef kFontCollectionsFolderType	/* provided so compiler doesn't balk when using 10.3.9 or 10.4u SDKs */
#define kFontCollectionsFolderType 'fncl'
#endif


enum {
	MDUserDomain	=	kUserDomain,			/*	~/										*/
	MDLocalDomain	=	kLocalDomain,			/* /Library/								*/
	MDNetworkDomain	=	kNetworkDomain,			/* /Network/								*/	
	MDSystemDomain	=	kSystemDomain,			/* /System/									*/
	MDClassicDomain	=	kClassicDomain,			/* /System Folder/ (no longer applicable)	*/
	MDAllDomains	=	kOnAppropriateDisk		/* varies									*/
};

typedef FSVolumeRefNum MDSearchPathDomain;

enum {
	MDApplicationsDirectory				=	kApplicationsFolderType,
	MDApplicationSupportDirectory		=	kApplicationSupportFolderType,
	MDCachesDirectory					=	kCachedDataFolderType,
	MDDesktopDirectory					=	kDesktopFolderType,
	MDDocumentsDirectory				=	kDocumentsFolderType,
	MDDownloadsDirectory				=	kDownloadsFolderType,
	MDFontCollectionsDirectory			=	kFontCollectionsFolderType,
	MDFontsDirectory					=	kFontsFolderType,
	MDFontsDisabledDirectory			=	'MDfD',
	MDHomeDirectory						=	kCurrentUserFolderType,
	MDLibraryDirectory					=	kDomainLibraryFolderType,
	MDLogsDirectory						=	kLogsFolderType,
	MDMoviesDirectory					=	kMovieDocumentsFolderType,
	MDMusicDirectory					=	kMusicDocumentsFolderType,
	MDPicturesDirectory					=	kPictureDocumentsFolderType,
	MDPreferencesDirectory				=	kPreferencesFolderType,
	MDQuickTimeComponentsDirectory		=	kQuickTimeComponentsFolderType,
	MDSoundsDirectory					=	kSystemSoundsFolderType,
	MDTemporaryDirectory				=	kTemporaryFolderType,
	MDTrashDirectory					=	kTrashFolderType,
	MDUsersDirectory					=	kUsersFolderType,
	MDDarwinUserCachesDirectory			=	'MDdc'
};


typedef OSType MDSearchPathDirectory;


@interface MDFolderManager : NSObject {
	NSMutableArray	*tempDirectories;
}
+ (MDFolderManager *)defaultManager;
+ (NSString *)tempDirectoryWithIdentifier:(NSString *)aName;
+ (NSString *)tempDirectoryWithIdentifier:(NSString *)aName assureUniqueFilename:(BOOL)flag;
+ (BOOL)cleanupTempDirectoryAtPath:(NSString *)aPath error:(NSError **)outError;

- (NSString *)tempDirectoryWithIdentifier:(NSString *)aName;
- (NSString *)tempDirectoryWithIdentifier:(NSString *)aName assureUniqueFilename:(BOOL)flag;
- (BOOL)cleanupTempDirectoryAtPath:(NSString *)aPath error:(NSError **)outError;

- (NSString *)pathForDirectory:(MDSearchPathDirectory)aDirectory inDomain:(MDSearchPathDomain)aDomain error:(NSError **)outError;
- (NSString *)pathForDirectory:(MDSearchPathDirectory)aDirectory inDomain:(MDSearchPathDomain)aDomain create:(BOOL)create error:(NSError **)outError;

- (NSString *)pathForDirectory:(MDSearchPathDirectory)aDirectory forItemAtPath:(NSString *)aPath error:(NSError **)outError;
- (NSString *)pathForDirectory:(MDSearchPathDirectory)aDirectory forItemAtPath:(NSString *)aPath create:(BOOL)create error:(NSError **)outError;

- (NSString *)pathForDirectoryWithName:(NSString *)aName inDirectory:(MDSearchPathDirectory)aDirectory inDomain:(MDSearchPathDomain)aDomain error:(NSError **)outError;
- (NSString *)pathForDirectoryWithName:(NSString *)aName inDirectory:(MDSearchPathDirectory)aDirectory inDomain:(MDSearchPathDomain)aDomain create:(BOOL)create error:(NSError **)outError;

@end


