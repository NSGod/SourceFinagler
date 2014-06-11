//
//  HKArchiveFile.h
//  HLKit
//
//  Created by Mark Douma on 4/27/2010.
//  Copyright (c) 2009-2012 Mark Douma LLC. All rights reserved.
//


#import <Foundation/Foundation.h>


@class HKItem, HKFolder;

enum {
	HKArchiveFileNoType			= 0,
	HKArchiveFileBSPType		= 1,
	HKArchiveFileGCFType		= 2,
	HKArchiveFilePAKType		= 3,
	HKArchiveFileVBSPType		= 4,
	HKArchiveFileWADType		= 5,
	HKArchiveFileXZPType		= 6,
	HKArchiveFileZIPType		= 7,
	HKArchiveFileNCFType		= 8,
	HKArchiveFileVPKType		= 9,
	HKArchiveFileSGAType		= 10
};
typedef NSUInteger HKArchiveFileType;


@interface HKArchiveFile : NSObject {
	
	NSString				*filePath;
	
	NSNumber				*fileSize;
	
	HKFolder				*items;
	NSMutableArray			*allItems;
	
	NSString				*version;
	
	HKArchiveFileType		archiveFileType;
	
	BOOL					haveGatheredAllItems;
	
	BOOL					isReadOnly;
	
@protected
	void *_privateData;
	
}

+ (HKArchiveFileType)archiveFileTypeForContentsOfFile:(NSString *)aPath;


- (id)initWithContentsOfFile:(NSString *)aPath;
- (id)initWithContentsOfFile:(NSString *)aPath showInvisibleItems:(BOOL)showInvisibleItems sortDescriptors:(NSArray *)sortDescriptors error:(NSError **)outError;


@property (nonatomic, readonly, retain) NSString *filePath;

@property (nonatomic, readonly, retain) NSNumber *fileSize;

@property (nonatomic, readonly, assign) HKArchiveFileType archiveFileType;

@property (nonatomic, readonly, assign) BOOL isReadOnly;
@property (nonatomic, readonly, assign) BOOL haveGatheredAllItems;


@property (nonatomic, readonly, retain) NSString *version;


- (HKFolder *)items;
- (HKItem *)itemAtPath:(NSString *)aPath;

- (NSArray *)allItems;


@end


