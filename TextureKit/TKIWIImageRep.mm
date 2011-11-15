//
//  TKIWIImageRep.mm
//  Texture Kit
//
//  Created by Mark Douma on 9/25/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKIWIImageRep.h>
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

#import "TKFoundationAdditions.h"



#define TK_DEBUG 1


NSString * const TKIWIType			= @"com.infinityward.iwi";
NSString * const TKIWIFileType		= @"iwi";
NSString * const TKIWIPboardType	= @"TKIWIPboardType";



@interface TKIWIImageRep (TKPrivate)
+ (NSArray *)imageRepsWithData:(NSData *)aData firstRepresentationOnly:(BOOL)firstRepOnly;
@end



static TKIWIFormat defaultIWIFormat = TKIWIFormatDefault;

@implementation TKIWIImageRep

/* Implemented by subclassers to indicate what UTI-identified data types they can deal with. */
+ (NSArray *)imageUnfilteredTypes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	static NSArray *types = nil;
	if (types == nil) types = [[NSArray alloc] initWithObjects:TKIWIType, nil];
	return types;
}


+ (NSArray *)imageUnfilteredFileTypes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	static NSArray *fileTypes = nil;
	if (fileTypes == nil) fileTypes = [[NSArray alloc] initWithObjects:TKIWIFileType, nil];
	return fileTypes;
}


+ (NSArray *)imageUnfilteredPasteboardTypes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	static NSArray *imageUnfilteredPasteboardTypes = nil;
	
	if (imageUnfilteredPasteboardTypes == nil) {
		NSArray *types = [super imageUnfilteredPasteboardTypes];
		NSLog(@"[%@ %@] super's imageUnfilteredPasteboardTypes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), types);
		imageUnfilteredPasteboardTypes = [[types arrayByAddingObject:TKIWIPboardType] retain];
	}
	return imageUnfilteredPasteboardTypes;
}



//+ (BOOL)canInitWithPasteboard:(NSPasteboard *)pasteboard {
//	
//}



+ (BOOL)canInitWithData:(NSData *)aData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([aData length] < sizeof(OSType)) return NO;
	OSType magic = 0;
	[aData getBytes:&magic length:sizeof(magic)];
	magic = NSSwapBigIntToHost(magic);
	return (magic == TKIWIVersion5Magic || magic == TKIWIVersion6Magic || magic == TKIWIVersion7Magic);
}


+ (Class)imageRepClassForType:(NSString *)type {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([type isEqualToString:TKIWIType]) {
		return [self class];
	}
	return [super imageRepClassForType:type];
}


+ (Class)imageRepClassForFileType:(NSString *)fileType {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([fileType isEqualToString:TKIWIFileType]) {
		return [self class];
	}
	return [super imageRepClassForFileType:fileType];
}


+ (TKIWIFormat)defaultFormat {
	TKIWIFormat defaultFormat = 0;
	@synchronized(self) {
		defaultFormat = defaultIWIFormat;
	}
	return defaultFormat;
}


+ (void)setDefaultFormat:(TKIWIFormat)aFormat {
	@synchronized(self) {
		defaultIWIFormat = aFormat;
	}
}


+ (NSData *)IWIRepresentationOfImageRepsInArray:(NSArray *)tkImageReps options:(NSDictionary *)options {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[self class] IWIRepresentationOfImageRepsInArray:tkImageReps usingFormat:[[self class] defaultFormat] quality:[TKImageRep defaultDXTCompressionQuality] options:options];
}

+ (NSData *)IWIRepresentationOfImageRepsInArray:(NSArray *)tkImageReps usingFormat:(TKVTFFormat)aFormat quality:(TKDXTCompressionQuality)aQuality options:(NSDictionary *)options {
#if TK_DEBUG
	NSLog(@"[%@ %@] tkImageReps == %@, options == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), tkImageReps, options);
#endif
	NSParameterAssert([tkImageReps count] != 0);
	
	return nil;
}



+ (NSArray *)imageRepsWithData:(NSData *)aData firstRepresentationOnly:(BOOL)firstRepOnly {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	OSType magic = 0;
	[aData getBytes:&magic length:sizeof(magic)];
	magic = NSSwapBigIntToHost(magic);
#if TK_DEBUG
	NSLog(@"[%@ %@] magic == 0x%x, %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), magic, NSFileTypeForHFSTypeCode(magic));
#endif
	
	TKIWIHeader header;
	
	if ([aData length] < sizeof(TKIWIHeader)) {
		NSLog(@"[%@ %@] ERROR: !([aData length] < sizeof(TKIWIHeader)) !", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return nil;
	}
	
	NSUInteger currentOffset = 0;
	
	
	[aData getBytes:&header range:NSMakeRange(currentOffset, sizeof(TKIWIHeader))];
	
	header.signature		= NSSwapLittleIntToHost(header.signature);
	header.width			= NSSwapLittleShortToHost(header.width);
	header.height			= NSSwapLittleShortToHost(header.width);
	
	
	
	return nil;
}


+ (NSArray *)imageRepsWithData:(NSData *)aData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[self class] imageRepsWithData:aData firstRepresentationOnly:NO];
}


+ (id)imageRepWithData:(NSData *)aData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSArray *imageReps = [[self class] imageRepsWithData:aData firstRepresentationOnly:YES];
	if ([imageReps count]) return [imageReps objectAtIndex:0];
	return nil;
}

- (id)initWithData:(NSData *)aData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSArray *imageReps = [[self class] imageRepsWithData:aData firstRepresentationOnly:YES];
	if ((imageReps == nil) || !([imageReps count] > 0)) {
		[self release];
		return nil;
	}
	self = [[imageReps objectAtIndex:0] retain];
	return self;
}


- (id)copyWithZone:(NSZone *)zone {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	TKIWIImageRep *copy = (TKIWIImageRep *)[super copyWithZone:zone];
	NSLog(@"[%@ %@] copy == %@, class == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), copy, NSStringFromClass([copy class]));
	return copy;
}


- (id)initWithCoder:(NSCoder *)coder {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (self = [super initWithCoder:coder]) {
		
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super encodeWithCoder:coder];
	
}

@end


