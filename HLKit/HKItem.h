//
//  HKItem.h
//  HLKit
//
//  Created by Mark Douma on 11/20/2009.
//  Copyright (c) 2009-2012 Mark Douma LLC. All rights reserved.
//

#import <HLKit/HKNode.h>
#import <HLKit/HLKitDefines.h>


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


HLKIT_EXTERN NSString * const HKErrorDomain;
HLKIT_EXTERN NSString * const HKErrorMessageKey;
HLKIT_EXTERN NSString * const HKSystemErrorMessageKey;


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

+ (NSImage *)iconForItem:(HKItem *)anItem;
+ (NSImage *)copiedImageForItem:(HKItem *)anItem;

- (BOOL)writeToFile:(NSString *)aPath assureUniqueFilename:(BOOL)assureUniqueFilename resultingPath:(NSString **)resultingPath error:(NSError **)outError;

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *nameExtension;
@property (nonatomic, retain) NSString *kind;
@property (nonatomic, retain) NSNumber *size;

@property (nonatomic, retain) NSString *path;

@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *dimensions;
@property (nonatomic, retain) NSString *version;
@property (nonatomic, retain) NSString *compression;
@property (nonatomic, retain, setter=setAlpha:) NSString *hasAlpha;
@property (nonatomic, retain) NSString *hasMipmaps;

@property (nonatomic, assign, setter=setExtractable:) BOOL isExtractable;
@property (nonatomic, assign, setter=setEncrypted:) BOOL isEncrypted;
@property (nonatomic, assign) HKFileType fileType;


- (NSString *)pathRelativeToItem:(HKItem *)anItem;

- (NSArray *)descendants;
- (NSArray *)visibleDescendants;

//- (id)parentFromArray:(NSArray *)array;
//- (NSIndexPath *)indexPathInArray:(NSArray *)array;

@end


