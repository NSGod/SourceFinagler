//
//  HKGCFFile.h
//  HLKit
//
//  Created by Mark Douma on 10/27/2010.
//  Copyright (c) 2009-2011 Mark Douma LLC. All rights reserved.
//

#import <HLKit/HKArchiveFile.h>


@interface HKGCFFile : HKArchiveFile {
	
	NSUInteger		packageID;
	
	NSUInteger		blockSize;
	NSUInteger		totalBlockCount;
	NSUInteger		usedBlockCount;
	NSUInteger		freeBlockCount;
	
	NSUInteger		lastVersionPlayed;
}


@property (assign, readonly) NSUInteger packageID;

@property (assign, readonly) NSUInteger blockSize;
@property (assign, readonly) NSUInteger totalBlockCount;
@property (assign, readonly) NSUInteger usedBlockCount;
@property (assign, readonly) NSUInteger freeBlockCount;

@property (assign, readonly) NSUInteger lastVersionPlayed;

@end
