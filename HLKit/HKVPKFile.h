//
//  HKVPKFile.h
//  HLKit
//
//  Created by Mark Douma on 10/27/2010.
//  Copyright (c) 2009-2012 Mark Douma LLC. All rights reserved.
//

#import <HLKit/HKArchiveFile.h>


@interface HKVPKFile : HKArchiveFile {

	NSUInteger		archiveCount;
	NSUInteger		addonGameID;
}

@property (nonatomic, readonly, assign) NSUInteger archiveCount;
@property (nonatomic, readonly, assign) NSUInteger	addonGameID;

@end
