//
//  MDItem.h
//  Source Finagler
//
//  Created by Mark Douma on 11/20/2009.
//  Copyright 2009 Mark Douma LLC. All rights reserved.
//

#import "MDNode.h"

enum {
	MDHLErrorNotExtractable = 1
};

enum {
	MDFileTypeNone				= 0,
	MDFileTypeHTML				= 1,
	MDFileTypeText				= 2,
	MDFileTypeImage				= 3,
	MDFileTypeSound				= 4,
	MDFileTypeMovie				= 5,
	MDFileTypeOther				= 6,
	MDFileTypeNotExtractable	= 7
};
typedef NSUInteger MDFileType;


extern NSString * const MDHLErrorDomain;
extern NSString * const MDHLErrorMessageKey;
extern NSString * const MDHLSystemErrorMessageKey;


@interface MDItem : MDNode {
	NSString			*name;
	NSString			*nameExtension;
	NSString			*kind;
	NSNumber			*size;
	
	NSString			*path;
	
	// for images
	NSString			*dimensions;
	NSString			*version;
	NSString			*compression;
	NSString			*hasAlpha;
	NSString			*hasMipmaps;
	
	
	NSString			*type; // UTI
	MDFileType			fileType;
	
	BOOL				isExtractable;
	BOOL				isEncrypted;
	
}

- (BOOL)writeToFile:(NSString *)aPath assureUniqueFilename:(BOOL)assureUniqueFilename resultingPath:(NSString **)resultingPath error:(NSError **)outError;

@property (retain) NSString *name;
@property (retain) NSString	*nameExtension;
@property (retain) NSString *kind;
@property (retain) NSNumber *size;

@property (retain) NSString *path;

@property (retain) NSString *type;
@property (retain) NSString *dimensions;
@property (retain) NSString *version;
@property (retain) NSString *compression;
@property (retain, setter=setAlpha:) NSString *hasAlpha;
@property (retain) NSString *hasMipmaps;

@property (assign, setter=setExtractable:) BOOL isExtractable;
@property (assign, setter=setEncrypted:) BOOL isEncrypted;
@property (assign) MDFileType fileType;


- (NSString *)pathRelativeToItem:(MDItem *)anItem;

- (NSArray *)descendants;
- (NSArray *)visibleDescendants;

//- (id)parentFromArray:(NSArray *)array;
//- (NSIndexPath *)indexPathInArray:(NSArray *)array;

@end


