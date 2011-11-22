//
//  HKVPKFile.h
//  Source Finagler
//
//  Created by Mark Douma on 10/27/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <HLKit/HKArchiveFile.h>


extern NSString * const VSAddonInfoNameKey;
extern NSString * const VSAddonSteamAppIDKey;


@interface HKVPKFile : HKArchiveFile {

	NSUInteger		archiveCount;
	NSUInteger		addonGameID;
}

@property (assign, readonly) NSUInteger archiveCount;
@property (assign, readonly) NSUInteger	addonGameID;

@end
