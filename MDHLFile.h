//
//  MDHLFile.h
//  Source Finagler
//
//  Created by Mark Douma on 4/27/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//


#import <Foundation/Foundation.h>


@class MDItem, MDFolder;

enum {
	MDHLFileNoType		= 0,
	MDHLFileBSPType		= 1,
	MDHLFileGCFType		= 2,
	MDHLFilePAKType		= 3,
	MDHLFileVBSPType	= 4,
	MDHLFileWADType		= 5,
	MDHLFileXZPType		= 6,
	MDHLFileZIPType		= 7,
	MDHLFileNCFType		= 8,
	MDHLFileVPKType		= 9
};
typedef NSUInteger MDHLFileType;


@interface MDHLFile : NSObject {
	
	NSString				*filePath;
	
	MDFolder				*items;
	NSMutableArray			*allItems;
	
	NSString				*version;
	
	MDHLFileType			fileType;
	
	BOOL					haveGatheredAllItems;
	
	BOOL					isReadOnly;
	
@protected
	void *_privateData;
	
}

+ (MDHLFileType)fileTypeForData:(NSData *)aData;


- (id)initWithContentsOfFile:(NSString *)aPath;
- (id)initWithContentsOfFile:(NSString *)aPath showInvisibleItems:(BOOL)showInvisibleItems sortDescriptors:(NSArray *)sortDescriptors error:(NSError **)outError;


@property (retain, readonly) NSString *filePath;

@property (assign, readonly) MDHLFileType fileType;

@property (assign, readonly) BOOL isReadOnly;
@property (assign, readonly) BOOL haveGatheredAllItems;


@property (retain) NSString *version;


- (MDFolder *)items;
- (MDItem *)itemAtPath:(NSString *)path;

- (NSArray *)allItems;


@end


