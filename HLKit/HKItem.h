//
//  HKItem.h
//  Source Finagler
//
//  Created by Mark Douma on 11/20/2009.
//  Copyright 2009 Mark Douma LLC. All rights reserved.
//

#import <HLKit/HKNode.h>

enum {
	HKErrorNotExtractable = 1
};

enum {
	HKFileTypeNone				= 0,
	HKFileTypeHTML				= 1,
	HKFileTypeText				= 2,
	HKFileTypeImage				= 3,
	HKFileTypeSound				= 4,
	HKFileTypeMovie				= 5,
	HKFileTypeOther				= 6,
	HKFileTypeNotExtractable	= 7
};
typedef NSUInteger HKFileType;


extern NSString * const HKErrorDomain;
extern NSString * const HKErrorMessageKey;
extern NSString * const HKSystemErrorMessageKey;


@interface HKItem : HKNode {
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
	HKFileType			fileType;
	
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
@property (assign) HKFileType fileType;


- (NSString *)pathRelativeToItem:(HKItem *)anItem;

- (NSArray *)descendants;
- (NSArray *)visibleDescendants;

//- (id)parentFromArray:(NSArray *)array;
//- (NSIndexPath *)indexPathInArray:(NSArray *)array;

@end


