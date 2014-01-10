//
//  HKVPKFile.h
//  HLKit
//
//  Created by Mark Douma on 10/27/2010.
//  Copyright (c) 2009-2012 Mark Douma LLC. All rights reserved.
//

#import <HLKit/HKArchiveFile.h>


enum {
	HKVPKUnknownArchiveType				= 0,
	HKVPKSourceAddonFileArchiveType		= 1,
	HKVPKDirectoryArchiveType			= 2,	// blah_dir.vpk
	HKVPKMultipartArchiveType			= 3,	// blah_001.vpk
};
typedef NSUInteger HKVPKArchiveType;


enum {
	HKSourceAddonStatusUnknown	= 0,
	HKSourceAddonNotAnAddonFile,
	HKSourceAddonNoAddonInfoFound,
	HKSourceAddonAddonInfoUnreadable,
	HKSourceAddonNoGameIDFoundInAddonInfo,
	HKSourceAddonValidAddon
};
typedef NSUInteger HKSourceAddonStatus;


@interface HKVPKFile : HKArchiveFile {
	
	NSUInteger				archiveVersion;
	NSUInteger				archiveCount;
	
	NSString				*archiveDirectoryFilePath;
	
	HKVPKArchiveType		vpkArchiveType;
	
	HKSourceAddonStatus		sourceAddonStatus;
	
	NSUInteger				sourceAddonGameID;
	
}

@property (nonatomic, readonly, assign) NSUInteger archiveVersion;
@property (nonatomic, readonly, assign) NSUInteger archiveCount;

@property (nonatomic, readonly, retain) NSString *archiveDirectoryFilePath;

@property (nonatomic, readonly, assign) HKVPKArchiveType vpkArchiveType;

@property (nonatomic, readonly, assign) HKSourceAddonStatus sourceAddonStatus;

@property (nonatomic, readonly, assign) NSUInteger sourceAddonGameID;



@end


